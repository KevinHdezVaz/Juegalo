import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Handler para mensajes en background (top-level, fuera de clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [BG] Notificación recibida: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  // Stream que emite rutas cuando el usuario toca una notificación
  final _routeController = StreamController<String>.broadcast();
  Stream<String> get onNavigate => _routeController.stream;

  // Stream que emite cuando el usuario toca una notificación de pago
  final _paymentController = StreamController<void>.broadcast();
  Stream<void> get onPaymentTapped => _paymentController.stream;

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;
    final screen = message.data['screen'] as String?;
    if (screen == null) return;
    final route = switch (screen) {
      'wallet'  => '/home/cashout',
      'home'    => '/home',
      'profile' => '/profile',
      _         => '/home',
    };
    debugPrint('🔔 [Notification] Navegando a: $route');
    _routeController.add(route);

    // Si es una notificación de pago, emitir señal para reseña
    if (screen == 'wallet') {
      debugPrint('🔔 [Notification] Pago recibido — activando señal de reseña');
      _paymentController.add(null);
    }
  }

  // Canal Android
  static const _androidChannel = AndroidNotificationChannel(
    'juegalo_main',
    'JUEGALO Notificaciones',
    description: 'Alertas de bonos, ranking y actividad',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init() async {
    // Registrar handler background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configurar canal Android
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Inicializar flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Escuchar mensajes en foreground → mostrar notificación local
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // App en background → usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Guardar token cuando se renueva
    _fcm.onTokenRefresh.listen(_saveToken);
  }

  /// Llamar desde el splash después de que el router esté listo.
  /// Maneja el caso de app cerrada → usuario toca notificación.
  Future<void> checkInitialMessage() async {
    try {
      // En iOS simulator / dispositivos sin APNS puede colgarse indefinidamente
      final message = await _fcm.getInitialMessage().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⚠️ [Notification] getInitialMessage timeout, continuando...');
          return null;
        },
      );
      _handleMessage(message);
    } catch (e) {
      debugPrint('⚠️ [Notification] checkInitialMessage error: $e');
    }
  }

  /// Pide permisos y guarda el token en Supabase.
  /// Llamar después de que el usuario inicia sesión.
  Future<void> requestAndSaveToken() async {
    // Pedir permiso (iOS muestra diálogo, Android 13+ también)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('🔕 Permisos de notificación denegados');
      return;
    }

    // iOS: necesita APNS token primero (no disponible en simulador)
    if (Platform.isIOS) {
      try {
        final apns = await _fcm.getAPNSToken();
        if (apns == null) {
          debugPrint('⚠️ APNS token no disponible (simulador o sin permisos)');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ APNS no disponible: $e');
        return;
      }
    }

    try {
      final token = await _fcm.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('⚠️ No se pudo obtener FCM token: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    // Supabase puede no estar inicializado aún (race condition al arrancar)
    try {
      Supabase.instance.client;
    } catch (_) {
      debugPrint('⚠️ FCM token recibido antes de inicializar Supabase, ignorando');
      return;
    }

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token}).eq('id', uid);
      debugPrint('✅ FCM token guardado: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Error guardando FCM token: $e');
    }
  }

  void _handleForeground(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    // Si es un pago aprobado con la app abierta, activar review también
    final type = message.data['type'] as String?;
    if (type == 'cashout_paid') {
      debugPrint('🔔 [Notification] Pago recibido en foreground — activando señal de reseña');
      _paymentController.add(null);
    }

    _local.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Limpia el token al cerrar sesión
  Future<void> clearToken() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': null}).eq('id', uid);
      await _fcm.deleteToken();
    } catch (_) {}
  }
}
