import 'package:flutter/material.dart';

const meynColor = Color.fromRGBO(0, 118, 90, 1);
ThemeData createTheme(Brightness brightness) => ThemeData(
      colorScheme:
          ColorScheme.fromSeed(seedColor: meynColor, brightness: brightness),
      appBarTheme: const AppBarTheme(
        //iconTheme: IconThemeData(color: Colors.white),
        color: meynColor,
        foregroundColor: Colors.white,
      ),
    );

/// You can override the [LiveBirdsHandlingTheme]
/// by adding the following to the [ThemeData]:
///
/// LiveBirdsHandlingStyle: <ThemeExtension<dynamic>>[
///   AreaPanelStyle(
///       machineColor: Colors.black,
///       withLiveBirdsColor: Colors.green,
///       withBirdsGettingStunnedColor: Colors.orange,
///       withStunnedBirdsColor: Colors.red,
///       withoutBirdsColor: Colors.black)
/// ],
///
/// see https://api.flutter.dev/flutter/material/ThemeExtension-class.html

class LiveBirdsHandlingTheme extends ThemeExtension<LiveBirdsHandlingTheme> {
  final Color backGroundColor;
  final Color machineColor;
  final Color withAwakeBirdsColor;
  final Color withBirdsBeingStunnedColor;
  final Color withStunnedBirdsColor;
  final Color withoutBirdsColor;

  LiveBirdsHandlingTheme(
      {required this.backGroundColor,
      required this.machineColor,
      required this.withAwakeBirdsColor,
      required this.withBirdsBeingStunnedColor,
      required this.withStunnedBirdsColor,
      required this.withoutBirdsColor});

  LiveBirdsHandlingTheme.fromMainTheme(ThemeData theme)
      : this(
            backGroundColor: theme.scaffoldBackgroundColor,
            machineColor: theme.colorScheme.onSurface.withOpacity(0.8),
            withAwakeBirdsColor: Colors.green,
            withBirdsBeingStunnedColor: Colors.orange,
            withStunnedBirdsColor: Colors.red,
            withoutBirdsColor: theme.colorScheme.onSurface);

  @override
  LiveBirdsHandlingTheme copyWith({
    Color? backGroundColor,
    Color? machineColor,
    Color? withLiveBirdsColor,
    Color? withBirdsGettingStunnedColor,
    Color? withStunnedBirdsColor,
    Color? withoutBirdsColor,
  }) =>
      LiveBirdsHandlingTheme(
        backGroundColor: backGroundColor ?? this.backGroundColor,
        machineColor: machineColor ?? this.machineColor,
        withAwakeBirdsColor: withLiveBirdsColor ?? withAwakeBirdsColor,
        withBirdsBeingStunnedColor:
            withBirdsGettingStunnedColor ?? withBirdsBeingStunnedColor,
        withStunnedBirdsColor: withStunnedBirdsColor ?? this.withoutBirdsColor,
        withoutBirdsColor: withoutBirdsColor ?? this.withoutBirdsColor,
      );

  @override
  LiveBirdsHandlingTheme lerp(
      covariant ThemeExtension<LiveBirdsHandlingTheme>? other, double t) {
    if (other is! LiveBirdsHandlingTheme) {
      return this;
    }
    return LiveBirdsHandlingTheme(
        backGroundColor: Color.lerp(backGroundColor, other.backGroundColor, t)!,
        machineColor: Color.lerp(machineColor, other.machineColor, t)!,
        withAwakeBirdsColor:
            Color.lerp(withAwakeBirdsColor, other.withAwakeBirdsColor, t)!,
        withBirdsBeingStunnedColor: Color.lerp(
            withBirdsBeingStunnedColor, other.withBirdsBeingStunnedColor, t)!,
        withStunnedBirdsColor:
            Color.lerp(withStunnedBirdsColor, other.withStunnedBirdsColor, t)!,
        withoutBirdsColor:
            Color.lerp(withoutBirdsColor, other.withoutBirdsColor, t)!);
  }
}

extension LiveBirdsHandlingThemeExtension on ThemeData {
  LiveBirdsHandlingTheme get liveBirdsHandling =>
      extension<LiveBirdsHandlingTheme>() ??
      LiveBirdsHandlingTheme.fromMainTheme(this);
}
