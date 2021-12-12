import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/module_de_stacker.dart';


class ModuleDeStackerWidget extends StatelessWidget {
  final ModuleDeStacker deStacker;

  ModuleDeStackerWidget(this.deStacker);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
        message: deStacker.toString(),
        child: RotationTransition(
            turns: AlwaysStoppedAnimation(deStacker.inFeedDirection.opposite
                .toCompassDirection()
                .degrees /
                360),
            child: CustomPaint(painter: ModuleDeStackerPainter(deStacker))));
  }
}

class ModuleDeStackerPainter extends CustomPainter {
  final ModuleDeStacker deStacker;

  ModuleDeStackerPainter(this.deStacker);

  @override
  void paint(Canvas canvas, Size size) {
    _drawRectangle(canvas, size);
    _drawSupports(canvas, size);
    _drawDirectionTriangle(canvas, size);
  }

  _drawDirectionTriangle(Canvas canvas, Size size) {
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

  _drawRectangle(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    var x1 = size.width * 0.3;
    var x2 = size.width * 0.7;
    var y1 = size.height * 0.1;
    var y2 = size.height * 0.9;
    canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), paint);
  }

  _drawSupports(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    var x1 = size.width * 0.2;
    var y1 = size.height * 0.1;
    var x2 = size.width * 0.7;
    var y2 = size.height * 0.7;
    var width = size.width * 0.1;
    var height = size.height * 0.2;
    canvas.drawRect(Rect.fromLTWH(x1, y1, width, height), paint);
    canvas.drawRect(Rect.fromLTWH(x2, y1, width, height), paint);
    canvas.drawRect(Rect.fromLTWH(x1, y2, width, height), paint);
    canvas.drawRect(Rect.fromLTWH(x2, y2, width, height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
