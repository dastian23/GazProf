import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  auth.ServiceAccountCredentials? _credentials;
  bool _initialized = false;

  Future<void> initialize() async {
    final base64Json = dotenv.env['FCM_SERVICE_ACCOUNT_BASE64'];
    debugPrint('[FCM] init, base64 length: ${base64Json?.length}');
    if (base64Json == null || base64Json.isEmpty) return;

    try {
      final jsonStr = utf8.decode(base64Decode(base64Json));
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      _credentials = auth.ServiceAccountCredentials.fromJson(jsonMap);
      _initialized = true;
      debugPrint('[FCM] initialized successfully');
    } catch (e) {
      debugPrint('[FCM] init error: $e');
    }
  }

  Future<void> sendNewOrderNotification(
    String orderId,
    Map<String, dynamic> orderData,
  ) async {
    debugPrint('[FCM] sendNewOrderNotification called, initialized: $_initialized');
    if (!_initialized) return;

    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rol', isEqualTo: 'sofer')
          .get();
      debugPrint('[FCM] found ${usersSnapshot.docs.length} sofer users');

      final tokens = <String>[];
      for (final doc in usersSnapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      debugPrint('[FCM] tokens found: ${tokens.length}');
      if (tokens.isEmpty) return;

      final adresa = orderData['adresa_livrare'] ?? 'Adresă necunoscută';
      final blocAp = orderData['bloc_apartament'] ?? '';
      final adresaCompleta = blocAp.isNotEmpty ? '$adresa, $blocAp' : adresa;
      final total = orderData['total_comanda'] ?? 0;
      final produse = orderData['produse'] ?? [];
      final tipPlata = orderData['tip_plata'] ?? 'cash';
      final tipAdresa = orderData['tip_adresa'] ?? 'oras';

      final produseLines = (produse as List)
          .map((p) => '${p['cantitate']}x ${p['nume']}')
          .toList();

      final tipPlataLabel = tipPlata.toString().toLowerCase() == 'card' ? 'Card' : tipPlata.toString().toLowerCase() == 'facutara' ? 'Facutara' : 'Cash';
      final tipAdresaLabel = tipAdresa.toString().toLowerCase() == 'rute' ? 'Rute' : 'Oraș';

      final bodyLines = <String>[
        adresaCompleta,
        ...produseLines,
        '$tipPlataLabel — $tipAdresaLabel',
      ];
      final body = bodyLines.join('\n');

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(_credentials!, scopes);

      int successCount = 0;
      int failureCount = 0;

      for (final token in tokens) {
        final message = {
          'message': {
            'token': token,
            'notification': {
              'title': 'Comandă nouă — $total lei',
              'body': body,
            },
            'data': {
              'orderId': orderId,
              'type': 'new_order',
            },
            'android': {
              'priority': 'HIGH',
              'notification': {
                'channel_id': 'new_orders',
                'color': '#0779B7',
                'visibility': 'PUBLIC',
                'sound': 'default',
                'notification_count': 1,
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                  'alert': {
                    'title': 'Comandă nouă — $total lei',
                    'body': body,
                  },
                },
              },
            },
          },
        };

        final response = await client.post(
          Uri.parse('https://fcm.googleapis.com/v1/projects/gazprof-ec09d/messages:send'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(message),
        );

        if (response.statusCode == 200) {
          successCount++;
        } else {
          failureCount++;
          debugPrint('FCM error ${response.statusCode}: ${response.body}');
        }
      }

      client.close();
      debugPrint('FCM sent: $successCount success, $failureCount failure');
    } catch (e) {
      debugPrint('FCM error: $e');
    }
  }
}
