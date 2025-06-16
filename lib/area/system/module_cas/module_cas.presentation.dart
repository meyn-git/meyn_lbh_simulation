import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class ModuleCasPainter extends ShapePainter {
  ModuleCasPainter(ModuleCas cas, LiveBirdsHandlingTheme theme)
    : super(shape: cas.shape, theme: theme);
}

class ModuleCasShape extends CompoundShape {
  late final Box cabin;
  late final Box moduleDoor;
  late final CompassDirection gasDuctsDirection;
  late final double _cabinBottomToModuleGroupInOutLink;

  ModuleCasShape(ModuleCas cas) {
    var truckRowFootprint =
        cas.area.productDefinition.truckRows.first.footprintOnSystem;
    var cabinSize = (truckRowFootprint + cabinPadding * 2);
    var leftPlatform = Box(xInMeters: 0.8, yInMeters: cabinSize.yInMeters);
    cabin = Box(xInMeters: cabinSize.xInMeters, yInMeters: cabinSize.yInMeters);
    var rightPlatform = Box(xInMeters: 0.8, yInMeters: cabinSize.yInMeters);
    var inletDuct = Box(xInMeters: 0.3, yInMeters: 0.7);
    var outletDuct = Box(xInMeters: 0.3, yInMeters: 0.7);
    moduleDoor = cas.moduleDoor == ModuleDoor.rollDoorUp
        ? Box(xInMeters: 1.92, yInMeters: 0.5)
        : Box(xInMeters: 3.175, yInMeters: 0.2);

    link(leftPlatform.centerRight, cabin.centerLeft);
    link(cabin.centerRight, rightPlatform.centerLeft);

    switch (cas.moduleDoor) {
      case ModuleDoor.rollDoorUp:
        link(cabin.bottomCenter, moduleDoor.topCenter);

        /// shuttle has 20cm between front and track
        _cabinBottomToModuleGroupInOutLink = 0.20;
        break;
      case ModuleDoor.slideDoorToLeft:
        link(rightPlatform.bottomRight.addX(-0.75), moduleDoor.topRight);
        _cabinBottomToModuleGroupInOutLink = moduleDoor.yInMeters;
        break;
      case ModuleDoor.slideDoorToRight:
        link(leftPlatform.bottomLeft.addX(0.75), moduleDoor.topLeft);
        _cabinBottomToModuleGroupInOutLink = moduleDoor.yInMeters;
        break;
    }

    var ductOffsetY =
        (cabinSize.yInMeters - inletDuct.yInMeters - outletDuct.yInMeters) *
        0.25;
    if (cas.gasDuctsLeft) {
      link(leftPlatform.topRight.addY(ductOffsetY), inletDuct.topRight);
      link(leftPlatform.bottomRight.addY(-ductOffsetY), outletDuct.bottomRight);
      gasDuctsDirection = const CompassDirection.west();
    } else {
      link(rightPlatform.topLeft.addY(ductOffsetY), inletDuct.topLeft);
      link(rightPlatform.bottomLeft.addY(-ductOffsetY), outletDuct.bottomLeft);
      gasDuctsDirection = const CompassDirection.east();
    }
  }

  /// space between module and cabin
  late final SizeInMeters cabinPadding = const SizeInMeters(
    xInMeters: 0.15,
    yInMeters: 0.1,
  );

  late final OffsetInMeters centerToCabinCenter =
      topLefts[cabin]! + cabin.centerCenter - centerCenter;

  late final OffsetInMeters centerToModuleGroupInOutLink =
      centerToCabinCenter + _cabinCenterToModuleGroupInOutLink;

  late final OffsetInMeters _cabinCenterToModuleGroupInOutLink = OffsetInMeters(
    xInMeters: 0,
    yInMeters: cabin.yInMeters * 0.5 + _cabinBottomToModuleGroupInOutLink,
  );
}
