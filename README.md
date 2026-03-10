# Yape Pablituuu Notify 🔔

🛡️ **Escucha Activa de Pagos de Yape** con Voice-To-Speech.

Una herramienta diseñada para comerciantes, emprendedores y usuarios activos de Yape que necesitan estar informados instantáneamente sobre cualquier pago recibido en su Android sin tener que encender la pantalla constantemente.

---

## ✨ Características Principales

- 🗣️ **Lectura Inteligente de Voz (TTS)**: Te lee en voz alta cada pago de Yape con gramática humana ("Pablito te yapeó 10 soles con 50 céntimos").
- 🥷 **Servicio en Segundo Plano**: Funciona perfectamente con la pantalla apagada o mientras usas otras apps.
- 🧹 **Filtro Inteligente de Textos**: Transforma los textos secos de las notificaciones oficiales en lenguaje conversacional simple y remueve símbolos innecesarios.
- 🎨 **Interfaz Dual y Mínima**: Un interruptor robusto y gigantesco para cambiar entre encendido/apagado, y un selector nativo entre Modo Claro / Modo Oscuro.
- 🔍 **Lector de Historial en Barra**: Presionando un botón puedes decirle a la app que escudriñe las notificaciones encoladas actualmente para no perder ni un solo Yape si el modo en vivo estaba desactivado.

## 🔥 Diseño y UX

Construido utilizando buenas prácticas y respetando la simetría y el espaciado (Responsive Design) de Android y iOS moderno:
- Animaciones dinámicas de transición sobre botones masivos y legibles.
- Feedback del estado del servicio de notificaciones en tiempo real, en la parte inferior de la pantalla.
  
## 🛠️ Tecnologías Utilizadas

- **Flutter / Dart** (Último SDK)
- **Android Native** (`android.service.notification.NotificationListenerService`)
- Lector TTS vía `flutter_tts` integrado a `es-ES`.
- `notification_listener_service`

---

### Instalación (Android)

1. Descarga el paquete oficial `.apk` de la sección Releases.
2. Instala la app en tu celular Android.
3. Permite la escucha de Interceptor de Notificaciones en la ventana "Acceso Especial".
4. ¡Disfruta escuchando tus Yapes sin mirar tu teléfono!

*Desarrollado con ❤️ para maximizar productividad.*
