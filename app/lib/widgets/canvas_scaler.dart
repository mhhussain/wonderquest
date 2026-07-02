import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/save_controller.dart';
import '../theme/wq_colors.dart';

/// Wraps [child] in a fixed 1194×834 design canvas, scaled to fill the screen
/// while preserving the aspect ratio (letterbox). Any screen rendered inside
/// this widget lays out against exactly 1194×834 logical pixels. Letterbox
/// areas are filled with [WqColors.ink].
///
/// Place this as the root [home:] of [MaterialApp]:
/// ```dart
/// home: CanvasScaler(child: PlayMinuteTicker(child: MyScreen()))
/// ```
class CanvasScaler extends StatelessWidget {
  const CanvasScaler({super.key, required this.child});

  final Widget child;

  /// Fixed design-canvas width in logical pixels (landscape iPad).
  static const double designWidth = 1194;

  /// Fixed design-canvas height in logical pixels (landscape iPad).
  static const double designHeight = 834;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WqColors.ink,
      child: SizedBox.expand(
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs a one-minute periodic timer that records each elapsed play-minute via
/// [SaveController.addMinute]. Pauses the timer when the app is backgrounded
/// and resumes it when the app returns to the foreground.
///
/// Wrap the app shell with this widget (just inside [CanvasScaler]):
/// ```dart
/// CanvasScaler(child: PlayMinuteTicker(child: MapScreen()))
/// ```
class PlayMinuteTicker extends ConsumerStatefulWidget {
  const PlayMinuteTicker({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PlayMinuteTicker> createState() => _PlayMinuteTickerState();
}

class _PlayMinuteTickerState extends ConsumerState<PlayMinuteTicker>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.read(saveControllerProvider.notifier).addMinute();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopTimer();
    } else if (state == AppLifecycleState.resumed) {
      if (_timer == null) _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
