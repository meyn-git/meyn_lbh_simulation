import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class ModuleWasherConveyorPainter extends ShapePainter {
  ModuleWasherConveyorPainter(
    ModuleWasherConveyor conveyor,
    LiveBirdsHandlingTheme theme,
  ) : super(shape: conveyor.shape, theme: theme);
}

class ModuleWasherConveyorShape extends CompoundShape {
  late final OffsetInMeters centerToConveyorCenter;
  late final OffsetInMeters centerToModuleInLink;
  late final OffsetInMeters centerToModuleOutLink;

  static const double conveyorWidthInMeters = 1.2;
  static const double frameWidthInMeters = 0.5;

  ModuleWasherConveyorShape(ModuleWasherConveyor moduleWasher) {
    var frameEast = Box(
      xInMeters:
          frameWidthInMeters, //standard grande drawer conveyor frame width
      yInMeters: moduleWasher.lengthInMeters,
    );
    var conveyor = Box(
      xInMeters: conveyorWidthInMeters, //standard grande drawer conveyor width
      yInMeters: moduleWasher.lengthInMeters,
    );
    var frameWest = Box(
      xInMeters:
          frameWidthInMeters, //standard grande drawer conveyor frame width
      yInMeters: moduleWasher.lengthInMeters,
    );

    var motor = Box(xInMeters: 0.3, yInMeters: 0.63);
    link(frameWest.centerRight, conveyor.centerLeft);
    link(conveyor.centerRight, frameEast.centerLeft);
    link(frameEast.topRight.addY(0.1), motor.topLeft);
    centerToConveyorCenter =
        topLefts[conveyor]! + conveyor.centerCenter - centerCenter;
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
