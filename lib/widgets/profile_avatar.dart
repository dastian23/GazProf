import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final Color color;

  const ProfileAvatar({super.key, required this.name, this.color = Colors.blue});

  @override
  Widget build(BuildContext context) {
    String initials = "U";
    if (name.trim().isNotEmpty) {
      initials = name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join().toUpperCase();
    }
    return Container(
      width: 35, height: 35,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
    );
  }
}
