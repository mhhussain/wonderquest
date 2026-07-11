import 'package:flutter/widgets.dart';

/// True when the platform requests reduced motion (e.g. iOS "Reduce Motion",
/// surfaced as [MediaQueryData.disableAnimations]).
///
/// Decorative animations — sparkles, pop bounces, drifting backgrounds, the
/// travel sequence, page transitions — must be skipped or shortened when
/// this is set. Gameplay-essential movement stays (nothing in v1 requires
/// motion to be playable).
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);
