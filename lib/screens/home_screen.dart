import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Regla 2: Tipado estricto (No 'dynamic', uso explícito de bool y String)
  bool _isServiceActive = false;
  bool _isDarkMode = true; // Nuevo estado para el Tema

  // Instancia del reproductor de voz de Android/iOS
  final FlutterTts _flutterTts = FlutterTts();
  
  // Suscripción en segundo plano del listener
  StreamSubscription<ServiceNotificationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _initTts();
    _checkPermissionStatus();
  }

  // Inicializar configuración de TTS para que sea secuencial
  Future<void> _initTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
  }

  // Verificar estado del permiso maestro sin pedirlo activamente al inicio
  Future<void> _checkPermissionStatus() async {
    bool isGranted = await NotificationListenerService.isPermissionGranted();
    if (isGranted) {
      // Si ya tiene permisos y no estamos escuchando, podemos prepararnos
      debugPrint("Permisos concedidos previamente");
    }
  }

  // Lógica principal de Activar/Desactivar el listener
  void _toggleService() async {
    if (_isServiceActive) {
      // Apagar
      _subscription?.cancel();
      setState(() {
        _isServiceActive = false;
      });
    } else {
      // Encender
      bool isGranted = await NotificationListenerService.isPermissionGranted();
      if (!isGranted) {
        // Pedir permiso, abre ajustes
        await NotificationListenerService.requestPermission();
        return; // El usuario se irá a Configuración, no encendemos aún
      }

      setState(() {
        _isServiceActive = true;
      });
      _startListeningNotifications();
    }
  }

  // Conexión al canal infinito de Android (Notificaciones en Vivo)
  void _startListeningNotifications() {
    _subscription = NotificationListenerService.notificationsStream.listen((event) {
      // 1. Filtramos solo lo que venga del paquete nativo de Yape
      if (event.packageName == 'com.bcp.innovacxion.yapeapp' && event.content != null) {
        String content = event.content!;
        
        // 2. Extraemos el mensaje limpio
        String? speakableMessage = _parseYapeNotification(content);
        if (speakableMessage != null) {
          _speak(speakableMessage);
        }
      }
    });
  }

  // Regla Inteligente: Parseador de Notificaciones 
  String? _parseYapeNotification(String text) {
    if (!text.contains("te envió un pago por S/")) return null;
    
    // Separamos el texto usando la frase clave pivot
    List<String> parts = text.split("te envió un pago por S/");
    if (parts.length < 2) return null;
    
    String rawName = parts[0].trim();
    String rawAmountInfo = parts[1].trim();
    
    // Limpieza 1: Si hay un prefijo de 'Yape! '
    if (rawName.startsWith("Yape!")) {
      rawName = rawName.substring(5).trim();
    }
    
    // Limpieza 2: Tomar el primer nombre sin asteriscos ni símbolos extraños
    String firstName = rawName.split(" ").first.replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ]'), '');
    
    // Extracción 3: El número (Soporta ej "1.00", "5.50" o "1.")
    RegExp amountRegex = RegExp(r'^(\d+(?:\.\d+)?)');
    Match? match = amountRegex.firstMatch(rawAmountInfo);
    if (match != null) {
      String amountStr = match.group(1)!;
      double? amount = double.tryParse(amountStr);
      if (amount != null) {
        
        // --- NUEVA LÓGICA DE SOLES Y CÉNTIMOS ---
        int enteros = amount.toInt();
        // Redondeamos para evitar errores de precisión (ej. 1.50 -> 50 céntimos)
        int centimos = ((amount - enteros) * 100).round();
        
        String speakableMoney = "";

        // 1. Decir los soles si hay
        if (enteros > 0 || centimos == 0) {
          String monedaSoles = (enteros == 1) ? "sol" : "soles";
          speakableMoney = "$enteros $monedaSoles";
        }

        // 2. Decir los céntimos si hay
        if (centimos > 0) {
          String textCentimos = "$centimos céntimos";
          
          if (enteros > 0) {
            // "5 soles con 50 céntimos"
            speakableMoney += " con $textCentimos";
          } else {
            // Solo depositaron céntimos (Raro pero funcional): "50 céntimos"
            speakableMoney = textCentimos;
          }
        }
        
        return "$firstName te yapeó $speakableMoney";
      }
    }
    return null;
  }

  // Leer manualmente las notificaciones actuales que ya están en el celular
  Future<void> _readActiveNotifications() async {
    bool isGranted = await NotificationListenerService.isPermissionGranted();
    if (!isGranted) {
      await _speak("Por favor, enciende el servicio primero para darme permiso.");
      return;
    }

    try {
      final List<ServiceNotificationEvent> events = await NotificationListenerService.getActiveNotifications();
      
      int yapeCount = 0;
      for (var event in events) {
        // Primero verificamos que sea de Yape
        if (event.packageName == 'com.bcp.innovacxion.yapeapp' && event.content != null) {
          String content = event.content!;
          
          String? speakableMessage = _parseYapeNotification(content);
          if (speakableMessage != null) {
            yapeCount++;
            await _speak(speakableMessage);
            // Pequeña pausa de seguridad entre mensajes
            await Future.delayed(const Duration(milliseconds: 1500));
          }
        }
      }

      if (yapeCount == 0) {
        await _speak("No tienes pagos de Yape recientes en tus notificaciones.");
      }
    } catch (e) {
      debugPrint("Error leyendo actuales: $e");
    }
  }

  // Reproductor final universal
  Future<void> _speak(String message) async {
    try {
      await _flutterTts.setLanguage("es-ES");
      await _flutterTts.setPitch(1.0); 
      await _flutterTts.setSpeechRate(0.5); 
      await _flutterTts.speak(message);
    } catch (e) {
      debugPrint("Error TTS: $e");
    }
  }

  // Botón de prueba (opcional, dejamos el de Pablito intacto por ahora para testear TTS)
  Future<void> _speakGreeting() async {
    await _speak("Hola, soy Pablito");
  }

  @override
  Widget build(BuildContext context) {
    // Regla 1: Diseño 100% Responsivo y Seguro (SafeArea implementado)
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _buildHeaderButton(
                    icon: Icons.volume_up,
                    label: 'Pablito Voice',
                    onTap: () {
                      _speakGreeting(); // Llamamos a la función asíncrona de voz al tocar
                    },
                  ),
                  _buildIconOnlyButton(
                    icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    onTap: () {
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32.0),
              
              // Logos superpuestos / juntos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildLogoImage('assets/images/app_icon.png', width: 70.0, height: 70.0),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('+', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  _buildLogoImage('assets/images/yape-logo-fondo-transparente.png', width: 70.0, height: 70.0),
                ],
              ),
              const SizedBox(height: 24.0),
              
              // Título y Descripción principal
              Text(
                'Yape Notify',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                'Detecta automáticamente tus pagos de Yape y mantén el control de tus ingresos al instante.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Estado visual de Servicio Arreglado
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    _isServiceActive ? 'Servicio Activo ' : 'Servicio Inactivo ', // Solución a UI errónea pedida
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: _isDarkMode ? Colors.white : Colors.black87),
                  ),
                  Text('📡', style: TextStyle(fontSize: 16.0, color: _isServiceActive ? Colors.white : Colors.white38)),
                ],
              ),
              
              const Spacer(),
              
              // Botón Gigante (Toggle OFF/ON)
              GestureDetector(
                onTap: _toggleService, // Llama a la lógica de permisos real
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 180.0,
                  height: 180.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Si está activo es Azul, si está OFF es Rojo.
                    color: _isServiceActive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: _isServiceActive ? const Color(0x403B82F6) : const Color(0x40EF4444),
                        blurRadius: 24.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isServiceActive ? 'ON' : 'OFF',
                      style: const TextStyle(
                        fontSize: 48.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white, // Blanco fijo para contrastar bien con el Rojo/Azul
                      ),
                    ),
                  ),
                ),
              ),
              
              // Botón para Leer Notificaciones Actuales de la Barra
              const SizedBox(height: 16.0),
              GestureDetector(
                onTap: _readActiveNotifications,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF181B26) : Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: _isDarkMode ? Colors.white10 : Colors.black12),
                    boxShadow: _isDarkMode ? null : const [BoxShadow(color: Colors.black12, blurRadius: 4.0)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.history, size: 20.0, color: _isDarkMode ? Colors.white70 : Colors.black87),
                      const SizedBox(width: 8.0),
                      Text(
                        'Leer Notificaciones Actuales',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Cuidado y Estado del Sistema en la parte baja (Regla 1 de layouts flexibles)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF181B26) : Colors.white, 
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: _isDarkMode ? Colors.white10 : Colors.transparent),
                  boxShadow: _isDarkMode ? null : const [BoxShadow(color: Colors.black12, blurRadius: 4.0)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Estado del Sistema',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _isServiceActive
                          ? 'Escuchando en segundo plano los pagos de Yape. Puedes minimizar la aplicación con seguridad.'
                          : 'Esperando a configurar el permiso de notificaciones o ser activado...',
                      style: TextStyle(color: _isDarkMode ? Colors.white54 : Colors.black54, fontSize: 13.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: _isDarkMode ? const Color(0xFF0F111A) : const Color(0xFFE8ECEF), // Un gris mucho más relajante para los ojos en lugar de blanco resplandeciente
    );
  }

  // Regla 4: Arquitectura y Modularidad. (Funciones pequeñas que devuelven la IU modularizada)
  Widget _buildHeaderButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF181B26) : Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: _isDarkMode ? null : [BoxShadow(color: Colors.black12, blurRadius: 4.0)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 20.0, color: _isDarkMode ? Colors.white : Colors.black87),
            const SizedBox(width: 8.0),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0, color: _isDarkMode ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconOnlyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF181B26) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: _isDarkMode ? null : const [BoxShadow(color: Colors.black12, blurRadius: 4.0)],
        ),
        child: Icon(icon, size: 20.0, color: _isDarkMode ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildLogoImage(String path, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF181B26) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: _isDarkMode ? null : const [BoxShadow(color: Colors.black12, blurRadius: 4.0)],
      ),
      child: Center(
        child: Image.asset(
          path,
          width: width * 0.6,
          height: height * 0.6,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

}
