import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleDeStackerPainter extends ShapePainter {
  ModuleDeStackerPainter(
      ModuleDeStacker deStacker, LiveBirdsHandlingTheme theme)
      : super(shape: deStacker.shape, theme: theme);
}

class ModuleDeStackerShape extends CompoundShape {
  static const double lengthInMeters = 3.4;

  late final Box conveyor;

  ModuleDeStackerShape() {
    var northEastLeg = Box(xInMeters: 0.3, yInMeters: 0.3);
    var southEastLeg = Box(xInMeters: 0.3, yInMeters: 0.3);
    var southWestLeg = Box(xInMeters: 0.3, yInMeters: 0.3);
    var northWestLeg = Box(xInMeters: 0.3, yInMeters: 0.3);
    var liftFrame = Box(xInMeters: 1.661, yInMeters: lengthInMeters);
    var westConveyorFrame = Box(
        xInMeters: ModuleConveyorShape.frameWidthInMeters,
        yInMeters: lengthInMeters);
    conveyor = Box(
        xInMeters: ModuleConveyorShape.conveyorWidthInMeters,
        yInMeters: lengthInMeters);
    var eastConveyorFrame = Box(
        xInMeters: ModuleConveyorShape.frameWidthInMeters,
        yInMeters: lengthInMeters);

    link(liftFrame.centerCenter, conveyor.centerCenter);
    link(liftFrame.topRight, northEastLeg.topLeft);
    link(liftFrame.bottomRight, southEastLeg.bottomLeft);
    link(liftFrame.bottomLeft, southWestLeg.bottomRight);
    link(liftFrame.topLeft, northWestLeg.topRight);
    link(conveyor.centerLeft, westConveyorFrame.centerRight);
    link(conveyor.centerRight, eastConveyorFrame.centerLeft);
  }

  late final OffsetInMeters centerToConveyorCenter =
      topLefts[conveyor]! + conveyor.centerCenter - centerCenter;

  late final OffsetInMeters centerToSupportsCenter =
      centerToConveyorCenter.addX(0.1)..addY(0.1);

  late final OffsetInMeters centerToModuleGroupOutLink =
      centerToConveyorCenter.addY(lengthInMeters * -0.5);

  late final OffsetInMeters centerToModuleGroupInLink =
      centerToConveyorCenter.addY(lengthInMeters * 0.5);
}
