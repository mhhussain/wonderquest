import 'package:flutter/material.dart';
import 'wq_colors.dart';

abstract final class WqTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: WqColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: WqColors.orange,
          surface: WqColors.background,
        ),
        fontFamily: 'Nunito',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Nunito',
            color: WqColors.ink,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Nunito',
            color: WqColors.ink,
          ),
        ),
      );

  /// Baloo 2 bold heading style at the given [size].
  static TextStyle headingStyle(double size) => TextStyle(
        fontFamily: 'Baloo2',
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: WqColors.ink,
      );

  /// Nunito body style at the given [size].
  static TextStyle bodyStyle(double size, {Color color = WqColors.ink}) =>
      TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        color: color,
      );

  // Convenience text style aliases.
  static const TextStyle heading = TextStyle(
    fontFamily: 'Baloo2',
    fontWeight: FontWeight.w700,
    color: WqColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.w400,
    color: WqColors.ink,
  );
}
