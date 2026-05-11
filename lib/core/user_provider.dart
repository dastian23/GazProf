import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String _userName = "";
  String _userStatus = "";

  String get userName => _userName;
  String get userStatus => _userStatus;

  // Update data locally and notify all screens
  void setUserData(String name, String status) {
    _userName = name;
    _userStatus = status;
    notifyListeners();
  }

  // Function to reload data from firebase
  Future<void> refreshUser() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        _userName = doc['nume'] ?? "";
        _userStatus = doc['status'] ?? "";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Eroare refresh user: $e");
    }
  }
}