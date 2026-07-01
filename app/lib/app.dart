import 'package:flutter/material.dart';

import 'features/spike/tts_spike_screen.dart';
import 'theme/wq_colors.dart';
import 'theme/wq_theme.dart';

class WonderQuestApp extends StatelessWidget {
  const WonderQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wonder Quest',
      debugShowCheckedModeBanner: false,
      theme: WqTheme.theme,
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary placeholder home screen while the real shell is being built.
/// Contains a debug section for in-progress spike screens.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WqColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Wonder Quest', style: WqTheme.headingStyle(36)),
            const SizedBox(height: 8),
            Text(
              'Placeholder — shell coming in Task 5',
              style: WqTheme.body.copyWith(color: WqColors.softInk),
            ),
            const SizedBox(height: 40),
            // ── Debug / spike navigation ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WqColors.backgroundAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WqColors.lines),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Debug Spikes',
                    style: WqTheme.body.copyWith(color: WqColors.softInk),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    key: const Key('btn_open_tts_spike'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WqColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TtsSpikeScreen(),
                      ),
                    ),
                    child: const Text('Arabic TTS Spike (Task 3)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
