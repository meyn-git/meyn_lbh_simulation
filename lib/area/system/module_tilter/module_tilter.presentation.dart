import 'package:meyn_lbh_simulation/area/system/system.domain.dart';

import 'module_tilter.domain.dart';
import '../shape.presentation.dart';
import '../../../theme.presentation.dart';

class ModuleTilterPainter extends ShapePainter {
  ModuleTilterPainter(ModuleTilter tilter, LiveBirdsHandlingTheme theme)
      : super(shape: tilter.shape, theme: theme);
}

class ModuleTilterShape extends CompoundShape {
  static const double lengthInMeters = 3.88;

  late final Box conveyor;
  late final OffsetInMeters centerToBirdsOutLink;

  ModuleTilterShape(ModuleTilter tilter) {
    var pivotFrame1 = Box(xInMeters: 0.75, yInMeters: 0.35);
    var pivotFrame2 = Box(xInMeters: 0.75, yInMeters: 0.35);
    var leftConveyorFrame = Box(xInMeters: 0.25, yInMeters: lengthInMeters);
    conveyor = Box(xInMeters: 1.35, yInMeters: lengthInMeters);
    var rightConveyorFrame = Box(xInMeters: 0.25, yInMeters: lengthInMeters);
    var platform = Box(xInMeters: 0.75, yInMeters: lengthInMeters);
    if (tilter.tiltDirection == Direction.counterClockWise) {
      link(leftConveyorFrame.centerRight, conveyor.centerLeft);
      link(conveyor.centerRight, rightConveyorFrame.centerLeft);
      link(rightConveyorFrame.centerRight, platform.centerLeft);
      link(leftConveyorFrame.bottomLeft.addY(-0.25), pivotFrame1.bottomRight);
      link(leftConveyorFrame.topLeft.addY(0.25), pivotFrame2.topRight);
      centerToBirdsOutLink = topLefts[leftConveyorFrame]! +
          leftConveyorFrame.centerLeft -
          centerCenter;
    } else {
      link(platform.centerRight, leftConveyorFrame.centerLeft);
      link(leftConveyorFrame.centerRight, conveyor.centerLeft);
      link(conveyor.centerRight, rightConveyorFrame.centerLeft);
      link(rightConveyorFrame.bottomRight.addY(-0.25), pivotFrame1.bottomLeft);
      link(rightConveyorFrame.topRight.addY(0.25), pivotFrame2.topLeft);
      centerToBirdsOutLink = topLefts[rightConveyorFrame]! +
          rightConveyorFrame.centerRight -
          centerCenter;
    }
  }

  late final OffsetInMeters centerToConveyorCenter =
      topLefts[conveyor]! + conveyor.centerCenter - centerCenter;

  late final OffsetInMeters centerToModuleGroupOutLink =
      centerToConveyorCenter.addY(lengthInMeters * -0.5);

  late final OffsetInMeters centerToModuleGroupInLink =
      centerToConveyorCenter.addY(lengthInMeters * 0.5);
}
