import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_auth;

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

      await _db.collection('users').doc(res.user!.uid).set({
        'nume': name,
        'telefon': phone,
        'email': email,
        'rol': 'neatribuit',
        'esteAprobat': false,
        //'status': 'neatribuit',
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
      // 1. Authentication
      UserCredential res = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Extract the user's document from Firestore
      DocumentSnapshot doc = await _db.collection('users').doc(res.user!.uid).get();

      if (doc.exists) {
        return {
          'success': true,
          'rol': doc['rol'] ?? 'neatribuit',
          'nume': doc['nume'] ?? 'Utilizator',
          //'status': doc['status'] ?? 'neatribuit',
        };
      } else {
        return {'success': false, 'error': 'Datele utilizatorului nu au fost găsite în baza de date.'};
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

      final g_auth.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );


      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();

        if (doc.exists) {
          return {
            'success': true,
            'rol': doc['rol'] ?? 'neatribuit',
            'nume': doc['nume'] ?? user.displayName ?? 'Utilizator Google',
            //'status': doc['status'] ?? 'neatribuit',
          };
        } else {
          await _db.collection('users').doc(user.uid).set({
            'nume': user.displayName ?? 'Utilizator Google',
            'email': user.email,
            'rol': 'neatribuit',
            'esteAprobat': false,
            //'status': 'neatribuit',
            'data_creare': FieldValue.serverTimestamp(),
          });

          return {
            'success': true,
            'rol': 'neatribuit',
            'nume': user.displayName ?? 'Utilizator Google',
            //'status': 'neatribuit',
          };
        }
      }
      return {'success': false, 'error': 'Eroare necunoscută la conectare.'};
    } catch (e) {
      return {'success': false, 'error': 'Eroare la conectarea cu Google: ${e.toString()}'};
    }
  }

  // --- FORGOT PASSWORD ---
  // --- STEP 1: SENDING OTP CODE ---
  Future<String?> sendOtpCode(String email) async {
    try {
      final normalizedEmail = email.trim();
      var userCheck = await _db.collection('users').where('email', isEqualTo: normalizedEmail).get();
      if (userCheck.docs.isEmpty) return "Nu există un cont cu acest email.";

      String otpCode = (1000 + Random().nextInt(9000)).toString();

      await _db.collection('password_resets').doc(normalizedEmail).set({
        'otp': otpCode,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      });

      // Load keys securely from .env file
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

  // --- STEP 2: VALIDATE OTP CODE ---
  Future<bool> verifyOtp(String email, String enteredCode) async {
    try {
      var doc = await _db.collection('password_resets').doc(email.trim()).get();
      if (!doc.exists) return false;

      bool isValid = (doc.data()!['otp'] == enteredCode &&
          DateTime.now().millisecondsSinceEpoch < doc.data()!['expiresAt']);

      if (isValid) {
        await _auth.sendPasswordResetEmail(email: email.trim());
        await _db.collection('password_resets').doc(email.trim()).delete();
      }

      return isValid;
    } catch (e) {
      return false;
    }
  }

  // --- STEP 3: UPDATE THE PASSWORD --- 
  Future<String?> updatePasswordManual(String email, String newPassword) async {
    try {
      // 1. Searching user's UID by email
      var userQuery = await _db.collection('users').where('email', isEqualTo: email.trim()).get();

      if (userQuery.docs.isNotEmpty) {
        String uid = userQuery.docs.first.id;

        // 2. Update the password in the firestore document
        await _db.collection('users').doc(uid).update({
          'parola_resetata': true,
          'ultima_actualizare_parola': FieldValue.serverTimestamp(),
        });

        await _auth.sendPasswordResetEmail(email: email.trim());

        return null;
      }
      return "Utilizatorul nu a fost găsit.";
    } catch (e) {
      return e.toString();
    }
  }

  // --- LOGOUT ---
  Future<void> logOut() async {
    try {
      await _auth.signOut();

      await g_auth.GoogleSignIn().signOut();
    } catch (e) {
      print("Eroare la deconectare: $e");
    }
  }

  Future<void> sendPasswordResetEmailDirect(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}