import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.presentation.dart';

class LoadingForkLiftTruckPainter extends ShapePainter {
  LoadingForkLiftTruckPainter(
    LoadingForkLiftTruck forkLiftTruck,
    LiveBirdsHandlingTheme theme,
  ) : super(shape: forkLiftTruck.shape, theme: theme);
}

class UnLoadingForkLiftTruckPainter extends ShapePainter {
  UnLoadingForkLiftTruckPainter(
    UnLoadingForkLiftTruck forkLiftTruck,
    LiveBirdsHandlingTheme theme,
  ) : super(shape: forkLiftTruck.shape, theme: theme);
}

class ForkLiftTruckShape extends VehicleShape {
  late OffsetInMeters centerToModuleGroupCenter;
  late OffsetInMeters centerToFrontForkCarriage;
  @override
  late double centerToAxleCenterInMeters;

  //TODO set with constructor parameter
  var moduleGroupLengthInMeters = 2.43;

  ForkLiftTruckShape() {
    var leftFork = BoxWithCurvedNorthSide(
      xInMeters: 0.14,
      yInMeters: 2,
      yCurveInMeters: 0.2,
    );
    var rightFork = BoxWithCurvedNorthSide(
      xInMeters: 0.14,
      yInMeters: 2,
      yCurveInMeters: 0.2,
    );
    var forkCarriage = Box(xInMeters: 1.5, yInMeters: 0.15);
    var mast = Box(xInMeters: 0.8, yInMeters: 0.3);
    var body = BoxWithCurvedSouthSide(
      xInMeters: 1.2,
      yInMeters: 2.1,
      yCurveInMeters: 0.2,
    );
    var frontLeftWheel = Box(xInMeters: 0.15, yInMeters: 0.6);
    var frontRightWheel = Box(xInMeters: 0.1, yInMeters: 0.6);
    var backLeftWheel = Box(xInMeters: 0.05, yInMeters: 0.4);
    var backRightWheel = Box(xInMeters: 0.05, yInMeters: 0.4);
    var frontWindow = Box(xInMeters: 0.9, yInMeters: 0.3);
    var roof = Box(xInMeters: 0.9, yInMeters: 1);
    var backWindow = Box(xInMeters: 0.9, yInMeters: 0.2);

    // body with wheels
    link(body.topLeft, frontLeftWheel.topRight);
    link(body.topRight, frontRightWheel.topLeft);
    link(body.topLeft.addY(1.4), backLeftWheel.topRight);
    link(body.topRight.addY(1.4), backRightWheel.topLeft);
    // cabin
    link(body.topCenter, frontWindow.topCenter);
    link(frontWindow.bottomCenter, roof.topCenter);
    link(roof.bottomCenter, backWindow.topCenter);
    // mast cariage and forks
    link(body.topCenter, mast.bottomCenter);
    link(mast.topCenter, forkCarriage.bottomCenter);
    link(forkCarriage.topCenter.addX(-0.45), leftFork.bottomLeft);
    link(forkCarriage.topCenter.addX(0.45), rightFork.bottomRight);

    var topToFrontAxcel =
        (topLefts[frontLeftWheel]! + frontLeftWheel.centerLeft).yInMeters;
    var topToBackAxcel =
        (topLefts[backLeftWheel]! + backLeftWheel.centerLeft).yInMeters;
    centerToAxleCenterInMeters = (topToBackAxcel - topToFrontAxcel) / 2;
    var topToAxcelCenter = topToFrontAxcel + centerToAxleCenterInMeters;
    var lengthToAdd =
        topToAxcelCenter * 2 - (topLefts[body]! + body.bottomCenter).yInMeters;
    var paddingToMoveCenterPoint = InvisibleBox(
      xInMeters: 1,
      yInMeters: lengthToAdd,
    );

    link(body.bottomCenter, paddingToMoveCenterPoint.topCenter);

    // var circle = Circle(diameterInMeters: 0.1);
    // var outline = Box(xInMeters: xInMeters, yInMeters: yInMeters);
    // link(paddingToMoveCenterPoint.bottomCenter, outline.bottomCenter);
    // link(outline.centerCenter, circle.centerCenter);

    centerToFrontForkCarriage =
        (topLefts[forkCarriage]! + forkCarriage.topCenter) - centerCenter;

    centerToModuleGroupCenter = centerToFrontForkCarriage.addY(
      moduleGroupLengthInMeters * -0.55,
    );
  }
}
