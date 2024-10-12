import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_row_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';

class DrawerBalance implements Detailable {
  final LiveBirdHandlingArea area;

  late ModuleGroupRoute? routeBetweenUnloaderAndLoader =
      findRouteBetweenUnloaderAndLoader(area);

  DrawerBalance(this.area);

  @override
  final String name = 'DrawerBalance';

  final Map<int, String> drawersContainers = {
    4: '1: 1x4L 0x5L',
    5: '1: 0x4L 1x5L',
    8: '2: 2x4L 0x5L',
    9: '2: 1x4L 1x5L',
    10: '2: 0x4L 2x5L',
    13: '3: 2x4L 1x5L',
    14: '3: 1x4L 2x5L',
    18: '4: 2x4L 2x5L',
    22: '5: 3x4L 2x5L',
    23: '5: 2x4L 3x5L',
    26: '6: 4x4L 2x5L',
    27: '6: 3x4L 3x5L',
    28: '6: 2x4L 4x5L',
  };
  @override
  ObjectDetails get objectDetails {
    // var modulesWithoutDrawers = area.moduleGroups
    //     .map((group) => group.modules.where((module) => module.nrOfBirds == 0))
    //     .expand((m) => m);
    var objectDetails = ObjectDetails(name);
    var numberOfDrawers = area.drawers.length;
    objectDetails.appendProperty('drawers', numberOfDrawers);

    if (routeBetweenUnloaderAndLoader != null) {
      var systems = routeBetweenUnloaderAndLoader!.systems;
      var modules = area.moduleGroups
          .where((moduleGroup) => atOrBetweenSystem(systems, moduleGroup))
          .map((moduleGroup) => moduleGroup.modules)
          .expand((module) => module)
          .toList();
      if (modules.isNotEmpty) {
        var emptyDrawerSpots =
            modules.map((m) => m.variant.levels).reduce((a, b) => a + b);
        objectDetails
          ..appendProperty('drawer spots in empty modules', emptyDrawerSpots)
          ..appendProperty('equal',
              numberOfDrawers == emptyDrawerSpots ? 'OK' : '!!! NOT EQUAL !!!')
          ..appendProperty(
              'empty modules',
              '${modules.length} '
                  '${modules.where((m) => m.variant.levels == 4).length}x4L '
                  '${modules.where((m) => m.variant.levels == 5).length}x5L ');
        // ..appendProperty('empty 4L modules',
        //     modules.where((m) => m.variant.levels == 4).length)
        // ..appendProperty('empty 5L modules',
        //     modules.where((m) => m.variant.levels == 5).length);
      }
    }
    return objectDetails;
  }

  ModuleGroupRoute? findRouteBetweenUnloaderAndLoader(
      LiveBirdHandlingArea area) {
    var moduleDrawerColumnUnloader =
        area.systems.whereType<ModuleDrawerColumnUnloader>().firstOrNull;
    var moduleDrawerRowUnloader =
        area.systems.whereType<ModuleDrawerRowUnloader>().firstOrNull;
    var modulesOut = moduleDrawerColumnUnloader?.modulesOut ??
        moduleDrawerRowUnloader?.modulesOut;
    var moduleDrawerLoader =
        area.systems.whereType<ModuleDrawerLoader>().firstOrNull;
    if (modulesOut != null && moduleDrawerLoader != null) {
      return modulesOut.findRoute(destination: moduleDrawerLoader);
    }
    return null;
  }

  atOrBetweenSystem(List<PhysicalSystem> systems, ModuleGroup moduleGroup) {
    var position = moduleGroup.position;
    if (position is AtModuleGroupPlace) {
      var system = position.place.system;
      return systems.contains(system);
    }
    if (position is BetweenModuleGroupPlaces) {
      var source = position.source.system;
      var destination = position.destination.system;
      return systems.contains(source) && source is! ModuleDrawerLoader ||
          systems.contains(destination) &&
              destination is! ModuleDrawerColumnUnloader &&
              destination is! ModuleDrawerRowUnloader;
    }
    return false;
  }
}
