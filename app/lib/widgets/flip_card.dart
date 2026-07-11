import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A 3D flip card widget that animates between front and back content.
///
/// Tapping the card triggers a 400ms Y-axis rotation animation. The displayed
/// content swaps at the 90° midpoint, creating a card-flip illusion. The
/// [onFlipped] callback fires exactly once, when the back side first becomes
/// visible (on the initial front → back flip only).
///
/// Usage:
/// ```dart
/// FlipCard(
///   front: Image.asset('animal.png'),
///   back: Text('Interesting fact...'),
///   onFlipped: () => print('Flipped!'),
/// )
/// ```
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.onFlipped,
    this.startFlipped = false,
  });

  /// The widget displayed on the front of the card.
  final Widget front;

  /// The widget displayed on the back of the card.
  final Widget back;

  /// Called exactly once when the back side becomes visible (initial flip).
  /// Not called on subsequent flips back to front.
  final VoidCallback? onFlipped;

  /// If true, the card starts showing the back side.
  final bool startFlipped;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  bool _isFlipped = false;
  bool _hasCalledOnFlipped = false;

  @override
  void initState() {
    super.initState();
    _isFlipped = widget.startFlipped;
    _hasCalledOnFlipped = widget.startFlipped;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Listen to controller to detect when animation crosses π/2 midpoint.
    _controller.addListener(_handleAnimationProgress);

    // If starting flipped, set animation to the end state immediately.
    if (widget.startFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleAnimationProgress);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationProgress() {
    final angle = _rotationAnimation.value;

    // Fire onFlipped exactly once when angle first crosses π/2 (the midpoint)
    // during a forward flip. This occurs when the back side first becomes visible.
    if (!_hasCalledOnFlipped && angle >= math.pi / 2 && widget.onFlipped != null) {
      widget.onFlipped!();
      _hasCalledOnFlipped = true;
    }
  }

  void _handleTap() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    // Toggle flip state. setState is not needed here; AnimatedBuilder rebuilds
    // on animation changes, so this variable is read only when the animation fires.
    _isFlipped = !_isFlipped;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            final angle = _rotationAnimation.value;

            // Determine which side to show based on animation progress.
            // At 0 radians (0°), show front.
            // At π radians (180°), show back.
            // Swap at π/2 radians (90°).
            final showBack = angle > math.pi / 2;

            // Create the perspective matrix with Y-axis rotation.
            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(angle);

            return Transform(
              transform: matrix,
              alignment: Alignment.center,
              child: showBack
                  ? Transform(
                      // Flip the back content 180° so it reads correctly
                      // (without this, it would be mirrored).
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: widget.back,
                    )
                  : widget.front,
            );
          },
        ),
      ),
    );
  }
}
