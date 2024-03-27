import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/gui/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleDrawerLoaderWidget extends StatelessWidget {
  final ModuleDrawerLoader loader;

  const ModuleDrawerLoaderWidget(this.loader, {super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return RotationTransition(
      turns: AlwaysStoppedAnimation(
          loader.inFeedDirection.opposite.toCompassDirection().toFraction()),
      child: CustomPaint(painter: ModuleDrawerLoaderPainter(loader, theme)),
    );
  }
}

class ModuleDrawerLoaderPainter extends CustomPainter {
  final ModuleDrawerLoader loader;
  final LiveBirdsHandlingTheme theme;
  ModuleDrawerLoaderPainter(this.loader, this.theme);

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

class DrawerLoaderLiftPainter extends DrawerConveyorPainter {
  final DrawerLoaderLift drawerLift;
  final LiveBirdsHandlingTheme theme;
  DrawerLoaderLiftPainter(this.drawerLift, this.theme);

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
