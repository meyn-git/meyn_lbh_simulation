import 'dart:math';

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';

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
    var rotationFrame = Circle(diameterInMeters: 2);
    var frameEast = Box(
        xInMeters: ModuleConveyorShape
            .frameWidthInMeters, //standard grande drawer conveyor frame width
        yInMeters: moduleRotatingConveyor.lengthInMeters);
    var conveyor = Box(
        xInMeters: ModuleConveyorShape
            .conveyorWidthInMeters, //standard grande drawer conveyor width
        yInMeters: moduleRotatingConveyor.lengthInMeters);
    var frameWest = Box(
        xInMeters: ModuleConveyorShape
            .frameWidthInMeters, //standard grande drawer conveyor frame width
        yInMeters: moduleRotatingConveyor.lengthInMeters);
    var motor = Box(xInMeters: 0.3, yInMeters: 0.4);

    diameterInMeters = _calculateDiameter(moduleRotatingConveyor);
    var padding =
        InvisibleBox(xInMeters: diameterInMeters, yInMeters: diameterInMeters);

    link(padding.centerCenter, conveyor.centerCenter);
    link(conveyor.centerLeft, frameWest.centerRight);
    link(conveyor.centerRight, frameEast.centerLeft);
    link(frameWest.topLeft.addY(0.15), motor.topRight);
    link(conveyor.centerCenter, rotationFrame.centerCenter);

    centerToConveyorCenter =
        topLefts[conveyor]! + conveyor.centerCenter - centerCenter;
  }

  double _calculateDiameter(ModuleRotatingConveyor moduleRotatingConveyor) {
    var width = ModuleConveyorShape.conveyorWidthInMeters +
        ModuleConveyorShape.frameWidthInMeters * 2;
    var height = moduleRotatingConveyor.lengthInMeters;
    return sqrt(pow(width, 2) + pow(height, 2)) + 0.1;
  }
}
