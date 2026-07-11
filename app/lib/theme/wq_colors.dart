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

  static const skyTint = Color(0xFFD6EEFF); // letter-pop sky

  /// Standard soft drop shadow used by cards and tiles across all lands.
  static const shadow = Color(0x22000000);

  // Scene accents (kept as named tokens so land scenes stay on-palette)
  static const gold = Color(0xFFFFD700); // math-lab machine trim
  static const wood = Color(0xFFC67C2A); // math-lab machine body
  static const woodDark = Color(0xFF8B5E0A); // math-lab machine border/text
  static const woodDeep = Color(0xFF7A4E1D); // math-lab conveyor belt
  static const oceanSurface = Color(0xFF6DD5FA); // travel-animation sea (top)
  static const oceanDeep = Color(0xFF2980B9); // travel-animation sea (bottom)
  static const mapSkyLight = Color(0xFFBFE8F7); // world-map backdrop (top)
  static const mapSkyDark = Color(0xFF8FCDEA); // world-map backdrop (bottom)
  static const mapOutline = Color(0x521C5A78); // world-map continent outline
  static const deepSea = Color(0xFF0D1B2A); // whale-world background
  static const sand = Color(0xFFF2D98C); // safari-hunt background

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
