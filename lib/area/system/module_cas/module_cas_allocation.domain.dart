import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:user_command/user_command.dart';

import '../../area.domain.dart';
import '../../module/module.domain.dart';

/// Allocates the destination of a [ModuleGroup] of a given location depending on the
/// state of the [ModuleCas] units and transport modules between this position
/// and the [ModuleCas] units
class ModuleCasAllocation implements System, TimeProcessor {
  final LiveBirdHandlingArea area;

  @override
  late String name = 'ModuleCasAllocation';

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  final ModuleGroupPlace allocationPlace;
  late final List<ModuleGroupRoute> _routesToCasUnits = _findRoutesToCasUnits();

  ModuleCasAllocation({
    required this.area,
    required this.allocationPlace,
  });

  @override
  onUpdateToNextPointInTime(Duration jump) {
    var moduleGroupToAllocate = allocationPlace.moduleGroup;
    if (moduleGroupToAllocate == null) {
      return;
    }
    var destination = casWithHighestScore;
    if (destination != null) {
      moduleGroupToAllocate.destination = destination;
    }
  }

  @override
  ObjectDetails get objectDetails {
    var destination = casWithHighestScore;
    return ObjectDetails(name).appendProperty(
        'destination', destination == null ? 'none' : destination.name);
  }

  @override
  String toString() => objectDetails.toString();

  List<ModuleGroupRoute> _findRoutesToCasUnits() {
    var routesToCasUnits = <ModuleGroupRoute>[];
    var source = allocationPlace.system as LinkedSystem;
    var sourceOutLinks = source.links.whereType<ModuleGroupOutLink>();
    for (var sourceOutLink in sourceOutLinks) {
      for (var casUnit in allModuleCasUnits) {
        var route = sourceOutLink.findRoute(
          destination: casUnit,
        );
        if (route != null) {
          routesToCasUnits.add(route);
        }
      }
    }

    return routesToCasUnits;
  }

  late final Iterable<ModuleCas> allModuleCasUnits =
      area.systems.whereType<ModuleCas>();

  ModuleCas? get casWithHighestScore {
    double highScore = 0;
    ModuleCas? casWithHighestScore;
    for (var route in _routesToCasUnits) {
      var score = route.casNewStackScore;
      if (score > highScore) {
        highScore = score;
        casWithHighestScore = route.cas;
      }
    }

    if (highScore == 0) {
      return null;
    } else {
      return casWithHighestScore;
    }
  }
}
