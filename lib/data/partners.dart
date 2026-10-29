import 'dart:ui';

import 'content.dart';
import 'models.dart';

/// Where a partner lives on the home screen and the picker.
class PartnerHome {
  const PartnerHome(
    this.habitatId, {
    this.time = ActiveTime.night,
    this.skyLine,
    this.rest = 0.86,
  });

  final String habitatId;

  /// Time of day on the picker. The home screen follows the clock.
  final ActiveTime time;

  /// Where the water starts, for an ocean home with sky above it.
  final double? skyLine;

  /// Where its feet rest, as a fraction of the scene's height.
  final double rest;
}

/// A partner a kid can choose to explore with. All partners are looks-only:
/// none of them changes how the game plays, so there's no wrong pick.
class Partner {
  const Partner({
    required this.id,
    required this.name,
    required this.place,
    required this.species,
    required this.glow,
    required this.lines,
    required this.art,
    required this.home,
  });

  final String id;

  /// The name it starts with. Kids can rename it.
  final String name;

  /// Where it's from: Forest, Sea, or Sky.
  final String place;

  /// The real animal, like "Philippine tarsier".
  final String species;

  /// The partner's parol color on the picker.
  final Color glow;

  /// Real facts it says when tapped. The first is used on the picker.
  final List<String> lines;

  /// The drawing used for it. Partners are drawn facing forward on the same
  /// layout as Tarsi, so every outfit fits them all.
  final Creature art;

  final PartnerHome home;
}

const defaultPartner = 'tarsi';

final List<Partner> partners = [
  Partner(
    id: 'tarsi',
    name: 'Tarsi',
    place: 'Forest',
    species: 'Philippine tarsier',
    glow: const Color(0xFFF08A3C),
    lines: const [
      'Each of my eyes is as big as my brain!',
      'I can turn my head almost all the way around!',
      'I sleep all day and hunt bugs at night.',
      'I can leap from tree to tree in one big jump!',
      "Let's find more creatures tonight!",
    ],
    art: creatureById['tarsier']!,
    home: const PartnerHome('rainforest'),
  ),
  const Partner(
    id: 'pawi',
    name: 'Pawi',
    place: 'Sea',
    species: 'Green sea turtle (pawikan)',
    glow: Color(0xFF5EC4D9),
    lines: [
      'I can nap underwater for hours!',
      'I munch seagrass like a little lawnmower!',
      'Turtles like me swim back to the beach where we hatched.',
      'My shell is part of my skeleton!',
      "Let's find more creatures tonight!",
    ],
    art: Creature(
      id: 'partner_pawi',
      name: 'Pawi',
      localName: 'Pawikan',
      habitatId: 'ocean',
      time: ActiveTime.dayAndNight,
      rarity: Rarity.rare,
      kind: 'Reptile',
      fact: '',
      color: Color(0xFF7CC48F),
    ),
    home: PartnerHome('ocean', skyLine: 0.45, rest: 0.94),
  ),
  const Partner(
    id: 'haribon',
    name: 'Haribon',
    place: 'Sky',
    species: 'Philippine eagle',
    glow: Color(0xFFF2B23C),
    lines: [
      "I'm the national bird of the Philippines!",
      'My name means "king of birds."',
      'My wings are as wide as a door is tall!',
      'My crest puffs up like a lion’s mane.',
      "Let's find more creatures tonight!",
    ],
    art: Creature(
      id: 'partner_haribon',
      name: 'Haribon',
      localName: 'Haribon',
      habitatId: 'rainforest',
      time: ActiveTime.day,
      rarity: Rarity.legendary,
      kind: 'Bird',
      fact: '',
      color: Color(0xFF8A6440),
    ),
    home: PartnerHome('rainforest', time: ActiveTime.dawn),
  ),
];

final Map<String, Partner> partnerById = {for (final p in partners) p.id: p};

Partner partnerOf(String id) => partnerById[id] ?? partners.first;
