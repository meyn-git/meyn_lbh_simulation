import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/area/name.domain.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/player.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';
import 'package:user_command/user_command.dart';

class MonitorPanel extends StatefulWidget {
  const MonitorPanel({super.key});

  @override
  State<MonitorPanel> createState() => _MonitorPanelState();
}

class _MonitorPanelState extends State<MonitorPanel> implements UpdateListener {
  Player get player => GetIt.instance<Player>();

  @override
  void initState() {
    player.addUpdateListener(this);
    super.initState();
  }

  @override
  void dispose() {
    player.removeUpdateListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var objects = player.objectsToMonitor.toList();
    return ListView.separated(
      padding: const EdgeInsets.all(6),
      itemCount: objects.length,
      itemBuilder: (context, index) => MonitorTile(objects[index]),
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 6),
    );
  }

  @override
  void onUpdate() {
    setState(() {
      // updates tiles
    });
  }
}

class MonitorTile extends StatelessWidget {
  final Object objectToMonitor;
  const MonitorTile(this.objectToMonitor, {super.key});

  @override
  Widget build(BuildContext context) {
    var name = _name();
    return ListTile(
      onTap: () {
        if (objectToMonitor is Commandable) {
          CommandPopupMenu(
            context,
            (objectToMonitor as Commandable).commands,
            title: name,
          );
        }
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      tileColor: Theme.of(
        context,
      ).liveBirdsHandling.machineColor.withAlpha((255.0 * 0.2).round()),
      title: Text(name),
      subtitle: subTitleWidget,
    );
  }

  String _name() {
    if (objectToMonitor is Namable) {
      return (objectToMonitor as Namable).name;
    } else {
      return objectToMonitor
          .toString()
          .replaceAll(RegExp(r'Instance of '), '')
          .replaceAll(RegExp('\n.*'), '')
          .replaceAll(RegExp('\''), '');
    }
  }

  Widget? get subTitleWidget => objectToMonitor is DetailProvider
      ? Text(subTitle, softWrap: false)
      : null;

  String get subTitle =>
      (objectToMonitor as DetailProvider).objectDetails.propertiesToString(0);
}
