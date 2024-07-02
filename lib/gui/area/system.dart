import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_row_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter_dump_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/gui/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/loading_fork_lift_truck.dart';
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
import 'package:meyn_lbh_simulation/gui/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class MachineWidget extends StatelessWidget {
  final SystemLayout layout;
  final PhysicalSystem system;

  MachineWidget(this.layout, this.system) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return RotationTransition(
        turns: AlwaysStoppedAnimation(layout.rotationOf(system).toFraction()),
        child: CustomPaint(painter: createSystemPainter(system, theme)));
  }
}

CustomPainter createSystemPainter(
    PhysicalSystem system, LiveBirdsHandlingTheme theme) {
  if (system is LoadingForkLiftTruck) {
    return LoadingForkLiftTruckPainter(theme);
  }
  if (system is UnLoadingForkLiftTruck) {
    return UnLoadingForkLiftTruckPainter(theme);
  }
  if (system is ModuleConveyor) {
    return ModuleConveyorPainter(system, theme);
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
