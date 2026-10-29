import 'package:flutter/material.dart';

import 'data/models.dart';
import 'widgets/celebrations.dart';

/// Paper lantern night: navy night sky, cream paper, and warm parol light.
abstract final class AppColors {
  // Night
  static const sky = Color(0xFF1B1E4B);
  static const deep = Color(0xFF12143A);
  static const track = Color(0xFF2C3170);
  static const hill = Color(0xFF2A3A7A);

  // Paper
  static const cream = Color(0xFFF6EAD0);
  static const ink = Color(0xFF3B2A14);
  static const inkMuted = Color(0xFF7A6A52);

  // Lantern colors
  static const orange = Color(0xFFF08A3C);
  static const red = Color(0xFFE5574A);
  static const gold = Color(0xFFF2B23C);
  static const pink = Color(0xFFF2A7B5);
  static const blue = Color(0xFF9FD3E6);

  // Text on the night sky
  static const text = Color(0xFFFFF4DC);
  static const muted = Color(0xFFCBC4E8);

  // Feedback
  static const heart = Color(0xFFFF9C7A);
  static const right = Color(0xFFB9E08F);
  static const wrong = Color(0xFFF4A49A);
  static const rightInk = Color(0xFF2F6B2A);
  static const wrongInk = Color(0xFFA3362B);

  // Leaves, dark to light
  static const leaf1 = Color(0xFF1C6A48);
  static const leaf2 = Color(0xFF2A7F56);
  static const leaf3 = Color(0xFF3A9563);
  static const leaf4 = Color(0xFF5BB174);
}

/// Sky colors and how hidden the search scene is for each time of day.
class TimeLook {
  const TimeLook(this.top, this.bottom, this.darkness);
  final Color top;
  final Color bottom;

  /// Opacity of the darkness outside the flashlight beam, or of the haze
  /// outside the magnifying glass by day.
  final double darkness;

  static TimeLook of(ActiveTime t) => switch (t) {
    ActiveTime.day => const TimeLook(
      Color(0xFF8FCDEB),
      Color(0xFFE4F4E4),
      0.55,
    ),
    // Scenes are only ever drawn as day or night; this is a fallback.
    ActiveTime.dayAndNight => of(ActiveTime.night),
    ActiveTime.dawn => const TimeLook(
      Color(0xFF3A4A8C),
      Color(0xFFF2B36B),
      0.86,
    ),
    ActiveTime.dusk => const TimeLook(
      Color(0xFF3B2A6B),
      Color(0xFFC0607A),
      0.9,
    ),
    ActiveTime.night => const TimeLook(
      Color(0xFF1B1E4B),
      Color(0xFF2C3170),
      0.96,
    ),
  };
}

IconData timeIcon(ActiveTime t) => switch (t) {
  ActiveTime.dawn || ActiveTime.dusk => Icons.wb_twilight_rounded,
  ActiveTime.night => Icons.nightlight_round,
  ActiveTime.day => Icons.wb_sunny_rounded,
  ActiveTime.dayAndNight => Icons.brightness_6_rounded,
};

/// Display text in the rounded paper-cut font. Leave [color] out to inherit
/// cream on the night sky or ink on paper.
TextStyle display(double size, {Color? color}) => TextStyle(
  fontFamily: 'Sniglet',
  fontSize: size,
  fontWeight: FontWeight.w800,
  color: color,
  height: 1.1,
);

const bodyFont = 'Atkinson Hyperlegible';

ThemeData buildTheme() {
  final body = ThemeData.dark().textTheme.apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  OutlineInputBorder border(Color c, [double w = 2]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(color: c, width: w),
  );

  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: bodyFont,
    scaffoldBackgroundColor: AppColors.sky,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,
      onPrimary: AppColors.cream,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
      error: AppColors.red,
    ),
    textTheme: body,
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.cream,
      titleTextStyle: TextStyle(color: AppColors.ink),
      contentTextStyle: TextStyle(color: AppColors.ink, fontSize: 16),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      dragHandleColor: AppColors.inkMuted,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.orange,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cream,
      hintStyle: const TextStyle(color: AppColors.inkMuted),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(AppColors.orange, 3),
    ),
    // Screens turn like journal pages.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PageTurnTransitionsBuilder(),
        TargetPlatform.iOS: PageTurnTransitionsBuilder(),
        TargetPlatform.windows: PageTurnTransitionsBuilder(),
        TargetPlatform.macOS: PageTurnTransitionsBuilder(),
        TargetPlatform.linux: PageTurnTransitionsBuilder(),
        TargetPlatform.fuchsia: PageTurnTransitionsBuilder(),
      },
    ),
  );
}
