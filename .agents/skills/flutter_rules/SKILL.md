---
name: Flutter Coding Rules
description: Reglas estrictas de programación en Flutter para este proyecto, incluyendo UI responsiva, tipado fuerte y manejo de nulos.
---
# Reglas Centrales de Código para la App

## Regla 1: Diseño 100% Responsivo y Seguro (SafeArea)
- Todo el contenido principal de las pantallas ("Scaffold body") debe estar envuelto en un widget `SafeArea`.
- Usar proporciones relativas (como `MediaQuery`, `Flexible`, `Expanded`) en lugar de dimensiones fijas en píxeles rígidos en la medida de lo posible.

## Regla 2: Seguridad de Tipado Estricto (Cero "any" o "dynamic")
- Especificar siempre el tipo exacto en las variables y retornos de funciones (ej. `String`, `int`, `double`).
- NUNCA usar `dynamic` intencionalmente para la lógica principal. Si interactuamos con JSON de notificaciones, se debe "parsear" de inmediato a objetos y tipos concretos.
- No hacer autocompletados con tipos genéricos inciertos.

## Regla 3: Código Funcional, Limpio y Null Safety
- Todo el código entregado debe estar completo y debe compilar a la primera (cero "completa el resto aquí").
- Respetar de forma implacable el "Null Safety" de Dart. Se debe verificar si los datos de la notificación existen antes de mostrarlos para evitar crasheos por valores nulos.
- Las llamadas a servicios asíncronos incluirán manejo de errores (`try-catch`).

## Regla 4: Arquitectura y Modularidad
- Separar claramente la Interfaz de Usuario (Widgets visuales) del "Cerebro" (lógica de fondo y permisos).
- Mantener los archivos organizados por módulos.

## Regla 5: Eliminación de Todo lo Innecesario (Limpieza de Código)
- Eliminar rigurosamente todos los comentarios autogenerados (como los de Flutter al crear el proyecto) y código de ejemplos previos (ej. el contador u otros estados no usados).
- El código entregado será limpio, conciso y libre de variables, importaciones o clases que no estén en uso ("Dead code").
