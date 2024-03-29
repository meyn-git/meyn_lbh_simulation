import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_unloader.dart';
import 'package:meyn_lbh_simulation/gui/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleDrawerUnloaderWidget extends StatelessWidget {
  final ModuleDrawerUnloader unloader;

  const ModuleDrawerUnloaderWidget(this.unloader, {super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return RotationTransition(
      turns: AlwaysStoppedAnimation(
          unloader.inFeedDirection.opposite.toCompassDirection().toFraction()),
      child: CustomPaint(painter: ModuleDrawerUnloaderPainter(unloader, theme)),
    );
  }
}

class ModuleDrawerUnloaderPainter extends CustomPainter {
  final ModuleDrawerUnloader unloader;
  final LiveBirdsHandlingTheme theme;
  ModuleDrawerUnloaderPainter(this.unloader, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    _drawConveyor(canvas, size);
    _drawDirectionTriangle(size, canvas);
  }

  void _drawDirectionTriangle(Size size, Canvas canvas) {
    var paint = Paint();
    paint.color = theme.machineColor;
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
    paint.color = theme.machineColor;
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
  final LiveBirdsHandlingTheme theme;
  DrawerUnloaderLiftPainter(this.drawerLift, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    _drawCircumference(canvas, size);
  }

  _drawCircumference(
    Canvas canvas,
    Size size,
  ) {
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
