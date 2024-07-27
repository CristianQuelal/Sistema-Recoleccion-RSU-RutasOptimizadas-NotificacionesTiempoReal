// Importa el paquete flutter_local_notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Crea una instancia del plugin FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin= FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async{ // Método asíncrono para inicializar las notificaciones
  // Configuración de inicialización para Android
  const AndroidInitializationSettings initializationSettingsAndroid= AndroidInitializationSettings('@mipmap/launcher_icon');
  // Configuración de inicialización para iOS
  const DarwinInitializationSettings initializationSettingsIOS= DarwinInitializationSettings();
  // Configuración de inicialización para ambas plataformas
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  // Inicializa el plugin con la configuración especificada
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> mostrarNotificaciones(String mensaje) async { // Método asíncrono para mostrar una notificación
  // Configuración de la notificación para Android
  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'id_canal', // ID del canal de notificación
    'nombre_canal', // Nombre del canal de notificación
    importance: Importance.max, // Importancia máxima
    priority: Priority.high, // Prioridad alta
  );
  // Configuración de la notificación para plataforma Android
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );
// Muestra la notificación con el título, mensaje y configuración especificados
  await flutterLocalNotificationsPlugin.show(
    1, // ID de la notificación
    'ResiRutas', // Título de la notificación
    mensaje, // Mensaje de la notificación
    notificationDetails, // Configuración de la notificación
  );
}
