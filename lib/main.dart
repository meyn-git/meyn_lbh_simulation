import 'package:flutter/material.dart';

import 'domain/player.dart';
import 'gui/layout.dart';

void main() {
  runApp(MyApp());
}

const title = 'Meyn Live Bird Handling Simulator';
const meynColor = Color.fromRGBO(0, 118, 90, 1);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: _createThemeData(),
      home: PlayerWidget(),
    );
  }

  ThemeData _createThemeData() {
    return ThemeData(
      primarySwatch: _createMeynMaterialColor(),
    );
  }

  MaterialColor _createMeynMaterialColor() {
    return MaterialColor(meynColor.value, {
      50: meynColor.withOpacity(0.05),
      100: meynColor.withOpacity(0.1),
      200: meynColor.withOpacity(0.2),
      300: meynColor.withOpacity(0.3),
      400: meynColor.withOpacity(0.4),
      500: meynColor.withOpacity(0.5),
      600: meynColor.withOpacity(0.6),
      700: meynColor.withOpacity(0.7),
      800: meynColor.withOpacity(0.8),
      900: meynColor.withOpacity(0.9),
    });
  }
}

class PlayerWidget extends StatefulWidget {
  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  static final player = Player();
  var layoutWidget = createLayoutWidget();

  static LayoutWidget createLayoutWidget() => LayoutWidget(key:UniqueKey(), player:player);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          actions: [
            buildRestartButton(context),
            if (!player.playing) buildPlayButton(context),
            if (player.playing) buildPauseButton(context),
            if (player.speed > 1) buildDecreaseSpeedButton(context),
            buildIncreaseSpeedButton(context),
          ],
        ),
        body: layoutWidget,
      );
  }

  IconButton buildIncreaseSpeedButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.fast_forward_rounded),
      tooltip: 'Faster (x${player.speed + 1})',
      onPressed: () {
        setState(() {
          player.increaseSpeed();
        });
      },
    );
  }

  IconButton buildDecreaseSpeedButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.fast_rewind_rounded),
      tooltip: 'Slower (x${player.speed - 1})',
      onPressed: () {
        setState(() {
          player.decreaseSpeed();
        });
      },
    );
  }

  IconButton buildPauseButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.pause_rounded),
      tooltip: 'Pause',
      onPressed: () {
        setState(() {
          player.pause();
        });
      },
    );
  }

  IconButton buildPlayButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.play_arrow_rounded),
      tooltip: 'Play',
      onPressed: () {
        setState(() {
          player.play();
        });
      },
    );
  }

  IconButton buildRestartButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.replay_rounded),
      tooltip: 'Restart',
      onPressed: () {
        setState(() {
          layoutWidget=createLayoutWidget();
        });
      },
    );
  }
}
