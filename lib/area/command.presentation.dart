import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/area/player.domain.dart';
import 'package:user_command/user_command.dart';

abstract class Commandable {
  List<Command> get commands;
}

// class AddToMonitorPanel extends Command {
//   final Object objectToMonitor;
//   AddToMonitorPanel(this.objectToMonitor)
//       : super.dynamic(
//             name: () => 'Monitor',
//             icon: () => Icons.monitor,
//             visible: () => !GetIt.instance
//                 .get<Player>()
//                 .objectsToMonitor
//                 .contains(objectToMonitor),
//             action: () => GetIt.instance
//                 .get<Player>()
//                 .objectsToMonitor
//                 .add(objectToMonitor));
// }

class RemoveFromMonitorPanel extends Command {
  final Object objectToMonitor;
  RemoveFromMonitorPanel(this.objectToMonitor)
      : super.dynamic(
            name: () => 'Stop monitoring',
            icon: () => Icons.delete,
            visible: () => GetIt.instance
                .get<Player>()
                .objectsToMonitor
                .contains(objectToMonitor),
            action: () => GetIt.instance
                .get<Player>()
                .objectsToMonitor
                .remove(objectToMonitor));
}
