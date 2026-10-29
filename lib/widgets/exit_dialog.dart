import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'common.dart';
import '../state/game_state.dart';
import 'partner_art.dart';

/// Asks before leaving the app. The partner plays peekaboo over the top of the
/// card. Returns true if the kid chose to exit.
Future<bool> confirmExit(
  BuildContext context, {
  List<String> outfit = const [],
}) {
  return _showPeekaboo(
    context,
    _PeekabooCard(
      outfit: outfit,
      title: 'Peekaboo! Leaving?',
      message:
          '${GameScope.maybeOf(context)?.partnerName ?? 'Tarsi'} wants to play a little more.',
      stayLabel: 'Play more',
      leaveLabel: 'Exit',
    ),
  );
}

/// Asks before leaving a stage in the middle. Stages only save when they
/// end, so this lists what would be lost. Returns true to leave.
Future<bool> confirmLeaveStage(
  BuildContext context, {
  required int caught,
  required int correct,
  required int xp,
  List<String> outfit = const [],
}) {
  final chips = [
    if (caught > 0)
      caught == 1 ? '1 creature caught' : '$caught creatures caught',
    if (correct > 0) correct == 1 ? '1 answer right' : '$correct answers right',
    if (xp > 0) '+$xp XP',
  ];
  return _showPeekaboo(
    context,
    _PeekabooCard(
      outfit: outfit,
      title: 'Leave this stage?',
      message: chips.isEmpty
          ? 'You can come back and play it anytime.'
          : 'If you leave now, you’ll lose what you found so far:',
      chips: chips,
      stayLabel: 'Keep going',
      leaveLabel: 'Leave stage',
    ),
  );
}

Future<bool> _showPeekaboo(BuildContext context, Widget card) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Stay',
    barrierColor: const Color(0xB30A0B22),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, _, _) => SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: Center(child: card),
      ),
    ),
    transitionBuilder: (_, a, _, child) {
      final t = Curves.elasticOut.transform(a.value.clamp(0, 1));
      return Opacity(
        opacity: a.value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Transform.rotate(angle: -0.07 * (1 - t), child: child),
        ),
      );
    },
  );
  return result ?? false;
}

/// A paper card with the partner playing peekaboo over its top edge. The stay
/// button is big; the leave button is small, so accidental taps stay.
class _PeekabooCard extends StatefulWidget {
  const _PeekabooCard({
    required this.outfit,
    required this.title,
    required this.message,
    required this.stayLabel,
    required this.leaveLabel,
    this.chips = const [],
  });
  final List<String> outfit;
  final String title;
  final String message;
  final List<String> chips;
  final String stayLabel;
  final String leaveLabel;

  @override
  State<_PeekabooCard> createState() => _PeekabooCardState();
}

class _PeekabooCardState extends State<_PeekabooCard>
    with TickerProviderStateMixin {
  /// The partner pops up, ducks down, and pops back up, over and over.
  late final AnimationController _peek = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  /// Plays when leaving: the partner ducks away for good.
  late final AnimationController _duck = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  static const _peekHeight = 62.0;

  @override
  void dispose() {
    _peek.dispose();
    _duck.dispose();
    super.dispose();
  }

  /// How far down the partner is: 0 = peeking up, 1 = hidden behind the card.
  double _hidden(double t) {
    double ease(double x) => Curves.easeInOut.transform(x.clamp(0, 1));
    if (t < 0.15) return 0;
    if (t < 0.25) return ease((t - 0.15) / 0.1);
    if (t < 0.45) return 1;
    if (t < 0.55) return 1 - ease((t - 0.45) / 0.1);
    return 0;
  }

  Future<void> _exit() async {
    HapticFeedback.lightImpact();
    if (!MediaQuery.of(context).disableAnimations) {
      _peek.stop();
      await _duck.forward();
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      width: 300,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // The partner peeking over the top edge, clipped so it looks like it's
          // hiding behind the card.
          Positioned(
            top: -_peekHeight + 4,
            child: SizedBox(
              width: 110,
              height: _peekHeight,
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_peek, _duck]),
                  builder: (_, child) {
                    final base = still ? 0.0 : _hidden(_peek.value);
                    final down = max(
                      base,
                      Curves.easeIn.transform(_duck.value),
                    );
                    return Transform.translate(
                      offset: Offset(0, down * (_peekHeight + 8)),
                      child: child,
                    );
                  },
                  child: OverflowBox(
                    maxHeight: 110,
                    alignment: Alignment.topCenter,
                    child: PartnerArt(
                      size: 110,
                      shadow: false,
                      outfit: widget.outfit,
                    ),
                  ),
                ),
              ),
            ),
          ),
          PaperCard(
            tilt: -1.5,
            seed: 77,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: display(24),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 15,
                  ),
                ),
                if (widget.chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in widget.chips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFE0BD),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                PaperButton(
                  label: widget.stayLabel,
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _exit,
                  child: Text(
                    widget.leaveLabel,
                    style: display(16, color: AppColors.inkMuted).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A short goodbye before the app closes: the partner asleep with floating z's.
/// Tapping anywhere goes back to the game, for platforms where apps can't
/// close themselves.
class GoodbyeScreen extends StatefulWidget {
  const GoodbyeScreen({super.key, required this.name, this.outfit = const []});
  final String name;
  final List<String> outfit;

  @override
  State<GoodbyeScreen> createState() => _GoodbyeScreenState();
}

class _GoodbyeScreenState extends State<GoodbyeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _z = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  Timer? _close;
  bool _showHint = false;

  /// Only Android apps can close themselves. On the web, closing would mean
  /// going back in browser history, and iPhones don't allow it at all.
  static bool get _canClose =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _close = Timer(const Duration(milliseconds: 1800), () {
      if (_canClose) {
        SystemNavigator.pop();
      } else if (mounted) {
        setState(() => _showHint = true);
      }
    });
  }

  @override
  void dispose() {
    _close?.cancel();
    _z.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NightSky(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PartnerArt(
                        size: 140,
                        blinkNow: true,
                        outfit: widget.outfit,
                      ),
                      AnimatedBuilder(
                        animation: _z,
                        builder: (_, _) => Stack(
                          children: [for (var i = 0; i < 3; i++) _floatingZ(i)],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PopIn(
                  startScale: 0.5,
                  child: Text(
                    'Peekaboo, see you soon!',
                    textAlign: TextAlign.center,
                    style: display(26),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${GameScope.maybeOf(context)?.partnerName ?? 'Tarsi'} is hiding until you’re back, ${widget.name}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: _showHint ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
                  child: const Pill(
                    'Tap to keep playing',
                    icon: Icons.touch_app_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _floatingZ(int i) {
    final t = (_z.value + i / 3) % 1;
    return Positioned(
      left: 128 + t * 30,
      top: 40 - t * 50,
      child: Opacity(
        opacity: t < 0.3 ? t / 0.3 : 1 - (t - 0.3) / 0.7,
        child: Text(
          i == 2 ? 'Z' : 'z',
          style: display(16 + t * 10, color: AppColors.muted),
        ),
      ),
    );
  }
}
