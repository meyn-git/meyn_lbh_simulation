import 'package:flutter/material.dart';

import '/domain/player.dart';
import '/gui/layout.dart';

class PlayerWidget extends StatefulWidget {
  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  static final player = Player();
  var layoutWidget = createLayoutWidget();

  static LayoutWidget createLayoutWidget() =>
      LayoutWidget(key: UniqueKey(), player: player);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          buildRestartButton(),
          if (!player.playing) buildPlayButton(),
          if (player.playing) buildPauseButton(),
          buildSpeedButton(),
          SizedBox(width: 40,),
        ],
      ),
      body: layoutWidget,
    );
  }

  IconButton buildPauseButton() {
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

  IconButton buildPlayButton() {
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

  IconButton buildRestartButton() {
    return IconButton(
      icon: const Icon(Icons.replay_rounded),
      tooltip: 'Restart',
      onPressed: () {
        setState(() {
          layoutWidget = createLayoutWidget();
        });
      },
    );
  }

  buildSpeedButton() {
    return SpeedDropDownButton(player);
  }
}

/// This is the stateful widget that the main application instantiates.
class SpeedDropDownButton extends StatefulWidget {
  final Player player;

  const SpeedDropDownButton(this.player);

  @override
  State<SpeedDropDownButton> createState() => _SpeedDropDownButtonState(player);
}

/// This is the private State class that goes with MyStatefulWidget.
class _SpeedDropDownButtonState extends State<SpeedDropDownButton> {
  final Player player;

  _SpeedDropDownButtonState(this.player);

  @override
  Widget build(BuildContext context) {
    var values = <int>[for (int i = 1; i <= 64; i=i+i) i];
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: 1,
        iconSize: 0,
        elevation: 16,
        style: const TextStyle(color: Colors.black),
        onChanged: (int? newValue) {
          if (newValue != null) {
            setState(() {
              player.speed = newValue;
            });
          }
        },
        selectedItemBuilder: (BuildContext context) {
          return values.map((int value) {
            return Row(
              children: [
                Icon(Icons.speed_rounded),
                Text(
                  'x${player.speed}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            );
          }).toList();
        },
        items: values.map<DropdownMenuItem<int>>((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Row(
              children: [
                Icon(Icons.speed_rounded, color: Colors.black),
                Text('x$value'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
