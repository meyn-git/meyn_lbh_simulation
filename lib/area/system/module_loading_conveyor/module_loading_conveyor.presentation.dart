import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';

class ModuleLoadingConveyorPainter extends ShapePainter {
  ModuleLoadingConveyorPainter(
    ModuleLoadingConveyor conveyor,
    LiveBirdsHandlingTheme theme,
  ) : super(shape: conveyor.shape, theme: theme);
}

class ModuleLoadingConveyorShape extends CompoundShape {
  late final OffsetInMeters centerToModuleGroupPlace;
  late final OffsetInMeters centerToModuleInLink;
  late final OffsetInMeters centerToModuleOutLink;

  static const double conveyorWidthInMeters = 1.2;
  //standard grande drawer conveyor frame width (VDL and Maxiload-twin or Omnia might be different)
  static const double frameWidthInMeters = 0.065;

  static const double taperedGuideWidthInMeters = 0.3;

  ModuleLoadingConveyorShape(ModuleLoadingConveyor moduleLoadingConveyor) {
    var moduleGroupFootPrint = moduleLoadingConveyor
        .area
        .productDefinition
        .truckRows
        .first
        .footprintOnSystem;
    var frameEast = Box(
      xInMeters: frameWidthInMeters,
      yInMeters: moduleLoadingConveyor.lengthInMeters,
    );
    var taperedGuideEast = Box(
      xInMeters: taperedGuideWidthInMeters,
      yInMeters: moduleGroupFootPrint.yInMeters,
    );
    var conveyor = Box(
      xInMeters: conveyorWidthInMeters,
      yInMeters: moduleLoadingConveyor.lengthInMeters,
    );
    var frameWest = Box(
      xInMeters: frameWidthInMeters,
      yInMeters: moduleLoadingConveyor.lengthInMeters,
    );
    var taperedGuideWest = Box(
      xInMeters: taperedGuideWidthInMeters,
      yInMeters: moduleGroupFootPrint.yInMeters,
    );

    var motor = Box(xInMeters: 0.3, yInMeters: 0.63);
    link(frameWest.centerRight, conveyor.centerLeft);
    link(conveyor.bottomLeft, taperedGuideWest.bottomRight);
    link(conveyor.centerRight, frameEast.centerLeft);
    link(conveyor.bottomRight, taperedGuideEast.bottomLeft);
    link(frameEast.topRight.addY(0.1), motor.topLeft);

    var centerToConveyorCenter =
        topLefts[conveyor]! + conveyor.centerCenter - centerCenter;
    centerToModuleGroupPlace = OffsetInMeters(
      xInMeters: centerToConveyorCenter.xInMeters,
      yInMeters: yInMeters * 0.5 - moduleGroupFootPrint.yInMeters * 0.5,
    );
    centerToModuleInLink = OffsetInMeters(
      xInMeters: centerToConveyorCenter.xInMeters,
      yInMeters: yInMeters * 0.5,
    );
    centerToModuleOutLink = OffsetInMeters(
      xInMeters: centerToConveyorCenter.xInMeters,
      yInMeters: yInMeters * -0.5,
    );
  }
}
