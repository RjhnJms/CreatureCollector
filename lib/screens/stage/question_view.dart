import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../../services/music.dart';
import '../../services/sfx.dart';
import '../../services/speech.dart';
import '../../state/settings.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/creature_art.dart';

/// Shows one question of any type. Calls [onAnswer] once with whether the
/// answer was right, then [onNext] when the kid taps Next.
class QuestionView extends StatefulWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.hintsLeft,
    required this.onUseHint,
    required this.onAnswer,
    required this.onNext,
  });

  final Question question;
  final int hintsLeft;

  /// Returns false if no hints are left.
  final bool Function() onUseHint;
  final void Function(bool correct) onAnswer;
  final VoidCallback onNext;

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  bool? _correct;

  /// Bumped when a hint is used; the answer widget reacts to it.
  int _hintsUsed = 0;

  bool get _answered => _correct != null;

  void _submit(bool correct) {
    if (_answered) return;
    correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    (correct ? Sfx.correct : Sfx.wrong).play();
    widget.onAnswer(correct);
    setState(() => _correct = correct);
  }

  /// A hint removes a wrong option (always leaving one) or places one sort
  /// item. True/false has nothing to remove, so no hint is offered there.
  bool get _hintWouldHelp => switch (widget.question) {
    ChoiceQuestion q => _hintsUsed < q.options.length - 2,
    PictureQuestion q => _hintsUsed < q.optionIds.length - 2,
    SortQuestion q => _hintsUsed < q.items.length - 1,
  };

  void _hint() {
    if (_answered || !_hintWouldHelp || !widget.onUseHint()) return;
    setState(() => _hintsUsed++);
  }

  String get _readAloud => switch (widget.question) {
    ChoiceQuestion q => '${q.prompt} ${q.options.join(', or ')}',
    SortQuestion q => '${q.prompt} ${q.bins.join(', or ')}',
    final q => q.prompt,
  };

  // Keep the music low while a question is up so the read-aloud voice is
  // clear. Keyed per screen: the next question appears before this one goes.
  late final _duckKey = 'question-${identityHashCode(this)}';

  @override
  void initState() {
    super.initState();
    Music.instance.duck(_duckKey, true);
    if (Settings.instance.autoRead) {
      // A short pause first, so the question is on screen before it's read.
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && !_answered) Speech.instance.speak(_readAloud);
      });
    }
  }

  @override
  void dispose() {
    Speech.instance.stop();
    Music.instance.duck(_duckKey, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final creature = creatureById[q.creatureId]!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: [
              Row(
                children: [
                  CreatureArt(creature, size: 50, animate: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _typeLabel(q),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Squish(
                    onTap: () => Speech.instance.speak(_readAloud),
                    child: Semantics(
                      label: 'Read aloud',
                      child: CustomPaint(
                        painter: PaperShapePainter(
                          color: AppColors.cream,
                          seed: 31,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PopIn(
                from: const Offset(0, -10),
                startScale: 0.9,
                child: Text(q.prompt, style: display(26)),
              ),
              const SizedBox(height: 18),
              switch (q) {
                ChoiceQuestion() => _ChoiceAnswers(
                  question: q,
                  hintsUsed: _hintsUsed,
                  locked: _answered,
                  onPick: _submit,
                ),
                PictureQuestion() => _PictureAnswers(
                  question: q,
                  hintsUsed: _hintsUsed,
                  locked: _answered,
                  onPick: _submit,
                ),
                SortQuestion() => _SortAnswers(
                  question: q,
                  hintsUsed: _hintsUsed,
                  locked: _answered,
                  onCheck: _submit,
                ),
              },
              if (_answered) ...[
                const SizedBox(height: 20),
                PopIn(
                  from: const Offset(0, 30),
                  startScale: 0.8,
                  startTilt: 4,
                  child: _Feedback(correct: _correct!, explain: q.explain),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _answered
              ? PopIn(
                  startScale: 0.6,
                  child: PaperButton(
                    label: 'Next',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: widget.onNext,
                  ),
                )
              : PaperButton(
                  label: !_hintWouldHelp && _hintsUsed == 0
                      ? 'No hints for this one'
                      : 'Hint (${widget.hintsLeft} left)',
                  icon: Icons.lightbulb_outline_rounded,
                  color: AppColors.track,
                  textColor: AppColors.gold,
                  size: 16,
                  onPressed: widget.hintsLeft > 0 && _hintWouldHelp
                      ? _hint
                      : null,
                ),
        ),
      ],
    );
  }
}

String _typeLabel(Question q) => switch (q) {
  ChoiceQuestion(isTrueFalse: true) => 'True or false?',
  ChoiceQuestion() => 'Pick the answer',
  PictureQuestion() => 'Tap the right picture',
  SortQuestion() => 'Tap an item, then tap its group',
};

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.explain});
  final bool correct;
  final String explain;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      tilt: correct ? -1.2 : 1,
      seed: correct ? 41 : 42,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.info_rounded,
            color: correct ? AppColors.rightInk : AppColors.wrongInk,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'Tama! Correct!' : 'Not quite. You lost a heart.',
                  style: display(
                    19,
                    color: correct ? AppColors.rightInk : AppColors.wrongInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explain,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _TileState { idle, right, wrong, faded }

/// An answer as a paper tag. It drops in, shakes when wrong, and bursts
/// confetti when right.
class _AnswerTag extends StatelessWidget {
  const _AnswerTag({
    required this.child,
    required this.onTap,
    required this.index,
    this.state = _TileState.idle,
  });

  final Widget child;
  final VoidCallback? onTap;
  final int index;
  final _TileState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _TileState.idle => AppColors.cream,
      _TileState.right => AppColors.right,
      _TileState.wrong => AppColors.wrong,
      _TileState.faded => const Color(0xFF4A4F86),
    };
    return PopIn(
      delay: Duration(milliseconds: 90 * index),
      from: const Offset(0, -26),
      startScale: 0.85,
      startTilt: index.isEven ? -8 : 8,
      child: Shake(
        trigger: state == _TileState.wrong,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedOpacity(
              opacity: state == _TileState.faded ? 0.4 : 1,
              duration: const Duration(milliseconds: 250),
              child: PaperCard(
                color: color,
                seed: index + 50,
                tilt: index.isEven ? -0.6 : 0.6,
                padding: EdgeInsets.zero,
                onTap: onTap,
                child: child,
              ),
            ),
            if (state == _TileState.right)
              const Positioned.fill(
                child: OverflowBox(
                  maxWidth: 300,
                  maxHeight: 300,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: ConfettiBurst(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Removes [count] wrong options, chosen once and kept stable.
List<int> _hiddenWrong(int optionCount, int answer, int count, int seed) {
  final wrong = [
    for (var i = 0; i < optionCount; i++)
      if (i != answer) i,
  ]..shuffle(Random(seed));
  // Always leave at least one wrong option.
  return wrong.take(min(count, wrong.length - 1)).toList();
}

class _ChoiceAnswers extends StatefulWidget {
  const _ChoiceAnswers({
    required this.question,
    required this.hintsUsed,
    required this.locked,
    required this.onPick,
  });

  final ChoiceQuestion question;
  final int hintsUsed;
  final bool locked;
  final void Function(bool) onPick;

  @override
  State<_ChoiceAnswers> createState() => _ChoiceAnswersState();
}

class _ChoiceAnswersState extends State<_ChoiceAnswers> {
  late final List<int> _order;
  final int _seed = Random().nextInt(1 << 20);
  int? _picked;

  @override
  void initState() {
    super.initState();
    _order = List.generate(widget.question.options.length, (i) => i);
    // Keep True before False; shuffle everything else.
    if (!widget.question.isTrueFalse) _order.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final hidden = _hiddenWrong(
      q.options.length,
      q.answer,
      widget.hintsUsed,
      _seed,
    );
    return Column(
      children: [
        for (var n = 0; n < _order.length; n++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AnswerTag(
              index: n,
              state: _stateFor(_order[n], hidden),
              onTap: widget.locked || hidden.contains(_order[n])
                  ? null
                  : () {
                      setState(() => _picked = _order[n]);
                      widget.onPick(_order[n] == q.answer);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        q.options[_order[n]],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.locked && _order[n] == q.answer)
                      const Icon(
                        Icons.check_rounded,
                        color: AppColors.rightInk,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  _TileState _stateFor(int i, List<int> hidden) {
    if (hidden.contains(i)) return _TileState.faded;
    if (!widget.locked) return _TileState.idle;
    if (i == widget.question.answer) return _TileState.right;
    if (i == _picked) return _TileState.wrong;
    return _TileState.idle;
  }
}

class _PictureAnswers extends StatefulWidget {
  const _PictureAnswers({
    required this.question,
    required this.hintsUsed,
    required this.locked,
    required this.onPick,
  });

  final PictureQuestion question;
  final int hintsUsed;
  final bool locked;
  final void Function(bool) onPick;

  @override
  State<_PictureAnswers> createState() => _PictureAnswersState();
}

class _PictureAnswersState extends State<_PictureAnswers> {
  late final List<String> _ids = [...widget.question.optionIds]..shuffle();
  final int _seed = Random().nextInt(1 << 20);
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final answerIndex = _ids.indexOf(q.answerId);
    final hidden = _hiddenWrong(
      _ids.length,
      answerIndex,
      widget.hintsUsed,
      _seed,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _ids.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _AnswerTag(
              index: i,
              state: hidden.contains(i)
                  ? _TileState.faded
                  : !widget.locked
                  ? _TileState.idle
                  : _ids[i] == q.answerId
                  ? _TileState.right
                  : _ids[i] == _picked
                  ? _TileState.wrong
                  : _TileState.idle,
              onTap: widget.locked || hidden.contains(i)
                  ? null
                  : () {
                      setState(() => _picked = _ids[i]);
                      widget.onPick(_ids[i] == q.answerId);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Column(
                  children: [
                    CreatureArt(creatureById[_ids[i]]!, size: 84),
                    const SizedBox(height: 6),
                    // Names appear only after answering, so they don't give it away.
                    Text(
                      widget.locked ? creatureById[_ids[i]]!.name : ' ',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13, height: 1.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SortAnswers extends StatefulWidget {
  const _SortAnswers({
    required this.question,
    required this.hintsUsed,
    required this.locked,
    required this.onCheck,
  });

  final SortQuestion question;
  final int hintsUsed;
  final bool locked;
  final void Function(bool) onCheck;

  @override
  State<_SortAnswers> createState() => _SortAnswersState();
}

class _SortAnswersState extends State<_SortAnswers> {
  late final List<String> _items = widget.question.items.keys.toList()
    ..shuffle();

  /// Item -> bin index chosen by the kid.
  final Map<String, int> _placed = {};

  /// Items placed by a hint. They can't be moved.
  final Set<String> _hinted = {};
  String? _selected;
  int _hintsApplied = 0;
  bool? _result;

  @override
  void didUpdateWidget(covariant _SortAnswers old) {
    super.didUpdateWidget(old);
    // Each hint places one item in its correct group.
    while (_hintsApplied < widget.hintsUsed) {
      _hintsApplied++;
      final unsure = _items.firstWhere(
        (i) => !_hinted.contains(i) && _placed[i] != widget.question.items[i],
        orElse: () => '',
      );
      if (unsure.isEmpty) break;
      _placed[unsure] = widget.question.items[unsure]!;
      _hinted.add(unsure);
      if (_selected == unsure) _selected = null;
    }
  }

  void _tapItem(String item) {
    if (widget.locked || _hinted.contains(item)) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_placed.containsKey(item)) {
        _placed.remove(item);
        _selected = item;
      } else {
        _selected = _selected == item ? null : item;
      }
    });
  }

  void _tapBin(int bin) {
    final item = _selected;
    if (widget.locked || item == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _placed[item] = bin;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final waiting = _items.where((i) => !_placed.containsKey(i)).toList();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (var i = 0; i < waiting.length; i++)
                  PopIn(
                    key: ValueKey('w-${waiting[i]}'),
                    delay: Duration(milliseconds: 70 * i),
                    from: const Offset(0, -16),
                    child: _chip(waiting[i]),
                  ),
                if (waiting.isEmpty && !widget.locked)
                  const Text(
                    'All sorted. Check your answer!',
                    style: TextStyle(color: AppColors.muted),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (var b = 0; b < q.bins.length; b++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _tapBin(b),
                  child: AnimatedScale(
                    scale: _selected != null ? 1.02 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: PaperCard(
                      color: _selected != null
                          ? const Color(0xFFFFF6E0)
                          : AppColors.cream,
                      seed: b + 60,
                      tilt: b.isEven ? -0.5 : 0.5,
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(q.bins[b], style: display(17)),
                                if (_selected != null) ...[
                                  const Spacer(),
                                  const Icon(
                                    Icons.touch_app_rounded,
                                    size: 18,
                                    color: AppColors.orange,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final item in _items)
                                  if (_placed[item] == b)
                                    PopIn(
                                      key: ValueKey('p-$item-$b'),
                                      startScale: 0.5,
                                      child: _chip(item),
                                    ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!widget.locked)
              PaperButton(
                label: 'Check',
                onPressed: waiting.isEmpty
                    ? () {
                        final ok = _items.every(
                          (i) => _placed[i] == q.items[i],
                        );
                        setState(() => _result = ok);
                        widget.onCheck(ok);
                      }
                    : null,
              ),
          ],
        ),
        if (_result == true)
          const Positioned.fill(child: ConfettiBurst(count: 36)),
      ],
    );
  }

  Widget _chip(String item) {
    final selected = _selected == item;
    Color color = selected ? AppColors.gold : const Color(0xFFE9D9B4);
    if (widget.locked || _hinted.contains(item)) {
      color = _placed[item] == widget.question.items[item]
          ? AppColors.right
          : AppColors.wrong;
    }
    return AnimatedScale(
      scale: selected ? 1.1 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: PaperCard(
        color: color,
        seed: item.length,
        tilt: selected ? -4 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        onTap: () => _tapItem(item),
        child: Text(
          item,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
