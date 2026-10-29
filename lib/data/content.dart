import 'package:flutter/widgets.dart';

import 'models.dart';

// ---------------------------------------------------------------------------
// Creatures
// ---------------------------------------------------------------------------

const creatures = <Creature>[
  // Rainforest
  Creature(
    id: 'tarsier',
    name: 'Philippine tarsier',
    localName: 'Mamag',
    habitatId: 'rainforest',
    time: ActiveTime.night,
    rarity: Rarity.rare,
    kind: 'Mammal',
    fact:
        'Each of its eyes is about as big as its whole brain. Its eyes '
        "can't move, so it turns its head almost all the way around instead.",
    color: Color(0xFFC99160),
  ),
  Creature(
    id: 'firefly',
    name: 'Firefly',
    localName: 'Alitaptap',
    habitatId: 'rainforest',
    time: ActiveTime.night,
    rarity: Rarity.common,
    kind: 'Insect',
    fact:
        'Fireflies make their own light. They flash patterns in the dark '
        'to find each other.',
    color: Color(0xFFF2D16B),
    silentReason: 'Fireflies talk with flashes of light, not sounds!',
  ),
  Creature(
    id: 'eagle',
    name: 'Philippine eagle',
    localName: 'Haribon',
    habitatId: 'rainforest',
    time: ActiveTime.day,
    rarity: Rarity.legendary,
    kind: 'Bird',
    fact:
        "It's the national bird of the Philippines and one of the biggest "
        'eagles in the world. A pair raises only one chick every two years.',
    color: Color(0xFF8A5A3A),
    sound: CreatureSound(
      file: 'philippine_eagle.mp3',
      credit:
          'Recorded by Tomas Carlberg, Eagle Centre, Mindanao · '
          'xeno-canto XC175278 · CC BY-NC-SA 4.0',
    ),
  ),
  Creature(
    id: 'rafflesia',
    name: 'Rafflesia',
    localName: '',
    habitatId: 'rainforest',
    time: ActiveTime.dayAndNight,
    rarity: Rarity.rare,
    kind: 'Plant',
    fact:
        'It has no leaves, stems, or roots of its own. It lives inside a '
        'vine and smells like rotting meat to attract flies.',
    color: Color(0xFFC8452F),
    silentReason: 'It\'s a flower, so it has no voice. It calls flies with its smell instead.',
  ),
  Creature(
    id: 'colugo',
    name: 'Philippine flying lemur',
    localName: 'Kagwang',
    habitatId: 'rainforest',
    time: ActiveTime.night,
    rarity: Rarity.rare,
    kind: 'Mammal',
    fact:
        "It isn't a lemur and it can't really fly. It glides between trees "
        'on a furry cape of skin, more than 100 meters in one jump.',
    color: Color(0xFF8C8270),
  ),
  Creature(
    id: 'civet',
    name: 'Asian palm civet',
    localName: 'Musang',
    habitatId: 'rainforest',
    time: ActiveTime.night,
    rarity: Rarity.common,
    kind: 'Mammal',
    fact:
        'It eats fruits, insects, and small animals. It sleeps in trees '
        'during the day and looks for food at night.',
    color: Color(0xFF6E6152),
  ),

  // Ocean
  Creature(
    id: 'whaleshark',
    name: 'Whale shark',
    localName: 'Butanding',
    habitatId: 'ocean',
    time: ActiveTime.dayAndNight,
    rarity: Rarity.legendary,
    kind: 'Fish',
    fact:
        "It's the biggest fish in the world, but it eats tiny plankton by "
        'filtering water through its huge mouth.',
    color: Color(0xFF5B7A99),
    silentReason:
        'A quiet giant: scientists have never heard a whale shark make a call.',
  ),
  Creature(
    id: 'dugong',
    name: 'Dugong',
    localName: 'Duyong',
    habitatId: 'ocean',
    time: ActiveTime.dayAndNight,
    rarity: Rarity.rare,
    kind: 'Mammal',
    fact:
        "Also called a sea cow, it grazes on seagrass. It's a mammal, so "
        'it swims up to the surface to breathe air.',
    color: Color(0xFF9A8F86),
  ),
  Creature(
    id: 'clownfish',
    name: 'Clownfish',
    localName: '',
    habitatId: 'ocean',
    time: ActiveTime.day,
    rarity: Rarity.common,
    kind: 'Fish',
    fact:
        'It lives among the stinging arms of a sea anemone. A slimy coat '
        'on its skin keeps it from getting stung.',
    color: Color(0xFFF07A2A),
  ),
  Creature(
    id: 'clam',
    name: 'Giant clam',
    localName: 'Taklobo',
    habitatId: 'ocean',
    time: ActiveTime.day,
    rarity: Rarity.rare,
    kind: 'Mollusk',
    fact:
        'The biggest clam in the world can weigh more than 200 kilograms. '
        'Tiny algae living inside it give it bright colors.',
    color: Color(0xFF4FA3A0),
    silentReason: 'Giant clams have no voice. They just open and close their shells slowly.',
  ),
  Creature(
    id: 'turtle',
    name: 'Green sea turtle',
    localName: 'Pawikan',
    habitatId: 'ocean',
    time: ActiveTime.dayAndNight,
    rarity: Rarity.rare,
    kind: 'Reptile',
    fact:
        'Adults eat seagrass and algae. Mother turtles crawl onto the beach '
        'at night to lay their eggs in the sand.',
    color: Color(0xFF5E8B4E),
  ),
  Creature(
    id: 'seastar',
    name: 'Sea star',
    localName: 'Isdang-bituin',
    habitatId: 'ocean',
    time: ActiveTime.night,
    rarity: Rarity.common,
    kind: 'Sea animal',
    fact: "It isn't a fish at all. If it loses an arm, it can grow a new one.",
    color: Color(0xFFE5703F),
    silentReason: 'Sea stars have no voice. They feel their way with hundreds of tiny tube feet.',
  ),
  // Rice terraces
  Creature(
    id: 'rice',
    name: 'Rice plant',
    localName: 'Palay',
    habitatId: 'terraces',
    time: ActiveTime.dayAndNight,
    rarity: Rarity.common,
    kind: 'Plant',
    fact:
        'Rice is a kind of grass that grows in flooded fields. The grains '
        'we eat are its seeds.',
    color: Color(0xFF7DBA5A),
    silentReason: 'Plants don\'t make sounds, but you can hear the wind rustle its leaves.',
  ),
  Creature(
    id: 'carabao',
    name: 'Carabao',
    localName: 'Kalabaw',
    habitatId: 'terraces',
    time: ActiveTime.day,
    rarity: Rarity.common,
    kind: 'Mammal',
    fact:
        'Carabaos roll in mud to cool off and keep bugs away. They help '
        'farmers plow their rice fields.',
    color: Color(0xFF6F6A70),
  ),
  Creature(
    id: 'birdwing',
    name: 'Magellan birdwing',
    localName: 'Paru-paro',
    habitatId: 'terraces',
    time: ActiveTime.day,
    rarity: Rarity.rare,
    kind: 'Insect',
    fact:
        'One of the biggest butterflies in the Philippines. Its golden '
        'back wings shimmer blue-green when light hits them.',
    color: Color(0xFFF2C14E),
    silentReason: 'Butterflies are silent. They talk with bright colors and smells instead.',
  ),
  Creature(
    id: 'bleedingheart',
    name: 'Luzon bleeding-heart',
    localName: '',
    habitatId: 'terraces',
    time: ActiveTime.day,
    rarity: Rarity.rare,
    kind: 'Bird',
    fact:
        'The red patch on its white chest looks like a wound, but it is '
        'just colorful feathers.',
    color: Color(0xFF6E7FA3),
    sound: CreatureSound(
      file: 'luzon_bleeding_heart.mp3',
      credit:
          'Recorded by David Edwards, Sierra Madre, Luzon · '
          'xeno-canto XC35236 · CC BY-NC-ND 2.5',
      maxSeconds: 12,
    ),
  ),
  Creature(
    id: 'sailfin',
    name: 'Philippine sailfin lizard',
    localName: '',
    habitatId: 'terraces',
    time: ActiveTime.day,
    rarity: Rarity.rare,
    kind: 'Reptile',
    fact:
        'It has a tall sail on its tail and swims well. Young ones can '
        'even run across the water!',
    color: Color(0xFF6E8B4E),
  ),
  Creature(
    id: 'cloudrat',
    name: 'Luzon cloud rat',
    localName: '',
    habitatId: 'terraces',
    time: ActiveTime.night,
    rarity: Rarity.legendary,
    kind: 'Mammal',
    fact:
        'One of the biggest rats in the world, with long fluffy fur. It '
        'lives only in the mountain forests of Luzon.',
    color: Color(0xFFD9D2C4),
  ),
  // Mangrove
  Creature(
    id: 'mudskipper',
    name: 'Mudskipper',
    localName: 'Talimusak',
    habitatId: 'mangrove',
    time: ActiveTime.day,
    rarity: Rarity.common,
    kind: 'Fish',
    fact:
        'A fish that walks on mud with its fins and breathes air through '
        'its wet skin. Its eyes sit on top of its head like a periscope.',
    color: Color(0xFF9A8A62),
  ),
  Creature(
    id: 'fiddlercrab',
    name: 'Fiddler crab',
    localName: '',
    habitatId: 'mangrove',
    time: ActiveTime.day,
    rarity: Rarity.common,
    kind: 'Crustacean',
    fact:
        'Boy fiddler crabs have one giant claw. They wave it to say '
        '"this is my spot!"',
    color: Color(0xFFE5704F),
  ),
  Creature(
    id: 'mangrovetree',
    name: 'Mangrove tree',
    localName: 'Bakawan',
    habitatId: 'mangrove',
    time: ActiveTime.dayAndNight,
    rarity: Rarity.common,
    kind: 'Plant',
    fact:
        'Its stilt roots hold the shore together against big waves, and '
        'baby fish hide between them.',
    color: Color(0xFF3F9A63),
    silentReason: 'Trees are quiet, but listen for the crabs and birds living in its roots!',
  ),
  Creature(
    id: 'kingfisher',
    name: 'Collared kingfisher',
    localName: 'Salaksak',
    habitatId: 'mangrove',
    time: ActiveTime.day,
    rarity: Rarity.rare,
    kind: 'Bird',
    fact:
        'It sits very still on a branch, then swoops down to catch crabs '
        'and fish. Look for its bright blue wings and white collar.',
    color: Color(0xFF2FA8C8),
    sound: CreatureSound(
      file: 'collared_kingfisher.mp3',
      credit:
          'Recorded by Albert Lastukhin, Puerto Galera, Mindoro · '
          'xeno-canto XC349240 · CC BY-NC-SA 4.0',
    ),
  ),
  Creature(
    id: 'monitor',
    name: 'Water monitor',
    localName: 'Bayawak',
    habitatId: 'mangrove',
    time: ActiveTime.day,
    rarity: Rarity.rare,
    kind: 'Reptile',
    fact:
        'A big lizard that swims with its strong tail and smells with '
        'its forked tongue.',
    color: Color(0xFF4E5A4A),
  ),
  Creature(
    id: 'catsnake',
    name: 'Mangrove cat snake',
    localName: '',
    habitatId: 'mangrove',
    time: ActiveTime.night,
    rarity: Rarity.legendary,
    kind: 'Reptile',
    fact:
        'A shiny black snake with yellow bands that hunts at night. '
        'Admire it from far away: never touch a wild snake.',
    color: Color(0xFF2A2A30),
  ),
  // Cave
  Creature(
    id: 'fruitbat',
    name: "Geoffroy's fruit bat",
    localName: 'Paniki',
    habitatId: 'cave',
    time: ActiveTime.night,
    rarity: Rarity.common,
    kind: 'Mammal',
    fact:
        'It finds its way in dark caves by making clicking sounds with its '
        'tongue and listening for the echoes.',
    color: Color(0xFF8A6A4E),
  ),
  Creature(
    id: 'swiftlet',
    name: 'Edible-nest swiftlet',
    localName: 'Balinsasayaw',
    habitatId: 'cave',
    time: ActiveTime.day,
    rarity: Rarity.rare,
    kind: 'Bird',
    fact:
        'It builds its cup-shaped nest out of its own spit, glued high on '
        'a cave wall.',
    color: Color(0xFF5E5A66),
    sound: CreatureSound(
      file: 'edible_nest_swiftlet.mp3',
      credit:
          'Recorded by Peter Boesman, Sepilok, Borneo · '
          'xeno-canto XC359519 · CC BY-NC-ND 4.0',
    ),
  ),
  Creature(
    id: 'cavecricket',
    name: 'Cave cricket',
    localName: '',
    habitatId: 'cave',
    time: ActiveTime.night,
    rarity: Rarity.common,
    kind: 'Insect',
    fact:
        'It has no wings, but its super-long feelers help it find its way '
        'in the dark.',
    color: Color(0xFFC9A87A),
    silentReason: 'Garden crickets chirp with their wings. Cave crickets have no wings, so they stay quiet.',
  ),
  Creature(
    id: 'whipspider',
    name: 'Whip spider',
    localName: '',
    habitatId: 'cave',
    time: ActiveTime.night,
    rarity: Rarity.rare,
    kind: 'Arachnid',
    fact:
        'It looks spooky but has no venom. Its long, thin front legs work '
        'like feelers in the dark.',
    color: Color(0xFF7A5E70),
    silentReason: 'Whip spiders are silent hunters. They feel and smell with their long front legs.',
  ),
  Creature(
    id: 'cavecrab',
    name: 'Cave crab',
    localName: '',
    habitatId: 'cave',
    time: ActiveTime.night,
    rarity: Rarity.rare,
    kind: 'Crustacean',
    fact:
        'It lives by underground rivers. With no sunlight in the cave, it '
        'is pale instead of colorful.',
    color: Color(0xFFD9B8C8),
    silentReason: 'Cave crabs are quiet. In the dark, they feel their way with their legs.',
  ),
  Creature(
    id: 'stalactite',
    name: 'Stalactite',
    localName: '',
    habitatId: 'cave',
    time: ActiveTime.dayAndNight,
    rarity: Rarity.legendary,
    kind: 'Rock',
    fact:
        'Not a living thing! Dripping water leaves tiny bits of rock '
        'behind, and over hundreds of years they build a rock "icicle."',
    color: Color(0xFFD6CDBE),
    silentReason:
        'It\'s rock, so it makes no sound, except the drip, drip of water!',
    alive: false,
  ),
];

final creatureById = {for (final c in creatures) c.id: c};

// ---------------------------------------------------------------------------
// Habitats and stages
// ---------------------------------------------------------------------------

const habitats = <Habitat>[
  Habitat(
    id: 'rainforest',
    name: 'Rainforest',
    blurb: 'Tall trees, glowing insects, and big-eyed hunters.',
    color: Color(0xFF27704A),
    stageIds: ['r1', 'r2', 'r3', 'r4'],
  ),
  Habitat(
    id: 'ocean',
    name: 'Ocean',
    blurb: 'Gentle giants, coral reefs, and sandy shores.',
    color: Color(0xFF2F5FA3),
    stageIds: ['o1', 'o2', 'o3', 'o4'],
  ),
  Habitat(
    id: 'terraces',
    name: 'Rice Terraces',
    blurb: 'Mountain rice fields, bright butterflies, and sunny riverbanks.',
    color: Color(0xFF6CAB4A),
    stageIds: ['t1', 't2', 't3', 't4'],
    time: ActiveTime.day,
  ),
  Habitat(
    id: 'mangrove',
    name: 'Mangrove',
    blurb: 'Where the forest meets the sea: roots, mud, and fireflies.',
    color: Color(0xFF3E9BA8),
    stageIds: ['m1', 'm2', 'm3', 'm4'],
    time: ActiveTime.day,
  ),
  Habitat(
    id: 'cave',
    name: 'Cave',
    blurb: 'Bats, swiftlets, glowworms, and a secret river.',
    color: Color(0xFF5A4E6E),
    stageIds: ['c1', 'c2', 'c3', 'c4'],
  ),
];

final habitatById = {for (final h in habitats) h.id: h};

const stages = <Stage>[
  Stage(
    id: 'r1',
    habitatId: 'rainforest',
    number: 1,
    title: 'Forest giants',
    topic: 'Birds, plants, and what they eat',
    creatureIds: ['eagle', 'rafflesia'],
  ),
  Stage(
    id: 'r2',
    habitatId: 'rainforest',
    number: 2,
    title: 'Lights in the dark',
    topic: 'Nocturnal animals and insects',
    creatureIds: ['tarsier', 'firefly'],
  ),
  Stage(
    id: 'r3',
    habitatId: 'rainforest',
    number: 3,
    title: 'Tree travelers',
    topic: 'How animals move and eat',
    creatureIds: ['colugo', 'civet'],
  ),
  Stage(
    id: 'r4',
    habitatId: 'rainforest',
    number: 4,
    title: 'Rainforest review',
    topic: 'Everything from the rainforest',
    creatureIds: [],
    isBoss: true,
  ),
  Stage(
    id: 'o1',
    habitatId: 'ocean',
    number: 1,
    title: 'Gentle giants',
    topic: 'Big sea animals and what they eat',
    creatureIds: ['whaleshark', 'dugong'],
  ),
  Stage(
    id: 'o2',
    habitatId: 'ocean',
    number: 2,
    title: 'Reef friends',
    topic: 'Living together on the coral reef',
    creatureIds: ['clownfish', 'clam'],
  ),
  Stage(
    id: 'o3',
    habitatId: 'ocean',
    number: 3,
    title: 'Shore and sand',
    topic: 'Reptiles, eggs, and regrowing arms',
    creatureIds: ['turtle', 'seastar'],
  ),
  Stage(
    id: 'o4',
    habitatId: 'ocean',
    number: 4,
    title: 'Ocean review',
    topic: 'Everything from the ocean',
    creatureIds: [],
    isBoss: true,
  ),
  Stage(
    id: 't1',
    habitatId: 'terraces',
    number: 1,
    title: 'Fields of gold',
    topic: 'Plants, farms, and the food we eat',
    creatureIds: ['rice', 'carabao'],
  ),
  Stage(
    id: 't2',
    habitatId: 'terraces',
    number: 2,
    title: 'Wings in the sun',
    topic: 'Birds, insects, and life cycles',
    creatureIds: ['birdwing', 'bleedingheart'],
  ),
  Stage(
    id: 't3',
    habitatId: 'terraces',
    number: 3,
    title: 'River and treetop',
    topic: 'Reptiles, rodents, and day versus night',
    creatureIds: ['sailfin', 'cloudrat'],
  ),
  Stage(
    id: 't4',
    habitatId: 'terraces',
    number: 4,
    title: 'Terraces review',
    topic: 'Everything from the rice terraces',
    creatureIds: [],
    isBoss: true,
  ),
  Stage(
    id: 'm1',
    habitatId: 'mangrove',
    number: 1,
    title: 'Muddy shores',
    topic: 'Animals of the mud and the tides',
    creatureIds: ['mudskipper', 'fiddlercrab'],
  ),
  Stage(
    id: 'm2',
    habitatId: 'mangrove',
    number: 2,
    title: 'Roots and wings',
    topic: 'Plants and birds that protect the coast',
    creatureIds: ['mangrovetree', 'kingfisher'],
  ),
  Stage(
    id: 'm3',
    habitatId: 'mangrove',
    number: 3,
    title: 'Hiders in the roots',
    topic: 'Reptiles and staying safe around them',
    creatureIds: ['monitor', 'catsnake'],
  ),
  Stage(
    id: 'm4',
    habitatId: 'mangrove',
    number: 4,
    title: 'Mangrove review',
    topic: 'Everything from the mangrove',
    creatureIds: [],
    isBoss: true,
  ),
  Stage(
    id: 'c1',
    habitatId: 'cave',
    number: 1,
    title: 'Wings in the dark',
    topic: 'Bats, birds, and finding the way in the dark',
    creatureIds: ['fruitbat', 'swiftlet'],
  ),
  Stage(
    id: 'c2',
    habitatId: 'cave',
    number: 2,
    title: 'Cave crawlers',
    topic: 'Insects, spiders, and how they are different',
    creatureIds: ['cavecricket', 'whipspider'],
  ),
  Stage(
    id: 'c3',
    habitatId: 'cave',
    number: 3,
    title: 'The secret river',
    topic: 'Living and non-living things underground',
    creatureIds: ['cavecrab', 'stalactite'],
  ),
  Stage(
    id: 'c4',
    habitatId: 'cave',
    number: 4,
    title: 'Cave review',
    topic: 'Everything from the cave',
    creatureIds: [],
    isBoss: true,
  ),
];

final stageById = {for (final s in stages) s.id: s};

// ---------------------------------------------------------------------------
// Questions (10 per creature; each play asks a few of them)
// ---------------------------------------------------------------------------

const _tf = ['True', 'False'];

const questions = <Question>[
  // Tarsier
  ChoiceQuestion(
    creatureId: 'tarsier',
    prompt: 'What does a tarsier eat?',
    options: ['Insects', 'Leaves', 'Rice'],
    answer: 0,
    explain:
        'Tarsiers hunt insects like crickets and grasshoppers. They are '
        'the only primates that eat only animals.',
  ),
  ChoiceQuestion(
    creatureId: 'tarsier',
    prompt: 'Tarsiers are awake during the day.',
    options: _tf,
    answer: 1,
    explain:
        'Tarsiers are nocturnal. They sleep during the day and hunt at '
        'night.',
  ),
  ChoiceQuestion(
    creatureId: 'tarsier',
    prompt: 'Why does a tarsier turn its head so far around?',
    options: ["Its eyes can't move", "It's dizzy", "It's dancing"],
    answer: 0,
    explain:
        'Its eyes are so big they are stuck in place, so it turns its '
        'whole head to look around.',
  ),
  PictureQuestion(
    creatureId: 'tarsier',
    prompt: 'Which one is the tarsier?',
    optionIds: ['civet', 'tarsier', 'colugo'],
    answerId: 'tarsier',
    explain: 'The tarsier is the small one with giant round eyes.',
  ),

  // Firefly
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: 'What do fireflies use their light for?',
    options: ['To find each other', 'To cook food', 'To keep warm'],
    answer: 0,
    explain:
        'Fireflies flash light patterns to find and talk to other '
        'fireflies.',
  ),
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: 'Fireflies are a kind of insect.',
    options: _tf,
    answer: 0,
    explain:
        'Fireflies are beetles, and beetles are insects. They have six '
        'legs.',
  ),
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: 'What is it called when a living thing makes its own light?',
    options: ['Bioluminescence', 'Photosynthesis', 'Evaporation'],
    answer: 0,
    explain:
        '"Bio" means life and "luminescence" means light. Fireflies are '
        'bioluminescent.',
  ),
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: 'How many legs does an insect have?',
    options: ['6', '4', '8'],
    answer: 0,
    explain:
        'All insects have six legs. Spiders have eight, so spiders are '
        'not insects.',
  ),

  // Philippine eagle
  ChoiceQuestion(
    creatureId: 'eagle',
    prompt: 'What is the national bird of the Philippines?',
    options: ['Philippine eagle', 'Maya bird', 'Chicken'],
    answer: 0,
    explain: 'The Philippine eagle became the national bird in 1995.',
  ),
  ChoiceQuestion(
    creatureId: 'eagle',
    prompt: 'What does the Philippine eagle mostly eat?',
    options: ['Monkeys and flying lemurs', 'Grass', 'Fruits'],
    answer: 0,
    explain:
        "It's a carnivore. It hunts animals like monkeys, flying lemurs, "
        'and snakes.',
  ),
  ChoiceQuestion(
    creatureId: 'eagle',
    prompt: 'The Philippine eagle is critically endangered.',
    options: _tf,
    answer: 0,
    explain:
        'Only a few hundred pairs are left in the wild, mostly because '
        'their forests are being cut down.',
  ),
  SortQuestion(
    creatureId: 'eagle',
    prompt: 'Sort the animals by what they eat.',
    bins: ['Plants', 'Animals'],
    items: {'Philippine eagle': 1, 'Dugong': 0, 'Tarsier': 1, 'Cow': 0},
    explain: 'Eagles and tarsiers eat animals. Dugongs and cows eat plants.',
  ),

  // Rafflesia
  ChoiceQuestion(
    creatureId: 'rafflesia',
    prompt: 'What does a rafflesia flower smell like?',
    options: ['Rotting meat', 'Roses', 'Chocolate'],
    answer: 0,
    explain:
        'The bad smell attracts flies, which carry its pollen to other '
        'flowers.',
  ),
  ChoiceQuestion(
    creatureId: 'rafflesia',
    prompt: 'Rafflesia has green leaves.',
    options: _tf,
    answer: 1,
    explain:
        'Rafflesia has no leaves, stems, or roots. It lives inside a vine '
        'and takes food from it.',
  ),
  ChoiceQuestion(
    creatureId: 'rafflesia',
    prompt:
        'A living thing that takes its food from another living thing is '
        'called a…',
    options: ['Parasite', 'Predator', 'Producer'],
    answer: 0,
    explain:
        'Rafflesia is a parasite. It gets its food from the vine it lives '
        'in.',
  ),
  SortQuestion(
    creatureId: 'rafflesia',
    prompt: 'Living or non-living?',
    bins: ['Living', 'Non-living'],
    items: {'Rafflesia': 0, 'Rock': 1, 'Firefly': 0, 'Water': 1},
    explain:
        'Living things grow, need food, and make more of their kind. '
        "Rocks and water don't.",
  ),

  // Flying lemur
  ChoiceQuestion(
    creatureId: 'colugo',
    prompt: 'The flying lemur can fly like a bird.',
    options: _tf,
    answer: 1,
    explain:
        'It glides. It spreads a furry skin like a kite and sails from '
        'tree to tree.',
  ),
  ChoiceQuestion(
    creatureId: 'colugo',
    prompt: 'What does the flying lemur eat?',
    options: ['Leaves and flowers', 'Fish', 'Insects only'],
    answer: 0,
    explain:
        'Flying lemurs are herbivores. They eat leaves, shoots, and '
        'flowers.',
  ),
  ChoiceQuestion(
    creatureId: 'colugo',
    prompt: 'How far can a flying lemur glide in one jump?',
    options: [
      'More than 100 meters',
      'About 1 meter',
      'All the way to the sea',
    ],
    answer: 0,
    explain: "That's about as long as a football field.",
  ),
  ChoiceQuestion(
    creatureId: 'colugo',
    prompt: 'When is the flying lemur awake?',
    options: ['At night', 'At noon', 'Only when it rains'],
    answer: 0,
    explain: "It's nocturnal. During the day it hangs quietly on tree trunks.",
  ),

  // Civet
  ChoiceQuestion(
    creatureId: 'civet',
    prompt:
        'A civet eats fruits, insects, and small animals. What kind of '
        'eater is it?',
    options: ['Omnivore', 'Herbivore', 'Carnivore'],
    answer: 0,
    explain: 'Omnivores eat both plants and animals.',
  ),
  ChoiceQuestion(
    creatureId: 'civet',
    prompt: 'Civets sleep in trees during the day.',
    options: _tf,
    answer: 0,
    explain:
        'Civets are nocturnal. They rest in trees by day and look for '
        'food at night.',
  ),
  SortQuestion(
    creatureId: 'civet',
    prompt: 'Sort these eaters.',
    bins: ['Herbivore', 'Carnivore', 'Omnivore'],
    items: {'Civet': 2, 'Flying lemur': 0, 'Tarsier': 1, 'People': 2},
    explain:
        'Herbivores eat plants, carnivores eat animals, and omnivores '
        'eat both.',
  ),
  PictureQuestion(
    creatureId: 'civet',
    prompt: 'Which one is the civet?',
    optionIds: ['tarsier', 'dugong', 'civet'],
    answerId: 'civet',
    explain: 'The civet has a long body, a pointy face, and a long tail.',
  ),

  // Whale shark
  ChoiceQuestion(
    creatureId: 'whaleshark',
    prompt: 'What is the biggest fish in the world?',
    options: ['Whale shark', 'Clownfish', 'Tuna'],
    answer: 0,
    explain: 'Whale sharks can grow as long as a bus.',
  ),
  ChoiceQuestion(
    creatureId: 'whaleshark',
    prompt: 'What does a whale shark eat?',
    options: ['Tiny plankton', 'Big whales', 'Seaweed only'],
    answer: 0,
    explain: 'It filters tiny plankton out of the water with its huge mouth.',
  ),
  ChoiceQuestion(
    creatureId: 'whaleshark',
    prompt: 'A whale shark is a kind of whale.',
    options: _tf,
    answer: 1,
    explain:
        "Despite its name, it's a shark, and sharks are fish. Whales are "
        'mammals.',
  ),
  ChoiceQuestion(
    creatureId: 'whaleshark',
    prompt: 'Where in the Philippines are whale sharks famous?',
    options: ['Donsol, Sorsogon', 'Baguio City', 'Vigan, Ilocos Sur'],
    answer: 0,
    explain: 'People visit Donsol to see butanding swimming near the shore.',
  ),

  // Dugong
  ChoiceQuestion(
    creatureId: 'dugong',
    prompt: 'What does a dugong eat?',
    options: ['Seagrass', 'Fish', 'Crabs'],
    answer: 0,
    explain:
        "Dugongs graze on seagrass, like cows eating grass. That's why "
        "they're called sea cows.",
  ),
  ChoiceQuestion(
    creatureId: 'dugong',
    prompt: 'Dugongs need to breathe air.',
    options: _tf,
    answer: 0,
    explain:
        'Dugongs are mammals. They swim to the surface to breathe through '
        'their nostrils.',
  ),
  SortQuestion(
    creatureId: 'dugong',
    prompt: 'Mammal or fish?',
    bins: ['Mammal', 'Fish'],
    items: {'Dugong': 0, 'Whale shark': 1, 'Clownfish': 1, 'Tarsier': 0},
    explain:
        'Mammals breathe air and feed their babies milk. Fish breathe '
        'underwater with gills.',
  ),
  ChoiceQuestion(
    creatureId: 'dugong',
    prompt: "What's another name for the dugong?",
    options: ['Sea cow', 'Sea horse', 'Sea dog'],
    answer: 0,
    explain: "It's called a sea cow because it grazes on seagrass meadows.",
  ),

  // Clownfish
  ChoiceQuestion(
    creatureId: 'clownfish',
    prompt: 'Where does a clownfish live?',
    options: ['In a sea anemone', 'In a tree', 'In a cave on land'],
    answer: 0,
    explain: 'It hides between the stinging arms of a sea anemone.',
  ),
  ChoiceQuestion(
    creatureId: 'clownfish',
    prompt: "Why doesn't the sea anemone sting the clownfish?",
    options: ['A slimy coat protects it', "It's too fast", "It's invisible"],
    answer: 0,
    explain: 'A layer of slime on its skin protects it from stings.',
  ),
  ChoiceQuestion(
    creatureId: 'clownfish',
    prompt: 'Clownfish breathe using gills.',
    options: _tf,
    answer: 0,
    explain: 'Fish take in oxygen from the water using gills.',
  ),
  PictureQuestion(
    creatureId: 'clownfish',
    prompt: 'Which one is the clownfish?',
    optionIds: ['whaleshark', 'seastar', 'clownfish'],
    answerId: 'clownfish',
    explain: 'The clownfish is small and orange with white stripes.',
  ),

  // Giant clam
  ChoiceQuestion(
    creatureId: 'clam',
    prompt: 'What is a taklobo?',
    options: ['A giant clam', 'A giant crab', 'A giant fish'],
    answer: 0,
    explain:
        'Taklobo is the Filipino name for the giant clam, the biggest '
        'clam in the world.',
  ),
  ChoiceQuestion(
    creatureId: 'clam',
    prompt: 'Grown-up giant clams walk across the sea floor.',
    options: _tf,
    answer: 1,
    explain:
        'Adult giant clams stay in one spot on the reef for their whole '
        'lives.',
  ),
  ChoiceQuestion(
    creatureId: 'clam',
    prompt: 'What gives giant clams their bright colors?',
    options: ['Tiny algae inside them', 'Colorful sand', 'The sunset'],
    answer: 0,
    explain:
        'Tiny algae live in the clam. They make food from sunlight and '
        'share it with the clam.',
  ),
  ChoiceQuestion(
    creatureId: 'clam',
    prompt: 'How does a giant clam get food?',
    options: [
      'From the water and its algae',
      'By hunting fish',
      'By eating '
          'leaves',
    ],
    answer: 0,
    explain:
        'It filters tiny bits of food from the water, and its algae make '
        'food from sunlight.',
  ),

  // Green sea turtle
  ChoiceQuestion(
    creatureId: 'turtle',
    prompt: 'What do grown-up green sea turtles eat?',
    options: ['Seagrass and algae', 'Fish', 'Crabs'],
    answer: 0,
    explain: 'Adult green sea turtles are herbivores.',
  ),
  ChoiceQuestion(
    creatureId: 'turtle',
    prompt: 'Where do sea turtles lay their eggs?',
    options: ['In sand on the beach', 'On the sea floor', 'In a tree'],
    answer: 0,
    explain: 'Mother turtles dig nests in beach sand, usually at night.',
  ),
  ChoiceQuestion(
    creatureId: 'turtle',
    prompt: 'Sea turtles are reptiles.',
    options: _tf,
    answer: 0,
    explain:
        'Like lizards and snakes, turtles are reptiles. They have scales '
        'and lay eggs.',
  ),
  ChoiceQuestion(
    creatureId: 'turtle',
    prompt: 'What is the Filipino name for the sea turtle?',
    options: ['Pawikan', 'Butanding', 'Taklobo'],
    answer: 0,
    explain:
        'Pawikan is the sea turtle. Butanding is the whale shark and '
        'taklobo is the giant clam.',
  ),

  // Sea star
  ChoiceQuestion(
    creatureId: 'seastar',
    prompt: 'A sea star is a fish.',
    options: _tf,
    answer: 1,
    explain: "Sea stars have no gills, fins, or backbone, so they aren't fish.",
  ),
  ChoiceQuestion(
    creatureId: 'seastar',
    prompt: 'What can a sea star do if it loses an arm?',
    options: ['Grow a new one', 'Nothing', 'Turn into a fish'],
    answer: 0,
    explain: 'Sea stars can regrow lost arms. This is called regeneration.',
  ),
  ChoiceQuestion(
    creatureId: 'seastar',
    prompt: 'How many arms do most sea stars have?',
    options: ['5', '3', '10'],
    answer: 0,
    explain: 'Most sea stars have five arms, but some kinds have many more.',
  ),
  PictureQuestion(
    creatureId: 'seastar',
    prompt: 'Which one is the sea star?',
    optionIds: ['clam', 'seastar', 'clownfish'],
    answerId: 'seastar',
    explain: 'The sea star is shaped like a star with five arms.',
  ),

  // ---- More questions: each stage picks a few at random, so replays vary.

  // Tarsier
  ChoiceQuestion(
    creatureId: 'tarsier',
    prompt: 'Where do Philippine tarsiers live?',
    options: ['Forests on islands like Bohol', 'Deserts', 'Snowy mountains'],
    answer: 0,
    explain:
        'They live in forests on Bohol, Samar, Leyte, and Mindanao, '
        'hiding in thick bushes and small trees.',
  ),
  ChoiceQuestion(
    creatureId: 'tarsier',
    prompt: 'A tarsier can jump many times its own body length.',
    options: _tf,
    answer: 0,
    explain:
        'Its long back legs work like springs, so it can leap from tree '
        'to tree to catch insects.',
  ),
  ChoiceQuestion(
    creatureId: 'tarsier',
    prompt: 'What helps a tarsier hold on to branches?',
    options: ['Padded fingertips', 'Wings', 'A shell'],
    answer: 0,
    explain:
        'Its long fingers end in round, soft pads that grip branches '
        'like little suction cups.',
  ),
  ChoiceQuestion(
    creatureId: 'tarsier',
    prompt: 'How big is a Philippine tarsier?',
    options: ['It fits in your hand', 'As big as a dog', 'As big as a car'],
    answer: 0,
    explain:
        'Its body is only about as long as a grown-up\'s hand, one of the '
        'smallest primates in the world.',
  ),
  ChoiceQuestion(
    creatureId: 'tarsier',
    prompt: 'Tarsiers make good pets.',
    options: _tf,
    answer: 1,
    explain:
        'Tarsiers get stressed easily and belong in the wild. In the '
        'Philippines, it is against the law to keep them as pets.',
  ),
  SortQuestion(
    creatureId: 'tarsier',
    prompt: 'Awake at night or by day?',
    bins: ['Night', 'Day'],
    items: {'Tarsier': 0, 'Firefly': 0, 'Philippine eagle': 1, 'Butterfly': 1},
    explain:
        'Tarsiers and fireflies come out at night. Eagles and butterflies '
        'are busy during the day.',
  ),

  // Firefly
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: 'Which part of a firefly glows?',
    options: ['The end of its belly', 'Its eyes', 'Its wings'],
    answer: 0,
    explain: 'The light comes from the last part of its belly, the abdomen.',
  ),
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: 'What can make fireflies disappear from a place?',
    options: ['Bright lights and pollution', 'Rainbows', 'Music'],
    answer: 0,
    explain:
        'Bright lights make it hard for fireflies to see each other\'s '
        'flashes, and dirty water harms their young.',
  ),
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: 'What is a baby firefly called?',
    options: ['A larva', 'A puppy', 'A tadpole'],
    answer: 0,
    explain:
        'Baby insects are called larvae. Many firefly larvae can glow '
        'too!',
  ),
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: 'What is "alitaptap"?',
    options: ['A firefly', 'A butterfly', 'A bee'],
    answer: 0,
    explain: 'Alitaptap is the Filipino word for firefly.',
  ),
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: "A firefly's light is hot like a light bulb.",
    options: _tf,
    answer: 1,
    explain:
        'Fireflies make "cold light." It gives off almost no heat at '
        'all.',
  ),
  ChoiceQuestion(
    creatureId: 'firefly',
    prompt: 'Fireflies like dark places near clean water and plants.',
    options: _tf,
    answer: 0,
    explain:
        'Many fireflies gather along rivers and mangroves, far from '
        'bright city lights.',
  ),

  // Philippine eagle
  ChoiceQuestion(
    creatureId: 'eagle',
    prompt: 'How wide are the Philippine eagle\'s open wings?',
    options: ['About 2 meters', 'About 20 centimeters', 'About 10 meters'],
    answer: 0,
    explain:
        'From tip to tip its wings stretch about 2 meters, wider than '
        'most grown-ups are tall.',
  ),
  ChoiceQuestion(
    creatureId: 'eagle',
    prompt: 'What is another name for the Philippine eagle?',
    options: ['Monkey-eating eagle', 'Fish-eating owl', 'Seed-eating duck'],
    answer: 0,
    explain:
        'It used to be called the monkey-eating eagle because it '
        'sometimes hunts monkeys.',
  ),
  ChoiceQuestion(
    creatureId: 'eagle',
    prompt: 'Philippine eagles build their nests high in tall trees.',
    options: _tf,
    answer: 0,
    explain:
        'They need big, old forest trees to build their huge nests, far '
        'above the ground.',
  ),
  ChoiceQuestion(
    creatureId: 'eagle',
    prompt: 'Why are Philippine eagles in danger?',
    options: [
      'Their forests are cut down',
      'They eat candy',
      'They fly too fast',
    ],
    answer: 0,
    explain:
        'When forests are cut down, eagles lose their homes and the '
        'animals they hunt.',
  ),
  ChoiceQuestion(
    creatureId: 'eagle',
    prompt: 'How many chicks does a Philippine eagle pair raise at a time?',
    options: ['One', 'Ten', 'Fifty'],
    answer: 0,
    explain:
        'A pair raises just one chick every two years, so every eagle '
        'counts.',
  ),
  PictureQuestion(
    creatureId: 'eagle',
    prompt: 'Which one is the Philippine eagle?',
    optionIds: ['colugo', 'eagle', 'tarsier'],
    answerId: 'eagle',
    explain: 'The eagle has a shaggy crest and a big hooked beak.',
  ),

  // Rafflesia
  ChoiceQuestion(
    creatureId: 'rafflesia',
    prompt: 'What is rafflesia famous for?',
    options: ['A giant flower', 'Glowing seeds', 'Singing leaves'],
    answer: 0,
    explain:
        'Some kinds of rafflesia have the biggest single flowers in the '
        'world.',
  ),
  ChoiceQuestion(
    creatureId: 'rafflesia',
    prompt: 'Which animal helps rafflesia make seeds?',
    options: ['Flies', 'Whales', 'Cows'],
    answer: 0,
    explain:
        'Its smell attracts flies. They carry pollen from flower to '
        'flower.',
  ),
  ChoiceQuestion(
    creatureId: 'rafflesia',
    prompt: 'A rafflesia flower stays open for many years.',
    options: _tf,
    answer: 1,
    explain:
        'It blooms for only about a week, then it turns black and rots '
        'away.',
  ),
  ChoiceQuestion(
    creatureId: 'rafflesia',
    prompt: 'How does rafflesia get its food?',
    options: [
      'From the vine it lives in',
      'From sunlight on its leaves',
      'By eating insects',
    ],
    answer: 0,
    explain:
        'Rafflesia lives inside a jungle vine and takes food and water '
        'from it.',
  ),
  ChoiceQuestion(
    creatureId: 'rafflesia',
    prompt: 'What do we call a living thing that takes food from another?',
    options: ['A parasite', 'A predator', 'A pollinator'],
    answer: 0,
    explain:
        'A parasite lives on or in another living thing and takes its '
        'food. Rafflesia is a parasite.',
  ),
  PictureQuestion(
    creatureId: 'rafflesia',
    prompt: 'Which one is the rafflesia?',
    optionIds: ['firefly', 'rafflesia', 'eagle'],
    answerId: 'rafflesia',
    explain: 'Rafflesia is the big red flower with white spots.',
  ),

  // Flying lemur
  ChoiceQuestion(
    creatureId: 'colugo',
    prompt: 'What does the flying lemur use to glide?',
    options: ['A skin cape between its legs', 'Feathers', 'A balloon'],
    answer: 0,
    explain:
        'Stretchy skin connects its neck, legs, and tail. It spreads it '
        'out like a kite.',
  ),
  ChoiceQuestion(
    creatureId: 'colugo',
    prompt: 'The flying lemur is a real lemur.',
    options: _tf,
    answer: 1,
    explain:
        'Lemurs live in Madagascar. Flying lemurs are a different animal '
        'called a colugo.',
  ),
  ChoiceQuestion(
    creatureId: 'colugo',
    prompt: 'Where does a mother flying lemur keep her baby?',
    options: [
      'On her belly, under her cape',
      'In a nest of rocks',
      'In the water',
    ],
    answer: 0,
    explain:
        'The baby clings to her belly. She folds her gliding skin around '
        'it like a hammock.',
  ),
  ChoiceQuestion(
    creatureId: 'colugo',
    prompt: 'Which animal hunts flying lemurs?',
    options: ['The Philippine eagle', 'The clownfish', 'The sea star'],
    answer: 0,
    explain:
        'Flying lemurs are one of the Philippine eagle\'s favorite '
        'foods.',
  ),
  ChoiceQuestion(
    creatureId: 'colugo',
    prompt: 'Where does a flying lemur spend most of its life?',
    options: ['In trees', 'Underground', 'In the sea'],
    answer: 0,
    explain:
        'It eats, sleeps, and raises its babies in the trees. On the '
        'ground it is very clumsy.',
  ),
  PictureQuestion(
    creatureId: 'colugo',
    prompt: 'Which one is the flying lemur?',
    optionIds: ['civet', 'colugo', 'eagle'],
    answerId: 'colugo',
    explain: 'The flying lemur has a big skin cape for gliding.',
  ),

  // Civet
  ChoiceQuestion(
    creatureId: 'civet',
    prompt: 'What is the Filipino name for the palm civet?',
    options: ['Alamid', 'Pawikan', 'Haribon'],
    answer: 0,
    explain: 'In the Philippines it is called alamid or musang.',
  ),
  ChoiceQuestion(
    creatureId: 'civet',
    prompt: 'What do palm civets eat?',
    options: [
      'Fruits, insects, and small animals',
      'Only rocks',
      'Only seaweed',
    ],
    answer: 0,
    explain: 'Civets eat lots of ripe fruit, plus insects and small animals.',
  ),
  ChoiceQuestion(
    creatureId: 'civet',
    prompt: 'Civets help forests grow by spreading seeds.',
    options: _tf,
    answer: 0,
    explain:
        'They eat fruit and leave the seeds far away in their droppings, '
        'where new trees can grow.',
  ),
  ChoiceQuestion(
    creatureId: 'civet',
    prompt: 'An animal that eats both plants and animals is called...',
    options: ['An omnivore', 'A herbivore', 'A carnivore'],
    answer: 0,
    explain:
        'Omnivores eat both. Herbivores eat only plants, and carnivores '
        'eat only animals.',
  ),
  ChoiceQuestion(
    creatureId: 'civet',
    prompt: "What is on a palm civet's face?",
    options: ['A dark mask with white spots', 'A long trunk', 'A beak'],
    answer: 0,
    explain:
        'Its dark face mask and white spots help it blend into the '
        'shadows at night.',
  ),
  ChoiceQuestion(
    creatureId: 'civet',
    prompt: "A palm civet's tail has stripes like rings.",
    options: _tf,
    answer: 1,
    explain:
        'The Asian palm civet has a plain, dark tail. Some other kinds '
        'of civets have ringed tails.',
  ),

  // Whale shark
  ChoiceQuestion(
    creatureId: 'whaleshark',
    prompt: 'What is the Filipino name for the whale shark?',
    options: ['Butanding', 'Duyong', 'Pawikan'],
    answer: 0,
    explain: 'Filipinos call the whale shark butanding.',
  ),
  ChoiceQuestion(
    creatureId: 'whaleshark',
    prompt: 'How does a whale shark breathe?',
    options: ['With gills', 'With lungs', 'Through its tail'],
    answer: 0,
    explain:
        'It is a fish, so it breathes with gills that take air from the '
        'water.',
  ),
  ChoiceQuestion(
    creatureId: 'whaleshark',
    prompt: 'Whale sharks are dangerous to people.',
    options: _tf,
    answer: 1,
    explain:
        'Whale sharks are gentle giants. They eat tiny plankton, not '
        'people.',
  ),
  ChoiceQuestion(
    creatureId: 'whaleshark',
    prompt: 'What pattern does a whale shark have?',
    options: [
      'White spots and stripes',
      'Rainbow scales',
      'Orange and white bands',
    ],
    answer: 0,
    explain:
        'Every whale shark has its own pattern of spots, like a '
        'fingerprint.',
  ),
  ChoiceQuestion(
    creatureId: 'whaleshark',
    prompt: 'What should you do when swimming near a whale shark?',
    options: [
      "Keep your distance and don't touch it",
      'Ride on its back',
      'Feed it chips',
    ],
    answer: 0,
    explain:
        'Touching or chasing whale sharks can hurt them. Watch quietly '
        'from a few meters away.',
  ),
  PictureQuestion(
    creatureId: 'whaleshark',
    prompt: 'Which one is the whale shark?',
    optionIds: ['dugong', 'clownfish', 'whaleshark'],
    answerId: 'whaleshark',
    explain: 'The whale shark is the big fish covered in pale spots.',
  ),

  // Dugong
  ChoiceQuestion(
    creatureId: 'dugong',
    prompt: 'Where do dugongs find their food?',
    options: ['In seagrass meadows', 'On mountains', 'In caves'],
    answer: 0,
    explain: 'Dugongs graze on seagrass that grows in shallow, sunny water.',
  ),
  ChoiceQuestion(
    creatureId: 'dugong',
    prompt: 'What kind of tail does a dugong have?',
    options: ["A flat tail like a whale's", 'A long furry tail', 'No tail'],
    answer: 0,
    explain:
        'Its tail, called a fluke, is flat and wide like a whale\'s. It '
        'moves it up and down to swim.',
  ),
  ChoiceQuestion(
    creatureId: 'dugong',
    prompt: 'Baby dugongs drink milk from their mothers.',
    options: _tf,
    answer: 0,
    explain:
        'Dugongs are mammals, so mothers feed their babies milk, just '
        'like people do.',
  ),
  ChoiceQuestion(
    creatureId: 'dugong',
    prompt: 'What harms dugongs the most?',
    options: [
      'Fishing nets and losing seagrass',
      'Too much sunshine',
      'Eating too many fish',
    ],
    answer: 0,
    explain:
        'Dugongs get caught in nets and hit by boats, and dirty water '
        'kills the seagrass they eat.',
  ),
  ChoiceQuestion(
    creatureId: 'dugong',
    prompt: 'What is the Filipino name for the dugong?',
    options: ['Duyong', 'Butanding', 'Pawikan'],
    answer: 0,
    explain: 'Filipinos call the dugong duyong.',
  ),
  PictureQuestion(
    creatureId: 'dugong',
    prompt: 'Which one is the dugong?',
    optionIds: ['turtle', 'dugong', 'whaleshark'],
    answerId: 'dugong',
    explain: 'The dugong is the round, gray one munching seagrass.',
  ),

  // Clownfish
  ChoiceQuestion(
    creatureId: 'clownfish',
    prompt: 'What colors is a clownfish?',
    options: ['Orange and white', 'Purple and green', 'All black'],
    answer: 0,
    explain: 'It is bright orange with white bands edged in black.',
  ),
  ChoiceQuestion(
    creatureId: 'clownfish',
    prompt: 'Clownfish help take care of their anemone.',
    options: _tf,
    answer: 0,
    explain:
        'Clownfish clean their anemone and chase away fish that want to '
        'eat it.',
  ),
  ChoiceQuestion(
    creatureId: 'clownfish',
    prompt: 'When two living things help each other, it is called...',
    options: ['Symbiosis', 'Hibernation', 'Migration'],
    answer: 0,
    explain:
        'Clownfish and anemones live in symbiosis: each one helps the '
        'other.',
  ),
  ChoiceQuestion(
    creatureId: 'clownfish',
    prompt: 'What do clownfish eat?',
    options: ['Tiny plankton and algae', 'Big sharks', 'Coconuts'],
    answer: 0,
    explain: 'Clownfish eat tiny plankton, algae, and leftover bits of food.',
  ),
  ChoiceQuestion(
    creatureId: 'clownfish',
    prompt: 'Clownfish live in cold, icy water.',
    options: _tf,
    answer: 1,
    explain: 'Clownfish live in warm, shallow water around coral reefs.',
  ),
  ChoiceQuestion(
    creatureId: 'clownfish',
    prompt: 'Where do clownfish lay their eggs?',
    options: ['On a rock next to their anemone', 'On a tree', 'On the beach'],
    answer: 0,
    explain:
        'They lay eggs on a rock close to their anemone, and the father '
        'guards them.',
  ),

  // Giant clam
  ChoiceQuestion(
    creatureId: 'clam',
    prompt: 'How big can a giant clam grow?',
    options: ['Over 1 meter wide', 'As small as a coin', 'As big as a house'],
    answer: 0,
    explain:
        'The biggest giant clams grow over 1 meter wide and are heavier '
        'than three grown-ups.',
  ),
  ChoiceQuestion(
    creatureId: 'clam',
    prompt: 'Giant clams can live for over 100 years.',
    options: _tf,
    answer: 0,
    explain:
        'Giant clams grow slowly and can live for a very long time, '
        'sometimes more than 100 years.',
  ),
  ChoiceQuestion(
    creatureId: 'clam',
    prompt: 'Why do giant clams need sunlight?',
    options: [
      'Tiny algae inside them make food',
      'To get a tan',
      'To stay warm at night',
    ],
    answer: 0,
    explain:
        'Tiny algae living in the clam use sunlight to make food, and '
        'they share it with the clam.',
  ),
  ChoiceQuestion(
    creatureId: 'clam',
    prompt: 'A giant clam is a kind of...',
    options: ['Mollusk, like a snail', 'Fish', 'Plant'],
    answer: 0,
    explain:
        'Clams are mollusks: soft-bodied animals, many with shells, like '
        'snails and octopuses.',
  ),
  ChoiceQuestion(
    creatureId: 'clam',
    prompt: 'Giant clams can trap divers in their shells.',
    options: _tf,
    answer: 1,
    explain:
        "That's just a myth. Giant clams close very slowly and are no "
        'danger to people.',
  ),
  PictureQuestion(
    creatureId: 'clam',
    prompt: 'Which one is the giant clam?',
    optionIds: ['seastar', 'clam', 'clownfish'],
    answerId: 'clam',
    explain: 'The giant clam has a wavy shell and a bright, colorful mantle.',
  ),

  // Green sea turtle
  ChoiceQuestion(
    creatureId: 'turtle',
    prompt: 'Why is it called a "green" sea turtle?',
    options: [
      'Seagrass turns its fat green',
      'Its shell glows green',
      'It lives in green lakes',
    ],
    answer: 0,
    explain:
        'Eating so much seagrass and algae gives the fat under its shell '
        'a green color.',
  ),
  ChoiceQuestion(
    creatureId: 'turtle',
    prompt: 'Sea turtles can pull their heads into their shells.',
    options: _tf,
    answer: 1,
    explain:
        'Land turtles can hide their heads, but sea turtles cannot. They '
        'swim away from danger instead.',
  ),
  ChoiceQuestion(
    creatureId: 'turtle',
    prompt: 'What does a sea turtle use to swim?',
    options: ['Flippers', 'Wheels', 'Feathered wings'],
    answer: 0,
    explain:
        'Its front flippers work like wings, so it "flies" through the '
        'water.',
  ),
  ChoiceQuestion(
    creatureId: 'turtle',
    prompt: 'Where do baby sea turtles go after they hatch?',
    options: [
      'They crawl to the sea',
      'They climb trees',
      'They stay in the nest',
    ],
    answer: 0,
    explain:
        'Hatchlings dig out of the sand, often at night, and hurry down '
        'the beach to the sea.',
  ),
  ChoiceQuestion(
    creatureId: 'turtle',
    prompt: 'Which trash is very dangerous for sea turtles?',
    options: ['Plastic bags', 'Fallen leaves', 'Sand'],
    answer: 0,
    explain:
        'Floating plastic bags look like jellyfish, and turtles can get '
        'sick if they eat them.',
  ),
  PictureQuestion(
    creatureId: 'turtle',
    prompt: 'Which one is the sea turtle?',
    optionIds: ['dugong', 'seastar', 'turtle'],
    answerId: 'turtle',
    explain: 'The sea turtle has a shell and big flippers.',
  ),

  // Sea star
  ChoiceQuestion(
    creatureId: 'seastar',
    prompt: "Where is a sea star's mouth?",
    options: [
      'Underneath, in the middle',
      'At the tip of an arm',
      'On its back',
    ],
    answer: 0,
    explain: 'Its mouth is on the bottom, right in the center.',
  ),
  ChoiceQuestion(
    creatureId: 'seastar',
    prompt: 'What does a sea star use to move?',
    options: ['Hundreds of tiny tube feet', 'Fins', 'Long legs with knees'],
    answer: 0,
    explain:
        'Under each arm are hundreds of tiny tube feet that grip and '
        'pull it along.',
  ),
  ChoiceQuestion(
    creatureId: 'seastar',
    prompt: 'Sea stars have a brain.',
    options: _tf,
    answer: 1,
    explain:
        'Sea stars have no brain. Nerves in each arm help it sense the '
        'world.',
  ),
  ChoiceQuestion(
    creatureId: 'seastar',
    prompt: 'What do many sea stars like to eat?',
    options: ['Clams and mussels', 'Grass', 'Bananas'],
    answer: 0,
    explain:
        'Many sea stars pull open clams and mussels with their arms to '
        'eat them.',
  ),
  ChoiceQuestion(
    creatureId: 'seastar',
    prompt: 'Where do sea stars live?',
    options: ['Only in the sea', 'In rivers and lakes', 'On land'],
    answer: 0,
    explain: 'Sea stars need salty seawater. None live in fresh water.',
  ),
  ChoiceQuestion(
    creatureId: 'seastar',
    prompt: 'Sea stars have eyes at the ends of their arms.',
    options: _tf,
    answer: 0,
    explain:
        'Each arm has a tiny eye spot at its tip that can tell light '
        'from dark.',
  ),

  // ---- Rice terraces

  // Rice plant
  ChoiceQuestion(
    creatureId: 'rice',
    prompt: 'What do we call rice that still has its husk?',
    options: ['Palay', 'Kanin', 'Bigas'],
    answer: 0,
    explain:
        'Palay is rice with its husk. Bigas is the uncooked grain, and '
        'kanin is cooked rice.',
  ),
  ChoiceQuestion(
    creatureId: 'rice',
    prompt: 'What is cooked rice called in Filipino?',
    options: ['Kanin', 'Palay', 'Bigas'],
    answer: 0,
    explain: 'Kanin is the cooked rice on your plate.',
  ),
  ChoiceQuestion(
    creatureId: 'rice',
    prompt: 'Rice is a kind of grass.',
    options: _tf,
    answer: 0,
    explain:
        'Rice is a grass, like corn and wheat. We eat its seeds, called '
        'grains.',
  ),
  ChoiceQuestion(
    creatureId: 'rice',
    prompt: 'What do plants need to make their own food?',
    options: ['Sunlight, water, and air', 'Candy', 'Darkness only'],
    answer: 0,
    explain:
        'Plants use sunlight, water, and a gas from the air to make '
        'their food.',
  ),
  ChoiceQuestion(
    creatureId: 'rice',
    prompt: 'What is it called when plants make food from sunlight?',
    options: ['Photosynthesis', 'Bioluminescence', 'Hibernation'],
    answer: 0,
    explain:
        '"Photo" means light. In photosynthesis, leaves turn sunlight '
        'into food for the plant.',
  ),
  ChoiceQuestion(
    creatureId: 'rice',
    prompt: 'Where does rice usually grow?',
    options: ['In flooded fields called paddies', 'Under the sea', 'In caves'],
    answer: 0,
    explain: 'Rice grows in paddies, fields kept covered with shallow water.',
  ),
  ChoiceQuestion(
    creatureId: 'rice',
    prompt: 'Who built the Banaue Rice Terraces?',
    options: ['The Ifugao people, long ago', 'Robots', 'Dinosaurs'],
    answer: 0,
    explain:
        'The Ifugao people carved them into the mountains by hand, '
        'hundreds of years ago.',
  ),
  ChoiceQuestion(
    creatureId: 'rice',
    prompt: 'The rice terraces were carved into the mountains by hand.',
    options: _tf,
    answer: 0,
    explain:
        'People shaped them with simple tools, step by step, and families '
        'still farm them today.',
  ),
  ChoiceQuestion(
    creatureId: 'rice',
    prompt: 'Which part of the rice plant do we eat?',
    options: ['The seeds, called grains', 'The roots', 'The leaves'],
    answer: 0,
    explain: 'Each grain of rice is a seed from the rice plant.',
  ),
  PictureQuestion(
    creatureId: 'rice',
    prompt: 'Which one is the rice plant?',
    optionIds: ['rafflesia', 'rice', 'carabao'],
    answerId: 'rice',
    explain: 'The rice plant has long green leaves and drooping golden grains.',
  ),

  // Carabao
  ChoiceQuestion(
    creatureId: 'carabao',
    prompt: 'Why do carabaos roll in the mud?',
    options: [
      'To cool down and keep bugs away',
      'To find fish',
      'To hide their horns',
    ],
    answer: 0,
    explain:
        'Carabaos can\'t sweat much, so a mud bath keeps them cool and '
        'protects their skin from bugs.',
  ),
  ChoiceQuestion(
    creatureId: 'carabao',
    prompt: 'How do carabaos help farmers?',
    options: [
      'They pull plows in rice fields',
      'They cook rice',
      'They fly to the market',
    ],
    answer: 0,
    explain:
        'Strong carabaos pull plows through muddy fields to get them '
        'ready for planting.',
  ),
  ChoiceQuestion(
    creatureId: 'carabao',
    prompt: 'The carabao is a kind of water buffalo.',
    options: _tf,
    answer: 0,
    explain:
        'The carabao is a water buffalo, and it loves being near water '
        'and mud.',
  ),
  ChoiceQuestion(
    creatureId: 'carabao',
    prompt: 'What does a carabao eat?',
    options: ['Grass and plants', 'Meat', 'Fish'],
    answer: 0,
    explain: 'Carabaos eat grass, rice straw, and other plants.',
  ),
  ChoiceQuestion(
    creatureId: 'carabao',
    prompt: 'An animal that eats only plants is called...',
    options: ['A herbivore', 'A carnivore', 'An omnivore'],
    answer: 0,
    explain:
        'Herbivores eat only plants. Carabaos, cows, and dugongs are all '
        'herbivores.',
  ),
  ChoiceQuestion(
    creatureId: 'carabao',
    prompt: 'Carabao milk can be made into white cheese.',
    options: _tf,
    answer: 0,
    explain:
        'Kesong puti, a soft white cheese, is often made from carabao '
        'milk.',
  ),
  ChoiceQuestion(
    creatureId: 'carabao',
    prompt: 'How does a baby carabao get food at first?',
    options: [
      "It drinks its mother's milk",
      'It hatches from an egg',
      'It grows from a seed',
    ],
    answer: 0,
    explain: 'Carabaos are mammals, so mothers feed their babies milk.',
  ),
  ChoiceQuestion(
    creatureId: 'carabao',
    prompt: "What are a carabao's horns like?",
    options: ['Long and curved back', 'Short and straight', 'It has no horns'],
    answer: 0,
    explain:
        'Carabaos have big horns that curve out and back, like a '
        'crescent moon.',
  ),
  ChoiceQuestion(
    creatureId: 'carabao',
    prompt: 'The carabao is a famous symbol of hard work in the Philippines.',
    options: _tf,
    answer: 0,
    explain:
        'For many Filipinos, the patient, strong carabao stands for hard '
        'work.',
  ),
  PictureQuestion(
    creatureId: 'carabao',
    prompt: 'Which one is the carabao?',
    optionIds: ['carabao', 'dugong', 'cloudrat'],
    answerId: 'carabao',
    explain: 'The carabao is the gray one with big curved horns.',
  ),

  // Magellan birdwing
  ChoiceQuestion(
    creatureId: 'birdwing',
    prompt: 'What do butterflies drink?',
    options: ['Nectar from flowers', 'Milk', 'Seawater'],
    answer: 0,
    explain:
        'Butterflies sip sweet nectar through a long, curly tongue like a '
        'straw.',
  ),
  ChoiceQuestion(
    creatureId: 'birdwing',
    prompt: 'Butterflies start life as caterpillars.',
    options: _tf,
    answer: 0,
    explain:
        'A butterfly hatches from an egg as a caterpillar, then changes '
        'into a butterfly.',
  ),
  ChoiceQuestion(
    creatureId: 'birdwing',
    prompt: 'What comes between the caterpillar and the butterfly?',
    options: ['The pupa, or chrysalis', 'The egg', 'The tadpole'],
    answer: 0,
    explain:
        'Egg, caterpillar, pupa, butterfly! Inside the pupa, the '
        'caterpillar changes into a butterfly.',
  ),
  ChoiceQuestion(
    creatureId: 'birdwing',
    prompt: 'What happens to the birdwing\'s golden wings in bright light?',
    options: ['They shimmer blue-green', 'They turn red', 'They glow at night'],
    answer: 0,
    explain:
        'Its back wings shimmer blue-green when light hits them at just '
        'the right angle.',
  ),
  ChoiceQuestion(
    creatureId: 'birdwing',
    prompt: 'Butterflies taste with their...',
    options: ['Feet', 'Ears', 'Wings'],
    answer: 0,
    explain:
        'Butterflies have taste sensors on their feet, so they taste '
        'leaves by standing on them.',
  ),
  ChoiceQuestion(
    creatureId: 'birdwing',
    prompt: 'How many wings does a butterfly have?',
    options: ['Four', 'Two', 'Six'],
    answer: 0,
    explain: 'Butterflies have four wings: two in front and two in back.',
  ),
  ChoiceQuestion(
    creatureId: 'birdwing',
    prompt: 'Butterflies help flowers make seeds.',
    options: _tf,
    answer: 0,
    explain:
        'As butterflies visit flowers, they carry pollen from one to '
        'another. That helps make seeds.',
  ),
  ChoiceQuestion(
    creatureId: 'birdwing',
    prompt: 'What is "paru-paro"?',
    options: ['A butterfly', 'A bird', 'A bee'],
    answer: 0,
    explain: 'Paru-paro is the Filipino word for butterfly.',
  ),
  SortQuestion(
    creatureId: 'birdwing',
    prompt: 'Insect or not an insect?',
    bins: ['Insect', 'Not an insect'],
    items: {'Butterfly': 0, 'Firefly': 0, 'Spider': 1, 'Carabao': 1},
    explain:
        'Insects have six legs. Spiders have eight, and carabaos have '
        'four, so they are not insects.',
  ),
  PictureQuestion(
    creatureId: 'birdwing',
    prompt: 'Which one is the butterfly?',
    optionIds: ['firefly', 'bleedingheart', 'birdwing'],
    answerId: 'birdwing',
    explain: 'The birdwing has big black and golden wings.',
  ),

  // Luzon bleeding-heart
  ChoiceQuestion(
    creatureId: 'bleedingheart',
    prompt: 'Why is it called a "bleeding-heart"?',
    options: [
      'A red patch on its chest looks like a wound',
      'It is hurt',
      'It only eats red berries',
    ],
    answer: 0,
    explain:
        'The bright red patch on its white chest looks like a wound, but '
        'it is just feathers.',
  ),
  ChoiceQuestion(
    creatureId: 'bleedingheart',
    prompt: 'The red patch on its chest is a real wound.',
    options: _tf,
    answer: 1,
    explain: 'It is not hurt at all. The red color is made of feathers.',
  ),
  ChoiceQuestion(
    creatureId: 'bleedingheart',
    prompt: 'Where does the bleeding-heart look for food?',
    options: ['On the forest floor', 'High in the clouds', 'Under the sea'],
    answer: 0,
    explain: 'It walks along the forest floor, searching the leaves for food.',
  ),
  ChoiceQuestion(
    creatureId: 'bleedingheart',
    prompt: 'What does the bleeding-heart eat?',
    options: ['Seeds, berries, and small bugs', 'Fish', 'Only grass'],
    answer: 0,
    explain:
        'It pecks up seeds, berries, and small insects and worms from the '
        'ground.',
  ),
  ChoiceQuestion(
    creatureId: 'bleedingheart',
    prompt: 'Where does the Luzon bleeding-heart live?',
    options: ['In forests on Luzon', 'In Antarctica', 'In the desert'],
    answer: 0,
    explain:
        'As its name says, it lives in the forests of Luzon and nearby '
        'small islands.',
  ),
  ChoiceQuestion(
    creatureId: 'bleedingheart',
    prompt: 'Bleeding-hearts spend most of their time walking on the ground.',
    options: _tf,
    answer: 0,
    explain:
        'It can fly, but it is a ground pigeon. It walks and runs more '
        'than it flies.',
  ),
  ChoiceQuestion(
    creatureId: 'bleedingheart',
    prompt: 'A pigeon is a kind of...',
    options: ['Bird', 'Mammal', 'Reptile'],
    answer: 0,
    explain: 'Pigeons are birds: they have feathers, wings, and a beak.',
  ),
  ChoiceQuestion(
    creatureId: 'bleedingheart',
    prompt: "What covers a bird's body?",
    options: ['Feathers', 'Scales', 'Fur'],
    answer: 0,
    explain:
        'Only birds have feathers. They keep birds warm and help them fly.',
  ),
  ChoiceQuestion(
    creatureId: 'bleedingheart',
    prompt: 'Why are bleeding-hearts becoming rare?',
    options: [
      'Forests are cut down and some are caught as pets',
      'Too much rain',
      'They sleep too much',
    ],
    answer: 0,
    explain:
        'They lose their forest homes, and some are trapped to be sold '
        'as pets.',
  ),
  PictureQuestion(
    creatureId: 'bleedingheart',
    prompt: 'Which one is the bleeding-heart?',
    optionIds: ['bleedingheart', 'eagle', 'birdwing'],
    answerId: 'bleedingheart',
    explain: 'The bleeding-heart is the round pigeon with a red chest patch.',
  ),

  // Philippine sailfin lizard
  ChoiceQuestion(
    creatureId: 'sailfin',
    prompt: 'Where is the sailfin lizard\'s sail?',
    options: ['On its tail', 'On its head', 'On its feet'],
    answer: 0,
    explain: 'A tall, thin sail stands up along the top of its tail.',
  ),
  ChoiceQuestion(
    creatureId: 'sailfin',
    prompt: 'Young sailfin lizards can run across water for a short way.',
    options: _tf,
    answer: 0,
    explain:
        'Young ones are light and quick. Their wide toes help them run '
        'over the water\'s surface.',
  ),
  ChoiceQuestion(
    creatureId: 'sailfin',
    prompt: 'Where do sailfin lizards like to live?',
    options: ['Near rivers and streams', 'In deserts', 'In the snow'],
    answer: 0,
    explain:
        'They live by rivers, and they jump into the water when danger '
        'comes.',
  ),
  ChoiceQuestion(
    creatureId: 'sailfin',
    prompt: 'A lizard is a kind of...',
    options: ['Reptile', 'Amphibian', 'Fish'],
    answer: 0,
    explain: 'Lizards are reptiles, like turtles and snakes.',
  ),
  ChoiceQuestion(
    creatureId: 'sailfin',
    prompt: 'Sailfin lizards are good swimmers.',
    options: _tf,
    answer: 0,
    explain: 'They swim well, using their tall tail like a paddle.',
  ),
  ChoiceQuestion(
    creatureId: 'sailfin',
    prompt: 'What do sailfin lizards eat?',
    options: ['Leaves, fruits, and insects', 'Only rocks', 'Only milk'],
    answer: 0,
    explain: 'They eat both plants and small animals, so they are omnivores.',
  ),
  ChoiceQuestion(
    creatureId: 'sailfin',
    prompt: "What covers a reptile's skin?",
    options: ['Scales', 'Feathers', 'Fur'],
    answer: 0,
    explain: 'Reptiles have dry skin covered in scales.',
  ),
  ChoiceQuestion(
    creatureId: 'sailfin',
    prompt: 'How are baby sailfin lizards born?',
    options: [
      'They hatch from eggs',
      'They grow on trees',
      'They grow from seeds',
    ],
    answer: 0,
    explain: 'The mother lays eggs in the ground, and babies hatch from them.',
  ),
  ChoiceQuestion(
    creatureId: 'sailfin',
    prompt: "A lizard's body makes its own heat, like ours does.",
    options: _tf,
    answer: 1,
    explain:
        'Lizards warm up in the sun. That is why they love to bask on '
        'sunny rocks and branches.',
  ),
  PictureQuestion(
    creatureId: 'sailfin',
    prompt: 'Which one is the sailfin lizard?',
    optionIds: ['turtle', 'sailfin', 'civet'],
    answerId: 'sailfin',
    explain: 'The sailfin lizard has a tall sail on its tail.',
  ),

  // Luzon cloud rat
  ChoiceQuestion(
    creatureId: 'cloudrat',
    prompt: 'When is the cloud rat awake?',
    options: ['At night', 'At noon'],
    answer: 0,
    explain:
        'Cloud rats are nocturnal. They rest by day and come out at '
        'night.',
  ),
  ChoiceQuestion(
    creatureId: 'cloudrat',
    prompt: 'Where does the Luzon cloud rat live?',
    options: ['In mountain forests of Luzon', 'In the sea', 'In the desert'],
    answer: 0,
    explain:
        'It lives in the mountain forests of northern Luzon and climbs '
        'in the trees.',
  ),
  ChoiceQuestion(
    creatureId: 'cloudrat',
    prompt: 'Cloud rats are much bigger than house rats.',
    options: _tf,
    answer: 0,
    explain:
        'It is one of the biggest rats in the world, about the size of '
        'a cat.',
  ),
  ChoiceQuestion(
    creatureId: 'cloudrat',
    prompt: 'What does a cloud rat eat?',
    options: ['Leaves and other plants', 'Fish', 'Meat'],
    answer: 0,
    explain: 'Cloud rats eat young leaves, shoots, and other plants.',
  ),
  ChoiceQuestion(
    creatureId: 'cloudrat',
    prompt: "What is a cloud rat's fur like?",
    options: ['Long and fluffy', 'Hard scales', 'Feathers'],
    answer: 0,
    explain: 'Its long, fluffy fur keeps it warm in the cool mountains.',
  ),
  ChoiceQuestion(
    creatureId: 'cloudrat',
    prompt: 'What do we call animals that are awake at night?',
    options: ['Nocturnal', 'Diurnal', 'Aquatic'],
    answer: 0,
    explain:
        'Nocturnal animals are awake at night. Diurnal ones are awake '
        'during the day.',
  ),
  ChoiceQuestion(
    creatureId: 'cloudrat',
    prompt: 'What do we call animals that are awake during the day?',
    options: ['Diurnal', 'Nocturnal', 'Aquatic'],
    answer: 0,
    explain:
        'Diurnal animals, like carabaos and butterflies, are busy in '
        'the daytime.',
  ),
  ChoiceQuestion(
    creatureId: 'cloudrat',
    prompt: 'Cloud rats live only in the Philippines.',
    options: _tf,
    answer: 0,
    explain:
        'Cloud rats are found nowhere else in the world. They are a '
        'Philippine treasure.',
  ),
  ChoiceQuestion(
    creatureId: 'cloudrat',
    prompt: 'Rats are rodents. What do all rodents have?',
    options: ['Front teeth that keep growing', 'Wings', 'Shells'],
    answer: 0,
    explain:
        'Rodents have front teeth that never stop growing, so they gnaw '
        'to keep them short.',
  ),
  PictureQuestion(
    creatureId: 'cloudrat',
    prompt: 'Which one is the cloud rat?',
    optionIds: ['civet', 'cloudrat', 'tarsier'],
    answerId: 'cloudrat',
    explain: 'The cloud rat is the fluffy one with a long, bushy tail.',
  ),

  // ---- Mangrove

  // Mudskipper
  ChoiceQuestion(
    creatureId: 'mudskipper',
    prompt: 'A mudskipper is a kind of...',
    options: ['Fish', 'Frog', 'Lizard'],
    answer: 0,
    explain:
        'It looks funny on land, but the mudskipper is a real fish with '
        'fins and gills.',
  ),
  ChoiceQuestion(
    creatureId: 'mudskipper',
    prompt: 'How does a mudskipper move across the mud?',
    options: ['It walks on its front fins', 'It flies', 'It rolls like a ball'],
    answer: 0,
    explain:
        'It uses its strong front fins like little arms to walk and '
        'skip across the mud.',
  ),
  ChoiceQuestion(
    creatureId: 'mudskipper',
    prompt: 'Mudskippers can breathe out of the water.',
    options: _tf,
    answer: 0,
    explain:
        'They breathe through their wet skin and mouth, and they keep '
        'water in their gills like a backpack.',
  ),
  ChoiceQuestion(
    creatureId: 'mudskipper',
    prompt: "Where are a mudskipper's eyes?",
    options: ['On top of its head', 'Under its belly', 'On its tail'],
    answer: 0,
    explain:
        'Its eyes poke up on top of its head, so it can watch for birds '
        'while half hidden in mud.',
  ),
  ChoiceQuestion(
    creatureId: 'mudskipper',
    prompt: 'Why does a mudskipper roll in the mud?',
    options: ['To keep its skin wet', 'To get warm', 'To hide its fins'],
    answer: 0,
    explain:
        'It needs wet skin to breathe on land, so it rolls in puddles and '
        'mud.',
  ),
  ChoiceQuestion(
    creatureId: 'mudskipper',
    prompt: 'What do mudskippers eat?',
    options: ['Small crabs, worms, and insects', 'Coconuts', 'Big fish'],
    answer: 0,
    explain:
        'They hunt small animals on the mud, like tiny crabs, worms, and '
        'insects.',
  ),
  ChoiceQuestion(
    creatureId: 'mudskipper',
    prompt: 'Mudskippers dig burrows in the mud.',
    options: _tf,
    answer: 0,
    explain:
        'They dig burrows that fill with water. They hide inside when the '
        'tide comes in.',
  ),
  ChoiceQuestion(
    creatureId: 'mudskipper',
    prompt: 'What is the mudskipper called in Filipino?',
    options: ['Talimusak', 'Bayawak', 'Salaksak'],
    answer: 0,
    explain: 'In Filipino, the mudskipper is called talimusak.',
  ),
  ChoiceQuestion(
    creatureId: 'mudskipper',
    prompt: 'How do boy mudskippers show off?',
    options: [
      'They jump high and raise their back fins',
      'They sing songs',
      'They change into birds',
    ],
    answer: 0,
    explain:
        'They flip into the air and raise their colorful back fins to '
        'impress others.',
  ),
  PictureQuestion(
    creatureId: 'mudskipper',
    prompt: 'Which one is the mudskipper?',
    optionIds: ['clownfish', 'mudskipper', 'sailfin'],
    answerId: 'mudskipper',
    explain: 'The mudskipper is the fish with eyes on top of its head.',
  ),

  // Fiddler crab
  ChoiceQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'What is special about a boy fiddler crab?',
    options: ['One claw is much bigger', 'It has wings', 'It glows'],
    answer: 0,
    explain: 'Boy fiddler crabs have one giant claw and one small claw.',
  ),
  ChoiceQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'Why does a fiddler crab wave its big claw?',
    options: [
      'To say "this is my spot"',
      'To wave hello to people',
      'To dry it off',
    ],
    answer: 0,
    explain:
        'Waving warns other crabs to stay away and helps attract a '
        'partner.',
  ),
  ChoiceQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'Girl fiddler crabs have two small claws.',
    options: _tf,
    answer: 0,
    explain:
        'Only the boys have a giant claw. Girls use both small claws to '
        'eat.',
  ),
  ChoiceQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'How does a fiddler crab eat?',
    options: [
      'It scoops tiny bits of food from the mud',
      'It hunts sharks',
      'It eats leaves from tall trees',
    ],
    answer: 0,
    explain:
        'It picks up mud with its small claw and eats the tiny bits of '
        'food in it.',
  ),
  ChoiceQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'Where does a fiddler crab hide when the tide comes in?',
    options: ['In its burrow', 'Up in the clouds', 'Inside a coconut'],
    answer: 0,
    explain:
        'It digs a burrow in the mud and hides inside when water covers '
        'the shore.',
  ),
  ChoiceQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'How many legs does a crab have, counting its claws?',
    options: ['10', '6', '4'],
    answer: 0,
    explain: 'Crabs have 8 walking legs plus 2 claws. That makes 10.',
  ),
  ChoiceQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'A crab is a kind of...',
    options: ['Crustacean', 'Insect', 'Fish'],
    answer: 0,
    explain:
        'Crabs, shrimp, and lobsters are crustaceans: animals with a '
        'hard outer shell and jointed legs.',
  ),
  ChoiceQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'Crabs grow bigger by getting out of their old shells.',
    options: _tf,
    answer: 0,
    explain:
        'A crab sheds its old, tight shell and grows a new, bigger one. '
        'This is called molting.',
  ),
  ChoiceQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'When are fiddler crabs busiest?',
    options: ['In the day, at low tide', 'Only in winter snow', 'Never'],
    answer: 0,
    explain:
        'When the water goes out at low tide, they come out to eat and '
        'wave their claws.',
  ),
  PictureQuestion(
    creatureId: 'fiddlercrab',
    prompt: 'Which one is the fiddler crab?',
    optionIds: ['fiddlercrab', 'seastar', 'clam'],
    answerId: 'fiddlercrab',
    explain: 'The fiddler crab is the one with one giant claw.',
  ),

  // Mangrove tree
  ChoiceQuestion(
    creatureId: 'mangrovetree',
    prompt: 'What is special about mangrove tree roots?',
    options: [
      'They stand up like stilts',
      'They glow',
      'They float in the sky',
    ],
    answer: 0,
    explain:
        'Many mangroves stand on arching stilt roots that hold them up '
        'in the mud.',
  ),
  ChoiceQuestion(
    creatureId: 'mangrovetree',
    prompt: 'Mangrove trees can grow in salty water.',
    options: _tf,
    answer: 0,
    explain:
        'Most trees die in salt water, but mangroves have special ways '
        'to handle the salt.',
  ),
  ChoiceQuestion(
    creatureId: 'mangrovetree',
    prompt: 'How do mangroves protect people who live by the sea?',
    options: [
      'They slow down big waves and storms',
      'They make it rain candy',
      'They scare away the moon',
    ],
    answer: 0,
    explain:
        'Their tangled roots act like a wall that slows down waves and '
        'keeps the shore from washing away.',
  ),
  ChoiceQuestion(
    creatureId: 'mangrovetree',
    prompt: 'Why do baby fish like mangrove roots?',
    options: [
      'They can hide from big fish there',
      'The roots are sweet',
      'The roots are warm like a bed',
    ],
    answer: 0,
    explain:
        'The roots make a safe nursery where baby fish hide until they '
        'grow up.',
  ),
  ChoiceQuestion(
    creatureId: 'mangrovetree',
    prompt: 'Mangrove seeds start growing while still on the tree.',
    options: _tf,
    answer: 0,
    explain:
        'Its long green seed pods sprout on the tree, then drop into the '
        'mud or float away to grow.',
  ),
  ChoiceQuestion(
    creatureId: 'mangrovetree',
    prompt: 'What is the mangrove tree called in Filipino?',
    options: ['Bakawan', 'Palay', 'Duyong'],
    answer: 0,
    explain: 'Filipinos call the mangrove tree bakawan.',
  ),
  ChoiceQuestion(
    creatureId: 'mangrovetree',
    prompt: 'Like all plants, mangroves give us...',
    options: ['Oxygen to breathe', 'Plastic', 'Electricity'],
    answer: 0,
    explain:
        'Plants make oxygen as they make their food, and we breathe '
        'that oxygen.',
  ),
  ChoiceQuestion(
    creatureId: 'mangrovetree',
    prompt: 'What happens when mangroves are cut down?',
    options: [
      'Shores wash away and animals lose homes',
      'More fish come',
      'Nothing at all',
    ],
    answer: 0,
    explain:
        'Without mangroves, waves eat away the shore and many animals '
        'lose their homes.',
  ),
  SortQuestion(
    creatureId: 'mangrovetree',
    prompt: 'Living or non-living?',
    bins: ['Living', 'Non-living'],
    items: {'Mangrove tree': 0, 'Mudskipper': 0, 'Mud': 1, 'Seawater': 1},
    explain:
        'Mangroves and mudskippers grow and need food. Mud and seawater '
        'do not.',
  ),
  PictureQuestion(
    creatureId: 'mangrovetree',
    prompt: 'Which one is the mangrove tree?',
    optionIds: ['rice', 'mangrovetree', 'rafflesia'],
    answerId: 'mangrovetree',
    explain: 'The mangrove tree stands on arching stilt roots.',
  ),

  // Collared kingfisher
  ChoiceQuestion(
    creatureId: 'kingfisher',
    prompt: 'What colors is the collared kingfisher?',
    options: ['Bright blue and white', 'Pink and purple', 'All black'],
    answer: 0,
    explain:
        'It has bright blue-green wings and back, and a white belly and '
        'collar.',
  ),
  ChoiceQuestion(
    creatureId: 'kingfisher',
    prompt: 'How does a kingfisher catch its food?',
    options: [
      'It waits on a branch, then swoops down',
      'It digs underground',
      'It builds a net',
    ],
    answer: 0,
    explain:
        'It sits very still watching, then dives down fast to grab its '
        'food.',
  ),
  ChoiceQuestion(
    creatureId: 'kingfisher',
    prompt: 'What does the collared kingfisher eat?',
    options: ['Crabs, insects, and small fish', 'Only grass', 'Rice'],
    answer: 0,
    explain:
        'In the mangroves it loves crabs, but it also eats insects, small '
        'fish, and lizards.',
  ),
  ChoiceQuestion(
    creatureId: 'kingfisher',
    prompt: 'What is the kingfisher called in Filipino?',
    options: ['Salaksak', 'Talimusak', 'Bakawan'],
    answer: 0,
    explain: 'Filipinos call the kingfisher salaksak.',
  ),
  ChoiceQuestion(
    creatureId: 'kingfisher',
    prompt: 'Kingfishers make their nests in holes.',
    options: _tf,
    answer: 0,
    explain:
        'Collared kingfishers nest in holes in trees or in termite '
        'nests.',
  ),
  ChoiceQuestion(
    creatureId: 'kingfisher',
    prompt: 'How do baby kingfishers start life?',
    options: [
      'They hatch from eggs',
      'They are born from seeds',
      'They fall from clouds',
    ],
    answer: 0,
    explain: 'All birds hatch from eggs, and kingfishers are birds.',
  ),
  ChoiceQuestion(
    creatureId: 'kingfisher',
    prompt: 'The collared kingfisher has a big, strong beak.',
    options: _tf,
    answer: 0,
    explain: 'Its big beak is perfect for grabbing slippery crabs and fish.',
  ),
  ChoiceQuestion(
    creatureId: 'kingfisher',
    prompt: 'Which sound might you hear from a kingfisher?',
    options: ['A loud "kee-kee-kee"', 'A "moo"', 'A "woof"'],
    answer: 0,
    explain:
        'Collared kingfishers are noisy birds with a loud, repeating '
        'call.',
  ),
  ChoiceQuestion(
    creatureId: 'kingfisher',
    prompt: 'What do we call an animal that hunts other animals?',
    options: ['A predator', 'A plant', 'A pollinator'],
    answer: 0,
    explain:
        'Predators hunt other animals for food. The kingfisher is a '
        'predator of crabs.',
  ),
  PictureQuestion(
    creatureId: 'kingfisher',
    prompt: 'Which one is the kingfisher?',
    optionIds: ['bleedingheart', 'eagle', 'kingfisher'],
    answerId: 'kingfisher',
    explain: 'The kingfisher is the bright blue bird with a white collar.',
  ),

  // Water monitor
  ChoiceQuestion(
    creatureId: 'monitor',
    prompt: 'What is the water monitor called in Filipino?',
    options: ['Bayawak', 'Butanding', 'Salaksak'],
    answer: 0,
    explain: 'Filipinos call the monitor lizard bayawak.',
  ),
  ChoiceQuestion(
    creatureId: 'monitor',
    prompt: 'Water monitors are great swimmers.',
    options: _tf,
    answer: 0,
    explain:
        'They swim by swishing their long, strong tail from side to '
        'side.',
  ),
  ChoiceQuestion(
    creatureId: 'monitor',
    prompt: 'Why does a monitor lizard flick its forked tongue?',
    options: ['To smell the air', 'To say hello', 'To cool its teeth'],
    answer: 0,
    explain: 'Its tongue picks up smells from the air, helping it find food.',
  ),
  ChoiceQuestion(
    creatureId: 'monitor',
    prompt: 'What does the water monitor eat?',
    options: ['Fish, crabs, and eggs', 'Only leaves', 'Only rice'],
    answer: 0,
    explain:
        'It eats fish, crabs, eggs, and even dead animals, which helps '
        'keep places clean.',
  ),
  ChoiceQuestion(
    creatureId: 'monitor',
    prompt: 'How are baby monitor lizards born?',
    options: [
      'They hatch from eggs',
      'They grow on trees',
      'They drink milk first',
    ],
    answer: 0,
    explain: 'Monitor lizards are reptiles, and they lay eggs.',
  ),
  ChoiceQuestion(
    creatureId: 'monitor',
    prompt: 'Why do monitor lizards lie in the sun?',
    options: ['To warm up their bodies', 'To get a tan', 'To fall asleep'],
    answer: 0,
    explain:
        'Reptiles warm up in the sun because their bodies don\'t make '
        'their own heat.',
  ),
  ChoiceQuestion(
    creatureId: 'monitor',
    prompt: 'Water monitors can grow longer than a grown-up is tall.',
    options: _tf,
    answer: 0,
    explain:
        'From nose to tail, big ones can be over 2 meters long. Most of '
        'that is tail!',
  ),
  ChoiceQuestion(
    creatureId: 'monitor',
    prompt: 'What should you do if you see a wild monitor lizard?',
    options: ['Watch from far away', 'Try to pet it', 'Chase it'],
    answer: 0,
    explain:
        'Wild animals can bite or scratch when scared. Give them space '
        'and enjoy watching.',
  ),
  ChoiceQuestion(
    creatureId: 'monitor',
    prompt: 'A monitor lizard is a kind of...',
    options: ['Reptile', 'Mammal', 'Bird'],
    answer: 0,
    explain: 'Monitor lizards are reptiles with scaly skin.',
  ),
  PictureQuestion(
    creatureId: 'monitor',
    prompt: 'Which one is the water monitor?',
    optionIds: ['sailfin', 'monitor', 'catsnake'],
    answerId: 'monitor',
    explain: 'The water monitor is the big dark lizard with yellow spots.',
  ),

  // Mangrove cat snake
  ChoiceQuestion(
    creatureId: 'catsnake',
    prompt: 'When does the mangrove cat snake hunt?',
    options: ['At night', 'At noon'],
    answer: 0,
    explain:
        'It is nocturnal. It rests in the trees by day and hunts at '
        'night.',
  ),
  ChoiceQuestion(
    creatureId: 'catsnake',
    prompt: 'What colors is the mangrove cat snake?',
    options: [
      'Shiny black with yellow bands',
      'Pink with green dots',
      'Plain white',
    ],
    answer: 0,
    explain: 'It is glossy black with bright yellow bands around its body.',
  ),
  ChoiceQuestion(
    creatureId: 'catsnake',
    prompt: 'It is safe to pick up a wild snake.',
    options: _tf,
    answer: 1,
    explain:
        'Never touch a wild snake. The mangrove cat snake has a mild '
        'venom. Watch from far away and tell a grown-up.',
  ),
  ChoiceQuestion(
    creatureId: 'catsnake',
    prompt: 'How does a snake smell things?',
    options: ['With its tongue', 'With its tail', 'With its scales'],
    answer: 0,
    explain: 'Snakes flick their tongues to catch smells from the air.',
  ),
  ChoiceQuestion(
    creatureId: 'catsnake',
    prompt: 'What does the mangrove cat snake eat?',
    options: ['Birds, lizards, and frogs', 'Grass', 'Fruits only'],
    answer: 0,
    explain:
        'It hunts small animals like birds, lizards, and frogs in the '
        'trees.',
  ),
  ChoiceQuestion(
    creatureId: 'catsnake',
    prompt: 'Snakes shed their old skin as they grow.',
    options: _tf,
    answer: 0,
    explain:
        'A snake wriggles out of its old skin, leaving it behind in one '
        'long piece.',
  ),
  ChoiceQuestion(
    creatureId: 'catsnake',
    prompt: 'How many legs does a snake have?',
    options: ['None', 'Four', 'Six'],
    answer: 0,
    explain: 'Snakes have no legs. They move by bending their long bodies.',
  ),
  ChoiceQuestion(
    creatureId: 'catsnake',
    prompt: 'Where does the mangrove cat snake like to rest?',
    options: ['In tree branches', 'Deep in the sea', 'In the snow'],
    answer: 0,
    explain:
        'It is a great climber and rests coiled on branches above the '
        'water.',
  ),
  ChoiceQuestion(
    creatureId: 'catsnake',
    prompt: 'A snake is a kind of...',
    options: ['Reptile', 'Amphibian', 'Insect'],
    answer: 0,
    explain: 'Snakes are reptiles, like lizards and turtles.',
  ),
  PictureQuestion(
    creatureId: 'catsnake',
    prompt: 'Which one is the mangrove cat snake?',
    optionIds: ['catsnake', 'monitor', 'colugo'],
    answerId: 'catsnake',
    explain: 'The cat snake is black with yellow bands.',
  ),

  // ---- Cave

  // Fruit bat
  ChoiceQuestion(
    creatureId: 'fruitbat',
    prompt: 'A bat is a kind of...',
    options: ['Mammal', 'Bird', 'Insect'],
    answer: 0,
    explain:
        'Bats have fur and feed their babies milk, so they are mammals, '
        'not birds.',
  ),
  ChoiceQuestion(
    creatureId: 'fruitbat',
    prompt: 'Bats are the only mammals that can really fly.',
    options: _tf,
    answer: 0,
    explain:
        'Some mammals glide, like the flying lemur, but only bats flap '
        'their wings and truly fly.',
  ),
  ChoiceQuestion(
    creatureId: 'fruitbat',
    prompt: "What are a bat's wings made of?",
    options: ['Skin stretched over long fingers', 'Feathers', 'Paper'],
    answer: 0,
    explain:
        'A bat\'s wing is like a hand with very long fingers and thin '
        'skin between them.',
  ),
  ChoiceQuestion(
    creatureId: 'fruitbat',
    prompt: 'How does this fruit bat find its way in a dark cave?',
    options: [
      'It clicks and listens for echoes',
      'It uses a flashlight',
      'It follows the smell of rain',
    ],
    answer: 0,
    explain:
        'It makes clicking sounds with its tongue. The echoes bounce '
        'back and tell it where the walls are.',
  ),
  ChoiceQuestion(
    creatureId: 'fruitbat',
    prompt: 'What does a fruit bat eat?',
    options: ['Fruit and flower nectar', 'Rocks', 'Fish'],
    answer: 0,
    explain: 'As its name says, it loves fruit, and it sips nectar too.',
  ),
  ChoiceQuestion(
    creatureId: 'fruitbat',
    prompt: 'How do fruit bats help the forest?',
    options: [
      'They spread seeds and pollen',
      'They cut down trees',
      'They make it rain',
    ],
    answer: 0,
    explain:
        'They drop seeds far away and carry pollen between flowers, '
        'helping new plants grow.',
  ),
  ChoiceQuestion(
    creatureId: 'fruitbat',
    prompt: 'How do bats rest in the cave?',
    options: [
      'Hanging upside down',
      'Standing on one leg',
      'Floating in water',
    ],
    answer: 0,
    explain:
        'Bats hang upside down by their feet. From there, they can drop '
        'and fly away fast.',
  ),
  ChoiceQuestion(
    creatureId: 'fruitbat',
    prompt: 'What is a bat called in Filipino?',
    options: ['Paniki', 'Salaksak', 'Bayawak'],
    answer: 0,
    explain: 'In Filipino, a bat is called paniki.',
  ),
  ChoiceQuestion(
    creatureId: 'fruitbat',
    prompt: 'Baby bats drink milk from their mothers.',
    options: _tf,
    answer: 0,
    explain: 'Bats are mammals, so mother bats feed their babies milk.',
  ),
  PictureQuestion(
    creatureId: 'fruitbat',
    prompt: 'Which one is the fruit bat?',
    optionIds: ['fruitbat', 'colugo', 'swiftlet'],
    answerId: 'fruitbat',
    explain: 'The fruit bat has big leathery wings and a fox-like face.',
  ),

  // Swiftlet
  ChoiceQuestion(
    creatureId: 'swiftlet',
    prompt: 'What does the swiftlet make its nest from?',
    options: ['Its own spit', 'Mud and sticks', 'Seaweed'],
    answer: 0,
    explain: 'It builds a little cup of hardened spit glued to the cave wall.',
  ),
  ChoiceQuestion(
    creatureId: 'swiftlet',
    prompt: 'What is the swiftlet called in Filipino?',
    options: ['Balinsasayaw', 'Paniki', 'Maya'],
    answer: 0,
    explain: 'Filipinos call the swiftlet balinsasayaw.',
  ),
  ChoiceQuestion(
    creatureId: 'swiftlet',
    prompt: 'Some swiftlets click to find their way in dark caves, like bats.',
    options: _tf,
    answer: 0,
    explain:
        'These swiftlets make clicking sounds and listen to the echoes in '
        'the dark.',
  ),
  ChoiceQuestion(
    creatureId: 'swiftlet',
    prompt: 'When does the swiftlet fly out to find food?',
    options: ['During the day', 'Only at midnight', 'Never'],
    answer: 0,
    explain: 'It flies out in the daytime and comes back to its cave to sleep.',
  ),
  ChoiceQuestion(
    creatureId: 'swiftlet',
    prompt: 'What does a swiftlet eat?',
    options: ['Tiny insects caught in the air', 'Fruit', 'Fish'],
    answer: 0,
    explain:
        'It zooms through the air with its mouth open, catching tiny '
        'flying insects.',
  ),
  ChoiceQuestion(
    creatureId: 'swiftlet',
    prompt: 'Swiftlets are a kind of bird.',
    options: _tf,
    answer: 0,
    explain:
        'Swiftlets have feathers and lay eggs, so they are birds, not '
        'bats.',
  ),
  ChoiceQuestion(
    creatureId: 'swiftlet',
    prompt: 'Why do people collect swiftlet nests?',
    options: ['To make bird\'s nest soup', 'To build houses', 'To make paper'],
    answer: 0,
    explain:
        'The nests are cooked into a famous soup. Taking too many can '
        'leave the birds without homes.',
  ),
  ChoiceQuestion(
    creatureId: 'swiftlet',
    prompt: 'What are swiftlet wings like?',
    options: [
      'Long and pointed for fast flying',
      'Short and round',
      'It has no wings',
    ],
    answer: 0,
    explain: 'Long, thin wings let swiftlets fly fast and twist in the air.',
  ),
  ChoiceQuestion(
    creatureId: 'swiftlet',
    prompt: 'How do baby swiftlets start life?',
    options: [
      'They hatch from eggs',
      'They grow from seeds',
      'They drink milk',
    ],
    answer: 0,
    explain:
        'The mother lays her eggs in the spit nest, and the chicks hatch '
        'there.',
  ),
  PictureQuestion(
    creatureId: 'swiftlet',
    prompt: 'Which one is the swiftlet?',
    optionIds: ['kingfisher', 'swiftlet', 'fruitbat'],
    answerId: 'swiftlet',
    explain: 'The swiftlet is the little bird sitting in a cup-shaped nest.',
  ),

  // Cave cricket
  ChoiceQuestion(
    creatureId: 'cavecricket',
    prompt: 'What helps a cave cricket find its way in the dark?',
    options: ['Its super-long feelers', 'A tiny lamp', 'Its tail'],
    answer: 0,
    explain:
        'Its antennae can be longer than its body. It feels and smells '
        'its way around.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecricket',
    prompt: 'Cave crickets have wings.',
    options: _tf,
    answer: 1,
    explain: 'Most cave crickets have no wings. They get around by jumping.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecricket',
    prompt: 'How does a cave cricket move fast?',
    options: ['It jumps with its long back legs', 'It flies', 'It swims'],
    answer: 0,
    explain: 'Its long, strong back legs let it spring away from danger.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecricket',
    prompt: 'How many legs does a cave cricket have?',
    options: ['6', '8', '4'],
    answer: 0,
    explain: 'Cave crickets are insects, and all insects have six legs.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecricket',
    prompt: 'What does a cave cricket eat?',
    options: ['Almost anything it finds', 'Only flowers', 'Only fish'],
    answer: 0,
    explain:
        'Food is hard to find in caves, so it eats almost anything: '
        'bits of plants, dead bugs, and more.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecricket',
    prompt: 'Cave crickets chirp loudly like garden crickets.',
    options: _tf,
    answer: 1,
    explain:
        'Garden crickets chirp by rubbing their wings. With no wings, '
        'cave crickets stay quiet.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecricket',
    prompt: 'What kind of place do cave crickets like?',
    options: ['Dark and damp', 'Hot and sunny', 'Dry and sandy'],
    answer: 0,
    explain: 'They like cool, dark, damp places like caves and under logs.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecricket',
    prompt: 'What shape is a cave cricket\'s back?',
    options: [
      'Humped, like a little hill',
      'Flat like paper',
      'Square like a box',
    ],
    answer: 0,
    explain:
        'Its back curves up in a hump, which is why some people call it '
        'a camel cricket.',
  ),
  SortQuestion(
    creatureId: 'cavecricket',
    prompt: 'Six legs or eight legs?',
    bins: ['6 legs', '8 legs'],
    items: {'Cave cricket': 0, 'Firefly': 0, 'Whip spider': 1, 'Spider': 1},
    explain:
        'Insects like crickets and fireflies have 6 legs. Spiders and '
        'their relatives have 8.',
  ),
  PictureQuestion(
    creatureId: 'cavecricket',
    prompt: 'Which one is the cave cricket?',
    optionIds: ['whipspider', 'cavecricket', 'firefly'],
    answerId: 'cavecricket',
    explain: 'The cave cricket has a humped back and very long feelers.',
  ),

  // Whip spider
  ChoiceQuestion(
    creatureId: 'whipspider',
    prompt: 'Whip spiders have venom.',
    options: _tf,
    answer: 1,
    explain:
        'Whip spiders have no venom and are harmless to people, even '
        'though they look spooky.',
  ),
  ChoiceQuestion(
    creatureId: 'whipspider',
    prompt: 'What does a whip spider use its long front legs for?',
    options: ['Feeling around in the dark', 'Swimming', 'Spinning webs'],
    answer: 0,
    explain:
        'Its front legs are long and thin like whips. It waves them to '
        'feel and smell what\'s nearby.',
  ),
  ChoiceQuestion(
    creatureId: 'whipspider',
    prompt: 'Whip spiders spin webs to catch food.',
    options: _tf,
    answer: 1,
    explain:
        'Whip spiders make no silk. They grab insects with spiny arms '
        'near their mouth.',
  ),
  ChoiceQuestion(
    creatureId: 'whipspider',
    prompt: 'What does a whip spider eat?',
    options: ['Insects like crickets', 'Leaves', 'Fruit'],
    answer: 0,
    explain: 'It hunts small animals like cave crickets in the dark.',
  ),
  ChoiceQuestion(
    creatureId: 'whipspider',
    prompt: 'When is the whip spider active?',
    options: ['At night', 'At noon'],
    answer: 0,
    explain: 'Whip spiders hunt at night and hide in cracks during the day.',
  ),
  ChoiceQuestion(
    creatureId: 'whipspider',
    prompt: 'Why is a whip spider\'s body so flat?',
    options: ['To squeeze into narrow cracks', 'To float on water', 'To fly'],
    answer: 0,
    explain: 'A flat body lets it slip into tight cracks in the rock to hide.',
  ),
  ChoiceQuestion(
    creatureId: 'whipspider',
    prompt: 'Spiders and their relatives are called...',
    options: ['Arachnids', 'Insects', 'Mammals'],
    answer: 0,
    explain:
        'Arachnids have 8 legs. Spiders, scorpions, and whip spiders are '
        'all arachnids.',
  ),
  ChoiceQuestion(
    creatureId: 'whipspider',
    prompt: 'How many legs does a whip spider have?',
    options: ['8', '6', '10'],
    answer: 0,
    explain:
        'It has 8 legs: it walks on 6 and uses the 2 long front ones as '
        'feelers.',
  ),
  ChoiceQuestion(
    creatureId: 'whipspider',
    prompt: 'Something that looks scary is always dangerous.',
    options: _tf,
    answer: 1,
    explain:
        'The whip spider looks scary but is harmless. Still, it\'s best '
        'to just watch wild animals.',
  ),
  PictureQuestion(
    creatureId: 'whipspider',
    prompt: 'Which one is the whip spider?',
    optionIds: ['cavecricket', 'cavecrab', 'whipspider'],
    answerId: 'whipspider',
    explain: 'The whip spider has a flat body and long, whip-like legs.',
  ),

  // Cave crab
  ChoiceQuestion(
    creatureId: 'cavecrab',
    prompt: 'Why are many cave animals pale instead of colorful?',
    options: [
      'There is no sunlight in caves',
      'They are scared',
      'They wash a lot',
    ],
    answer: 0,
    explain:
        'In total darkness, bright colors don\'t help, so many cave '
        'animals are pale.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecrab',
    prompt: 'Where does the cave crab live?',
    options: ['By underground rivers', 'In the treetops', 'In the desert'],
    answer: 0,
    explain: 'It lives in the dark by rivers and pools deep inside caves.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecrab',
    prompt: 'How does a cave crab find its way?',
    options: [
      'It feels around with its long legs',
      'It looks at the stars',
      'It follows the sun',
    ],
    answer: 0,
    explain:
        'In the dark, touch matters more than sight. It feels its way '
        'with its legs and claws.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecrab',
    prompt: 'What does a cave crab eat?',
    options: [
      'Bits of food washed into the cave',
      'Fresh grass',
      'Bananas from trees',
    ],
    answer: 0,
    explain:
        'It picks up bits of leaves, dead bugs, and other food carried '
        'in by the river.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecrab',
    prompt: 'Some cave animals have tiny eyes or no eyes at all.',
    options: _tf,
    answer: 0,
    explain:
        'Eyes don\'t help much in total darkness, so some cave animals '
        'have very small eyes or none.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecrab',
    prompt: 'What protects a crab\'s soft body?',
    options: ['A hard shell', 'Fluffy fur', 'Feathers'],
    answer: 0,
    explain: 'Crabs wear their skeleton on the outside, as a hard shell.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecrab',
    prompt: 'A cave crab is a crustacean, like a shrimp.',
    options: _tf,
    answer: 0,
    explain:
        'Crabs, shrimp, and lobsters are all crustaceans with hard '
        'shells and jointed legs.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecrab',
    prompt: 'Which famous Philippine cave has a river flowing through it?',
    options: [
      'Puerto Princesa Underground River',
      'Taal Volcano',
      'Chocolate Hills',
    ],
    answer: 0,
    explain:
        'In Palawan, a river flows for kilometers through a cave. It is '
        'one of the wonders of the Philippines.',
  ),
  ChoiceQuestion(
    creatureId: 'cavecrab',
    prompt: 'Why should we keep cave rivers clean?',
    options: [
      'Cave animals need clean water',
      'To make the cave darker',
      'So the rocks can swim',
    ],
    answer: 0,
    explain:
        'Cave animals live nowhere else. Trash and dirty water can harm '
        'their only home.',
  ),
  PictureQuestion(
    creatureId: 'cavecrab',
    prompt: 'Which one is the cave crab?',
    optionIds: ['fiddlercrab', 'cavecrab', 'seastar'],
    answerId: 'cavecrab',
    explain: 'The cave crab is the pale crab with long legs.',
  ),

  // Stalactite
  ChoiceQuestion(
    creatureId: 'stalactite',
    prompt: 'A stalactite is a living thing.',
    options: _tf,
    answer: 1,
    explain:
        'A stalactite is rock. It doesn\'t eat, breathe, or have babies, '
        'so it is non-living.',
  ),
  ChoiceQuestion(
    creatureId: 'stalactite',
    prompt: 'How does a stalactite form?',
    options: [
      'Dripping water leaves tiny bits of rock',
      'It grows from a seed',
      'Bats build it',
    ],
    answer: 0,
    explain:
        'Each drop of water leaves a tiny bit of mineral behind. Drop by '
        'drop, a rock icicle grows.',
  ),
  ChoiceQuestion(
    creatureId: 'stalactite',
    prompt: 'How fast does a stalactite grow?',
    options: [
      'Very slowly, over hundreds of years',
      'A meter every day',
      'Overnight',
    ],
    answer: 0,
    explain:
        'It grows just a tiny bit each year. Big ones can be thousands of '
        'years old.',
  ),
  ChoiceQuestion(
    creatureId: 'stalactite',
    prompt: 'What grows UP from the cave floor?',
    options: ['A stalagmite', 'A stalactite', 'A rainbow'],
    answer: 0,
    explain:
        'Stalactites hang from the ceiling. Stalagmites rise up from the '
        'floor where the drips land.',
  ),
  ChoiceQuestion(
    creatureId: 'stalactite',
    prompt: 'What forms when a stalactite and a stalagmite meet?',
    options: ['A column', 'A river', 'A volcano'],
    answer: 0,
    explain:
        'When they finally touch, they join into one tall rock pillar '
        'called a column.',
  ),
  ChoiceQuestion(
    creatureId: 'stalactite',
    prompt: 'We should not touch stalactites.',
    options: _tf,
    answer: 0,
    explain:
        'Oils from our hands can stop them from growing, and they break '
        'easily. Look, but don\'t touch!',
  ),
  ChoiceQuestion(
    creatureId: 'stalactite',
    prompt: 'What kind of rock are most caves made of?',
    options: ['Limestone', 'Ice', 'Glass'],
    answer: 0,
    explain:
        'Water slowly dissolves limestone, carving out caves over a very '
        'long time.',
  ),
  ChoiceQuestion(
    creatureId: 'stalactite',
    prompt: 'Which of these is non-living?',
    options: ['A stalactite', 'A bat', 'A cave cricket'],
    answer: 0,
    explain:
        'Bats and crickets eat, grow, and have babies. A stalactite is '
        'rock.',
  ),
  SortQuestion(
    creatureId: 'stalactite',
    prompt: 'Living or non-living?',
    bins: ['Living', 'Non-living'],
    items: {'Fruit bat': 0, 'Cave crab': 0, 'Stalactite': 1, 'River water': 1},
    explain:
        'Living things grow, eat, and have young. Stalactites and water '
        'do not.',
  ),
  PictureQuestion(
    creatureId: 'stalactite',
    prompt: 'Which one is the stalactite?',
    optionIds: ['clam', 'stalactite', 'rice'],
    answerId: 'stalactite',
    explain: 'The stalactite is the rock icicle hanging down.',
  ),
];

List<Question> questionsFor(String creatureId) =>
    questions.where((q) => q.creatureId == creatureId).toList();

// ---------------------------------------------------------------------------
// Achievements
// ---------------------------------------------------------------------------

const achievements = <Achievement>[
  Achievement(
    id: 'first_catch',
    title: 'First find',
    description: 'Catch your first creature',
    gems: 10,
  ),
  Achievement(
    id: 'collector_5',
    title: 'Collector',
    description: 'Catch 5 creatures',
    gems: 20,
  ),
  Achievement(
    id: 'collector_all',
    title: 'Complete Dex',
    description: 'Catch every creature',
    gems: 150,
  ),
  Achievement(
    id: 'perfect_stage',
    title: 'Sharp eye',
    description: 'Get 3 stars on a stage',
    gems: 15,
  ),
  Achievement(
    id: 'perfect_5',
    title: 'Eagle eye',
    description: 'Get 3 stars on 5 stages',
    gems: 40,
  ),
  Achievement(
    id: 'jungle_master',
    title: 'Jungle master',
    description: 'Finish every Rainforest stage',
    gems: 50,
  ),
  Achievement(
    id: 'ocean_master',
    title: 'Ocean master',
    description: 'Finish every Ocean stage',
    gems: 50,
  ),
  Achievement(
    id: 'cave_master',
    title: 'Cave explorer',
    description: 'Finish every Cave stage',
    gems: 50,
  ),
  Achievement(
    id: 'mangrove_master',
    title: 'Mangrove guardian',
    description: 'Finish every Mangrove stage',
    gems: 50,
  ),
  Achievement(
    id: 'terraces_master',
    title: 'Terrace keeper',
    description: 'Finish every Rice Terraces stage',
    gems: 50,
  ),
  Achievement(
    id: 'night_owl',
    title: 'Night owl',
    description: 'Catch 3 creatures that come out at night',
    gems: 20,
  ),
  Achievement(
    id: 'early_bird',
    title: 'Sun seeker',
    description: 'Catch 3 creatures that come out by day',
    gems: 20,
  ),
  Achievement(
    id: 'streak_3',
    title: 'Three moons',
    description: 'Play 3 days in a row',
    gems: 25,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Full moon',
    description: 'Play 7 days in a row',
    gems: 60,
  ),
  Achievement(
    id: 'answers_50',
    title: 'Know-it-all',
    description: 'Answer 50 questions correctly',
    gems: 40,
    secret: true,
  ),
];
