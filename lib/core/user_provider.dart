import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String _userName = "";
  String _userStatus = "";
  String _userEmail = "";

  String get userName => _userName;
  String get userStatus => _userStatus;
  String get userEmail => _userEmail;

  // Update data locally and notify all screens
  void setUserData(String name, String status, String email) {
    _userName = name;
    _userStatus = status;
    _userEmail = email;
    notifyListeners();
  }

  // Function to reload data from firebase
  Future<void> refreshUser() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      String uid = currentUser.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        _userName = doc['nume'] ?? "";
        _userStatus = doc['status'] ?? "";
        _userEmail = doc['email'] ?? "";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Eroare refresh user: $e");
    }
  }
}