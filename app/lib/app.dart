import 'package:flutter/material.dart';

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
      home: const CanvasScaler(
        child: PlayMinuteTicker(
          child: ExpeditionMapScreen(),
        ),
      ),
    );
  }
}
