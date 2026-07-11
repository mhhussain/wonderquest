import 'package:flutter/material.dart';

import 'core/motion.dart';
import 'features/map/expedition_map_screen.dart';
import 'theme/wq_theme.dart';
import 'widgets/canvas_scaler.dart';

class WonderQuestApp extends StatelessWidget {
  const WonderQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wonder Quest',
      debugShowCheckedModeBanner: false,
      theme: WqTheme.theme,
      builder: (context, child) {
        // Reduced-motion: replace page transitions with instant swaps.
        if (!reduceMotionOf(context)) return child!;
        return Theme(
          data: Theme.of(context).copyWith(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values)
                  platform: const _InstantPageTransitionsBuilder(),
              },
            ),
          ),
          child: child!,
        );
      },
      home: const CanvasScaler(
        child: PlayMinuteTicker(
          child: ExpeditionMapScreen(),
        ),
      ),
    );
  }
}

/// Page transition that swaps routes with no animation (reduced motion).
class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
