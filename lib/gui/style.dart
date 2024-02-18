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

/// You can override the [LiveBirdsHandlingStyle]
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

class LiveBirdsHandlingStyle extends ThemeExtension<LiveBirdsHandlingStyle> {
  final Color backGroundColor;
  final Color machineColor;
  final Color withAwakeBirdsColor;
  final Color withBirdsBeingStunnedColor;
  final Color withStunnedBirdsColor;
  final Color withoutBirdsColor;

  LiveBirdsHandlingStyle(
      {required this.backGroundColor,
      required this.machineColor,
      required this.withAwakeBirdsColor,
      required this.withBirdsBeingStunnedColor,
      required this.withStunnedBirdsColor,
      required this.withoutBirdsColor});

  factory LiveBirdsHandlingStyle.of(BuildContext context) =>
      Theme.of(context).extension<LiveBirdsHandlingStyle>() ??
      LiveBirdsHandlingStyle.ofDefault(context);

  factory LiveBirdsHandlingStyle.ofDefault(BuildContext context) =>
      LiveBirdsHandlingStyle(
          backGroundColor: Theme.of(context).scaffoldBackgroundColor,
          machineColor:
              Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
          withAwakeBirdsColor: Colors.green,
          withBirdsBeingStunnedColor: Colors.orange,
          withStunnedBirdsColor: Colors.red,
          withoutBirdsColor: Theme.of(context).colorScheme.onBackground);

  @override
  LiveBirdsHandlingStyle copyWith({
    Color? backGroundColor,
    Color? machineColor,
    Color? withLiveBirdsColor,
    Color? withBirdsGettingStunnedColor,
    Color? withStunnedBirdsColor,
    Color? withoutBirdsColor,
  }) =>
      LiveBirdsHandlingStyle(
        backGroundColor: backGroundColor ?? this.backGroundColor,
        machineColor: machineColor ?? this.machineColor,
        withAwakeBirdsColor: withLiveBirdsColor ?? this.withAwakeBirdsColor,
        withBirdsBeingStunnedColor:
            withBirdsGettingStunnedColor ?? this.withBirdsBeingStunnedColor,
        withStunnedBirdsColor: withStunnedBirdsColor ?? this.withoutBirdsColor,
        withoutBirdsColor: withoutBirdsColor ?? this.withoutBirdsColor,
      );

  @override
  LiveBirdsHandlingStyle lerp(
      covariant ThemeExtension<LiveBirdsHandlingStyle>? other, double t) {
    if (other is! LiveBirdsHandlingStyle) {
      return this;
    }
    return LiveBirdsHandlingStyle(
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
