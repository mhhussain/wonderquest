import 'package:flutter/material.dart';

/// The Wonder Quest signature button.
///
/// Renders a pill-shaped label with a solid darker "shadow" band along the
/// bottom edge. On tap-down the face shifts down 3 px, compressing the shadow
/// band and giving a physical press-depth feel. On tap-up / cancel the button
/// springs back and [onTap] fires.
///
/// All hit targets are ≥ 64 px tall (child-facing control requirement).
///
/// Usage:
/// ```dart
/// WqButton(
///   label: 'Play',
///   emojiKey: '▶',
///   color: WqColors.orange,
///   onTap: () { /* … */ },
/// )
/// ```
class WqButton extends StatefulWidget {
  const WqButton({
    super.key,
    required this.label,
    this.emojiKey,
    required this.color,
    required this.onTap,
    this.fontSize = 22,
  });

  final String label;

  /// Optional leading emoji / Unicode glyph displayed before the label.
  final String? emojiKey;

  final Color color;

  /// If null, the button renders with reduced opacity and is non-interactive.
  final VoidCallback? onTap;
  final double fontSize;

  @override
  State<WqButton> createState() => _WqButtonState();
}

class _WqButtonState extends State<WqButton> {
  bool _pressed = false;

  /// Returns a darker shade of [widget.color] used for the shadow band.
  Color get _shadowColor {
    final hsl = HSLColor.fromColor(widget.color);
    return hsl
        .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    const double shadowBandHeight = 6;
    const double faceHeight = 64;
    const double pressDepth = 3;
    const double totalHeight = faceHeight + shadowBandHeight;

    final double faceTop = _pressed ? pressDepth : 0.0;

    final bool enabled = widget.onTap != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap!();
              }
            : null,
        onTapCancel:
            enabled ? () => setState(() => _pressed = false) : null,
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              // ── Shadow band — always visible at the bottom ───────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: faceHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _shadowColor,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
              // ── Button face — slides down [pressDepth] px on press ───────
              Positioned(
                top: faceTop,
                left: 0,
                right: 0,
                height: faceHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.emojiKey != null) ...[
                            Text(
                              widget.emojiKey!,
                              style: TextStyle(fontSize: widget.fontSize),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
