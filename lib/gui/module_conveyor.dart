import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/layout.dart';
import 'package:meyn_lbh_simulation/domain/module_conveyor.dart';

class ModuleConveyorWidget extends StatelessWidget {
  final ModuleConveyor moduleConveyor;

  ModuleConveyorWidget(this.moduleConveyor);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: moduleConveyor.toString(),
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(moduleConveyor
            .inFeedDirection.opposite
            .toCompassDirection()
            .degrees /
            360),
        child: CustomPaint(painter: ModuleConveyorPainter()),
      ),
    );
  }
}

class ModuleConveyorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    drawRectangle(canvas, size);
    drawDirectionTriangle(size, canvas);
  }

  void drawDirectionTriangle(Size size, Canvas canvas) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.fill;
    var path = Path();
    path.moveTo(size.width * 0.45, size.height * 0.45);
    path.lineTo(size.width * 0.55, size.height * 0.45);
    path.lineTo(size.width * 0.50, size.height * 0.4);
    path.close();
    canvas.drawPath(path, paint);
  }

  Paint drawRectangle(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width * 0.4,
            height: size.width * 0.8),
        paint);
    return paint;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
