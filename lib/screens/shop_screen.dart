import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/rewards.dart';
import '../services/sfx.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';
import '../widgets/partner_art.dart';
import '../widgets/partner_picker.dart';

enum _Tab { wardrobe, parols, gifts, partner }

/// Where gems are spent: outfits for the partner and parol designs. Tap an item
/// to try it on in the preview before buying. Moon gifts can't be bought;
/// they come from keeping a streak.
/// What the shop preview shows the partner wearing. An item you don't own
/// yet is tried on so you can see it before buying. Owned items show what
/// the partner really wears, so taking one off shows right away.
@visibleForTesting
List<String> shopPreviewOutfit(
  Map<String, String> outfit,
  Reward? selected, {
  required bool owned,
}) {
  final map = Map<String, String>.from(outfit);
  if (selected != null && selected.kind == RewardKind.outfit && !owned) {
    map[selected.slot!.name] = selected.id;
  }
  return map.values.toList();
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  _Tab _tab = _Tab.wardrobe;
  Reward? _selected;
  int _hops = 0;
  int _bursts = 0;

  List<String> _previewOutfit(GameState game) => shopPreviewOutfit(
    game.outfit,
    _selected,
    owned: _selected != null && game.owns(_selected!.id),
  );

  ParolStyle _previewParol(GameState game) {
    final r = _selected;
    if (r != null && r.kind == RewardKind.parol) return parolStyleOf(r.id);
    return game.parolStyle;
  }

  void _select(Reward r) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = r;
      _hops++;
    });
  }

  Future<void> _buy(GameState game, Reward r) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Buy ${r.name}?', style: display(22, color: AppColors.ink)),
        content: Text('It costs ${r.price} gems. You have ${game.gems}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text(
              'Not now',
              style: TextStyle(color: AppColors.ink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text('Buy it', style: display(16, color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    if (await game.buy(r)) {
      Sfx.gem.play();
      HapticFeedback.mediumImpact();
      await game.equip(r);
      setState(() {
        _bursts++;
        _hops++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final items = rewards.where(
      (r) => switch (_tab) {
        _Tab.wardrobe => r.kind == RewardKind.outfit,
        _Tab.parols => r.kind == RewardKind.parol,
        _Tab.gifts => r.isGift,
        _Tab.partner => false,
      },
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Expanded(child: Text('Shop', style: display(30))),
              Pill(
                '${game.gems}',
                icon: Icons.diamond_rounded,
                iconColor: const Color(0xFF3A9BC8),
              ),
            ],
          ),
        ),
        _Preview(
          outfit: _previewOutfit(game),
          parol: _previewParol(game),
          hops: _hops,
          bursts: _bursts,
        ),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ItemAction(
              reward: _selected!,
              game: game,
              onBuy: () => _buy(game, _selected!),
              onEquip: () async {
                await game.equip(_selected!);
                setState(() => _hops++);
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (t, label, icon) in [
                (_Tab.wardrobe, 'Wardrobe', Icons.checkroom_rounded),
                (_Tab.parols, 'Parols', Icons.star_rounded),
                (_Tab.gifts, 'Moon gifts', Icons.nightlight_round),
                (_Tab.partner, 'Partner', Icons.pets_rounded),
              ])
                AnimatedScale(
                  scale: _tab == t ? 1.06 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: PaperCard(
                    color: _tab == t ? AppColors.gold : AppColors.cream,
                    tilt: _tab == t ? -2 : 0,
                    seed: label.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    onTap: () => setState(() => _tab = t),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: 6),
                        Text(label, style: display(15)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_tab == _Tab.partner)
          _PartnerPanel(
            key: ValueKey(game.partnerId),
            game: game,
            onSwitch: (id) async {
              if (id == game.partnerId) return;
              HapticFeedback.mediumImpact();
              await game.choosePartner(id);
              setState(() {
                _bursts++;
                _hops++;
              });
            },
          )
        else if (_tab == _Tab.gifts)
          _GiftsList(game: game, onSelect: _select, selected: _selected)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              key: ValueKey(_tab),
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
              children: [
                for (final (i, r) in items.indexed)
                  PopIn(
                    delay: Duration(milliseconds: 40 * i),
                    startScale: 0.6,
                    child: _ItemCard(
                      reward: r,
                      game: game,
                      selected: _selected?.id == r.id,
                      onTap: () => _select(r),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The partner on a branch under the parols, wearing whatever is being tried on.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.outfit,
    required this.parol,
    required this.hops,
    required this.bursts,
  });

  final List<String> outfit;
  final ParolStyle parol;
  final int hops;
  final int bursts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          Positioned.fill(
            child: PaperScene(
              habitatId: 'rainforest',
              layer: SceneLayer.back,
              parols: true,
              parolStyle: parol,
              perches: const [0.9],
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.82),
            child: Hop(
              trigger: hops,
              child: PartnerArt(size: 140, outfit: outfit),
            ),
          ),
          const Positioned.fill(
            child: PaperScene(habitatId: 'rainforest', layer: SceneLayer.front),
          ),
          if (bursts > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: ConfettiBurst(
                      key: ValueKey(bursts),
                      count: 40,
                      power: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.reward,
    required this.game,
    required this.selected,
    required this.onTap,
  });

  final Reward reward;
  final GameState game;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final owned = game.owns(reward.id);
    final inUse = reward.kind == RewardKind.parol
        ? game.parolId == reward.id
        : game.isWearing(reward.id);
    final locked = reward.isGift && !owned;
    return AnimatedScale(
      scale: selected ? 1.06 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: PaperCard(
        color: locked
            ? AppColors.track
            : selected
            ? const Color(0xFFFFF6E0)
            : AppColors.cream,
        tilt: selected ? -2 : 0,
        seed: reward.id.length,
        padding: const EdgeInsets.all(8),
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Center(
                // Locked gifts show faded, so kids can see what they're
                // working toward.
                child: Opacity(
                  opacity: locked ? 0.5 : 1,
                  child: reward.kind == RewardKind.outfit
                      ? PartnerArt(
                          size: 80,
                          animate: false,
                          outfit: [reward.id],
                          shadow: false,
                        )
                      : _ParolSwatch(style: parolStyleOf(reward.id)),
                ),
              ),
            ),
            Text(
              reward.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: locked ? AppColors.muted : AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            _PriceTag(reward: reward, owned: owned, inUse: inUse),
          ],
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({
    required this.reward,
    required this.owned,
    required this.inUse,
  });
  final Reward reward;
  final bool owned;
  final bool inUse;

  @override
  Widget build(BuildContext context) {
    final (String text, IconData? icon, Color color) = inUse
        ? ('In use', Icons.check_circle_rounded, AppColors.rightInk)
        : owned
        ? ('Owned', null, AppColors.inkMuted)
        : reward.isGift
        ? (
            '${reward.giftStreak} nights',
            Icons.nightlight_round,
            AppColors.muted,
          )
        : ('${reward.price}', Icons.diamond_rounded, const Color(0xFF3A9BC8));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          style: display(
            13,
            color: color == AppColors.muted ? AppColors.muted : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

/// A single parol drawn in a design, gently swaying.
class _ParolSwatch extends StatefulWidget {
  const _ParolSwatch({required this.style});
  final ParolStyle style;

  @override
  State<_ParolSwatch> createState() => _ParolSwatchState();
}

class _ParolSwatchState extends State<_ParolSwatch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2800 + Random().nextInt(900)),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: const Size(70, 84),
        painter: _SwatchPainter(
          widget.style,
          still ? 0 : sin(_c.value * 2 * pi) * 0.08,
        ),
      ),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.style, this.swing);
  final ParolStyle style;
  final double swing;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.sky);
    drawParol(
      canvas,
      Offset(size.width / 2, 4),
      18,
      style.colorAt(0),
      swing: swing,
      style: style,
    );
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.swing != swing || old.style != style;
}

/// Buy, wear, or hang the selected item.
class _ItemAction extends StatelessWidget {
  const _ItemAction({
    required this.reward,
    required this.game,
    required this.onBuy,
    required this.onEquip,
  });

  final Reward reward;
  final GameState game;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final owned = game.owns(reward.id);
    final isParol = reward.kind == RewardKind.parol;
    final inUse = isParol
        ? game.parolId == reward.id
        : game.isWearing(reward.id);
    final Widget button;
    if (owned) {
      button = PaperButton(
        label: isParol
            ? (inUse ? 'Hanging now' : 'Hang these parols')
            : (inUse ? 'Take it off' : 'Wear it'),
        icon: isParol ? Icons.star_rounded : Icons.checkroom_rounded,
        onPressed: isParol && inUse ? null : onEquip,
      );
    } else if (reward.isGift) {
      button = PaperButton(
        label: 'Keep a ${reward.giftStreak}-night streak',
        icon: Icons.nightlight_round,
        onPressed: null,
      );
    } else if (game.canAfford(reward)) {
      button = PaperButton(
        label: 'Buy for ${reward.price} gems',
        icon: Icons.diamond_rounded,
        onPressed: onBuy,
      );
    } else {
      button = PaperButton(
        label: 'Need ${reward.price! - game.gems} more gems',
        icon: Icons.diamond_rounded,
        onPressed: null,
      );
    }
    return PopIn(
      key: ValueKey(reward.id),
      from: const Offset(0, 12),
      startScale: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(reward.name, style: display(20)),
          Text(
            reward.blurb,
            style: const TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 10),
          button,
        ],
      ),
    );
  }
}

/// Moon gifts and how close the kid is to each one.
class _GiftsList extends StatelessWidget {
  const _GiftsList({
    required this.game,
    required this.onSelect,
    required this.selected,
  });
  final GameState game;
  final void Function(Reward) onSelect;
  final Reward? selected;

  @override
  Widget build(BuildContext context) {
    final streak = game.streak();
    final gifts = rewards.where((r) => r.isGift).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Play every night to earn these. You can’t buy them!',
            style: const TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            streak == 1
                ? 'Your streak: 1 night'
                : 'Your streak: $streak nights',
            style: display(17, color: AppColors.gold),
          ),
          const SizedBox(height: 12),
          for (final (i, r) in gifts.indexed) ...[
            PopIn(
              delay: Duration(milliseconds: 60 * i),
              from: const Offset(0, 16),
              startScale: 0.9,
              child: PaperCard(
                color: game.owns(r.id) ? AppColors.cream : AppColors.track,
                tilt: i.isEven ? -0.6 : 0.6,
                seed: r.id.length + 7,
                onTap: () => onSelect(r),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Opacity(
                        opacity: game.owns(r.id) ? 1 : 0.5,
                        child: r.kind == RewardKind.outfit
                            ? PartnerArt(
                                size: 64,
                                animate: false,
                                outfit: [r.id],
                                shadow: false,
                              )
                            : _ParolSwatch(style: parolStyleOf(r.id)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: display(
                              17,
                              color: game.owns(r.id)
                                  ? AppColors.ink
                                  : AppColors.text,
                            ),
                          ),
                          Text(
                            '${r.giftStreak}-night streak',
                            style: TextStyle(
                              color: game.owns(r.id)
                                  ? AppColors.inkMuted
                                  : AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Meter(
                            min(1, streak / r.giftStreak!),
                            track: game.owns(r.id)
                                ? const Color(0xFFE2D3B2)
                                : AppColors.deep,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      game.owns(r.id)
                          ? Icons.check_circle_rounded
                          : Icons.lock_rounded,
                      color: game.owns(r.id)
                          ? AppColors.rightInk
                          : AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Switch partners (always free; the outfit comes along) and rename the
/// current one.
class _PartnerPanel extends StatefulWidget {
  const _PartnerPanel({super.key, required this.game, required this.onSwitch});
  final GameState game;
  final ValueChanged<String> onSwitch;

  @override
  State<_PartnerPanel> createState() => _PartnerPanelState();
}

class _PartnerPanelState extends State<_PartnerPanel> {
  late final _name = TextEditingController(text: widget.game.partnerName);
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _rename() async {
    FocusScope.of(context).unfocus();
    await widget.game.renamePartner(_name.text);
    _name.text = widget.game.partnerName;
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          PartnerTokens(
            selected: game.partnerId,
            nameOf: game.partnerNameOf,
            onSelect: widget.onSwitch,
          ),
          const SizedBox(height: 8),
          Text(
            'Switching is free, and your outfit comes along.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          PaperCard(
            seed: 12,
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 12,
                    style: display(20, color: AppColors.ink),
                    decoration: InputDecoration(
                      labelText: 'Partner’s name',
                      hintText: game.partner.name,
                      counterText: '',
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (_) => setState(() => _saved = false),
                    onSubmitted: (_) => _rename(),
                  ),
                ),
                IconButton(
                  tooltip: 'Save name',
                  onPressed: _rename,
                  icon: Icon(
                    _saved ? Icons.check_circle_rounded : Icons.check_rounded,
                    color: _saved ? AppColors.rightInk : AppColors.ink,
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
