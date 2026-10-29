import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/partners.dart';
import '../theme.dart';
import 'common.dart';
import 'partner_art.dart';
import 'partner_move.dart';
import 'scene.dart';

/// A partner in its own home (the forest, the sea, or a dawn sky), saying
/// its first fact. Tapping it plays its move: a hop, a swim up for air, or
/// a flap and hover.
class PartnerStage extends StatefulWidget {
  const PartnerStage({
    super.key,
    required this.partner,
    this.height = 270,
    this.say,
  });
  final Partner partner;
  final double height;

  /// What the partner says. Defaults to its first fact.
  final String? say;

  @override
  State<PartnerStage> createState() => _PartnerStageState();
}

class _PartnerStageState extends State<PartnerStage> {
  int _hops = 0;

  @override
  void didUpdateWidget(PartnerStage old) {
    super.didUpdateWidget(old);
    if (old.partner.id != widget.partner.id) _hops++;
  }

  @override
  Widget build(BuildContext context) {
    final home = widget.partner.home;
    final habitat = home.habitatId, time = home.time, water = home.skyLine;
    const art = 140.0;
    final h = widget.height;
    final artTop = h * (water == null ? 0.9 : home.rest) - art * 0.95;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          // Tarsi gets a tree trunk on the right to leap to. It clings low,
          // so it stays clear of the speech bubble.
          final trunkX = widget.partner.id == 'tarsi' ? w - 44 : null;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  child: PaperScene(
                    key: ValueKey(widget.partner.id),
                    habitatId: habitat,
                    time: time,
                    layer: SceneLayer.back,
                    parols: true,
                    perches: water == null ? const [0.9] : const [],
                    skyLine: water,
                    trunk: trunkX == null ? null : trunkX / w,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: artTop,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _hops++);
                    },
                    child: PartnerTapMove(
                      trigger: _hops,
                      size: art,
                      partnerId: widget.partner.id,
                      surfaceRise: water == null
                          ? 0
                          : artTop + art * 0.505 - h * water,
                      leapX: trunkX == null ? 0 : trunkX - w / 2,
                      leapRise: art * 0.2,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: PaperScene(
                    habitatId: habitat,
                    time: time,
                    layer: SceneLayer.front,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: widget.height * 0.2,
                child: Center(
                  child: PopIn(
                    key: ValueKey('say-${widget.partner.id}-${widget.say}'),
                    startScale: 0.5,
                    child: PaperCard(
                      tilt: -2,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Text(
                        widget.say ?? widget.partner.lines.first,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Three round paper tokens, one for each partner. The chosen one lifts up
/// and glows in its parol color.
class PartnerTokens extends StatelessWidget {
  const PartnerTokens({
    super.key,
    required this.selected,
    required this.onSelect,
    this.nameOf,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  /// The name shown under each token. Defaults to the partner's own name.
  final String Function(String id)? nameOf;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final p in partners)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Semantics(
              button: true,
              selected: p.id == selected,
              label: nameOf?.call(p.id) ?? p.name,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(p.id);
                },
                child: AnimatedSlide(
                  offset: Offset(0, p.id == selected ? -0.08 : 0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.id == selected
                              ? AppColors.cream
                              : AppColors.track,
                          boxShadow: [
                            if (p.id == selected)
                              BoxShadow(color: p.glow, spreadRadius: 3),
                            const BoxShadow(
                              color: Color(0x59000000),
                              offset: Offset(2, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Transform.translate(
                          offset: const Offset(0, 10),
                          child: Transform.scale(
                            scale: 1.25,
                            child: PartnerArt(
                              partnerId: p.id,
                              size: 72,
                              animate: false,
                              shadow: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nameOf?.call(p.id) ?? p.name,
                        style: display(
                          14,
                          color: p.id == selected
                              ? AppColors.text
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
