import 'package:flutter/material.dart';
import 'package:gazprof/core/theme_provider.dart';

Color getTimeBorderColor(DateTime? orderTime) {
  if (orderTime == null) return Colors.transparent;
  final minutes = DateTime.now().difference(orderTime).inMinutes;
  if (minutes < 10) return Colors.green;
  if (minutes < 20) return Colors.amber;
  return Colors.red;
}
