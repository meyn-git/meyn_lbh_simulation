import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
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
  var areaWidget = createAreaWidget();

  static AreaWidget createAreaWidget() => AreaWidget(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(player.scenario.site.toString()),
        actions: [
          buildOpenButton(),
          buildRestartButton(),
          if (!player.playing) buildPlayButton(),
          if (player.playing) buildPauseButton(),
          buildSpeedButton(),
          buildInfoButton(),
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

  IconButton buildInfoButton() {
    return IconButton(
        icon: const Icon(Icons.info_outline),
        tooltip: 'Info',
        onPressed: () {
          setState(() {
            showAboutDialog(
                context: context,
                applicationLegalese: 'The 3-Clause BSD License:\n\n'
                    'Copyright 2021 Meyn Foodprocessing Technology\n\n'
                    'Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n'
                    '1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n'
                    '2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n'
                    '3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.\n\n'
                    'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.');
          });
        });
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

  Player get player => GetIt.instance<Player>();
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
    var sites = GetIt.instance<Sites>();
    for (var site in sites) {
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
          widget.scenario.area.toString(),
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
