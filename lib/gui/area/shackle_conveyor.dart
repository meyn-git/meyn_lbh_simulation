import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ShackleConveyorPainter extends ShapePainter {
  ShackleConveyorPainter(
      ShackleConveyor shackleConveyor, LiveBirdsHandlingTheme theme)
      : super(shape: shackleConveyor.shape, theme: theme);
}

class ShackleConveyorShape extends Shape {
  final ShackleConveyor shackleConveyor;
  static const double inchInMeters = 0.0254;

  late final OffsetInMeters centerToBirdInLink = OffsetInMeters(
      xInMeters: shackleConveyor.direction == Direction.counterClockWise
          ? shackleDiameterInMeters * -0.5
          : shackleDiameterInMeters * 0.5,
      yInMeters: 2);
  ShackleConveyorShape(this.shackleConveyor);

  /// repaint the shackles
  @override
  bool get shouldRepaint => true;

  @override
  void paint(Canvas canvas, LiveBirdsHandlingTheme theme, OffsetInMeters offset,
      double sizePerMeter) {
    _paintLine(canvas, theme, offset, sizePerMeter);
    _paintShackles(canvas, theme, offset, sizePerMeter);
  }

  late final double shacklePitchInMeters =
      shackleConveyor.shacklePitchInInches * inchInMeters;

  late final double shackleDiameterInMeters = shacklePitchInMeters * 0.5;

  @override
  double get xInMeters => shackleDiameterInMeters;

  @override
  double get yInMeters => 5;

  _paintLine(Canvas canvas, LiveBirdsHandlingTheme theme, OffsetInMeters offset,
      double sizePerMeter) {
    var paint = Paint();
    paint.color = theme.machineColor;

    var x = shackleDiameterInMeters * 0.5 * sizePerMeter;
    canvas.drawLine(
      Offset(x, 0.0),
      Offset(x, yInMeters * sizePerMeter),
      paint,
    );
  }

  void _paintShackles(Canvas canvas, LiveBirdsHandlingTheme theme,
      OffsetInMeters offset, double sizePerMeter) {
    var shacklePitchInMeters =
        shackleConveyor.shacklePitchInInches * inchInMeters;

    var fillPaint = Paint();
    fillPaint.color = theme.machineColor;
    fillPaint.style = PaintingStyle.fill;
    var strokePaint = Paint();
    strokePaint.color = theme.machineColor;
    strokePaint.style = PaintingStyle.stroke;

    var fraction = 1 -
        (shackleConveyor.elapsedTime.inMilliseconds /
            shackleConveyor.timePerBird.inMilliseconds);
    var position = OffsetInMeters(
        xInMeters: shackleDiameterInMeters * 0.5,
        yInMeters: shacklePitchInMeters * fraction +
            yInMeters -
            shacklePitchInMeters * 1.5);
    var radius = shackleDiameterInMeters * sizePerMeter * 0.5;

    int visibleShackles = (yInMeters / shacklePitchInMeters).truncate();
    for (int i = 0; i < visibleShackles; i++) {
      bool fullShackle = shackleConveyor.hasBirdInShackle(i);
      Paint paint = fullShackle ? fillPaint : strokePaint;

      canvas.drawCircle(position.toOffset() * sizePerMeter, radius, paint);
      position = position.addY(-shacklePitchInMeters);
    }
  }
}
