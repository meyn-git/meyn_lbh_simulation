import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_shuttle/module_suttle.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_shuttle/module_suttle.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_buffer_lane/module_buffer_lane.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_allocation.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_start.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_row_unloader/module_drawer_row_unloader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter_dump_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/player.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shackle_conveyor/shackle_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_loader/module_drawer_loader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_column_unloader/module_drawer_column_unloader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/fork_lift_truck.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_buffer_lane/module_buffer_lane.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_loader/module_drawer_loader.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_column_unloader/module_drawer_column_unloader.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_row_unloader/module_drawer_row_unloader.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter_dump_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/shackle_conveyor/shackle_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck_route.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck_route.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class SystemWidget extends StatelessWidget {
  final SystemLayout layout;
  final VisibleSystem system;

  SystemWidget(this.layout, this.system) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return Listener(
      onPointerDown: (_) => monitor(system),
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(layout.rotationOf(system).toFraction()),
        //TODO fix so that it is not continously creating new painers
        child: CustomPaint(painter: createSystemPainter(system, theme)),
      ),
    );
  }

  monitor(VisibleSystem system) {
    var player = GetIt.instance<Player>();
    var systems = player.scenario!.area.systems;
    List<Object> objectsToMonitor = [
      system,
      ...relatedObjectsToMonitor(systems, system),
    ];
    player.objectsToMonitor.addAll(objectsToMonitor);
  }

  List<Detailable> relatedObjectsToMonitor(
    List<System> systems,
    VisibleSystem selectedSystem,
  ) {
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
  VisibleSystem system,
  LiveBirdsHandlingTheme theme,
) {
  if (system is TruckRoutes) {
    return TruckRoutesPainter(system, theme);
  }
  if (system is BoxTruck) {
    return TruckPainter(system, theme);
  }
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
  if (system is ModuleUnLoadingConveyor) {
    return ModuleUnLoadingConveyorPainter(system, theme);
  }
  if (system is ModuleRotatingConveyor) {
    return ModuleRotatingConveyorPainter(system, theme);
  }
  if (system is ModuleShuttle) {
    return ModuleShuttlePainter(system, theme);
  }
  if (system is ModuleShuttleCarrier) {
    return ModuleShuttleCarrierPainter(system, theme);
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
