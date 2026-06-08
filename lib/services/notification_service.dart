import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gazprof/core/constants.dart';

import '../screens/sofer/documente/sofer_documente_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  Future<void> initialize() async {
    _tokenRefreshSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFcmToken(token);
    }

    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen(_saveFcmToken);

    _onMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundTap);

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _navigateToOrder(initialMessage.data['orderId'] ?? '');
    }
  }

  Future<void> _saveFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(user.uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    }
  }

  Future<void> saveFcmTokenIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFcmToken(token);
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    stopOrderListener();
  }

  void startOrderListener() {
    // Reserved for future use
  }

  void stopOrderListener() {
    // Reserved for future use
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final orderId = data['orderId'] ?? '';
    final type = data['type'] ?? '';
    if (notification == null || orderId.isEmpty) return;

    final isUrgent = type == 'urgent_order';
    final androidDetails = AndroidNotificationDetails(
      'new_orders',
      'Comenzi noi',
      channelDescription: 'Notificări pentru comenzi noi disponibile',
      importance: Importance.high,
      priority: Priority.high,
      color: isUrgent ? const Color(0xFFFF0000) : const Color(0xFF0779B7),
      icon: '@mipmap/launcher_icon',
    );
    final details = NotificationDetails(android: androidDetails);
    _localNotifications.show(
      orderId.hashCode,
      notification.title,
      notification.body,
      details,
      payload: orderId,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final orderId = response.payload ?? '';
    _navigateToOrder(orderId);
  }

  void _handleBackgroundTap(RemoteMessage message) {
    final orderId = message.data['orderId'] ?? '';
    _navigateToOrder(orderId);
  }

  void _navigateToOrder(String orderId) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SoferDocumenteScreen()),
      (route) => false,
    );
  }
}
