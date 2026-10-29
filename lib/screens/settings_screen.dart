import 'package:flutter/material.dart';

import '../data/content.dart';
import '../services/music.dart';
import '../state/game_state.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/startup_loader.dart' show developers;
import 'review_screen.dart';

/// Shown on the settings page and the licenses page. Keep in step with the
/// version in pubspec.yaml.
const appVersion = '1.0.0';

/// Scene, sound, display, and grown-up tools, as paper cards on the night
/// sky. Settings kids change sit at the top; grown-up tools sit lower.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final s = Settings.instance;
    final music = Music.instance;
    return Scaffold(
      body: NightSky(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([s, music.muted]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const _TopBar('Settings'),
                const _Section('Scene'),
                _Card(
                  seed: 1,
                  children: [
                    _Row(
                      icon: Icons.brightness_6_rounded,
                      tint: const Color(0xFFFFE7B8),
                      title: 'Day or night',
                      note: 'Auto follows the clock: sunny 6 am to 6 pm',
                    ),
                    _Choices(
                      labels: const ['Auto', 'Day', 'Night'],
                      icons: const [
                        null,
                        Icons.wb_sunny_rounded,
                        Icons.nightlight_round,
                      ],
                      selected: s.scene.index,
                      onSelect: (i) =>
                          s.update((s) => s.scene = SceneMode.values[i]),
                    ),
                  ],
                ),
                const _Section('Sound'),
                _Card(
                  seed: 2,
                  children: [
                    _Row(
                      icon: Icons.music_note_rounded,
                      tint: const Color(0xFFFDE2C8),
                      title: 'Music',
                      note: '"Up in the Sky"',
                      toggle: !music.muted.value,
                      onToggle: (_) => music.toggleMute(),
                    ),
                    _Row(
                      icon: Icons.notifications_active_rounded,
                      tint: const Color(0xFFFDE2C8),
                      title: 'Sound effects',
                      note: 'Chimes for answers, catches, and taps',
                      toggle: s.soundEffects,
                      onToggle: (v) => s.update((s) => s.soundEffects = v),
                    ),
                    _Row(
                      icon: Icons.pets_rounded,
                      tint: const Color(0xFFDDEBD2),
                      title: 'Animal calls',
                      note: 'Real sounds on Dex cards',
                      toggle: s.animalCalls,
                      onToggle: (v) => s.update((s) => s.animalCalls = v),
                    ),
                    _Row(
                      icon: Icons.record_voice_over_rounded,
                      tint: const Color(0xFFD8E6F2),
                      title: 'Read questions aloud',
                      note: 'Reads each question automatically',
                      toggle: s.autoRead,
                      onToggle: (v) => s.update((s) => s.autoRead = v),
                    ),
                    _Row(
                      icon: Icons.speed_rounded,
                      tint: const Color(0xFFD8E6F2),
                      title: 'Reading speed',
                    ),
                    _Choices(
                      labels: const ['Slow', 'Normal', 'Fast'],
                      selected: s.readSpeed.index,
                      onSelect: (i) =>
                          s.update((s) => s.readSpeed = ReadSpeed.values[i]),
                    ),
                  ],
                ),
                const _Section('Easier to see'),
                _Card(
                  seed: 3,
                  children: [
                    _Row(
                      icon: Icons.text_fields_rounded,
                      tint: const Color(0xFFEADCBC),
                      title: 'Text size',
                    ),
                    _Choices(
                      labels: const ['Normal', 'Large'],
                      selected: s.largeText ? 1 : 0,
                      onSelect: (i) => s.update((s) => s.largeText = i == 1),
                    ),
                    _Row(
                      icon: Icons.spa_rounded,
                      tint: const Color(0xFFEADCBC),
                      title: 'Calm motion',
                      note: 'Fewer bouncy animations',
                      toggle: s.calmMotion,
                      onToggle: (v) => s.update((s) => s.calmMotion = v),
                    ),
                  ],
                ),
                const _Section('About you'),
                ListenableBuilder(
                  listenable: game,
                  builder: (context, _) => _Card(
                    seed: 4,
                    children: [
                      _Row(
                        icon: Icons.face_rounded,
                        tint: const Color(0xFFFDE2C8),
                        title: 'Your name',
                        note: game.name,
                        onTap: () => _rename(context, game),
                      ),
                      _Row(
                        icon: Icons.school_rounded,
                        tint: const Color(0xFFFDE2C8),
                        title: 'Grade',
                      ),
                      _Choices(
                        labels: const ['1', '2', '3', '4', '5', '6'],
                        selected: game.grade - 1,
                        onSelect: (i) => game.setGrade(i + 1),
                      ),
                    ],
                  ),
                ),
                const _Section('For grown-ups'),
                _Card(
                  seed: 5,
                  children: [
                    _Row(
                      icon: Icons.insights_rounded,
                      tint: const Color(0xFFE2DDF2),
                      title: 'Progress report',
                      note: 'Creatures found and stars for each topic',
                      onTap: () => _open(context, const ProgressScreen()),
                    ),
                    _Row(
                      icon: Icons.alarm_rounded,
                      tint: const Color(0xFFE2DDF2),
                      title: 'Break reminder',
                      note: 'Your partner suggests a rest after a while',
                    ),
                    _Choices(
                      labels: const ['Off', '15 min', '30 min'],
                      selected: const [0, 15, 30].indexOf(s.breakMinutes),
                      onSelect: (i) => s.update(
                        (s) => s.breakMinutes = const [0, 15, 30][i],
                      ),
                    ),
                    _Row(
                      icon: Icons.restart_alt_rounded,
                      tint: const Color(0xFFF8D6D0),
                      title: 'Start over',
                      titleColor: AppColors.red,
                      note: 'Erases all progress. Asks first.',
                      onTap: () => _confirmReset(context, game),
                    ),
                  ],
                ),
                const _Section('About'),
                _Card(
                  seed: 6,
                  children: [
                    _Row(
                      icon: Icons.star_rounded,
                      tint: const Color(0xFFEADCBC),
                      title: 'Credits',
                      note: 'Developers, music, sounds, and fonts',
                      onTap: () => _open(context, const CreditsScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Creature Collector · version $appVersion',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _rename(BuildContext context, GameState game) async {
    final ctrl = TextEditingController(text: game.name);
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Your name', style: display(22, color: AppColors.ink)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.ink, fontSize: 18),
          onSubmitted: (v) => Navigator.pop(d, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, ctrl.text),
            child: const Text('Save', style: TextStyle(color: AppColors.ink)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null) await game.rename(name);
  }

  Future<void> _confirmReset(BuildContext context, GameState game) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Start over?', style: display(22, color: AppColors.ink)),
        content: const Text(
          'This erases your stars, creatures, and badges on this phone. '
          'Your settings stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text(
              'Keep my progress',
              style: TextStyle(color: AppColors.ink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text(
              'Erase everything',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    // Back to the first screen; with no profile it becomes onboarding.
    Navigator.of(context).popUntil((r) => r.isFirst);
    await game.resetProgress();
  }
}

/// How the player is doing: totals, then stars for each stage's topic.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final stats = [
      (
        Icons.pets_rounded,
        '${game.caught.length} of ${creatures.length}',
        'creatures found',
      ),
      (Icons.star_rounded, '${game.totalStars}', 'stars earned'),
      (Icons.check_circle_rounded, '${game.correctTotal}', 'right answers'),
      (Icons.trending_up_rounded, 'Level ${game.level}', 'explorer level'),
      (Icons.local_fire_department_rounded, '${game.streak()}', 'day streak'),
      (Icons.event_available_rounded, '${game.playDays.length}', 'days played'),
    ];
    return Scaffold(
      body: NightSky(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _TopBar('${game.name}\'s progress'),
              const SizedBox(height: 4),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.9,
                children: [
                  for (final (i, (icon, value, label)) in stats.indexed)
                    PaperCard(
                      seed: i + 10,
                      tilt: i.isEven ? -0.6 : 0.6,
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Icon(icon, color: AppColors.orange, size: 26),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(value, style: display(20)),
                                ),
                                Text(
                                  label,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkMuted,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (game.toReview.isNotEmpty) ...[
                const _Section('Needs practice'),
                _Card(
                  seed: 9,
                  children: [
                    for (final (creature, n) in _practiceByCreature(game))
                      _Credit(
                        creature,
                        n == 1
                            ? '1 question to review'
                            : '$n questions to review',
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: PaperButton(
                        label: 'Practice now',
                        icon: Icons.replay_rounded,
                        size: 16,
                        onPressed: () =>
                            SettingsScreen._open(context, const ReviewScreen()),
                      ),
                    ),
                  ],
                ),
              ],
              for (final h in habitats.where((h) => !h.comingSoon)) ...[
                _Section(h.name),
                _Card(
                  seed: h.name.length,
                  children: [
                    for (final id in h.stageIds)
                      if (stageById[id] case final st?)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      st.topic,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Stage ${st.number} · ${st.title}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              game.isStageDone(st.id)
                                  ? StarRow(game.stars[st.id] ?? 0, size: 18)
                                  : const Text(
                                      'Not yet',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Missed questions grouped by creature, most first.
List<(String, int)> _practiceByCreature(GameState game) {
  final counts = <String, int>{};
  for (final q in game.reviewQuestions) {
    final name = creatureById[q.creatureId]?.name ?? q.creatureId;
    counts.update(name, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts.entries.map((e) => (e.key, e.value)).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));
}

/// Who made the app, and the music, sounds, and fonts it uses.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calls = creatures.where((c) => c.sound != null);
    return Scaffold(
      body: NightSky(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _TopBar('Credits'),
              const _Section('Made by'),
              _Card(
                seed: 1,
                children: [
                  for (final name in developers) _Credit(name, 'Developer'),
                ],
              ),
              const _Section('Music'),
              _Card(
                seed: 2,
                children: const [
                  _Credit(
                    '"Up in the Sky" by Memoraphile',
                    'From OpenGameArt.org · CC0 (public domain)',
                  ),
                ],
              ),
              const _Section('Animal sounds'),
              _Card(
                seed: 3,
                children: [
                  for (final c in calls) _Credit(c.name, c.sound!.credit),
                ],
              ),
              const _Section('Fonts'),
              _Card(
                seed: 4,
                children: const [
                  _Credit('Sniglet by Haley Fiege', 'SIL Open Font License'),
                  _Credit(
                    'Atkinson Hyperlegible by the Braille Institute',
                    'SIL Open Font License',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: PaperButton(
                  label: 'All open-source licenses',
                  icon: Icons.description_rounded,
                  expand: false,
                  size: 16,
                  color: AppColors.track,
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'Creature Collector',
                    applicationVersion: appVersion,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pieces ----------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Semantics(
            label: 'Back',
            button: true,
            excludeSemantics: true,
            child: Squish(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.deep.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.muted.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: display(30))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Text(
        title.toUpperCase(),
        style: display(13, color: AppColors.gold).copyWith(letterSpacing: 1),
      ),
    );
  }
}

/// A paper card of rows, each separated by a faint line.
class _Card extends StatelessWidget {
  const _Card({required this.children, this.seed = 1});
  final List<Widget> children;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      seed: seed,
      tilt: seed.isEven ? 0.4 : -0.4,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// One setting: an icon, a title and note, and an optional switch or arrow.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.tint,
    required this.title,
    this.note,
    this.titleColor,
    this.toggle,
    this.onToggle,
    this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String? note;
  final Color? titleColor;
  final bool? toggle;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = toggle;
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? AppColors.ink,
                  ),
                ),
                if (note case final n? when n.isNotEmpty)
                  Text(
                    n,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkMuted,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          if (on != null) ...[
            const SizedBox(width: 8),
            _Toggle(on: on),
          ] else if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8A888)),
        ],
      ),
    );
    if (on != null && onToggle != null) {
      return Semantics(
        toggled: on,
        label: title,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onToggle!(!on),
          child: row,
        ),
      );
    }
    if (onTap != null) {
      return Semantics(
        button: true,
        label: title,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: row,
        ),
      );
    }
    return row;
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(3),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? AppColors.orange : const Color(0xFFCFC3A6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 2)],
        ),
      ),
    );
  }
}

/// A row of paper chips; the picked one is orange.
class _Choices extends StatelessWidget {
  const _Choices({
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.icons,
  });

  final List<String> labels;
  final List<IconData?>? icons;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          for (final (i, label) in labels.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                label: label,
                excludeSemantics: true,
                child: Squish(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 38,
                    decoration: BoxDecoration(
                      color: i == selected
                          ? AppColors.orange
                          : const Color(0xFFEADCBC),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: i == selected
                          ? const [
                              BoxShadow(
                                color: Color(0x40000000),
                                offset: Offset(2, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icons?[i] case final icon?) ...[
                              Icon(
                                icon,
                                size: 16,
                                color: i == selected
                                    ? AppColors.cream
                                    : AppColors.inkMuted,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              label,
                              style: display(
                                14,
                                color: i == selected
                                    ? AppColors.cream
                                    : AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit(this.title, this.note);
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          Text(
            note,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.inkMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
