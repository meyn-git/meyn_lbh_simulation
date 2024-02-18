import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/gui/style.dart';

class MonitorPanel extends StatefulWidget {
  const MonitorPanel({super.key});

  @override
  State<MonitorPanel> createState() => _MonitorPanelState();
}

class _MonitorPanelState extends State<MonitorPanel> implements UpdateListener {
  String propertyText = '';

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
      itemBuilder: (context, index) => ListTile(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14))),
        tileColor:
            LiveBirdsHandlingStyle.of(context).machineColor.withOpacity(0.2),
        title: Text(objects[index].toString()),
      ),
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 6),
    );
  }

  @override
  void onUpdate() {
    setState(() {
      if (player.objectsToMonitor.isEmpty) {
        propertyText = '';
      } else {
        //TODO remember the max nr of lines per object and keep it that way so they do not jump all the time when more or less are shown
        propertyText = player.objectsToMonitor.toString();
      }
    });
  }
}
