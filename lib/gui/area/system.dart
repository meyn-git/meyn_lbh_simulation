import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/system/module_loading_conveyor/module_loading_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/system/vehicle/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/domain/area/module_buffer_lane.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_row_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter_dump_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_washer.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/domain/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/system/vehicle/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/gui/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/system/vehicle/fork_lift_truck.presentation.dart';
import 'package:meyn_lbh_simulation/gui/area/module_buffer_lane.dart';
import 'package:meyn_lbh_simulation/gui/area/module_cas.dart';
import 'package:meyn_lbh_simulation/gui/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_row_unloader.dart';
import 'package:meyn_lbh_simulation/gui/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/gui/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/gui/area/module_tilter_dump_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/module_washer.dart';
import 'package:meyn_lbh_simulation/gui/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class SystemWidget extends StatelessWidget {
  final SystemLayout layout;
  final PhysicalSystem system;

  SystemWidget(this.layout, this.system) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return Listener(
      onPointerDown: (_) => monitor(system),
      child: RotationTransition(
          turns: AlwaysStoppedAnimation(layout.rotationOf(system).toFraction()),
          //TODO fix so that it is not continously creating new painers
          child: CustomPaint(painter: createSystemPainter(system, theme))),
    );
  }

  monitor(PhysicalSystem system) {
    var player = GetIt.instance<Player>();
    var systems = player.scenario!.area.systems;
    List<Object> objectsToMonitor = [
      system,
      ...relatedObjectsToMonitor(systems, system)
    ];
    player.objectsToMonitor.addAll(objectsToMonitor);
  }

  List<Detailable> relatedObjectsToMonitor(
      List<System> systems, PhysicalSystem selectedSystem) {
    var relatedObjects = <Detailable>[];
    if (selectedSystem is ModuleCas) {
      relatedObjects.addAll(systems.whereType<ModuleCasStart>());
    }
    for (var moduleCasAllocation in systems.whereType<ModuleCasAllocation>()) {
      if (system == moduleCasAllocation.allocationPlace.system) {
        relatedObjects.add(moduleCasAllocation);
      }
    }
    return relatedObjects;
  }
}

CustomPainter createSystemPainter(
    PhysicalSystem system, LiveBirdsHandlingTheme theme) {
  if (system is LoadingForkLiftTruck) {
    return LoadingForkLiftTruckPainter(system, theme);
  }
  if (system is UnLoadingForkLiftTruck) {
    return UnLoadingForkLiftTruckPainter(system, theme);
  }
  if (system is ModuleConveyor) {
    return ModuleConveyorPainter(system, theme);
  }
  if (system is ModuleLoadingConveyor) {
    return ModuleLoadingConveyorPainter(system, theme);
  }
  if (system is ModuleRotatingConveyor) {
    return ModuleRotatingConveyorPainter(system, theme);
  }
  if (system is ModuleCas) {
    return ModuleCasPainter(system, theme);
  }
  if (system is ModuleStacker) {
    return ModuleStackerPainter(system, theme);
  }
  if (system is ModuleDeStacker) {
    return ModuleDeStackerPainter(system, theme);
  }
  if (system is ModuleTilter) {
    return ModuleTilterPainter(system, theme);
  }
  if (system is ModuleDrawerColumnUnloader) {
    return ModuleDrawerColumnUnloaderPainter(system, theme);
  }
  if (system is DrawerUnloaderLift) {
    return DrawerUnloaderLiftPainter(system, theme);
  }
  if (system is ModuleDrawerRowUnloader) {
    return ModuleDrawerRowUnloaderPainter(system, theme);
  }
  if (system is ModuleDrawerRowUnloaderReceiver) {
    return ModuleDrawerRowUnloaderReceiverPainter(system, theme);
  }
  if (system is ModuleDrawerLoader) {
    return ModuleDrawerLoaderPainter(system, theme);
  }
  if (system is ModuleTilterDumpConveyor) {
    return ModuleTilterDumpConveyorPainter(system, theme);
  }
  if (system is ModuleWasherConveyor) {
    return ModuleWasherConveyorPainter(system, theme);
  }

  if (system is ModuleBufferSystem) {
    return ModuleBufferSystemPainter(system, theme);
  }

  if (system is ShackleConveyor) {
    return ShackleConveyorPainter(system, theme);
  }

  if (system is DrawerLoaderLift) {
    return DrawerLoaderLiftPainter(system, theme);
  }

  if (system is DrawerConveyorStraight) {
    return DrawerConveyorStraightPainter(system, theme);
  }
  if (system is DrawerConveyor90Degrees) {
    return DrawerConveyor90DegreePainter(system, theme);
  }
  throw Exception('Not supported system: ${system.runtimeType}');
}
