import 'package:flutter/material.dart';

import '../data/partners.dart';
import '../state/game_state.dart';
import 'creature_art.dart';

/// The kid's chosen partner, wearing its outfit. Before progress has
/// loaded (or with no game around), it's Tarsi with no outfit.
class PartnerArt extends StatelessWidget {
  const PartnerArt({
    super.key,
    this.size = 120,
    this.animate = true,
    this.shadow = true,
    this.gaze = Offset.zero,
    this.blinkNow = false,
    this.outfit,
    this.partnerId,
    this.limb = 0,
  });

  /// Flipper or wing swing, see [CreatureArt.limb].
  final double limb;

  final double size;
  final bool animate;
  final bool shadow;
  final Offset gaze;
  final bool blinkNow;

  /// Outfit to show instead of what the partner is wearing, for trying on.
  final List<String>? outfit;

  /// Shows this partner instead of the kid's own, for the picker.
  final String? partnerId;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.maybeOf(context);
    final partner = partnerOf(partnerId ?? game?.partnerId ?? defaultPartner);
    return CreatureArt(
      partner.art,
      size: size,
      animate: animate,
      shadow: shadow,
      gaze: gaze,
      blinkNow: blinkNow,
      limb: limb,
      outfit: outfit ?? game?.outfitItems ?? const [],
    );
  }
}
