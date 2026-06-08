import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/sofer/documente/sofer_documente_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _orderSubscription;

  Future<void> initialize() async {
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

    _fcm.onTokenRefresh.listen(_saveFcmToken);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundTap);

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _navigateToOrder(initialMessage.data['orderId'] ?? '');
    }
  }

  Future<void> _saveFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
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

  void startOrderListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _orderSubscription?.cancel();

    final now = DateTime.now();
    final startOfShift = DateTime(now.year, now.month, now.day, 7, 0, 0);
    final endOfShift = DateTime(now.year, now.month, now.day + 1, 1, 0, 0);

    _orderSubscription = FirebaseFirestore.instance
        .collection('comenzi')
        .where('status', isEqualTo: 'In asteptare')
        .where('data_creare', isGreaterThanOrEqualTo: startOfShift)
        .where('data_creare', isLessThan: endOfShift)
        .snapshots()
        .listen((_) {});
  }

  void stopOrderListener() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
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
