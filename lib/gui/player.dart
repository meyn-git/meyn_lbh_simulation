import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/life_bird_handling_area.dart';
import '/domain/player.dart';
import '/gui/area.dart';

class PlayerWidget extends StatefulWidget {
  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  static final player = Player();
  var areaWidget = createAreaWidget();

  static AreaWidget createAreaWidget() =>
      AreaWidget(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(player.area.name),
        actions: [
          buildOpenButton(),
          buildRestartButton(),
          if (!player.playing) buildPlayButton(),
          if (player.playing) buildPauseButton(),
          buildSpeedButton(),
          SizedBox(width: 40,),
        ],
      ),
      body: areaWidget,
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

  IconButton buildOpenButton() {
    return IconButton(
      icon: const Icon(Icons.folder_open_rounded),
      tooltip: 'Open other $LiveBirdHandlingArea',
      onPressed: () {
        setState(() {
          player.restartOtherArea();
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
          player.restart();
        });
      },
    );
  }

  buildSpeedButton() {
    return SpeedDropDownButton(player);
  }
}

class SpeedDropDownButton extends StatefulWidget {
  final Player player;

  const SpeedDropDownButton(this.player);

  @override
  State<SpeedDropDownButton> createState() => _SpeedDropDownButtonState(player);
}

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


