import 'dart:math';

import 'dart:async';

import 'package:flutter/material.dart';

import '../state/game_state.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/partner_art.dart';
import 'badges_screen.dart';
import 'dex_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'shop_screen.dart';

/// The main tabs: Home, Map, Dex, Shop, and Badges.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _tab = 0;

  // Break reminder: time spent with the app open and on screen.
  final _played = Stopwatch()..start();
  Timer? _breakCheck;
  bool _breakShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _breakCheck = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _maybeBreak(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breakCheck?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    state == AppLifecycleState.resumed ? _played.start() : _played.stop();
  }

  /// After the chosen minutes, the partner suggests a rest. It waits until
  /// the kid is back on the main tabs, so it never interrupts a stage.
  Future<void> _maybeBreak() async {
    final minutes = Settings.instance.breakMinutes;
    if (minutes == 0 || _breakShowing || !mounted) return;
    if (_played.elapsed < Duration(minutes: minutes)) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _breakShowing = true;
    final game = GameScope.of(context);
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PartnerArt(size: 110),
            const SizedBox(height: 8),
            Text(
              'Time for a break!',
              style: display(24, color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "You've been exploring for $minutes minutes, ${game.name}. "
              'Rest your eyes, stretch, and come back soon!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PaperButton(
              label: 'Okay!',
              icon: Icons.self_improvement_rounded,
              onPressed: () => Navigator.pop(d),
            ),
          ],
        ),
      ),
    );
    _played.reset();
    _breakShowing = false;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenMap: () => setState(() => _tab = 1)),
      const MapScreen(),
      const DexScreen(),
      const ShopScreen(),
      const BadgesScreen(),
    ];
    // The phone's back button: other tabs go back to Home first; on Home,
    // Tarsi plays peekaboo and asks before the app closes.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_tab != 0) {
          setState(() => _tab = 0);
          return;
        }
        final game = GameScope.of(context);
        final leave = await confirmExit(context, outfit: game.outfitItems);
        if (!leave || !context.mounted) return;
        await Navigator.of(context).push(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, _, _) =>
                GoodbyeScreen(name: game.name, outfit: game.outfitItems),
            transitionsBuilder: (_, a, _, child) =>
                FadeTransition(opacity: a, child: child),
          ),
        );
      },
      child: Scaffold(
        body: NightSky(
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                  scale: Tween(begin: 0.98, end: 1.0).animate(a),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
            ),
          ),
        ),
        bottomNavigationBar: _TabBar(
          index: _tab,
          onSelect: (i) => setState(() => _tab = i),
          // A dot on Badges while there are gems to claim
          dotOn: GameScope.of(context).unclaimedCount > 0 ? 4 : null,
        ),
      ),
    );
  }
}

const _tabs = [
  (Icons.home_rounded, 'Home'),
  (Icons.map_rounded, 'Map'),
  (Icons.menu_book_rounded, 'Dex'),
  (Icons.storefront_rounded, 'Shop'),
  (Icons.emoji_events_rounded, 'Badges'),
];

/// The bottom tabs: a strip of night along the bottom of the screen. The
/// open tab is a cream paper tag that lifts up; the rest sit in the dark.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onSelect, this.dotOn});
  final int index;
  final ValueChanged<int> onSelect;

  /// The tab showing a "something new" dot, if any.
  final int? dotOn;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.deep,
        border: Border(top: BorderSide(color: AppColors.track, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                for (final (i, (icon, label)) in _tabs.indexed)
                  Expanded(
                    child: _Tab(
                      icon: icon,
                      label: label,
                      selected: i == index,
                      // Alternate the lean so the tags look hand-placed.
                      tilt: i.isEven ? -2 : 2,
                      seed: i + 7,
                      dot: i == dotOn,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.tilt,
    required this.seed,
    required this.onTap,
    this.dot = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final double tilt;
  final int seed;
  final VoidCallback onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      label: dot ? '$label, gems to claim' : label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: Squish(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: selected ? 1 : 0),
          duration: still ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, t, _) {
            final o = t.clamp(0.0, 1.0);
            final color = Color.lerp(AppColors.muted, AppColors.ink, o)!;
            return Transform.translate(
              offset: Offset(0, -4 * t),
              child: Transform.rotate(
                angle: tilt * t * pi / 180,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: o,
                        child: CustomPaint(
                          painter: PaperShapePainter(
                            color: AppColors.cream,
                            seed: seed,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 5,
                      ),
                      // Shrinks instead of overflowing on narrow phones or
                      // with large text turned on.
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 26, color: color),
                              const SizedBox(height: 2),
                              Text(label, style: display(14, color: color)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (dot)
                      Positioned(
                        right: 10,
                        top: 4,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.deep, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
