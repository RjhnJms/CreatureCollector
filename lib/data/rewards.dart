import 'package:flutter/painting.dart';

/// Where an outfit item goes on Tarsi. One item per slot.
enum OutfitSlot { head, face, neck, body }

extension OutfitSlotLabel on OutfitSlot {
  String get label => switch (this) {
    OutfitSlot.head => 'Hats',
    OutfitSlot.face => 'Glasses',
    OutfitSlot.neck => 'Neck',
    OutfitSlot.body => 'Clothes',
  };
}

enum RewardKind { outfit, parol }

/// Something kids can own: an outfit for Tarsi or a parol design.
/// Bought with gems if [price] is set; a moon gift if [giftStreak] is set.
class Reward {
  const Reward({
    required this.id,
    required this.name,
    required this.kind,
    required this.blurb,
    this.price,
    this.slot,
    this.giftStreak,
  });

  final String id;
  final String name;
  final RewardKind kind;
  final String blurb;
  final int? price;
  final OutfitSlot? slot;

  /// Nights in a row needed to earn this as a moon gift.
  final int? giftStreak;

  bool get isGift => giftStreak != null;
  bool get isFree => price == 0;
}

/// How a parol design looks.
class ParolStyle {
  const ParolStyle({
    required this.colors,
    this.center = const Color(0xFFF6EAD0),
    this.tail = const Color(0xFFF6EAD0),
    this.rainbow = false,
    this.capiz = false,
  });

  /// Body colors. Several parols on a string take turns using them.
  final List<Color> colors;
  final Color center;
  final Color tail;

  /// Each star point gets its own color.
  final bool rainbow;

  /// Pearly capiz-shell panels with fine lines.
  final bool capiz;

  Color colorAt(int i) => colors[i % colors.length];
}

const defaultParol = 'classic';

const rewards = <Reward>[
  // Outfits
  Reward(
    id: 'salakot',
    name: 'Salakot',
    kind: RewardKind.outfit,
    slot: OutfitSlot.head,
    price: 40,
    blurb: 'A woven farmer’s hat for sunny days and starry nights.',
  ),
  Reward(
    id: 'flower_crown',
    name: 'Flower crown',
    kind: RewardKind.outfit,
    slot: OutfitSlot.head,
    price: 60,
    blurb: 'Sampaguita, gumamela, and a little leaf.',
  ),
  Reward(
    id: 'glasses',
    name: 'Round glasses',
    kind: RewardKind.outfit,
    slot: OutfitSlot.face,
    price: 25,
    blurb: 'For reading every fact in the Dex.',
  ),
  Reward(
    id: 'scarf',
    name: 'Ranger scarf',
    kind: RewardKind.outfit,
    slot: OutfitSlot.neck,
    price: 30,
    blurb: 'Every Night Ranger needs one.',
  ),
  Reward(
    id: 'bowtie',
    name: 'Bow tie',
    kind: RewardKind.outfit,
    slot: OutfitSlot.neck,
    price: 20,
    blurb: 'Fancy enough for a fiesta.',
  ),
  Reward(
    id: 'barong',
    name: 'Tiny barong',
    kind: RewardKind.outfit,
    slot: OutfitSlot.body,
    price: 80,
    blurb: 'A see-through barong with embroidery.',
  ),

  // Parol designs
  Reward(
    id: 'classic',
    name: 'Classic parols',
    kind: RewardKind.parol,
    price: 0,
    blurb: 'Red, gold, and orange, like every Paskong Pinoy.',
  ),
  Reward(
    id: 'sampaguita',
    name: 'Sampaguita',
    kind: RewardKind.parol,
    price: 50,
    blurb: 'White and green, like the national flower.',
  ),
  Reward(
    id: 'capiz',
    name: 'Capiz shell',
    kind: RewardKind.parol,
    price: 60,
    blurb: 'Pearly shell panels that shimmer.',
  ),
  Reward(
    id: 'ocean',
    name: 'Ocean blues',
    kind: RewardKind.parol,
    price: 70,
    blurb: 'For rangers who love the sea.',
  ),
  Reward(
    id: 'rainbow',
    name: 'Rainbow star',
    kind: RewardKind.parol,
    price: 90,
    blurb: 'Every point a different color.',
  ),
  Reward(
    id: 'golden',
    name: 'Golden parols',
    kind: RewardKind.parol,
    price: 120,
    blurb: 'The brightest parols in the forest.',
  ),

  // Moon gifts (earned with streaks, never sold)
  Reward(
    id: 'bituin',
    name: 'Bituin parols',
    kind: RewardKind.parol,
    giftStreak: 3,
    blurb: 'Silver-blue star lanterns for a 3-night streak.',
  ),
  Reward(
    id: 'moon_cape',
    name: 'Moon cape',
    kind: RewardKind.outfit,
    slot: OutfitSlot.body,
    giftStreak: 7,
    blurb: 'A starry cape for a 7-night streak.',
  ),
  Reward(
    id: 'star_glasses',
    name: 'Star glasses',
    kind: RewardKind.outfit,
    slot: OutfitSlot.face,
    giftStreak: 14,
    blurb: 'Twinkly glasses for a 14-night streak.',
  ),
  Reward(
    id: 'golden_salakot',
    name: 'Golden salakot',
    kind: RewardKind.outfit,
    slot: OutfitSlot.head,
    giftStreak: 28,
    blurb: 'For a full moon cycle: 28 nights in a row!',
  ),
];

final rewardById = {for (final r in rewards) r.id: r};

const parolStyles = <String, ParolStyle>{
  'classic': ParolStyle(
    colors: [Color(0xFFE5574A), Color(0xFFF2B23C), Color(0xFFF08A3C)],
  ),
  'sampaguita': ParolStyle(
    colors: [Color(0xFFFFFFFF), Color(0xFFE6F3DD), Color(0xFFFFFDF4)],
    center: Color(0xFF8BC48A),
    tail: Color(0xFFB9E08F),
  ),
  'capiz': ParolStyle(
    colors: [Color(0xFFF3EEE4), Color(0xFFEFE4D2), Color(0xFFF6E9DD)],
    center: Color(0xFFFFE3B8),
    capiz: true,
  ),
  'ocean': ParolStyle(
    colors: [Color(0xFF4FA3D9), Color(0xFF6CC4C9), Color(0xFF2F7FB0)],
    center: Color(0xFFE6F6FF),
    tail: Color(0xFFBDE6F5),
  ),
  'rainbow': ParolStyle(
    colors: [
      Color(0xFFE5574A),
      Color(0xFFF2B23C),
      Color(0xFF5BB174),
      Color(0xFF4FA3D9),
      Color(0xFFB07CD8),
    ],
    rainbow: true,
  ),
  'golden': ParolStyle(
    colors: [Color(0xFFF2C14E), Color(0xFFF7D774), Color(0xFFE8A93A)],
    center: Color(0xFFFFF4C2),
    tail: Color(0xFFF7D774),
  ),
  'bituin': ParolStyle(
    colors: [Color(0xFF9FB8E8), Color(0xFFC9D6F2), Color(0xFF7F9BD6)],
    center: Color(0xFFFFFFFF),
    tail: Color(0xFFDCE6FA),
  ),
};

ParolStyle parolStyleOf(String id) =>
    parolStyles[id] ?? parolStyles[defaultParol]!;
