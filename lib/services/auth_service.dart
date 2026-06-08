import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_auth;
import 'package:gazprof/core/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- REGISTER ---
  Future<String?> signUpUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection(FirestoreCollections.users).doc(res.user!.uid).set({
        'nume': name,
        'telefon': phone,
        'email': email,
        'rol': 'neatribuit',
        'data_creare': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // --- LOGIN & FETCHING DATA ---
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      var userCheck = await _db.collection(FirestoreCollections.users).where('email', isEqualTo: email.trim()).get();
      if (userCheck.docs.isEmpty) {
        return {'success': false, 'error': 'Email sau parolă incorectă.'};
      }

      // 1. Authentication
      UserCredential res = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Extract the user's document from Firestore
      DocumentSnapshot doc = await _db.collection(FirestoreCollections.users).doc(res.user!.uid).get();

      if (doc.exists) {
        return {
          'success': true,
          'rol': doc['rol'] ?? 'neatribuit',
          'nume': doc['nume'] ?? 'Utilizator',
          'email': doc['email'] ?? email.trim(),
        };
      } else {
        await _auth.signOut();
        return {'success': false, 'error': 'Email sau parolă incorectă.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'E-mail sau parolă incorectă.'};
    }
  }

  // --- GOOGLE SIGN IN ---
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final g_auth.GoogleSignInAccount? googleUser = await g_auth.GoogleSignIn().signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Conectarea a fost anulată.'};
      }

      final String userEmail = googleUser.email;

      var userCheck = await _db.collection(FirestoreCollections.users).where('email', isEqualTo: userEmail).get();
      if (userCheck.docs.isEmpty) {
        await g_auth.GoogleSignIn().signOut();
        return {
          'success': false,
          'error': 'Trebuie să te înregistrezi mai întâi ca să te poți loga.'
        };
      }

      final g_auth.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot doc = await _db.collection(FirestoreCollections.users).doc(user.uid).get();

        if (doc.exists) {
          return {
            'success': true,
            'rol': doc['rol'] ?? 'neatribuit',
            'nume': doc['nume'] ?? user.displayName ?? 'Utilizator Google',
            'email': doc['email'] ?? userEmail,
          };
        } else {
          await user.delete();
          await g_auth.GoogleSignIn().signOut();
          return {
            'success': false,
            'error': 'Datele utilizatorului nu au fost găsite.'
          };
        }
      }
      return {'success': false, 'error': 'Eroare necunoscută la conectare.'};
    } catch (e) {
      await g_auth.GoogleSignIn().signOut();
      return {'success': false, 'error': 'Eroare la conectarea cu Google: ${e.toString()}'};
    }
  }

  // --- FORGOT PASSWORD ---
  Future<String?> sendOtpCode(String email) async {
    try {
      final normalizedEmail = email.trim();
      var userCheck = await _db.collection(FirestoreCollections.users).where('email', isEqualTo: normalizedEmail).get();
      if (userCheck.docs.isEmpty) return null;

      String otpCode = (1000 + Random().nextInt(9000)).toString();

      await _db.collection(FirestoreCollections.passwordResets).doc(normalizedEmail).set({
        'otp': otpCode,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
        'attempts': 0,
      });

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json', 'Origin': 'http://localhost'},
        body: json.encode({
          'service_id': dotenv.env['EMAILJS_SERVICE_ID'],
          'template_id': dotenv.env['EMAILJS_TEMPLATE_ID'],
          'user_id': dotenv.env['EMAILJS_USER_ID'],
          'template_params': {'to_email': normalizedEmail, 'otp_code': otpCode}
        }),
      );

      return response.statusCode == 200 ? null : "Eroare server email";
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String enteredCode) async {
    try {
      var doc = await _db.collection(FirestoreCollections.passwordResets).doc(email.trim()).get();
      if (!doc.exists) return {'verified': false, 'locked': false, 'secondsLeft': 0, 'attemptsLeft': 0};

      final data = doc.data()!;

      final lockedUntil = data['lockedUntil'] as int?;
      if (lockedUntil != null && DateTime.now().millisecondsSinceEpoch < lockedUntil) {
        final secondsLeft = ((lockedUntil - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
        return {'verified': false, 'locked': true, 'secondsLeft': secondsLeft, 'attemptsLeft': 0};
      }

      final expiresAt = data['expiresAt'] as int;
      if (DateTime.now().millisecondsSinceEpoch >= expiresAt) {
        return {'verified': false, 'locked': false, 'secondsLeft': 0, 'attemptsLeft': 0};
      }

      if (data['otp'] == enteredCode) {
        await _auth.sendPasswordResetEmail(email: email.trim());
        await _db.collection(FirestoreCollections.passwordResets).doc(email.trim()).delete();
        return {'verified': true, 'locked': false, 'secondsLeft': 0, 'attemptsLeft': 5};
      }

      final attempts = (data['attempts'] as int? ?? 0) + 1;
      const maxAttempts = 5;
      final attemptsLeft = maxAttempts - attempts;

      if (attempts >= maxAttempts) {
        await doc.reference.update({
          'attempts': attempts,
          'lockedUntil': DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch,
        });
        return {'verified': false, 'locked': true, 'secondsLeft': 30, 'attemptsLeft': 0};
      }

      await doc.reference.update({'attempts': attempts});
      return {'verified': false, 'locked': false, 'secondsLeft': 0, 'attemptsLeft': attemptsLeft};
    } catch (e) {
      return {'verified': false, 'locked': false, 'secondsLeft': 0, 'attemptsLeft': 0};
    }
  }

  Future<void> logOut() async {
    try {
      await _auth.signOut();
      await g_auth.GoogleSignIn().signOut();
    } catch (e) {
      if (kDebugMode) debugPrint("Eroare la deconectare: $e");
    }
  }

  Future<void> sendPasswordResetEmailDirect(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}