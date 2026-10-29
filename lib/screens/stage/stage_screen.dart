import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../../services/sfx.dart';
import '../../services/sounds.dart';
import '../../state/game_state.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/celebrations.dart';
import '../../widgets/common.dart';
import '../../widgets/creature_art.dart';
import '../../widgets/exit_dialog.dart';
import '../../widgets/listen_button.dart';
import 'question_view.dart';
import 'search_view.dart';

class StageScreen extends StatefulWidget {
  const StageScreen({super.key, required this.stage});
  final Stage stage;

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> {
  late StageSession _session = StageSession(widget.stage);
  int _found = 0;
  bool _recorded = false;

  /// Set when the kid taps Next after losing their last heart.
  bool _failShown = false;
  List<Achievement> _newBadges = [];

  /// Tarsi hops across the parols for a moment while the stage gets ready.
  bool _loading = true;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    _loadTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  void _advance() {
    setState(() => _session.next());
    _recordIfDone();
  }

  void _answer(bool correct) {
    setState(() => _session.answer(correct));
  }

  bool get _showResult => _session.index >= _session.steps.length || _failShown;

  /// Saves progress once, when the result screen appears.
  Future<void> _recordIfDone() async {
    if (!_showResult || _recorded) return;
    _recorded = true;
    final game = GameScope.of(context);
    final oldLevel = game.level;
    final oldOpen = habitats.where(game.isHabitatUnlocked).toSet();
    final fresh = await game.recordStage(
      StageResult(
        stageId: widget.stage.id,
        stars: _session.stars,
        correct: _session.correct,
        found: _found,
        caught: _session.caught,
      ),
    );
    if (!mounted) return;
    setState(() => _newBadges = fresh);

    // After the results have had a moment, celebrate a level up and any
    // newly opened habitat, one after the other.
    final newLevel = game.level;
    final opened = habitats
        .where((h) => game.isHabitatUnlocked(h) && !oldOpen.contains(h))
        .toList();
    if (newLevel == oldLevel && opened.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    if (newLevel > oldLevel) {
      Sfx.levelUp.play();
      await showCelebration(context, LevelUpView(level: newLevel));
    }
    for (final h in opened) {
      if (!mounted) return;
      Sfx.levelUp.play();
      await showCelebration(context, HabitatUnlockView(habitat: h));
    }
  }

  /// Leaving mid-stage loses this run, so ask first. Once the results are
  /// showing, everything is saved and leaving is instant.
  Future<void> _maybeLeave() async {
    final nav = Navigator.of(context);
    if (_loading || _showResult) {
      nav.pop();
      return;
    }
    final s = _session;
    final step = s.current;
    // A creature on its catch screen counts, even before tapping on.
    final pendingCatch =
        step is CatchStep &&
        s.wasCaught(step.creature.id) &&
        !s.caught.contains(step.creature.id);
    final caught = s.caught.length + (pendingCatch ? 1 : 0);
    final leave = await confirmLeaveStage(
      context,
      caught: caught,
      correct: s.correct,
      xp: s.correct * 10 + caught * 25,
      outfit: GameScope.of(context).outfitItems,
    );
    if (leave && mounted) nav.pop();
  }

  void _retry() {
    setState(() {
      _session = StageSession(widget.stage);
      _found = 0;
      _recorded = false;
      _failShown = false;
      _newBadges = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: NightSky(
          child: SafeArea(child: LoadingTarsi(label: 'Getting ready')),
        ),
      );
    }
    final s = _session;
    final showResult = _showResult;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _maybeLeave();
      },
      child: Scaffold(
        body: NightSky(
          child: SafeArea(
            child: Column(
              children: [
                _TopBar(session: s, stage: widget.stage, onClose: _maybeLeave),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position:
                            Tween(
                              begin: const Offset(0.08, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: a,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(
                        '${s.index}-$showResult-${identityHashCode(s)}',
                      ),
                      child: showResult
                          ? _ResultView(
                              stage: widget.stage,
                              session: s,
                              newBadges: _newBadges,
                              onRetry: _retry,
                            )
                          : _stepView(s),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepView(StageSession s) {
    return switch (s.current) {
      SearchStep(:final creature) => SearchView(
        creature: creature,
        onFound: () {
          _found++;
          _advance();
        },
      ),
      QuestionStep(:final question) => QuestionView(
        question: question,
        hintsLeft: s.hints,
        onUseHint: () {
          final ok = s.useHint();
          setState(() {});
          return ok;
        },
        onAnswer: (correct) {
          _answer(correct);
          GameScope.of(context).noteAnswer(question, correct);
        },
        onNext: () {
          if (s.failed) {
            setState(() => _failShown = true);
            _recordIfDone();
          } else {
            _advance();
          }
        },
      ),
      CatchStep(:final creature) => _CatchView(
        creature: creature,
        caught: s.wasCaught(creature.id),
        onNext: _advance,
      ),
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.session,
    required this.stage,
    required this.onClose,
  });
  final StageSession session;
  final Stage stage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final total = session.questionCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave stage',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppColors.text),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.isBoss
                      ? stage.title
                      : 'Stage ${stage.number}: ${stage.title}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Meter(total == 0 ? 0 : session.answeredCount / total),
              ],
            ),
          ),
          const SizedBox(width: 12),
          HeartsRow(hearts: session.hearts),
        ],
      ),
    );
  }
}

/// The catch moment: light rays spin, the creature's card is taped in, and
/// a stamp slams down. Tapping on flies the card into the Dex book. If the
/// creature escaped, it leaps away into the leaves first.
class _CatchView extends StatefulWidget {
  const _CatchView({
    required this.creature,
    required this.caught,
    required this.onNext,
  });

  final Creature creature;
  final bool caught;
  final VoidCallback onNext;

  @override
  State<_CatchView> createState() => _CatchViewState();
}

class _CatchViewState extends State<_CatchView> with TickerProviderStateMixin {
  bool _stamped = false;
  bool _escaped = false;
  bool _leaving = false;
  Offset _toBook = Offset.zero;
  final _cardKey = GlobalKey();
  final _bookKey = GlobalKey();
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.caught) Sfx.wrong.play();
    if (widget.caught) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        setState(() => _stamped = true);
        Sfx.catchIt.play();
      });
    }
  }

  @override
  void dispose() {
    Sounds.instance.stop();
    _fly.dispose();
    _bounce.dispose();
    super.dispose();
  }

  Offset _center(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Future<void> _next() async {
    if (_leaving) return;
    _leaving = true;
    Sounds.instance.stop();
    if (!widget.caught || MediaQuery.of(context).disableAnimations) {
      widget.onNext();
      return;
    }
    setState(() => _toBook = _center(_bookKey) - _center(_cardKey));
    await _fly.forward();
    HapticFeedback.mediumImpact();
    await _bounce.forward();
    if (mounted) widget.onNext();
  }

  /// Card position while flying: a wiggle, then an arc into the book.
  Widget _flying(Widget card) {
    return AnimatedBuilder(
      animation: _fly,
      child: card,
      builder: (_, child) {
        final t = _fly.value;
        if (t == 0) return child!;
        final mid = _toBook * 0.5 + const Offset(0, -140);
        Offset pos;
        double rot, scale, fade = 1;
        if (t < 0.18) {
          final k = t / 0.18;
          pos = Offset.zero;
          rot = sin(k * pi) * 0.08;
          scale = 1 + sin(k * pi / 2) * 0.12;
        } else if (t < 0.55) {
          final k = Curves.easeOut.transform((t - 0.18) / 0.37);
          pos = Offset.lerp(Offset.zero, mid, k)!;
          rot = -0.5 * k;
          scale = 1.12 - 0.52 * k;
        } else {
          final k = Curves.easeIn.transform((t - 0.55) / 0.45);
          pos = Offset.lerp(mid, _toBook, k)!;
          rot = -0.5 - 3 * k;
          scale = 0.6 - 0.52 * k;
          fade = 1 - 0.6 * k;
        }
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: pos,
            child: Transform.rotate(
              angle: rot,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final creature = widget.creature;
    final caught = widget.caught;

    if (!caught && !_escaped) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            Text('Oh no!', style: display(36)),
            const SizedBox(height: 4),
            Text(
              'The ${creature.name} is getting away…',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 16),
            ),
            const SizedBox(height: 20),
            EscapeScene(
              creature: creature,
              onDone: () => setState(() => _escaped = true),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return Stack(
      children: [
        if (caught) const Positioned.fill(child: SpinningRays()),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              PopIn(
                startScale: 0.5,
                child: Text(
                  caught ? 'Caught!' : 'It slipped away…',
                  style:
                      display(
                        36,
                        color: caught ? AppColors.gold : AppColors.text,
                      ).copyWith(
                        shadows: const [
                          Shadow(
                            color: Color(0x88000000),
                            offset: Offset(2, 3),
                          ),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                caught
                    ? '${creature.name} was added to your Dex.'
                    : 'Play this stage again to catch the ${creature.name}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 22),
              _flying(
                PopIn(
                  key: _cardKey,
                  delay: const Duration(milliseconds: 150),
                  startScale: 0,
                  startTilt: -30,
                  child: _TapedCard(
                    creature: creature,
                    caught: caught,
                    stamped: _stamped,
                  ),
                ),
              ),
              if (caught) ...[
                const SizedBox(height: 20),
                PopIn(
                  delay: const Duration(milliseconds: 1100),
                  from: const Offset(0, 30),
                  startScale: 0.8,
                  child: AnimatedOpacity(
                    opacity: _leaving ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: PaperCard(
                      tilt: 1,
                      seed: 70,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: AppColors.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              creature.fact,
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                          ),
                          if (creature.sound case final sound?) ...[
                            const SizedBox(width: 8),
                            ListenButton(sound, compact: true),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: PaperButton(
                      label: caught ? 'Add to my Dex' : 'Keep exploring',
                      icon: caught ? Icons.menu_book_rounded : null,
                      onPressed: _next,
                    ),
                  ),
                  if (caught) ...[
                    const SizedBox(width: 14),
                    AnimatedBuilder(
                      animation: _bounce,
                      builder: (_, _) {
                        final b = _bounce.value;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            DexBook(key: _bookKey, bounce: b),
                            if (b > 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: -18 - b * 26,
                                child: Opacity(
                                  opacity: (1 - b).clamp(0, 1),
                                  child: Text(
                                    '+1',
                                    textAlign: TextAlign.center,
                                    style: display(20, color: AppColors.gold),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (_stamped)
          const Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment(0, -0.2),
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: ConfettiBurst(count: 44, power: 1.2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TapedCard extends StatelessWidget {
  const _TapedCard({
    required this.creature,
    required this.caught,
    required this.stamped,
  });
  final Creature creature;
  final bool caught;
  final bool stamped;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -3 * pi / 180,
      child: SizedBox(
        width: 230,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PaperCard(
              seed: 71,
              color: caught ? AppColors.cream : const Color(0xFFB9B2C9),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                children: [
                  CreatureArt(
                    creature,
                    size: 150,
                    silhouette: !caught,
                    animate: caught,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    creature.name,
                    style: display(21),
                    textAlign: TextAlign.center,
                  ),
                  if (creature.localName.isNotEmpty)
                    Text(
                      creature.localName,
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  const SizedBox(height: 6),
                  _RarityTag(creature.rarity),
                ],
              ),
            ),
            // Tape strips
            Positioned(left: -14, top: -8, child: _tape(-24)),
            Positioned(right: -14, top: -8, child: _tape(22)),
            if (caught)
              Positioned(
                right: -22,
                top: 28,
                child: AnimatedOpacity(
                  opacity: stamped ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: AnimatedScale(
                    scale: stamped ? 1 : 2.6,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Transform.rotate(
                      angle: -14 * pi / 180,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.9),
                          border: Border.all(color: AppColors.red, width: 3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'NAHULI!',
                          style: display(20, color: AppColors.red),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tape(double deg) => Transform.rotate(
    angle: deg * pi / 180,
    child: Container(
      width: 64,
      height: 18,
      color: AppColors.gold.withValues(alpha: 0.75),
    ),
  );
}

class _RarityTag extends StatelessWidget {
  const _RarityTag(this.rarity);
  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (rarity) {
      Rarity.common => ('Common', AppColors.inkMuted),
      Rarity.rare => ('Rare', const Color(0xFF2F7FB0)),
      Rarity.legendary => ('Legendary', AppColors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.stage,
    required this.session,
    required this.newBadges,
    required this.onRetry,
  });

  final Stage stage;
  final StageSession session;
  final List<Achievement> newBadges;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = session.failed;
    final xp = session.correct * 10 + session.caught.length * 25;
    return Stack(
      children: [
        if (!failed) const Positioned.fill(child: SpinningRays()),
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            PopIn(
              startScale: 0.3,
              child: Icon(
                failed
                    ? Icons.flashlight_off_rounded
                    : Icons.emoji_events_rounded,
                size: 72,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              failed ? 'Your flashlight ran out!' : 'Stage complete!',
              textAlign: TextAlign.center,
              style: display(32),
            ),
            const SizedBox(height: 6),
            Text(
              failed
                  ? 'You lost all your hearts. Every try helps you learn, so give '
                        'it another go.'
                  : '${session.correct} of ${session.questionCount} answers correct.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 16),
            ),
            if (!failed) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    PopIn(
                      delay: Duration(milliseconds: 400 + i * 260),
                      startScale: 0,
                      startTilt: -40,
                      child: Icon(
                        i < session.stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 56,
                        color: i < session.stars
                            ? AppColors.gold
                            : AppColors.muted,
                        shadows: const [
                          Shadow(
                            color: Color(0x88000000),
                            offset: Offset(2, 3),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            PopIn(
              delay: const Duration(milliseconds: 1200),
              startScale: 0.6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: xp),
                    duration: const Duration(milliseconds: 900),
                    builder: (_, v, _) =>
                        Pill('+$v XP', icon: Icons.bolt_rounded),
                  ),
                  const SizedBox(width: 8),
                  if (session.caught.isNotEmpty)
                    Pill(
                      '${session.caught.length} caught',
                      icon: Icons.pets_rounded,
                    ),
                ],
              ),
            ),
            if (!failed &&
                session.stars == 3 &&
                stage.creatureIds.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Center(
                child: PopIn(
                  delay: Duration(milliseconds: 1500),
                  startScale: 0,
                  startTilt: -20,
                  child: Pill(
                    'Perfect! Shiny cards unlocked',
                    icon: Icons.auto_awesome_rounded,
                  ),
                ),
              ),
            ],
            if (session.caught.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < session.caught.length; i++)
                    PopIn(
                      delay: Duration(milliseconds: 1300 + i * 200),
                      startScale: 0.2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: CreatureArt(
                          creatureById[session.caught[i]]!,
                          size: 80,
                          animate: true,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            for (var i = 0; i < newBadges.length; i++) ...[
              const SizedBox(height: 14),
              PopIn(
                delay: Duration(milliseconds: 1600 + i * 200),
                from: const Offset(0, 30),
                child: PaperCard(
                  tilt: i.isEven ? -1 : 1,
                  seed: 80 + i,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.orange,
                        size: 34,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New badge: ${newBadges[i].title}',
                              style: display(17),
                            ),
                            Text(
                              newBadges[i].description,
                              style: const TextStyle(color: AppColors.inkMuted),
                            ),
                            Text(
                              '+${newBadges[i].gems} gems to claim in Badges',
                              style: display(13, color: AppColors.orange),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (failed) ...[
              PaperButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
              const SizedBox(height: 12),
              PaperButton(
                label: 'Back to map',
                color: AppColors.track,
                textColor: AppColors.text,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ] else
              PaperButton(
                label: 'Back to map',
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
        if (!failed)
          const Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment(0, -0.55),
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: ConfettiBurst(count: 50, power: 1.2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
