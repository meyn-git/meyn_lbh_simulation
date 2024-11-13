import 'dart:math';

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';

class ModuleRotatingConveyorPainter extends ShapePainter {
  ModuleRotatingConveyorPainter(ModuleRotatingConveyor moduleRotatingConveyor,
      LiveBirdsHandlingTheme theme)
      : super(shape: moduleRotatingConveyor.shape, theme: theme);
}

class ModuleRotatingConveyorShape extends CompoundShape {
  late final double diameterInMeters;
  late final OffsetInMeters centerToConveyorCenter;
  late final OffsetInMeters centerToModuleInLink;
  late final OffsetInMeters centerToModuleOutLink;

  late final OffsetInMeters centerToModuleGroupLinkNorth =
      OffsetInMeters(xInMeters: 0, yInMeters: diameterInMeters * -0.5);

  OffsetInMeters centerToModuleGroupLink(CompassDirection direction) =>
      centerToModuleGroupLinkNorth.rotate(direction);

  ModuleRotatingConveyorShape(ModuleRotatingConveyor moduleRotatingConveyor) {
    var frameLength = _frameLength(moduleRotatingConveyor);
    var rotationFrame = Circle(diameterInMeters: 2);
    var frameEast = Box(
        xInMeters: ModuleConveyorShape.frameWidthInMeters,
        yInMeters: frameLength);
    var conveyor = Box(
        xInMeters: ModuleConveyorShape.conveyorWidthInMeters,
        yInMeters: frameLength);
    var frameWest = Box(
        xInMeters: ModuleConveyorShape.frameWidthInMeters,
        yInMeters: frameLength);
    var motor = Box(xInMeters: 0.3, yInMeters: 0.4);

    diameterInMeters = moduleRotatingConveyor.diameter.inMeters;
    var fullSize =
        InvisibleBox(xInMeters: diameterInMeters, yInMeters: diameterInMeters);

    link(fullSize.centerCenter, conveyor.centerCenter);
    link(conveyor.centerLeft, frameWest.centerRight);
    link(conveyor.centerRight, frameEast.centerLeft);
    link(frameWest.topLeft.addY(0.15), motor.topRight);
    link(conveyor.centerCenter, rotationFrame.centerCenter);

    centerToConveyorCenter = OffsetInMeters.zero;
    //topLefts[conveyor]! + conveyor.centerCenter - centerCenter;
  }

  double _frameLength(ModuleRotatingConveyor moduleRotatingConveyor) {
    var width = ModuleConveyorShape.conveyorWidthInMeters +
        ModuleConveyorShape.frameWidthInMeters * 2;
    const gap = 0.1;
    var diameter = moduleRotatingConveyor.diameter.inMeters;
    return sqrt(pow((diameter - gap), 2) - pow(width, 2));
  }
}
