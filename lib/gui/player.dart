import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/scenario.dart';
import 'package:meyn_lbh_simulation/domain/site.dart';

import '/domain/player.dart';
import '/gui/area.dart';

class PlayerWidget extends StatefulWidget {
  const PlayerWidget({Key? key}) : super(key: key);

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  static final player = Player();
  var areaWidget = createAreaWidget();

  static AreaWidget createAreaWidget() => AreaWidget(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(player.scenario.nameWithSite),
        actions: [
          buildOpenButton(),
          buildRestartButton(),
          if (!player.playing) buildPlayButton(),
          if (player.playing) buildPauseButton(),
          buildSpeedButton(),
          const SizedBox(
            width: 40,
          ),
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
          showDialog(
              context: context,
              builder: (BuildContext b) {
                return ProjectSelectionDialog(player);
              });
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

class ProjectSelectionDialog extends StatelessWidget {
  final Player player;

  const ProjectSelectionDialog(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Select project'),
        content: SizedBox(
          height: 300.0, // Change as per your requirement
          width: 300.0, // Change as per your requirement
          child: ListView(
            // shrinkWrap: true,
            // physics: AlwaysScrollableScrollPhysics(),
            children: _createListItems(player),
          ),
        ),
      );

  List<Widget> _createListItems(Player player) {
    List<Widget> listItems = [];

    for (var site in Sites()) {
      listItems.add(SiteTile(site));
      for (var scenario in site.scenarios) {
        listItems.add(ScenarioTile(scenario, player));
      }
    }
    return listItems;
  }
}

class ScenarioTile extends StatefulWidget {
  final Scenario scenario;
  final Player player;

  const ScenarioTile(this.scenario, this.player, {Key? key}) : super(key: key);

  @override
  State<ScenarioTile> createState() => _ScenarioTileState();
}

class _ScenarioTileState extends State<ScenarioTile> {
  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(
          widget.scenario.nameWithoutSite,
        ),
        onTap: () {
          setState(() {
            _closeDialog(context);
            widget.player.start(widget.scenario);
          });
        },
      );

  void _closeDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class SiteTile extends StatelessWidget {
  final Site site;

  const SiteTile(this.site, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => ListTile(
        title: Align(
          child: Text(
            site.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          alignment: const Alignment(-1.6, 0),
        ),
      );
}

class SpeedDropDownButton extends StatefulWidget {
  final Player player;

  const SpeedDropDownButton(this.player, {Key? key}) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State<SpeedDropDownButton> createState() => _SpeedDropDownButtonState(player);
}

class _SpeedDropDownButtonState extends State<SpeedDropDownButton> {
  final Player player;

  _SpeedDropDownButtonState(this.player);

  @override
  Widget build(BuildContext context) {
    var values = <int>[for (int i = 1; i <= 64; i = i + i) i];
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
                const Icon(Icons.speed_rounded),
                Text(
                  'x${player.speed}',
                  style: const TextStyle(color: Colors.white),
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
                const Icon(Icons.speed_rounded, color: Colors.black),
                Text('x$value'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
