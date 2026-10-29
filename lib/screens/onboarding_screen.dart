import 'package:flutter/material.dart';

import '../data/partners.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/partner_art.dart';
import '../widgets/partner_picker.dart';
import '../widgets/scene.dart';

/// First launch, in three steps: the kid enters their name and grade,
/// chooses a partner, and can give the partner a new name.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _partnerName = TextEditingController();
  int _grade = 3;
  int _hops = 0;
  int _step = 0;
  String _partner = defaultPartner;

  @override
  void dispose() {
    _name.dispose();
    _partnerName.dispose();
    super.dispose();
  }

  void _goTo(int step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    // The phone's back button steps back through onboarding first.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_step - 1);
      },
      child: Scaffold(
        body: NightSky(
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  0 => _aboutYou(),
                  1 => _pickPartner(),
                  _ => _namePartner(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _aboutYou() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 280,
          child: Stack(
            children: [
              const Positioned.fill(
                child: PaperScene(
                  habitatId: 'rainforest',
                  layer: SceneLayer.back,
                  parols: true,
                  perches: [0.9],
                ),
              ),
              // All three partners say hello, since none is chosen yet.
              Align(
                alignment: const Alignment(0, 0.8),
                child: GestureDetector(
                  onTap: () => setState(() => _hops++),
                  child: Hop(
                    trigger: _hops,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final p in partners)
                          PartnerArt(partnerId: p.id, size: 112),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: PaperScene(
                  habitatId: 'rainforest',
                  layer: SceneLayer.front,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PopIn(
                startScale: 0.6,
                child: Text(
                  'Welcome, Night Ranger!',
                  textAlign: TextAlign.center,
                  style: display(30),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Let's find the creatures hiding in the dark. "
                'First, tell me about you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 17),
              ),
              const SizedBox(height: 26),
              Text("What's your name?", style: display(18)),
              const SizedBox(height: 8),
              CustomPaint(
                painter: PaperShapePainter(color: AppColors.cream, seed: 3),
                child: TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 16,
                  style: const TextStyle(fontSize: 18, color: AppColors.ink),
                  decoration: const InputDecoration(
                    hintText: 'Ana',
                    counterText: '',
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 22),
              Text('What grade are you in?', style: display(18)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (var g = 1; g <= 6; g++)
                    AnimatedScale(
                      scale: _grade == g ? 1.08 : 1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: PaperCard(
                        color: _grade == g ? AppColors.gold : AppColors.cream,
                        tilt: _grade == g ? -3 : 0,
                        seed: g,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        onTap: () => setState(() => _grade = g),
                        child: Text('Grade $g', style: display(15)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              PaperButton(
                label: 'Next',
                icon: Icons.arrow_forward_rounded,
                onPressed: _name.text.trim().isEmpty ? null : () => _goTo(1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pickPartner() {
    final p = partnerOf(_partner);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _BackRow(onBack: () => _goTo(0)),
        Text(
          'Choose your partner',
          textAlign: TextAlign.center,
          style: display(28),
        ),
        const SizedBox(height: 2),
        const Text(
          'They’ll explore with you all the way.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 8),
        PartnerStage(partner: p),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(p.name, style: display(28)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE0BD),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                p.place.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        Text(
          p.species,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 18),
        PartnerTokens(
          selected: _partner,
          onSelect: (id) => setState(() => _partner = id),
        ),
        const SizedBox(height: 6),
        const Text(
          'You can switch partners anytime in the Shop, for free.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: PaperButton(
            label: 'Choose ${p.name}',
            icon: Icons.favorite_rounded,
            onPressed: () {
              _partnerName.text = p.name;
              _goTo(2);
            },
          ),
        ),
      ],
    );
  }

  Widget _namePartner() {
    final p = partnerOf(_partner);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _BackRow(onBack: () => _goTo(1)),
        PopIn(
          startScale: 0.6,
          child: Text(
            '${p.name} is your partner!',
            textAlign: TextAlign.center,
            style: display(28),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Want to give them a different name?',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        SizedBox(
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 300,
                height: 230,
                child: IgnorePointer(
                  child: ConfettiBurst(count: 40, power: 1.1),
                ),
              ),
              PopIn(
                startScale: 0.4,
                child: PartnerArt(partnerId: p.id, size: 180),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Partner’s name', style: display(18)),
              const SizedBox(height: 8),
              CustomPaint(
                painter: PaperShapePainter(color: AppColors.cream, seed: 5),
                child: TextField(
                  controller: _partnerName,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 12,
                  style: display(22, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: p.name,
                    counterText: '',
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can change it later in the Shop.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 22),
              PaperButton(
                label: 'Let’s go!',
                icon: Icons.flashlight_on_rounded,
                onPressed: () => GameScope.of(context).createProfile(
                  _name.text,
                  _grade,
                  partner: _partner,
                  partnerName: _partnerName.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small back arrow at the top of the later onboarding steps.
class _BackRow extends StatelessWidget {
  const _BackRow({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: 'Back',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
      ),
    );
  }
}
