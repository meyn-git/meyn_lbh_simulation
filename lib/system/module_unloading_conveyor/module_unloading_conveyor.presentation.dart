import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';
import 'package:meyn_lbh_simulation/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';

class ModuleUnLoadingConveyorPainter extends ShapePainter {
  ModuleUnLoadingConveyorPainter(
      ModuleUnLoadingConveyor conveyor, LiveBirdsHandlingTheme theme)
      : super(shape: conveyor.shape, theme: theme);
}

class ModuleUnLoadingConveyorShape extends CompoundShape {
  late final OffsetInMeters centerToModuleGroupPlace;
  late final OffsetInMeters centerToModuleInLink;
  late final OffsetInMeters centerToModuleOutLink;

  static const double conveyorWidthInMeters = 1.2;
  //standard grande drawer conveyor frame width (VDL and Maxiload-twin or Omnia might be different)
  static const double frameWidthInMeters = 0.065;

  static const double taperedGuideWidthInMeters = 0.3;

  ModuleUnLoadingConveyorShape(
      ModuleUnLoadingConveyor moduleUnloadingConveyor) {
    var moduleGroupFootPrint = moduleUnloadingConveyor
        .area.productDefinition.truckRows.first.footprintOnSystem;
    var frameEast = Box(
        xInMeters: frameWidthInMeters,
        yInMeters: moduleUnloadingConveyor.lengthInMeters);
    var taperedGuideEast = Box(
        xInMeters: taperedGuideWidthInMeters,
        yInMeters: moduleGroupFootPrint.yInMeters);
    var conveyor = Box(
        xInMeters: conveyorWidthInMeters,
        yInMeters: moduleUnloadingConveyor.lengthInMeters);
    var frameWest = Box(
        xInMeters: frameWidthInMeters,
        yInMeters: moduleUnloadingConveyor.lengthInMeters);
    var taperedGuideWest = Box(
        xInMeters: taperedGuideWidthInMeters,
        yInMeters: moduleGroupFootPrint.yInMeters);

    var motor = Box(xInMeters: 0.3, yInMeters: 0.63);
    link(frameWest.centerRight, conveyor.centerLeft);
    link(conveyor.topLeft, taperedGuideWest.topRight);
    link(conveyor.centerRight, frameEast.centerLeft);
    link(conveyor.topRight, taperedGuideEast.topLeft);
    link(frameEast.topRight.addY(0.1), motor.topLeft);

    var centerToConveyorCenter =
        topLefts[conveyor]! + conveyor.centerCenter - centerCenter;
    centerToModuleGroupPlace = OffsetInMeters(
        xInMeters: centerToConveyorCenter.xInMeters,
        yInMeters: moduleGroupFootPrint.yInMeters * 0.5 - yInMeters * 0.5);
    centerToModuleInLink = OffsetInMeters(
        xInMeters: centerToConveyorCenter.xInMeters,
        yInMeters: yInMeters * 0.5);
    centerToModuleOutLink = OffsetInMeters(
        xInMeters: centerToConveyorCenter.xInMeters,
        yInMeters: yInMeters * -0.5);
  }
}
