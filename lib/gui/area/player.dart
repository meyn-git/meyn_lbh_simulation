import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/domain/authorization/authorization.dart';
import 'package:meyn_lbh_simulation/domain/site/scenario.dart';
import 'package:meyn_lbh_simulation/domain/site/site.dart';
import 'package:meyn_lbh_simulation/gui/area/area.dart';
import 'package:meyn_lbh_simulation/gui/area/monitor_panel.dart';
import 'package:meyn_lbh_simulation/gui/login/login.dart';
import 'package:meyn_lbh_simulation/main.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(applicationTitle),
        actions: [
          buildRestartButton(),
          if (!player.playing) buildPlayButton(),
          if (player.playing) buildPauseButton(),
          buildSpeedButton(),
          const SizedBox(width: 40),
        ],
      ),
      drawer: const Menu(),
      body: PlayerPanel(),
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

class PlayerPanel extends StatelessWidget {
  final player = GetIt.instance<Player>();
  final areaPanel = AreaPanel(key: UniqueKey());

  PlayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (_tooSmallForExtraPanels(constraints)) {
        return areaPanel;
      } else {
        return Row(
          children: [
            Expanded(child: areaPanel),
            const SizedBox(
                width: _minimumSizeForExtraPanels, child: MonitorPanel())
          ],
        );
      }
    });
  }

  static const _minimumSizeForExtraPanels = 400.0;

  bool _tooSmallForExtraPanels(BoxConstraints constraints) =>
      constraints.maxWidth < (_minimumSizeForExtraPanels * 2);
}

class ScenarioTile extends StatefulWidget {
  final Scenario scenario;
  final Player player;

  const ScenarioTile(this.scenario, this.player, {super.key});

  @override
  State<ScenarioTile> createState() => _ScenarioTileState();
}

class _ScenarioTileState extends State<ScenarioTile> {
  @override
  Widget build(BuildContext context) => ListTile(
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(_createText()),
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

  String _createText() => '${widget.scenario.area.lineName}\n'
      '${widget.scenario.area.productDefinition.birdType}\n'
      '${widget.scenario.area.productDefinition.lineSpeedInShacklesPerHour}b/h ${widget.scenario.area.productDefinition.moduleGroupCapacities.join(' ')}';
}

class SiteTile extends StatelessWidget {
  final Site site;

  const SiteTile(this.site, {super.key});

  String get _emailSubject => 'Invitation to the $applicationTitle';

  String get _emailBody => 'Dear Madam or Sir,\n\n'
      'We would like to invite you to look at the: $applicationTitle.\n\n'
      'Please:\n'
      '- Open it on the following link: https://meyn-git.github.io/meyn_lbh_simulation_web/\n'
      '- Enter the following name: ${AuthorizationService.userNameForSite(site)}\n'
      '- Enter the following password: ${AuthorizationService.passwordForSite(site)}\n\n'
      'You can:\n'
      '- select different scenarios with the menu if applicable (open and close with the ☰ button on the top left)\n'
      '- start, pause, and increase the speed with the buttons on the top right\n\n'
      'Kind regards,\n\n'
      'The Meyn life bird handling team';

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(
          _createText(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: _isAdmin
            ? IconButton(
                icon: const Icon(Icons.mail_outline),
                tooltip: 'Send invitation e-mail',
                onPressed: () {
                  _sendEmail();
                },
              )
            : null,
      );

  String _createText() => '${site.meynLayoutCode}-${site.organizationName}\n'
      '${site.city}-${site.country}';

  Future<void> _sendEmail() async {
    Uri emailUrl = _createEmailUrl();
    await launchUrl(emailUrl);
  }

  bool get _isAdmin => GetIt.instance<AuthorizationService>().isAdmin;

  Uri _createEmailUrl() => Uri.parse(
      Uri.encodeFull('mailto:?subject=$_emailSubject&body=$_emailBody'));
}

class SpeedDropDownButton extends StatefulWidget {
  final Player player;

  const SpeedDropDownButton(this.player, {super.key});

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
        style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
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
                  style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor),
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
                Icon(Icons.speed_rounded,
                    color: Theme.of(context).colorScheme.onBackground),
                Text('x$value'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  Player get _player => GetIt.instance<Player>();

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) => Drawer(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Menu'),
          ),
          body: Scrollbar(
            thumbVisibility: true,
            controller: _scrollController,
            child: ListView(
              padding: EdgeInsets.zero,
              controller: _scrollController,
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: const Text('Logout'),
                  onTap: () {
                    setState(() {
                      _hideMenu(context);
                      _logout(context);
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () {
                    setState(() {
                      _hideMenu(context);
                      _showAboutDialog();
                    });
                  },
                ),
                ..._createListItems(_player),
              ],
            ),
          ),
        ),
      );

  void _hideMenu(BuildContext context) {
    Navigator.pop(context);
  }

  void _showAboutDialog() => showAboutDialog(
      context: context,
      applicationLegalese: 'The 3-Clause BSD License:\n\n'
          'Copyright 2021 Meyn Food Processing Technology\n\n'
          'Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n'
          '1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n'
          '2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n'
          '3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.\n\n'
          'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.');

  void _logout(BuildContext context) {
    var authorizationService = GetIt.instance<AuthorizationService>();
    authorizationService.logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  List<Widget> _createListItems(Player player) {
    List<Widget> listItems = [];
    var sites = GetIt.instance<AuthorizationService>().sitesThatCanBeViewed;
    for (var site in sites) {
      listItems.add(SiteTile(site));
      for (var scenario in site.scenarios) {
        listItems.add(ScenarioTile(scenario, player));
      }
    }
    return listItems;
  }
}
