import 'package:flutter/material.dart';

class NavBarClipper extends CustomClipper<Path> {
  final double buttonLeft, buttonBottom, buttonSize, margin;

  NavBarClipper({required this.buttonLeft, required this.buttonBottom, required this.buttonSize, required this.margin});

  @override
  Path getClip(Size size) {
    Path basePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(24),
      ));
    Path cutoutPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(
          buttonLeft + buttonSize / 2,
          size.height - (buttonBottom + buttonSize / 2),
        ),
        radius: buttonSize / 2 + margin,
      ));
    return Path.combine(PathOperation.difference, basePath, cutoutPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
