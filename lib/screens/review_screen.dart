import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/sfx.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/partner_art.dart';
import 'stage/question_view.dart';

/// A short practice round of questions the player got wrong before. No
/// hearts to lose: each one answered right is cleared and earns gems.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  static const roundSize = 5;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<Question> _questions;
  int _index = 0;
  int _fixed = 0;
  int _hints = 2;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_index == 0 && !_done) {
      _questions = GameScope.of(context).reviewQuestions
          .take(ReviewScreen.roundSize)
          .toList();
    }
  }

  Future<void> _next() async {
    if (_index + 1 < _questions.length) {
      setState(() => _index++);
      return;
    }
    await GameScope.of(context).finishReview(_fixed);
    if (_fixed > 0) Sfx.gem.play();
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    return Scaffold(
      body: NightSky(
        child: SafeArea(
          child: _done || total == 0
              ? _Finished(fixed: _fixed, total: total)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Stop practicing',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.text,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Practice · ${_index + 1} of $total',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Meter(_index / total),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: QuestionView(
                          key: ValueKey(_index),
                          question: _questions[_index],
                          hintsLeft: _hints,
                          onUseHint: () {
                            if (_hints == 0) return false;
                            setState(() => _hints--);
                            return true;
                          },
                          onAnswer: (correct) {
                            if (correct) _fixed++;
                            GameScope.of(context)
                                .noteAnswer(_questions[_index], correct);
                          },
                          onNext: _next,
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

class _Finished extends StatelessWidget {
  const _Finished({required this.fixed, required this.total});
  final int fixed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final left = GameScope.of(context).toReview.length;
    final gems = fixed * GameState.gemsPerFix;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          const PopIn(startScale: 0.5, child: PartnerArt(size: 150)),
          const SizedBox(height: 12),
          Text(
            total == 0
                ? 'Nothing to practice!'
                : fixed == total
                ? 'Great practice!'
                : 'Good practice!',
            style: display(32),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'You have no questions to review right now.'
                : 'You fixed $fixed of $total.'
                      '${left > 0 ? ' $left more to practice later.' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          if (gems > 0) ...[
            const SizedBox(height: 16),
            PopIn(
              delay: const Duration(milliseconds: 300),
              child: Pill(
                '+$gems gems',
                icon: Icons.diamond_rounded,
                iconColor: const Color(0xFF3A9BC8),
              ),
            ),
          ],
          const Spacer(),
          PaperButton(
            label: 'Done',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
