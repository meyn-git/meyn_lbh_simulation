import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleCasPainter extends ShapePainter {
  ModuleCasPainter(ModuleCas cas, LiveBirdsHandlingTheme theme)
      : super(shape: cas.shape, theme: theme);
}

class ModuleCasShape extends CompoundShape {
  late final Box cabin;
  late final Box slideDoorRail;

  late final CompassDirection gasDuctsDirection;

  ModuleCasShape(ModuleCas cas) {
    var moduleGroupSize =
        cas.area.productDefinition.moduleFamily.moduleGroupSurface;
    var cabinSize = (moduleGroupSize + cabinPadding * 2);
    var leftPlatform = Box(xInMeters: 0.8, yInMeters: cabinSize.yInMeters);
    cabin = Box(xInMeters: cabinSize.xInMeters, yInMeters: cabinSize.yInMeters);
    var rightPlatform = Box(xInMeters: 0.8, yInMeters: cabinSize.yInMeters);
    var inletDuct = Box(xInMeters: 0.3, yInMeters: 0.7);
    var outletDuct = Box(xInMeters: 0.3, yInMeters: 0.7);
    slideDoorRail = Box(xInMeters: 3.175, yInMeters: 0.2);

    link(leftPlatform.centerRight, cabin.centerLeft);
    link(cabin.centerRight, rightPlatform.centerLeft);

    if (cas.slideDoorLeft) {
      link(rightPlatform.bottomRight.addX(-0.75), slideDoorRail.topRight);
    } else {
      link(leftPlatform.bottomLeft.addX(0.75), slideDoorRail.topLeft);
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
  late final SizeInMeters cabinPadding =
      const SizeInMeters(xInMeters: 0.15, yInMeters: 0.1);

  late final OffsetInMeters centerToCabinCenter =
      topLefts[cabin]! + cabin.centerCenter - centerCenter;

  late final OffsetInMeters centerToModuleGroupInOutLink =
      centerToCabinCenter + _cabinCenterToModuleGroupInOutLink;

  late final OffsetInMeters _cabinCenterToModuleGroupInOutLink = OffsetInMeters(
    xInMeters: 0,
    yInMeters: cabin.yInMeters * 0.5 + slideDoorRail.yInMeters,
  );
}
