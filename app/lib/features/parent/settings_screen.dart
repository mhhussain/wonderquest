import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/art.dart';
import '../../core/save_controller.dart';
import '../../theme/wq_colors.dart';
import '../../theme/wq_theme.dart';
import '../../widgets/wq_button.dart';

// ── Dashboard (placeholder until Task 34) ─────────────────────────────────────

/// Placeholder parent dashboard shown after the multiplication gate passes.
///
/// Task 34 will replace the body with real analytics.  The AppBar "Settings"
/// action and the body [WqButton] both navigate to [SettingsScreen].
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Parent Dashboard', style: WqTheme.headingStyle(22)),
        actions: [
          IconButton(
            key: const Key('dashboard-settings'),
            icon: const Icon(Icons.settings_outlined, color: WqColors.ink),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Art.glyph('parent', size: 72),
            const SizedBox(height: 16),
            Text(
              'Dashboard coming in Task 34',
              style: WqTheme.headingStyle(24),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: WqButton(
                key: const Key('dashboard-settings-btn'),
                label: 'Settings',
                color: WqColors.grape,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings screen ────────────────────────────────────────────────────────────

/// Parent settings screen: sound toggle, reset progress, version, credits.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveControllerProvider).value;
    final soundOn = save?.soundOn ?? true;

    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Settings', style: WqTheme.headingStyle(22)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // ── Sound toggle ───────────────────────────────────────────────────
          _SettingsRow(
            label: 'Sound',
            trailing: Switch(
              key: const Key('settings-sound'),
              value: soundOn,
              activeThumbColor: WqColors.teal,
              onChanged: (_) =>
                  ref.read(saveControllerProvider.notifier).toggleSound(),
            ),
          ),
          const _Divider(),

          // ── Reset all progress ─────────────────────────────────────────────
          _SettingsRow(
            label: 'Reset all progress',
            trailing: TextButton(
              key: const Key('settings-reset'),
              onPressed: () => _confirmReset(context, ref),
              child: Text(
                'Reset',
                style: WqTheme.body.copyWith(
                  color: WqColors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const _Divider(),

          // ── App version ────────────────────────────────────────────────────
          _SettingsRow(
            label: 'Version',
            trailing: Text(
              '1.0.0',
              style: WqTheme.body.copyWith(color: WqColors.softInk),
            ),
          ),
          const SizedBox(height: 40),

          // ── Credits ────────────────────────────────────────────────────────
          Center(
            child: Text(
              'Made with ❤ for Hassan',
              style: WqTheme.body.copyWith(
                color: WqColors.softInk,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WqColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset all progress?', style: WqTheme.headingStyle(18)),
        content: const Text(
          'This will erase all stars, dinos, stickers, and progress. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm-reset'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: WqColors.coral),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(saveControllerProvider.notifier).resetAllProgress();
    }
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: WqTheme.body.copyWith(fontSize: 16),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: WqColors.lines, height: 1, thickness: 1);
  }
}
