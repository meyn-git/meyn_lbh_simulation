import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/module_tilter.dart';

class ModuleTilterWidget extends StatelessWidget {
  final ModuleTilter tilter;

  const ModuleTilterWidget(this.tilter, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tilter.toString(),
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(
            tilter.inFeedDirection.opposite.toCompassDirection().degrees / 360),
        child: CustomPaint(painter: ModuleTilterPainter(tilter)),
      ),
    );
  }
}

class ModuleTilterPainter extends CustomPainter {
  final ModuleTilter tilter;

  int maxBirdsOnDumpBelt;

  ModuleTilterPainter(this.tilter)
      : maxBirdsOnDumpBelt = tilter.minBirdsOnDumpBeltBuffer;

  @override
  void paint(Canvas canvas, Size size) {
    _drawConveyor(canvas, size);
    _drawReceivingConveyor(canvas, size);
    _drawDirectionTriangle(size, canvas);
    _drawBirdsOnReceivingConveyor(canvas, size);
  }

  void _drawDirectionTriangle(Size size, Canvas canvas) {
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

  _drawConveyor(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    var x1 = size.width * 0.3;
    var x2 = size.width * 0.7;
    var y1 = size.height * 0.1;
    var y2 = size.height * 0.9;
    canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), paint);
  }

  _drawReceivingConveyor(Canvas canvas, Size size) {
    var conveyorPaint = Paint();
    conveyorPaint.color = Colors.black;
    conveyorPaint.style = PaintingStyle.stroke;

    bool left = _dumpBeltOnLeftSide;
    var x1 = left ? 0.0 : size.width * 0.7;
    var x3 = left ? size.width * 0.3 : size.width;
    var y1 = size.height * 0.1;
    var y2 = size.height * 0.9;

    canvas.drawRect(Rect.fromLTRB(x1, y1, x3, y2), conveyorPaint);
  }

  _drawBirdsOnReceivingConveyor(Canvas canvas, Size size) {
    var birdPaint = Paint();
    birdPaint.color = Colors.grey;
    birdPaint.style = PaintingStyle.fill;

    bool left = _dumpBeltOnLeftSide;

    var x1 = left ? 0.0 : size.width - size.width * 0.3 * tilter.dumpBeltLoad;
    var x2 = left ? size.width * 0.3 * tilter.dumpBeltLoad : size.width;
    var y1 = size.height * 0.1;
    var y2 = size.height * 0.9;

    canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), birdPaint);
  }

  bool get _dumpBeltOnLeftSide {
    return tilter.inFeedDirection == CardinalDirection.north &&
            tilter.birdDirection == CardinalDirection.east ||
        tilter.inFeedDirection == CardinalDirection.east &&
            tilter.birdDirection == CardinalDirection.south ||
        tilter.inFeedDirection == CardinalDirection.south &&
            tilter.birdDirection == CardinalDirection.west ||
        tilter.inFeedDirection == CardinalDirection.west &&
            tilter.birdDirection == CardinalDirection.north;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
