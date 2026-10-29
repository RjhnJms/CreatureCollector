import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/onboarding_screen.dart';
import 'screens/shell.dart';
import 'services/music.dart';
import 'state/game_state.dart';
import 'state/settings.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/startup_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The bundled fonts' Open Font License, shown on Flutter's licenses page.
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in [
      ('Sniglet', 'OFL-Sniglet.txt'),
      ('Atkinson Hyperlegible', 'OFL-AtkinsonHyperlegible.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$file');
      yield LicenseEntryWithLineBreaks([font], text);
    }
  });
  runApp(const CreatureCollectorApp());
}

class CreatureCollectorApp extends StatefulWidget {
  const CreatureCollectorApp({super.key});

  @override
  State<CreatureCollectorApp> createState() => _CreatureCollectorAppState();
}

class _CreatureCollectorAppState extends State<CreatureCollectorApp> {
  GameState? _game;
  bool _ready = false;
  final _introDone = Completer<void>();

  @override
  void initState() {
    super.initState();
    // Load saved progress while the startup screen plays: the developer
    // credits pop out, then the parols light up. Move on only when both the
    // loading and the animation are done.
    final loading =
        Future.wait([GameState.load(), Settings.instance.load()])
            .then((r) => r.first as GameState)
          ..then((g) {
            if (mounted) setState(() => _game = g);
          });
    Future.wait([loading, _introDone.future]).then((_) {
      if (mounted) setState(() => _ready = true);
      Music.instance.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final app = MaterialApp(
      title: 'Creature Collector',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Large text and calm motion from Settings, on top of the phone's own.
      builder: (context, child) => ListenableBuilder(
        listenable: Settings.instance,
        builder: (context, _) {
          final s = Settings.instance;
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              disableAnimations: mq.disableAnimations || s.calmMotion,
              textScaler: s.largeText
                  ? TextScaler.linear(mq.textScaler.scale(1) * 1.15)
                  : mq.textScaler,
            ),
            child: child!,
          );
        },
      ),
      home: game == null || !_ready
          ? Scaffold(
              body: NightSky(
                child: SafeArea(
                  child: StartupLoader(
                    onFinished: () {
                      if (!_introDone.isCompleted) _introDone.complete();
                    },
                  ),
                ),
              ),
            )
          : ListenableBuilder(
              listenable: game,
              builder: (context, _) =>
                  game.hasProfile ? const Shell() : const OnboardingScreen(),
            ),
    );
    // Always in the tree, even before loading finishes, so the app isn't
    // rebuilt from scratch (restarting the startup screen) when it loads.
    return Listener(
      // Browsers block sound until the first tap; start the music then.
      onPointerDown: (_) => Music.instance.onUserTap(),
      child: GameScope(state: game, child: app),
    );
  }
}
