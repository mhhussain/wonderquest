import 'package:flutter/material.dart';

abstract final class WqColors {
  // Brand / section colors
  static const orange = Color(0xFFFF8A3D);
  static const teal = Color(0xFF2BB3C6);
  static const green = Color(0xFF7BC043);
  static const coral = Color(0xFFFF6B6B);
  static const grape = Color(0xFF8B7BE0);
  static const sky = Color(0xFF4AA8E0);
  static const yellow = Color(0xFFFFC53D);
  static const pink = Color(0xFFF472A8);

  // Warm neutrals
  static const background = Color(0xFFFFF8EE);
  static const backgroundAlt = Color(0xFFFFEFD9);
  static const card = Color(0xFFFFFFFF);
  static const gapBackground = Color(0xFFFFF3E6); // prototype gap-tile tint (raw/number.jsx)
  static const ink = Color(0xFF3A2E2A);
  static const softInk = Color(0xFF6E5D55);
  static const lines = Color(0xFFF0E2CF);

  /// Cycling palette for land tiles (orange → teal → green → … → pink).
  static const List<Color> landColors = [
    orange,
    teal,
    green,
    coral,
    grape,
    sky,
    yellow,
    pink,
  ];
}
