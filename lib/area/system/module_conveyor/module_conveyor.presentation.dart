import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class ModuleConveyorPainter extends ShapePainter {
  ModuleConveyorPainter(ModuleConveyor conveyor, LiveBirdsHandlingTheme theme)
      : super(shape: conveyor.shape, theme: theme);
}

class ModuleConveyorShape extends CompoundShape {
  late final OffsetInMeters centerToConveyorEnd;
  late final OffsetInMeters centerToModuleInLink;
  late final OffsetInMeters centerToModuleOutLink;

  static const double conveyorWidthInMeters = 1.2;
  //standard grande drawer conveyor frame width (VDL and Maxiload-twin or Omnia might be different)
  static const double frameWidthInMeters = 0.065;

  ModuleConveyorShape(ModuleConveyor moduleConveyor) {
    var moduleGroupSurface =
        moduleConveyor.area.productDefinition.truckRows.first.footprintOnSystem;
    var frameEast = Box(
        xInMeters: frameWidthInMeters,
        yInMeters: moduleConveyor.lengthInMeters);
    var conveyor = Box(
        xInMeters: conveyorWidthInMeters,
        yInMeters: moduleConveyor.lengthInMeters);
    var frameWest = Box(
        xInMeters: frameWidthInMeters,
        yInMeters: moduleConveyor.lengthInMeters);

    var motor = Box(xInMeters: 0.3, yInMeters: 0.63);
    link(frameWest.centerRight, conveyor.centerLeft);
    link(conveyor.centerRight, frameEast.centerLeft);
    link(frameEast.topRight.addY(0.1), motor.topLeft);
    var centerToConveyorCenter =
        topLefts[conveyor]! + conveyor.centerCenter - centerCenter;
    centerToConveyorEnd = OffsetInMeters(
        xInMeters: centerToConveyorCenter.xInMeters,
        yInMeters: yInMeters * -0.5 + moduleGroupSurface.yInMeters * 0.5 + 0.1);
    centerToModuleInLink = OffsetInMeters(
        xInMeters: centerToConveyorCenter.xInMeters,
        yInMeters: yInMeters * 0.5);
    centerToModuleOutLink = OffsetInMeters(
        xInMeters: centerToConveyorCenter.xInMeters,
        yInMeters: yInMeters * -0.5);
  }
}
