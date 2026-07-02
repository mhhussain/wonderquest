import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/art.dart';
import '../../theme/wq_colors.dart';
import '../../theme/wq_theme.dart';

/// Shows the multiplication parent gate as a modal dialog.
///
/// Randomly selects single-digit factors `a, b ∈ [3, 9]` and asks the parent
/// to compute `a × b`.  Correct answer → resolves `true`; ✕ dismiss → `false`.
/// Wrong answer triggers a horizontal shake animation and presents a new
/// question, keeping the dialog open.
///
/// [random] may be injected for deterministic widget tests:
/// ```dart
/// final passed = await showParentGate(context, random: Random(1));
/// ```
Future<bool> showParentGate(
  BuildContext context, {
  Random? random,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ParentGateDialog(random: random ?? Random()),
  );
  return result ?? false;
}

// ── Gate dialog ───────────────────────────────────────────────────────────────

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog({required this.random});

  final Random random;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog>
    with SingleTickerProviderStateMixin {
  late int _a;
  late int _b;
  String _entry = '';

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -9.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -9.0, end: 9.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 9.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  void _generateQuestion() {
    _a = 3 + widget.random.nextInt(7); // [3, 9]
    _b = 3 + widget.random.nextInt(7);
    _entry = '';
  }

  void _onDigit(String d) {
    if (_entry.length >= 3) return;
    setState(() => _entry += d);
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  void _onCheck() {
    final typed = int.tryParse(_entry);
    if (typed != null && typed == _a * _b) {
      Navigator.of(context).pop(true);
      return;
    }
    // Wrong — shake, then reset to a new question.
    _shakeCtrl.forward(from: 0.0).then((_) {
      if (mounted) setState(_generateQuestion);
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (ctx, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Dialog(
        key: const Key('gate-dialog'),
        backgroundColor: WqColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────────────────────────
                _GateHeader(
                  onClose: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(height: 20),

                // ── Multiplication question ──────────────────────────────────
                Text(
                  'What is $_a × $_b ?',
                  style: WqTheme.headingStyle(30),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                // ── Answer display ──────────────────────────────────────────
                _AnswerDisplay(
                  key: const Key('gate-answer'),
                  entry: _entry,
                ),
                const SizedBox(height: 16),

                // ── Number pad ──────────────────────────────────────────────
                _NumberPad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  onCheck: _entry.isNotEmpty ? _onCheck : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _GateHeader extends StatelessWidget {
  const _GateHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${Art.emoji('parent')} Grown-ups only',
            style: WqTheme.headingStyle(18),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        GestureDetector(
          key: const Key('gate-close'),
          onTap: onClose,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(
                '✕',
                style: TextStyle(
                  fontSize: 22,
                  color: WqColors.softInk,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Answer display ────────────────────────────────────────────────────────────

class _AnswerDisplay extends StatelessWidget {
  const _AnswerDisplay({super.key, required this.entry});

  final String entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: WqColors.backgroundAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WqColors.lines, width: 2),
      ),
      child: Text(
        entry.isEmpty ? '_' : entry,
        style: const TextStyle(
          fontFamily: 'Baloo2',
          fontWeight: FontWeight.w700,
          fontSize: 30,
          color: WqColors.ink,
        ),
      ),
    );
  }
}

// ── Number pad ────────────────────────────────────────────────────────────────

/// 3×3 grid of digits plus a bottom row of ← 0 ✓.
class _NumberPad extends StatelessWidget {
  const _NumberPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onCheck,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// Null when entry is empty (check button is disabled).
  final VoidCallback? onCheck;

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Digit rows 1–9
        for (int r = 0; r < _rows.length; r++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int c = 0; c < _rows[r].length; c++) ...[
                _PadKey(
                  key: Key('gate-digit-${_rows[r][c]}'),
                  label: _rows[r][c],
                  onTap: () => onDigit(_rows[r][c]),
                ),
                if (c < _rows[r].length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        // Bottom row: backspace | 0 | check
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadKey(
              key: const Key('gate-backspace'),
              label: '←',
              onTap: onBackspace,
            ),
            const SizedBox(width: 8),
            _PadKey(
              key: const Key('gate-digit-0'),
              label: '0',
              onTap: () => onDigit('0'),
            ),
            const SizedBox(width: 8),
            _PadKey(
              key: const Key('gate-check'),
              label: '✓',
              onTap: onCheck,
              color: onCheck != null ? WqColors.green : WqColors.lines,
              textColor: Colors.white,
            ),
          ],
        ),
      ],
    );
  }
}

/// Single key on the number pad.
class _PadKey extends StatelessWidget {
  const _PadKey({
    super.key,
    required this.label,
    required this.onTap,
    this.color = WqColors.backgroundAlt,
    this.textColor = WqColors.ink,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1.0 : 0.45,
        child: Container(
          width: 72,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WqColors.lines),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
