import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/partners.dart';
import '../data/rewards.dart';

/// What happened in a finished stage, passed back to [GameState].
class StageResult {
  const StageResult({
    required this.stageId,
    required this.stars,
    required this.correct,
    required this.found,
    required this.caught,
  });

  final String stageId;
  final int stars;
  final int correct;
  final int found;
  final List<String> caught;
}

/// The player's saved progress. Everything is stored on the phone, so the
/// app works offline.
class GameState extends ChangeNotifier {
  GameState(this._prefs) {
    _load();
  }

  static Future<GameState> load() async =>
      GameState(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const correctPerEvolution = 20;
  static const missionCatches = 2;
  static const missionAnswers = 10;
  static const missionStages = 1;
  static const missionReward = 30;

  String name = '';
  int grade = 3;
  int xp = 0;
  int gems = 0;
  int correctTotal = 0;
  Map<String, int> stars = {};
  Set<String> caught = {};
  Set<String> unlocked = {};
  List<String> playDays = [];

  String missionDate = '';
  int missionFound = 0;
  int missionAnswered = 0;
  int missionStagesDone = 0;
  bool missionRewarded = false;

  /// One-time celebrations for screens to play once, then clear. They are
  /// kept in memory only.
  ///
  /// Habitat id -> how many of its stages were done before the latest
  /// newly finished stage, so the map can light the trail from there.
  final Map<String, int> pendingTrail = {};

  /// True when today's play just added a night to the streak.
  bool streakBumped = false;

  /// Moon gifts just earned, waiting to be shown on the home screen.
  final List<Reward> pendingGifts = [];

  // Rewards ----------------------------------------------------------------

  static const gemsPerNewCreature = 10;

  /// Reward ids the kid owns. The classic parols are always owned.
  Set<String> owned = {defaultParol};

  /// Outfit slot name -> item id currently worn by the partner.
  Map<String, String> outfit = {};
  String parolId = defaultParol;

  List<String> get outfitItems => outfit.values.toList();
  ParolStyle get parolStyle => parolStyleOf(parolId);

  bool owns(String id) =>
      owned.contains(id) || (rewardById[id]?.isFree ?? false);

  bool isWearing(String id) => outfit.containsValue(id);

  bool canAfford(Reward r) => (r.price ?? 1 << 30) <= gems;

  /// Buys [r] with gems. Returns false if it can't be bought.
  Future<bool> buy(Reward r) async {
    if (owns(r.id) || r.price == null || !canAfford(r)) return false;
    gems -= r.price!;
    owned.add(r.id);
    await _save();
    notifyListeners();
    return true;
  }

  /// Puts on an outfit item, or hangs a parol design. Wearing an item that
  /// is already on takes it off.
  Future<void> equip(Reward r) async {
    if (!owns(r.id)) return;
    if (r.kind == RewardKind.parol) {
      parolId = r.id;
    } else {
      final slot = r.slot!.name;
      if (outfit[slot] == r.id) {
        outfit.remove(slot);
      } else {
        outfit[slot] = r.id;
      }
    }
    await _save();
    notifyListeners();
  }

  /// A creature's card is shiny once a stage it hides in gets 3 stars.
  bool isShiny(String creatureId) =>
      caught.contains(creatureId) &&
      stages.any(
        (st) => st.creatureIds.contains(creatureId) && (stars[st.id] ?? 0) == 3,
      );

  void _awardMoonGifts() {
    final s = streak();
    for (final r in rewards.where((r) => r.isGift)) {
      if (s >= r.giftStreak! && owned.add(r.id)) pendingGifts.add(r);
    }
  }

  bool get hasProfile => name.isNotEmpty;
  int get level => xp ~/ 100 + 1;
  int get xpIntoLevel => xp % 100;
  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  // Partner creature --------------------------------------------------------

  /// The partner the kid chose. Kids who started before partners existed
  /// keep Tarsi.
  String partnerId = defaultPartner;

  /// Names the kid gave to partners, by partner id. Kept per partner, so
  /// switching back brings the old name back too.
  Map<String, String> partnerNames = {};

  Partner get partner => partnerOf(partnerId);
  String get partnerName => partnerNameOf(partnerId);
  String partnerNameOf(String id) {
    final custom = partnerNames[id]?.trim() ?? '';
    return custom.isEmpty ? partnerOf(id).name : custom;
  }

  /// Switches to another partner. Always free, and the outfit carries over.
  Future<void> choosePartner(String id, {String? name}) async {
    if (!partnerById.containsKey(id)) return;
    partnerId = id;
    if (name != null) _setPartnerName(id, name);
    await _save();
    notifyListeners();
  }

  Future<void> renamePartner(String name) async {
    _setPartnerName(partnerId, name);
    await _save();
    notifyListeners();
  }

  void _setPartnerName(String id, String name) {
    final n = name.trim();
    if (n.isEmpty || n == partnerOf(id).name) {
      partnerNames.remove(id);
    } else {
      partnerNames[id] = n;
    }
  }

  static const partnerStages = ['Baby', 'Young', 'Grown', 'Elder'];
  int get partnerStage =>
      (correctTotal ~/ correctPerEvolution).clamp(0, partnerStages.length - 1);
  String get partnerStageName => partnerStages[partnerStage];
  bool get partnerMaxed => partnerStage == partnerStages.length - 1;
  int get answersToEvolve =>
      correctPerEvolution - correctTotal % correctPerEvolution;
  double get evolveProgress =>
      (correctTotal % correctPerEvolution) / correctPerEvolution;

  // Unlocking ---------------------------------------------------------------

  bool isStageDone(String stageId) => (stars[stageId] ?? 0) > 0;

  bool isHabitatUnlocked(Habitat h) {
    if (h.comingSoon) return false;
    final i = habitats.indexOf(h);
    if (i == 0) return true;
    final prev = habitats[i - 1];
    return prev.stageIds.every(isStageDone);
  }

  bool isStageUnlocked(Stage s) {
    final h = habitatById[s.habitatId]!;
    if (!isHabitatUnlocked(h)) return false;
    final i = h.stageIds.indexOf(s.id);
    return i == 0 || isStageDone(h.stageIds[i - 1]);
  }

  /// The first unlocked stage that isn't finished yet, for the Continue card.
  Stage? get nextStage {
    for (final h in habitats) {
      for (final id in h.stageIds) {
        final s = stageById[id]!;
        if (isStageUnlocked(s) && !isStageDone(id)) return s;
      }
    }
    return null;
  }

  // Streak ------------------------------------------------------------------

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool playedOn(DateTime d) => playDays.contains(dayKey(d));

  /// Days in a row played, counting back from today (or yesterday, so the
  /// streak isn't lost before you've had a chance to play today).
  int streak([DateTime? now]) {
    final n = now ?? DateTime.now();
    var day = DateTime(n.year, n.month, n.day);
    if (!playedOn(day)) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (playedOn(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  // Daily mission -----------------------------------------------------------

  void _rollMission() {
    final today = dayKey(DateTime.now());
    if (missionDate == today) return;
    missionDate = today;
    missionFound = 0;
    missionAnswered = 0;
    missionStagesDone = 0;
    missionRewarded = false;
  }

  bool get missionComplete =>
      missionFound >= missionCatches &&
      missionAnswered >= missionAnswers &&
      missionStagesDone >= missionStages;

  // Actions -----------------------------------------------------------------

  Future<void> createProfile(
    String newName,
    int newGrade, {
    String partner = defaultPartner,
    String? partnerName,
  }) async {
    name = newName.trim();
    grade = newGrade;
    partnerId = partnerById.containsKey(partner) ? partner : defaultPartner;
    if (partnerName != null) _setPartnerName(partnerId, partnerName);
    await _save();
    notifyListeners();
  }

  /// Saves a finished stage. Returns achievements unlocked by it.
  Future<List<Achievement>> recordStage(StageResult r) async {
    _rollMission();
    final today = dayKey(DateTime.now());
    if (!playDays.contains(today)) {
      playDays.add(today);
      streakBumped = true;
    }

    final best = stars[r.stageId] ?? 0;
    if (best == 0 && r.stars > 0) {
      final h = habitatById[stageById[r.stageId]!.habitatId]!;
      pendingTrail.putIfAbsent(
        h.id,
        () => h.stageIds.where(isStageDone).length,
      );
    }
    if (r.stars > best) {
      gems += (r.stars - best) * 5;
      stars[r.stageId] = r.stars;
    }
    xp += r.correct * 10 + r.caught.length * 25;
    correctTotal += r.correct;
    final newCreatures = r.caught.where((id) => !caught.contains(id)).length;
    gems += newCreatures * gemsPerNewCreature;
    caught.addAll(r.caught);
    _awardMoonGifts();

    missionFound += r.found;
    missionAnswered += r.correct;
    if (r.stars > 0) missionStagesDone++;
    if (missionComplete && !missionRewarded) {
      missionRewarded = true;
      gems += missionReward;
    }

    final fresh = _checkAchievements();
    await _save();
    notifyListeners();
    return fresh;
  }

  List<Achievement> _checkAchievements() {
    // Only living things count toward the day and night badges.
    int caughtWhere(bool Function(ActiveTime) test) => caught.where((id) {
      final c = creatureById[id]!;
      return c.alive && test(c.time);
    }).length;
    bool habitatDone(String id) => habitatById[id]!.stageIds.every(isStageDone);

    final earned = <String, bool>{
      'first_catch': caught.isNotEmpty,
      'collector_5': caught.length >= 5,
      'collector_all': caught.length == creatures.length,
      'perfect_stage': stars.values.any((s) => s == 3),
      'perfect_5': stars.values.where((s) => s == 3).length >= 5,
      'jungle_master': habitatDone('rainforest'),
      'ocean_master': habitatDone('ocean'),
      'terraces_master': habitatDone('terraces'),
      'mangrove_master': habitatDone('mangrove'),
      'cave_master': habitatDone('cave'),
      // Creatures out day and night count toward both.
      'night_owl': caughtWhere((t) => t.outAtNight) >= 3,
      // Keeps its old id so players who earned "Early bird" keep it as
      // "Sun seeker".
      'early_bird': caughtWhere((t) => t.outByDay) >= 3,
      'streak_3': streak() >= 3,
      'streak_7': streak() >= 7,
      'answers_50': correctTotal >= 50,
    };
    final fresh = <Achievement>[];
    for (final a in achievements) {
      if ((earned[a.id] ?? false) && unlocked.add(a.id)) fresh.add(a);
    }
    return fresh;
  }

  // Practice and tips ---------------------------------------------------------

  /// Questions answered wrong and not yet answered right, oldest first.
  /// Saved as [reviewKey]s.
  List<String> toReview = [];

  /// Tips the player has already seen, like how to use the flashlight.
  Set<String> seenTips = {};

  static const reviewCap = 30;

  /// Gems for each question fixed in a practice round.
  static const gemsPerFix = 2;

  /// A stable name for a question, so it survives app updates that add
  /// more questions.
  static String reviewKey(Question q) => '${q.creatureId}|${q.prompt}';

  /// The saved questions still waiting for practice, newest first.
  List<Question> get reviewQuestions {
    final byKey = {for (final q in questions) reviewKey(q): q};
    return [for (final k in toReview.reversed) ?byKey[k]];
  }

  /// Remembers a wrong answer for practice, or clears it once it's right.
  Future<void> noteAnswer(Question q, bool correct) async {
    final key = reviewKey(q);
    final had = toReview.remove(key);
    if (!correct) {
      toReview.add(key);
      if (toReview.length > reviewCap) toReview.removeAt(0);
    } else if (!had) {
      return;
    }
    await _save();
    notifyListeners();
  }

  /// Ends a practice round, with gems for each question fixed.
  Future<void> finishReview(int fixed) async {
    gems += fixed * gemsPerFix;
    await _save();
    notifyListeners();
  }

  bool hasSeenTip(String id) => seenTips.contains(id);

  // Badge rewards ------------------------------------------------------------

  /// Badges whose gems have been collected.
  Set<String> claimed = {};

  bool canClaim(Achievement a) =>
      unlocked.contains(a.id) && !claimed.contains(a.id);

  /// Earned badges with gems still waiting, for the dot on the Badges tab.
  int get unclaimedCount => achievements.where(canClaim).length;

  /// Collects a badge's gems. Returns how many were added (0 if none).
  Future<int> claimBadge(Achievement a) async {
    if (!canClaim(a)) return 0;
    claimed.add(a.id);
    gems += a.gems;
    await _save();
    notifyListeners();
    return a.gems;
  }

  Future<void> markTipSeen(String id) async {
    if (!seenTips.add(id)) return;
    await _save();
  }

  Future<void> rename(String newName) async {
    if (newName.trim().isEmpty) return;
    name = newName.trim();
    await _save();
    notifyListeners();
  }

  Future<void> setGrade(int newGrade) async {
    grade = newGrade;
    await _save();
    notifyListeners();
  }

  /// Erases progress but keeps settings, like music and text size.
  Future<void> resetProgress() async {
    for (final key in _prefs.getKeys().toList()) {
      if (!key.startsWith('setting.') && key != 'musicMuted') {
        await _prefs.remove(key);
      }
    }
    _load();
    notifyListeners();
  }

  // Storage -----------------------------------------------------------------

  void _load() {
    final p = _prefs;
    name = p.getString('name') ?? '';
    grade = p.getInt('grade') ?? 3;
    xp = p.getInt('xp') ?? 0;
    gems = p.getInt('gems') ?? 0;
    correctTotal = p.getInt('correctTotal') ?? 0;
    stars = (jsonDecode(p.getString('stars') ?? '{}') as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
    caught = (p.getStringList('caught') ?? []).toSet();
    unlocked = (p.getStringList('achievements') ?? []).toSet();
    playDays = p.getStringList('playDays') ?? [];
    missionDate = p.getString('missionDate') ?? '';
    missionFound = p.getInt('missionFound') ?? 0;
    missionAnswered = p.getInt('missionAnswered') ?? 0;
    missionStagesDone = p.getInt('missionStages') ?? 0;
    missionRewarded = p.getBool('missionRewarded') ?? false;
    owned = {defaultParol, ...?p.getStringList('owned')};
    outfit = (jsonDecode(p.getString('outfit') ?? '{}') as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
    parolId = p.getString('parol') ?? defaultParol;
    partnerId = p.getString('partner') ?? defaultPartner;
    partnerNames = (jsonDecode(
      p.getString('partnerNames') ?? '{}',
    ) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String));
    toReview = p.getStringList('toReview') ?? [];
    seenTips = (p.getStringList('seenTips') ?? []).toSet();
    claimed = (p.getStringList('claimedBadges') ?? []).toSet();
    pendingGifts.clear();
    _rollMission();
  }

  Future<void> _save() async {
    final p = _prefs;
    await Future.wait([
      p.setString('name', name),
      p.setInt('grade', grade),
      p.setInt('xp', xp),
      p.setInt('gems', gems),
      p.setInt('correctTotal', correctTotal),
      p.setString('stars', jsonEncode(stars)),
      p.setStringList('caught', caught.toList()),
      p.setStringList('achievements', unlocked.toList()),
      p.setStringList('playDays', playDays),
      p.setString('missionDate', missionDate),
      p.setInt('missionFound', missionFound),
      p.setInt('missionAnswered', missionAnswered),
      p.setInt('missionStages', missionStagesDone),
      p.setBool('missionRewarded', missionRewarded),
      p.setStringList('owned', owned.toList()),
      p.setString('outfit', jsonEncode(outfit)),
      p.setString('parol', parolId),
      p.setString('partner', partnerId),
      p.setString('partnerNames', jsonEncode(partnerNames)),
      p.setStringList('toReview', toReview),
      p.setStringList('seenTips', seenTips.toList()),
      p.setStringList('claimedBadges', claimed.toList()),
    ]);
  }
}

/// Makes [GameState] available to every screen and rebuilds them on change.
class GameScope extends InheritedNotifier<GameState> {
  /// [state] is null while saved progress is still loading.
  const GameScope({super.key, required GameState? state, required super.child})
    : super(notifier: state);

  static GameState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameScope>()!.notifier!;

  /// Like [of], but null before the game has loaded.
  static GameState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameScope>()?.notifier;
}
