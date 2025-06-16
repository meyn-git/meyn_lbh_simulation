import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck.domain.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class TruckPainter extends ShapePainter {
  TruckPainter(BoxTruck truck, LiveBirdsHandlingTheme theme)
    : super(shape: truck.shape, theme: theme);
}

class TruckShape extends TrailerPullerShape {
  @override
  late double centerToHitch;
  @override
  late double centerToAxleCenterInMeters;

  @override
  late List<OffsetInMeters> centerToModuleGroupCenters;

  TruckShape(BoxTruck truck) {
    var cabin = Box(
      xInMeters: truck.widthInMeter,
      yInMeters: truck.cabinLengthInMeter,
    );
    var cargoFloor = Box(
      xInMeters: truck.widthInMeter,
      yInMeters: truck.cargoFloorLengthInMeter,
    );
    var leftWheels = <Box>[];
    var rightWheels = <Box>[];
    for (int i = 0; i < 3; i++) {
      leftWheels.add(Box(xInMeters: 0.05, yInMeters: 1));
      rightWheels.add(Box(xInMeters: 0.05, yInMeters: 1));
    }

    link(cabin.bottomCenter.addY(0.1), cargoFloor.topCenter);
    link(cabin.topLeft.addY(0.9), leftWheels[0].topCenter);
    link(cabin.topRight.addY(0.9), rightWheels[0].topCenter);
    link(cargoFloor.bottomRight.addY(-4), leftWheels[1].centerRight);
    link(cargoFloor.bottomLeft.addY(-4), rightWheels[1].centerLeft);
    link(cargoFloor.bottomRight.addY(-2), leftWheels[2].centerRight);
    link(cargoFloor.bottomLeft.addY(-2), rightWheels[2].centerLeft);

    var topToFrontAxcel =
        (topLefts[leftWheels.first]! + leftWheels.first.centerLeft).yInMeters;
    var topToBackAxcel =
        (topLefts[leftWheels.last]! + leftWheels.last.centerLeft).yInMeters;
    centerToAxleCenterInMeters = (topToBackAxcel - topToFrontAxcel) / 2;
    var topToAxcelCenter = topToFrontAxcel + centerToAxleCenterInMeters;
    var lengthToAdd =
        topToAxcelCenter * 2 -
        (topLefts[cargoFloor]! + cargoFloor.bottomCenter).yInMeters;
    var paddingToMoveCenterPoint = InvisibleBox(
      xInMeters: 1,
      yInMeters: lengthToAdd,
    );

    link(cabin.topCenter, paddingToMoveCenterPoint.bottomCenter);

    centerToHitch = yInMeters / 2;

    centerToModuleGroupCenters =
        _createCenterToModuleGroupCentersWhenFacingNorth(truck, cargoFloor);
  }

  List<OffsetInMeters> _createCenterToModuleGroupCentersWhenFacingNorth(
    BoxTruck truck,
    Box cargoFloor,
  ) {
    var betweenModulesInMeters = 0.02;
    var centerToModuleGroupCenters = <OffsetInMeters>[];

    var moduleSizeInMeters =
        truck.routes.area.productDefinition.truckRows.first.footprintOnSystem;
    var centerToModuleCenter = OffsetInMeters(
      xInMeters: 0,
      yInMeters:
          centerCenter.yInMeters -
          topLefts[cargoFloor]!.yInMeters +
          betweenModulesInMeters / 2 +
          moduleSizeInMeters.xInMeters / 2,
    );
    var numberOfModules =
        cargoFloor.yInMeters ~/
        (moduleSizeInMeters.xInMeters + betweenModulesInMeters);
    for (int i = 0; i < numberOfModules; i++) {
      centerToModuleGroupCenters.add(centerToModuleCenter);
      centerToModuleCenter.addY(
        betweenModulesInMeters + moduleSizeInMeters.xInMeters,
      );
    }
    return centerToModuleGroupCenters;
  }
}
