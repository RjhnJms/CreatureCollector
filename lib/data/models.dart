import 'package:flutter/widgets.dart';

/// When a creature is active. Decides its search scene, so kids learn which
/// animals come out at night and which by day: night searches use a
/// flashlight in the dark, day searches a magnifying glass in the sun.
enum ActiveTime {
  dawn,
  dusk,
  night,
  day,

  /// Out at any hour. Each search is randomly a day or a night one.
  dayAndNight,
}

extension ActiveTimeLabel on ActiveTime {
  String get label => switch (this) {
    ActiveTime.dawn => 'Dawn',
    ActiveTime.dusk => 'Dusk',
    ActiveTime.night => 'Night',
    ActiveTime.day => 'Day',
    ActiveTime.dayAndNight => 'Day & night',
  };

  /// For the Dex card, like "Active at night".
  String get activeLabel => switch (this) {
    ActiveTime.dawn => 'Active at dawn',
    ActiveTime.dusk => 'Active at dusk',
    ActiveTime.night => 'Active at night',
    ActiveTime.day => 'Active by day',
    ActiveTime.dayAndNight => 'Active day & night',
  };

  bool get outAtNight =>
      this == ActiveTime.night || this == ActiveTime.dayAndNight;
  bool get outByDay => this == ActiveTime.day || this == ActiveTime.dayAndNight;
}

enum Rarity { common, rare, legendary }

class Creature {
  const Creature({
    required this.id,
    required this.name,
    required this.localName,
    required this.habitatId,
    required this.time,
    required this.rarity,
    required this.kind,
    required this.fact,
    required this.color,
    this.sound,
    this.silentReason,
    this.alive = true,
  });

  final String id;
  final String name;

  /// Filipino name, shown under the English name on the Dex card.
  final String localName;
  final String habitatId;
  final ActiveTime time;
  final Rarity rarity;

  /// Short label like "Mammal" or "Plant".
  final String kind;

  /// Fun fact shown on the catch screen and the Dex card.
  final String fact;

  /// Main body color, used by placeholder art until real art is added.
  final Color color;

  /// A real recording of its call, if we have one.
  final CreatureSound? sound;

  /// For creatures that make no sound people can hear: why, in one kid-
  /// friendly line. Shown on the Dex card where the Listen button would be.
  final String? silentReason;

  /// False for things in the Dex that aren't living, like a stalactite.
  /// They show "Not living" instead of when they're active.
  final bool alive;
}

/// A recording of an animal's real call, bundled under assets/sounds/.
class CreatureSound {
  const CreatureSound({
    required this.file,
    required this.credit,
    this.maxSeconds,
  });

  /// File name inside assets/sounds/.
  final String file;

  /// Who recorded it and its license, shown under the Listen button. The
  /// Creative Commons licenses require this credit.
  final String credit;

  /// Stop playing after this long, for long recordings. The file itself is
  /// left whole, since some licenses ("ND") don't allow cutting it.
  final int? maxSeconds;
}

class Habitat {
  const Habitat({
    required this.id,
    required this.name,
    required this.blurb,
    required this.color,
    required this.stageIds,
    this.comingSoon = false,
    this.time = ActiveTime.night,
  });

  final String id;
  final String name;
  final String blurb;
  final Color color;
  final List<String> stageIds;
  final bool comingSoon;

  /// Time of day its map card and stage path are drawn at.
  final ActiveTime time;
}

class Stage {
  const Stage({
    required this.id,
    required this.habitatId,
    required this.number,
    required this.title,
    required this.topic,
    required this.creatureIds,
    this.isBoss = false,
  });

  final String id;
  final String habitatId;
  final int number;
  final String title;
  final String topic;

  /// Creatures hidden in this stage. A boss stage has none: it is a review quiz.
  final List<String> creatureIds;
  final bool isBoss;
}

/// Base type for every question. [creatureId] links the question to the
/// creature it is about, so stages can pull the right questions.
sealed class Question {
  const Question({
    required this.creatureId,
    required this.prompt,
    required this.explain,
  });

  final String creatureId;
  final String prompt;

  /// Shown after answering, right or wrong, so every answer teaches something.
  final String explain;
}

/// Multiple choice. True/false questions are a choice with two options.
class ChoiceQuestion extends Question {
  const ChoiceQuestion({
    required super.creatureId,
    required super.prompt,
    required super.explain,
    required this.options,
    required this.answer,
  });

  final List<String> options;
  final int answer;

  bool get isTrueFalse =>
      options.length == 2 && options[0] == 'True' && options[1] == 'False';
}

/// Tap the right creature picture.
class PictureQuestion extends Question {
  const PictureQuestion({
    required super.creatureId,
    required super.prompt,
    required super.explain,
    required this.optionIds,
    required this.answerId,
  });

  final List<String> optionIds;
  final String answerId;
}

/// Put each item into the right group.
class SortQuestion extends Question {
  const SortQuestion({
    required super.creatureId,
    required super.prompt,
    required super.explain,
    required this.bins,
    required this.items,
  });

  final List<String> bins;

  /// Item label -> index into [bins].
  final Map<String, int> items;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.gems,
    this.secret = false,
  });

  final String id;
  final String title;
  final String description;

  /// Gems the player can claim once the badge is earned. Harder badges
  /// pay more.
  final int gems;
  final bool secret;
}
