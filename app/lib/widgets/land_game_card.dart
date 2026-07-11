import 'package:flutter/material.dart';

import '../core/art.dart';
import '../theme/wq_colors.dart';
import '../theme/wq_theme.dart';

/// Shared game-picker card tile used by land entry screens (Hoorof games,
/// Math Lab stations, …): coloured rounded box with the standard shadow, an
/// [Art] icon, a Baloo 2 title, and a Nunito subtitle.
///
/// [icon] is an [Art] key or an emoji passthrough — never render picker
/// glyphs via bare [Text], so v2 can swap them to illustrations in one place.
class LandGameCard extends StatelessWidget {
  const LandGameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.iconSize = 28,
    this.titleSize = 14,
    this.subtitleSize = 11,
    this.radius = 18,
    this.padding = 12,
  });

  final String title;
  final String subtitle;

  /// [Art] key (or emoji passthrough) for the card icon.
  final String icon;

  final Color color;
  final VoidCallback onTap;
  final double iconSize;
  final double titleSize;
  final double subtitleSize;
  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: WqColors.shadow,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Art.glyph(icon, size: iconSize),
              SizedBox(height: padding / 3),
              Text(
                title,
                maxLines: 2,
                style: WqTheme.headingStyle(titleSize)
                    .copyWith(color: Colors.white),
              ),
              Text(
                subtitle,
                maxLines: 1,
                style: WqTheme.bodyStyle(subtitleSize, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
