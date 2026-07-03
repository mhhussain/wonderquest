import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/world_content.dart';
import '../../../core/audio/tts_service.dart';
import '../../../theme/wq_theme.dart';

/// Travel phases matching the raw/world.jsx Travel component.
enum _TravelPhase { board, fly, land }

/// ~6s animated travel sequence: boarding → flying → landing → callback.
///
/// Tapping the "Skip ▸" button immediately fires [onArrive].
class TravelAnimation extends ConsumerStatefulWidget {
  const TravelAnimation({
    super.key,
    required this.continent,
    required this.onArrive,
  });

  final Continent continent;
  final VoidCallback onArrive;

  @override
  ConsumerState<TravelAnimation> createState() => _TravelAnimationState();
}

class _TravelAnimationState extends ConsumerState<TravelAnimation>
    with SingleTickerProviderStateMixin {
  _TravelPhase _phase = _TravelPhase.board;
  late AnimationController _planeCtrl;
  late Animation<double> _planeX;
  bool _done = false;

  @override
  void initState() {
    super.initState();

    _planeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..forward();

    _planeX = Tween<double>(begin: -0.15, end: 1.1).animate(
      CurvedAnimation(parent: _planeCtrl, curve: Curves.easeInOut),
    );

    final tts = ref.read(ttsServiceProvider);
    tts.speak("Buckle up! Let's fly to ${widget.continent.name}!");

    // Phase transitions (matching prototype timings)
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      setState(() => _phase = _TravelPhase.fly);
    });

    Future.delayed(const Duration(milliseconds: 4600), () {
      if (!mounted) return;
      setState(() => _phase = _TravelPhase.land);
      tts.speak('We have arrived in ${widget.continent.name}!');
    });

    Future.delayed(const Duration(milliseconds: 6200), () {
      if (mounted && !_done) _finish();
    });
  }

  @override
  void dispose() {
    _planeCtrl.dispose();
    super.dispose();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onArrive();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.continent;

    return Scaffold(
      body: GestureDetector(
        onTap: _finish,
        child: Stack(
          children: [
            // Ocean / sky gradient background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _phase == _TravelPhase.land
                          ? c.color2.withValues(alpha: 0.8)
                          : const Color(0xFF6DD5FA),
                      _phase == _TravelPhase.land
                          ? c.color.withValues(alpha: 0.9)
                          : const Color(0xFF2980B9),
                    ],
                  ),
                ),
              ),
            ),

            // Clouds
            ..._buildClouds(context),

            // Ocean strip at bottom (fly phase)
            if (_phase == _TravelPhase.fly)
              const Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Text(
                  '🌊🌊🌊🌊🌊🌊🌊🌊🌊',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28),
                ),
              ),

            // Animated plane
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _planeX,
                builder: (context2, child) {
                  return Align(
                    alignment: Alignment(_planeX.value * 2 - 1, 0),
                    child: const Text(
                      '✈️',
                      style: TextStyle(fontSize: 56),
                    ),
                  );
                },
              ),
            ),

            // Continent destination circle (land phase)
            if (_phase == _TravelPhase.land)
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(top: 60),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [c.color2, c.color],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.color.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(c.emoji, style: const TextStyle(fontSize: 56)),
                  ),
                ),
              ),

            // Banner at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _bannerTitle(),
                      style: WqTheme.headingStyle(22)
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bannerSub(),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Skip button (top-right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: TextButton(
                key: const Key('skip-travel'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _finish,
                child: const Text(
                  'Skip ▸',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bannerTitle() {
    switch (_phase) {
      case _TravelPhase.board:
        return '✈️ Boarding…';
      case _TravelPhase.fly:
        return 'Flying over the ocean! 🌊';
      case _TravelPhase.land:
        return '${widget.continent.emoji} Welcome to ${widget.continent.name}!';
    }
  }

  String _bannerSub() {
    switch (_phase) {
      case _TravelPhase.board:
        return 'Next stop: ${widget.continent.name}';
      case _TravelPhase.fly:
        return 'Look at the clouds go by…';
      case _TravelPhase.land:
        return widget.continent.blurb;
    }
  }

  List<Widget> _buildClouds(BuildContext context) {
    return List.generate(7, (k) {
      final startFraction = k / 7.0;
      return AnimatedBuilder(
        key: ValueKey('cloud-anim-$k'),
        animation: _planeCtrl,
        builder: (ctx, child) {
          final w = MediaQuery.of(ctx).size.width;
          final offset =
              ((startFraction + _planeCtrl.value * 0.4) % 1.2 - 0.1) * w;
          return Positioned(
            top: 40.0 + (k * 37 % 140).toDouble(),
            left: offset,
            child: Opacity(
              opacity: 0.7,
              child: Text(
                '☁️',
                style: TextStyle(fontSize: 24.0 + (k * 7 % 18)),
              ),
            ),
          );
        },
      );
    });
  }
}
