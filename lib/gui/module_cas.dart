
import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/layout.dart';
import 'package:meyn_lbh_simulation/domain/module_cas.dart';

class ModuleCasWidget extends StatelessWidget {

  final ModuleCas cas;

  ModuleCasWidget(this.cas);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: cas.toString(),
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(
            cas.inAndOutFeedDirection.toCompassDirection().degrees / 360),
        child: CustomPaint(painter: ModuleCasPainter()),
      ),
    );
  }

}

class ModuleCasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    drawRectangle(canvas, size);
    drawInFeedTriangle(canvas, size);
    drawOutFeedTriangle(canvas, size);
    drawAirIntakes(canvas, size);
  }

  void drawInFeedTriangle(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.fill;
    var path = Path();
    path.moveTo(size.width * 0.45, size.height * 0.55);
    path.lineTo(size.width * 0.55, size.height * 0.55);
    path.lineTo(size.width * 0.50, size.height * 0.6);
    path.close();
    canvas.drawPath(path, paint);
  }

  void drawOutFeedTriangle(Canvas canvas, Size size) {
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

  Paint drawAirIntakes(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.2, size.height * 0.2,
            size.width * 0.1, size.height * 0.2),
        paint);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.2, size.height * 0.6,
            size.width * 0.1, size.height * 0.2),
        paint);
    return paint;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}