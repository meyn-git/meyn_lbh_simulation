import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/machine.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_unloader.dart';
import 'package:meyn_lbh_simulation/gui/area/area.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_unloader.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class MachineWidget extends StatelessWidget {
  final MachineLayout layout;
  final Machine machine;

  MachineWidget(this.layout, this.machine) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return RotationTransition(
        turns: AlwaysStoppedAnimation(layout.rotationOf(machine).toFraction()),
        child: CustomPaint(painter: createMachinePainter(machine, theme)));
  }
}

DrawerConveyorPainter createMachinePainter(
    Machine machine, LiveBirdsHandlingTheme theme) {
  if (machine is DrawerLoaderLift) {
    return DrawerLoaderLiftPainter(machine, theme);
  }
  if (machine is DrawerUnloaderLift) {
    return DrawerUnloaderLiftPainter(machine, theme);
  }
  if (machine is DrawerConveyorStraight) {
    return DrawerConveyorStraightPainter(machine, theme);
  }
  if (machine is DrawerConveyor90Degrees) {
    return DrawerConveyor90DegreePainter(machine, theme);
  }
  throw Exception('Not supported drawerConveyor');
}

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
  final DrawerConveyorStraight drawerConveyor;
  final LiveBirdsHandlingTheme theme;

  DrawerConveyorStraightPainter(this.drawerConveyor, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;

    var path = Path();
    if (drawerConveyor.machineProtrudesInMeters > 0) {
      addMachineCircumferenceToPath(path, size);
    }

    addConveyorChainsToPath(path, size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void addConveyorChainsToPath(Path path, Size size) {
    var totalWidthInMeters = drawerConveyor.sizeWhenFacingNorth.widthInMeters;
    var offSet = drawerConveyor.machineProtrudesInMeters / totalWidthInMeters;
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
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;

    var path = Path();
    addConveyorChainsToPath(path, size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void addConveyorChainsToPath(Path path, Size size) {
    var widthInMeters = drawerConveyor.sizeWhenFacingNorth.widthInMeters;
    var sizePerMeter = size.width / widthInMeters;
    var shortRadius =
        size.width - DrawerConveyor.chainWidthInMeters * sizePerMeter;
    var longRadius = size.width;
    var centerPosition = _centerPosition(size);
    addQuarterCircleToPath(path, shortRadius, centerPosition);
    addQuarterCircleToPath(path, longRadius, centerPosition);
  }

  void addQuarterCircleToPath(Path path, double radius, Offset centerPosition) {
    var rotation = CardinalDirection.north.toCompassDirection();
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
    var dx = cos(rotation.toRadians()) * radius;
    var dy = sin(rotation.toRadians()) * radius;
    var offSet = Offset(dx, dy);
    return centerPosition + offSet;
  }

  Offset _centerPosition(Size size) => drawerConveyor.clockwise
      ? Offset(size.width, size.height)
      : Offset(0, size.height);
}
