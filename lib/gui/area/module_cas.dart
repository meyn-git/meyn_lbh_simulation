import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';

class ModuleCasWidget extends StatelessWidget {
  final ModuleCas cas;

  const ModuleCasWidget(this.cas, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: cas.toString(),
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(
            cas.inAndOutFeedDirection.toCompassDirection().degrees / 360),
        child: CustomPaint(painter: ModuleCasPainter(cas)),
      ),
    );
  }
}

class ModuleCasPainter extends CustomPainter {
  final ModuleCas cas;

  ModuleCasPainter(this.cas);

  @override
  void paint(Canvas canvas, Size size) {
    _drawRectangle(canvas, size);
    _drawInFeedTriangle(canvas, size);
    _drawOutFeedTriangle(canvas, size);
    _drawAirIntakes(canvas, size);
  }

  void _drawInFeedTriangle(Canvas canvas, Size size) {
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

  void _drawOutFeedTriangle(Canvas canvas, Size size) {
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

  _drawAirIntakes(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    bool left = cas.inAndOutFeedDirection == CardinalDirection.north &&
            cas.doorDirection == CardinalDirection.east ||
        cas.inAndOutFeedDirection == CardinalDirection.east &&
            cas.doorDirection == CardinalDirection.south ||
        cas.inAndOutFeedDirection == CardinalDirection.south &&
            cas.doorDirection == CardinalDirection.west ||
        cas.inAndOutFeedDirection == CardinalDirection.west &&
            cas.doorDirection == CardinalDirection.north;

    var x1 = left ? size.width * 0.2 : size.width * 0.7;
    var y1 = size.height * 0.2;
    var y2 = size.height * 0.6;
    var width = size.width * 0.1;
    var height = size.height * 0.2;
    canvas.drawRect(Rect.fromLTWH(x1, y1, width, height), paint);
    canvas.drawRect(Rect.fromLTWH(x1, y2, width, height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
