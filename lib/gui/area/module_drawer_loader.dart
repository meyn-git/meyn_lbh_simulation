import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleDrawerLoaderPainter extends ShapePainter {
  ModuleDrawerLoaderPainter(
      ModuleDrawerLoader drawerLoader, LiveBirdsHandlingTheme theme)
      : super(shape: drawerLoader.shape, theme: theme);
}

class ModuleDrawerLoaderShape extends CompoundShape {
  late final OffsetInMeters centerToConveyorCenter;
  late final OffsetInMeters centerToModuleInLink;
  late final OffsetInMeters centerToModuleOutLink;
  late final OffsetInMeters centerToFirstColumn;
  late final OffsetInMeters centerToSecondColumn;
  late final OffsetInMeters centerToDrawersInLink;

//TODO assumption
  static const lengthInMeters = 2.75 * 1.5;

  /// Most of this is constructor is a copy from the [ModuleConveyorShape]
  ModuleDrawerLoaderShape(ModuleDrawerLoader drawerLoader) {
    var moduleGroupLength = drawerLoader
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

    var motor = Box(xInMeters: 0.3, yInMeters: 0.63);
    link(frameWest.centerRight, conveyor.centerLeft);
    link(conveyor.centerRight, frameEast.centerLeft);
    link(frameEast.topRight.addY(0.1), motor.topLeft);

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
    centerToDrawersInLink = (drawerLoader.drawersFromLeft
            ? frameEast.centerLeft
            : frameWest.centerRight) -
        centerCenter;
  }
}

class DrawerLoaderLiftPainter extends ShapePainter {
  DrawerLoaderLiftPainter(
      DrawerLoaderLift drawerLoaderLift, LiveBirdsHandlingTheme theme)
      : super(shape: drawerLoaderLift.shape, theme: theme);
}

class DrawerLoaderLiftShape extends CompoundShape {
  late final int nrOfLiftPositions;
  late final OffsetInMeters centerToDrawerInLink;
  late final OffsetInMeters centerToDrawersOutLink;
  late final List<OffsetInMeters> centerLiftToDrawerCenterInLift =
      _createCenterLiftToDrawerCenterInLift();

  /// How far apart the minimized drawers are displayed.
  late final double minimizedDrawerDistanceInMeters;

  /// the drawers are minimized inside the lift to show all drawers in the lift
  late final SizeInMeters minimizedDrawerSize;

  DrawerLoaderLiftShape(DrawerLoaderLift drawerLoaderLift) {
    var lift = Box(xInMeters: 1.6, yInMeters: 1.5);
    var pusher = Box(xInMeters: 1.6, yInMeters: 2.9 * 0.5);
    link(lift.bottomCenter, pusher.topCenter);
    centerToDrawerInLink = lift.bottomCenter - centerCenter;
    centerToDrawersOutLink = lift.topCenter - centerCenter;
    nrOfLiftPositions = drawerLoaderLift.nrOfLiftPositions;
    minimizedDrawerDistanceInMeters = lift.yInMeters / (nrOfLiftPositions + 1);
    minimizedDrawerSize = SizeInMeters(
        xInMeters: minimizedDrawerDistanceInMeters * 0.8,
        yInMeters: minimizedDrawerDistanceInMeters * 0.8);
  }

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
