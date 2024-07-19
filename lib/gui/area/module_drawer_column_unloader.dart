import 'package:meyn_lbh_simulation/domain/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleDrawerColumnUnloaderPainter extends ShapePainter {
  ModuleDrawerColumnUnloaderPainter(
      ModuleDrawerColumnUnloader drawerUnloader, LiveBirdsHandlingTheme theme)
      : super(shape: drawerUnloader.shape, theme: theme);
}

class ModuleDrawerColumnUnloaderShape extends CompoundShape {
  late final OffsetInMeters centerToConveyorCenter;
  late final OffsetInMeters centerToModuleInLink;
  late final OffsetInMeters centerToModuleOutLink;
  late final OffsetInMeters centerToFirstColumn;
  late final OffsetInMeters centerToSecondColumn;
  late final OffsetInMeters centerToDrawersOutLink;

//TODO assumption
  static const lengthInMeters = 2.75 * 1.5;

  /// Most of this is constructor is a copy from the [ModuleConveyorShape]
  ModuleDrawerColumnUnloaderShape(ModuleDrawerColumnUnloader drawerUnloader) {
    var moduleGroupLength = drawerUnloader
        .area.productDefinition.moduleFamily.footprintSingleModule.yInMeters;
    var frameEast = Box(
        xInMeters: ModuleConveyorShape.frameWidthInMeters,
        yInMeters: lengthInMeters);
    var conveyor = Box(
        xInMeters: ModuleConveyorShape.conveyorWidthInMeters,
        yInMeters: lengthInMeters);
    var frameWest = Box(
        xInMeters: ModuleConveyorShape.frameWidthInMeters,
        yInMeters: lengthInMeters);
    var pusherFrame = Box(xInMeters: 2.9, yInMeters: 1.6);

    var motor = Box(xInMeters: 0.3, yInMeters: 0.63);
    link(frameWest.centerRight, conveyor.centerLeft);
    link(conveyor.centerRight, frameEast.centerLeft);
    link(frameEast.topRight.addY(0.1), motor.topLeft);
    if (drawerUnloader.drawerOutDirection == Direction.counterClockWise) {
      link(frameEast.centerRight, pusherFrame.centerLeft);
    } else {
      link(frameWest.centerLeft, pusherFrame.centerRight);
    }

    centerToConveyorCenter =
        topLefts[conveyor]! + conveyor.centerCenter - centerCenter;
    centerToFirstColumn = centerToConveyorCenter.addY(moduleGroupLength * 0.25);
    centerToSecondColumn =
        centerToConveyorCenter.addY(moduleGroupLength * -0.25);
    centerToModuleInLink = OffsetInMeters(
        xInMeters: centerToConveyorCenter.xInMeters,
        yInMeters: yInMeters * 0.5);
    centerToModuleOutLink = OffsetInMeters(
        xInMeters: centerToConveyorCenter.xInMeters,
        yInMeters: yInMeters * -0.5);
    centerToDrawersOutLink =
        (drawerUnloader.drawerOutDirection == Direction.counterClockWise
                ? topLefts[frameWest]! + frameWest.centerLeft
                : topLefts[frameEast]! + frameEast.centerRight) -
            centerCenter;
  }
}

class DrawerUnloaderLiftPainter extends ShapePainter {
  DrawerUnloaderLiftPainter(
      DrawerUnloaderLift drawerUnloaderLift, LiveBirdsHandlingTheme theme)
      : super(shape: drawerUnloaderLift.shape, theme: theme);
}

class DrawerUnloaderLiftShape extends Box {
  late final int nrOfLiftPositions;

  DrawerUnloaderLiftShape(DrawerUnloaderLift drawerUnloaderLift)
      : super(xInMeters: 1.5, yInMeters: 1.6) {
    nrOfLiftPositions = drawerUnloaderLift.levels;
  }

  late final OffsetInMeters centerToDrawersInLink = bottomCenter - centerCenter;
  late final OffsetInMeters centerToDrawerOutLink = topCenter - centerCenter;
  late final List<OffsetInMeters> centerLiftToDrawerCenterInLift =
      _createCenterLiftToDrawerCenterInLift();

  /// How far apart the minimized drawers are displayed.
  /// See [minimizedDrawerSize]
  late final double minimizedDrawerDistanceInMeters =
      yInMeters / (nrOfLiftPositions + 1);

  /// the drawers are minimized inside the lift to show all drawers in the lift
  late final SizeInMeters minimizedDrawerSize = SizeInMeters(
      xInMeters: minimizedDrawerDistanceInMeters * 0.8,
      yInMeters: minimizedDrawerDistanceInMeters * 0.8);

  List<OffsetInMeters> _createCenterLiftToDrawerCenterInLift() {
    var offsets = <OffsetInMeters>[];
    var xInMeters = centerCenter.xInMeters;
    for (int level = 0; level < nrOfLiftPositions; level++) {
      offsets.add(OffsetInMeters(
              xInMeters: xInMeters,
              yInMeters: (nrOfLiftPositions - level) *
                  minimizedDrawerDistanceInMeters) -
          centerCenter);
    }
    return offsets;
  }
}
