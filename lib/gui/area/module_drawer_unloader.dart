import 'package:fling_units/fling_units.dart';
import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_unloader.dart';
import 'package:meyn_lbh_simulation/gui/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/style.dart';

class ModuleDrawerUnloaderWidget extends StatelessWidget {
  final ModuleDrawerUnloader unloader;

  const ModuleDrawerUnloaderWidget(this.unloader, {super.key});

  @override
  Widget build(BuildContext context) {
    var style = LiveBirdsHandlingStyle.of(context);
    return RotationTransition(
      turns: AlwaysStoppedAnimation(
          unloader.inFeedDirection.opposite.toCompassDirection().toFraction()),
      child: CustomPaint(painter: ModuleDrawerUnloaderPainter(unloader, style)),
    );
  }
}

class ModuleDrawerUnloaderPainter extends CustomPainter {
  final ModuleDrawerUnloader unloader;
  final LiveBirdsHandlingStyle style;
  ModuleDrawerUnloaderPainter(this.unloader, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    _drawConveyor(canvas, size);
    _drawDirectionTriangle(size, canvas);
  }

  void _drawDirectionTriangle(Size size, Canvas canvas) {
    var paint = Paint();
    paint.color = style.machineColor;
    paint.style = PaintingStyle.fill;
    var path = Path();
    path.moveTo(size.width * 0.45, size.height * 0.45);
    path.lineTo(size.width * 0.55, size.height * 0.45);
    path.lineTo(size.width * 0.50, size.height * 0.4);
    path.close();
    canvas.drawPath(path, paint);
  }

  _drawConveyor(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = style.machineColor;
    paint.style = PaintingStyle.stroke;
    var x1 = size.width * 0.3;
    var x2 = size.width * 0.7;
    var y1 = size.height * 0.1;
    var y2 = size.height * 0.9;
    canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawerUnloaderLiftPainter extends DrawerConveyorPainter {
  final DrawerUnloaderLift drawerLift;
  final LiveBirdsHandlingStyle style;
  DrawerUnloaderLiftPainter(this.drawerLift, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    double sizePerMeter =
        size.width / drawerLift.sizeWhenFacingNorth.widthInMeters;
    for (int level = 0; level < drawerLift.nrOfLiftPositions; level++) {
      _drawDrawer(canvas, sizePerMeter,
          drawerLift.topLeftToLiftLevel(level).toOffset());
    }
  }

  _drawDrawer(
    Canvas canvas,
    double sizePerMeter,
    Offset topLeftToLiftLevel,
  ) {
    var paint = Paint();
    paint.color = style.machineColor;
    paint.style = PaintingStyle.stroke;

    var x1 = topLeftToLiftLevel.dx * sizePerMeter;
    var y1 = topLeftToLiftLevel.dy * sizePerMeter;
    var drawerLengthInMeters =
        GrandeDrawerModuleType.drawerOutSideLength.as(meters);
    var x2 = x1 + drawerLengthInMeters * sizePerMeter;
    var y2 = y1 + drawerLengthInMeters * sizePerMeter;
    canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
