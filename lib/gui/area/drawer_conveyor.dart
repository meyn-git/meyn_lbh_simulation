import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyors.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_unloader.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_unloader.dart';

class DrawerConveyorWidget extends StatelessWidget {
  final DrawerConveyor drawerConveyor;

  DrawerConveyorWidget(this.drawerConveyor) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: createDrawerConveyorPainter(drawerConveyor));
}

DrawerConveyorPainter createDrawerConveyorPainter(drawerConveyor) {
  if (drawerConveyor is UnloaderDrawerLift) {
    return UnloaderDrawerLiftPainter(drawerConveyor);
  }
  if (drawerConveyor is DrawerConveyorStraight) {
    return DrawerConveyorStraightPainter(drawerConveyor);
  }
  if (drawerConveyor is DrawerConveyor90Degrees) {
    return DrawerConveyor90DegreePainter(drawerConveyor);
  }
  throw Exception('Not supported drawerConveyor');
}

abstract class DrawerConveyorPainter extends CustomPainter {
  void addMachineToPath(Path path, Size size) {
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, 0);
  }
}

class DrawerConveyorStraightPainter extends DrawerConveyorPainter {
  final DrawerConveyorStraight drawerConveyor;

  DrawerConveyorStraightPainter(this.drawerConveyor);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;

    var path = Path();
    if (drawerConveyor.machineProtrudesInMeters > 0) {
      addMachineToPath(path, size);
    }
    switch (drawerConveyor.direction) {
      case CardinalDirection.north:
      case CardinalDirection.south:
        addConveyorChainsNorthOrSouthToPath(path, size);
        break;
      case CardinalDirection.east:
      case CardinalDirection.west:
        addConveyorChainsEastOrWestToPath(path, size);
        break;
      default:
        throw Exception('Not supported direction');
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void addConveyorChainsNorthOrSouthToPath(Path path, Size size) {
    var totalWidthInMeters = drawerConveyor.size.width;
    var offSet = drawerConveyor.machineProtrudesInMeters / totalWidthInMeters;
    path.moveTo(size.width * offSet, 0);
    path.lineTo(size.width * offSet, size.height);
    path.moveTo(size.width * (1 - offSet), 0);
    path.lineTo(size.width * (1 - offSet), size.height);
  }

  void addConveyorChainsEastOrWestToPath(Path path, Size size) {
    var totalWidthInMeters = drawerConveyor.size.height;
    var offSet = drawerConveyor.machineProtrudesInMeters / totalWidthInMeters;
    path.moveTo(0, size.height * offSet);
    path.lineTo(size.width, size.height * offSet);
    path.moveTo(0, size.height * (1 - offSet));
    path.lineTo(size.width, size.height * (1 - offSet));
  }
}

class DrawerConveyor90DegreePainter extends DrawerConveyorPainter {
  final DrawerConveyor90Degrees drawerConveyor;

  DrawerConveyor90DegreePainter(this.drawerConveyor);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;

    var path = Path();
    addConveyorChainsToPath(path, size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void addConveyorChainsToPath(Path path, Size size) {
    var widthInMeters = drawerConveyor.size.width;
    var sizePerMeter = size.width / widthInMeters;
    var halveConveyorWidth =
        DrawerConveyor.chainWidthInMeters / 2 * sizePerMeter;
    var shortRadius = size.width / 2 - halveConveyorWidth;
    var longRadius = size.width / 2 + halveConveyorWidth;
    var centerPosition = _centerPosition(size);
    addQuarterCircleToPath(path, shortRadius, centerPosition);
    addQuarterCircleToPath(path, longRadius, centerPosition);
  }

  void addQuarterCircleToPath(Path path, double radius, Offset centerPosition) {
    var rotation = drawerConveyor.startDirection.toCompassDirection();
    var position = circlePosition(centerPosition, radius, rotation);
    path.moveTo(position.dx, position.dy);

    var stepInDegrees = drawerConveyor.clockwise ? 10 : -10;
    for (int i = 0; i < 9; i++) {
      rotation = rotation.rotate(stepInDegrees);
      position = circlePosition(centerPosition, radius, rotation);
      path.lineTo(position.dx, position.dy);
    }
  }

  circlePosition(
      Offset centerPosition, double radius, CompassDirection rotation) {
    var dx = cos(rotation.radians) * radius;
    var dy = sin(rotation.radians) * radius;
    var offSet = Offset(dx, dy);
    return centerPosition + offSet;
  }

  Offset _centerPosition(Size size) {
    switch (drawerConveyor.startDirection) {
      case CardinalDirection.north:
        if (drawerConveyor.clockwise) {
          return Offset(size.width, size.height);
        } else {
          return Offset(0, size.height);
        }
      case CardinalDirection.east:
        if (drawerConveyor.clockwise) {
          return Offset(0, size.height);
        } else {
          return const Offset(0, 0);
        }
      case CardinalDirection.south:
        if (drawerConveyor.clockwise) {
          return const Offset(0, 0);
        } else {
          return Offset(size.width, 0);
        }
      case CardinalDirection.west:
        if (drawerConveyor.clockwise) {
          return Offset(size.width, 0);
        } else {
          return Offset(size.width, size.height);
        }
      default:
        throw Exception('Not supported direction');
    }
  }
}
