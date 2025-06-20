import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

abstract class DrawerConveyorPainter extends CustomPainter {
  void addMachineCircumferenceToPath(Path path, Size size) {
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, 0);
  }
}

class DrawerConveyorStraightPainter extends DrawerConveyorPainter {
  final SizeInMeters sizeWhenFacingNorth;
  final double systemProtrudesInMeters;
  final LiveBirdsHandlingTheme theme;

  DrawerConveyorStraightPainter(
    DrawerConveyorStraight drawerConveyor,
    this.theme,
  ) : systemProtrudesInMeters = drawerConveyor.systemProtrudesInMeters,
      sizeWhenFacingNorth = drawerConveyor.sizeWhenFacingNorth;

  DrawerConveyorStraightPainter.withSizes({
    required this.systemProtrudesInMeters,
    required this.sizeWhenFacingNorth,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;

    var path = Path();
    if (systemProtrudesInMeters > 0) {
      addMachineCircumferenceToPath(path, size);
    }

    addConveyorChainsToPath(path, size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  void addConveyorChainsToPath(Path path, Size size) {
    var totalWidthInMeters = sizeWhenFacingNorth.xInMeters;
    var offSet = systemProtrudesInMeters / totalWidthInMeters;
    path.moveTo(size.width * offSet, 0);
    path.lineTo(size.width * offSet, size.height);
    path.moveTo(size.width * (1 - offSet), 0);
    path.lineTo(size.width * (1 - offSet), size.height);
  }
}

class DrawerConveyor90DegreePainter extends DrawerConveyorPainter {
  final DrawerConveyor90Degrees drawerConveyor;
  final LiveBirdsHandlingTheme theme;
  DrawerConveyor90DegreePainter(this.drawerConveyor, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    //TODO for some reason we are being repainted every cycle. See
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;

    var path = Path();
    addConveyorChainsToPath(path, size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  void addConveyorChainsToPath(Path path, Size size) {
    var widthInMeters = drawerConveyor.sizeWhenFacingNorth.xInMeters;
    var sizePerMeter = size.width / widthInMeters;
    var shortRadius =
        size.width - DrawerConveyor.chainWidthInMeters * sizePerMeter;
    var longRadius = size.width;
    var circleCenter = _circleCenter(size);
    addQuarterCircleToPath(path, shortRadius, circleCenter);
    addQuarterCircleToPath(path, longRadius, circleCenter);
  }

  void addQuarterCircleToPath(Path path, double radius, Offset circleCenter) {
    var rotation = drawerConveyor.direction == Direction.clockWise
        ? const CompassDirection.west()
        : const CompassDirection.east();
    var position = positionOnCircle(circleCenter, radius, rotation);
    path.moveTo(position.dx, position.dy);

    var stepInDegrees = drawerConveyor.direction.sign * 10;
    for (int i = 0; i <= 9; i++) {
      position = positionOnCircle(circleCenter, radius, rotation);
      path.lineTo(position.dx, position.dy);
      rotation = rotation.rotate(stepInDegrees);
    }
  }

  Offset positionOnCircle(
    Offset circleCenter,
    double radius,
    CompassDirection rotation,
  ) {
    var dx = sin(rotation.toRadians()) * radius;
    var dy = -cos(rotation.toRadians()) * radius;
    var centerToCirclePoint = Offset(dx, dy);
    return circleCenter + centerToCirclePoint;
  }

  Offset _circleCenter(Size size) =>
      drawerConveyor.direction == Direction.clockWise
      ? Offset(size.width, size.height)
      : Offset(0, size.height);
}
