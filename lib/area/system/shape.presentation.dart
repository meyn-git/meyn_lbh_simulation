import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

//TODO make this a concrete class with GENERIC TYPE and remove all implementations
abstract class ShapePainter extends CustomPainter {
  final LiveBirdsHandlingTheme theme;
  final Shape shape;

  ShapePainter({required this.shape, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    var sizePerMeter = size.width / shape.xInMeters;
    shape.paint(canvas, theme, OffsetInMeters.zero, sizePerMeter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      shape.shouldRepaint;

  // void _paintShape(Canvas canvas, Shape shape, double sizeFactor) {
  //   var paint = Paint();
  //   paint.color = theme.machineColor;
  //   paint.style = PaintingStyle.stroke;
  //   canvas.drawRect(
  //       Rect.fromLTWH(
  //           shape.topLeft.xInMeters * sizeFactor,
  //           shape.topLeft.yInMeters * sizeFactor,
  //           shape.size.xInMeters * sizeFactor,
  //           shape.size.yInMeters * sizeFactor),
  //       paint);
  // }
}

abstract class Shape {
  double get xInMeters;
  double get yInMeters;

  late final ShapeTopLeftOffset topLeft = ShapeTopLeftOffset(
    shape: this,
    xInMeters: 0,
    yInMeters: 0,
  );
  late final ShapeTopLeftOffset topCenter = ShapeTopLeftOffset(
    shape: this,
    xInMeters: xInMeters * 0.5,
    yInMeters: 0,
  );
  late final ShapeTopLeftOffset topRight = ShapeTopLeftOffset(
    shape: this,
    xInMeters: xInMeters,
    yInMeters: 0,
  );

  late final ShapeTopLeftOffset centerLeft = ShapeTopLeftOffset(
    shape: this,
    xInMeters: 0,
    yInMeters: yInMeters * 0.5,
  );
  late final ShapeTopLeftOffset centerCenter = ShapeTopLeftOffset(
    shape: this,
    xInMeters: xInMeters * 0.5,
    yInMeters: yInMeters * 0.5,
  );
  late final ShapeTopLeftOffset centerRight = ShapeTopLeftOffset(
    shape: this,
    xInMeters: xInMeters,
    yInMeters: yInMeters * 0.5,
  );

  late final ShapeTopLeftOffset bottomLeft = ShapeTopLeftOffset(
    shape: this,
    xInMeters: 0,
    yInMeters: yInMeters,
  );
  late final ShapeTopLeftOffset bottomCenter = ShapeTopLeftOffset(
    shape: this,
    xInMeters: xInMeters * 0.5,
    yInMeters: yInMeters,
  );
  late final ShapeTopLeftOffset bottomRight = ShapeTopLeftOffset(
    shape: this,
    xInMeters: xInMeters,
    yInMeters: yInMeters,
  );

  bool get shouldRepaint => false;

  void paint(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  );

  late final SizeInMeters size = SizeInMeters(
    xInMeters: xInMeters,
    yInMeters: yInMeters,
  );
}

/// represents the offset from the top left of the shape
class ShapeTopLeftOffset extends OffsetInMeters {
  final Shape shape;
  ShapeTopLeftOffset({
    required this.shape,
    required super.xInMeters,
    required super.yInMeters,
  });

  @override
  ShapeTopLeftOffset addX(double xMetersToAdd) => ShapeTopLeftOffset(
    shape: shape,
    xInMeters: xInMeters + xMetersToAdd,
    yInMeters: yInMeters,
  );

  @override
  ShapeTopLeftOffset addY(double yMetersToAdd) => ShapeTopLeftOffset(
    shape: shape,
    xInMeters: xInMeters,
    yInMeters: yInMeters + yMetersToAdd,
  );
}

class Box extends Shape {
  @override
  final double xInMeters;
  @override
  final double yInMeters;
  Box({required this.xInMeters, required this.yInMeters});

  @override
  void paint(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  ) {
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(
        offset.xInMeters * sizePerMeter,
        offset.yInMeters * sizePerMeter,
        xInMeters * sizePerMeter,
        yInMeters * sizePerMeter,
      ),
      paint,
    );
  }
}

class BoxWithCurvedSouthSide extends Shape {
  @override
  final double xInMeters;
  @override
  final double yInMeters;
  final double yCurveInMeters;
  BoxWithCurvedSouthSide({
    required this.xInMeters,
    required this.yInMeters,
    required this.yCurveInMeters,
  });

  @override
  void paint(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  ) {
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;

    final path = Path();
    // top left
    path.moveTo(
      offset.xInMeters * sizePerMeter,
      offset.yInMeters * sizePerMeter,
    );
    // top right
    path.lineTo(
      (offset.xInMeters + xInMeters) * sizePerMeter,
      offset.yInMeters * sizePerMeter,
    );
    // bottom -curve right
    path.lineTo(
      (offset.xInMeters + xInMeters) * sizePerMeter,
      (offset.yInMeters + yInMeters - yCurveInMeters) * sizePerMeter,
    );
    // bottom curve
    path.quadraticBezierTo(
      (offset.xInMeters + xInMeters / 2) * sizePerMeter,
      (offset.yInMeters + yInMeters + yCurveInMeters) *
          sizePerMeter, // Control point for the curve
      offset.xInMeters * sizePerMeter,
      (offset.yInMeters + yInMeters - yCurveInMeters) *
          sizePerMeter, // Endpoint of the curve
    );
    path.close();
    canvas.drawPath(path, paint);
  }
}

class BoxWithCurvedNorthSide extends Shape {
  @override
  final double xInMeters;
  @override
  final double yInMeters;
  final double yCurveInMeters;
  BoxWithCurvedNorthSide({
    required this.xInMeters,
    required this.yInMeters,
    required this.yCurveInMeters,
  });

  @override
  void paint(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  ) {
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;

    final path = Path();
    // left, bottom of curve
    path.moveTo(
      offset.xInMeters * sizePerMeter,
      (offset.yInMeters + yCurveInMeters) * sizePerMeter,
    );

    // curve from left to right
    path.quadraticBezierTo(
      (offset.xInMeters + xInMeters / 2) * sizePerMeter,
      (offset.yInMeters - yCurveInMeters) *
          sizePerMeter, // Control point for the curve
      (offset.xInMeters + xInMeters) * sizePerMeter,
      (offset.yInMeters + yCurveInMeters) *
          sizePerMeter, // Endpoint of the curve
    );
    //  to bottom right
    path.lineTo(
      (offset.xInMeters + xInMeters) * sizePerMeter,
      (offset.yInMeters + yInMeters) * sizePerMeter,
    );
    // to bottom left
    path.lineTo(
      (offset.xInMeters) * sizePerMeter,
      (offset.yInMeters + yInMeters) * sizePerMeter,
    );

    path.close();
    canvas.drawPath(path, paint);
  }
}

/// [InvisibleBox] e.g. for padding
class InvisibleBox extends Box {
  InvisibleBox({required super.xInMeters, required super.yInMeters});

  @override
  void paint(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  ) {
    //no painting (invisible)
  }
}

class Circle extends Shape {
  @override
  final double xInMeters;
  @override
  final double yInMeters;

  Circle({required double diameterInMeters})
    : xInMeters = diameterInMeters,
      yInMeters = diameterInMeters;

  @override
  void paint(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  ) {
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(
      ((offset + centerCenter) * sizePerMeter).toOffset(),
      xInMeters * 0.5 * sizePerMeter,
      paint,
    );
  }
}

abstract class CompoundShape extends Shape {
  @override
  double xInMeters = 0;
  @override
  double yInMeters = 0;
  Map<Shape, OffsetInMeters> topLefts = {};
  CompoundShape();

  link(ShapeTopLeftOffset anchor1, anchor2) {
    if (!topLefts.keys.contains(anchor1.shape)) {
      topLefts[anchor1.shape] = topLefts.isEmpty
          ? OffsetInMeters.zero
          : anchor1;
    }

    if (topLefts.keys.contains(anchor2.shape)) {
      throw ArgumentError(
        'the shape of anchor2 was already added. Swap anchor1 and anchor2',
      );
    }
    topLefts[anchor2.shape] =
        topLefts[anchor1.shape]! + anchor1 + (anchor2 * -1.0);
    _calculateSize();
  }

  void add(OffsetInMeters topLeft, Shape shape) {
    topLefts[shape] = topLeft;
    _calculateSize();
  }

  _calculateSize() {
    var left = 0.0;
    var top = 0.0;
    for (var shape in topLefts.keys) {
      var topLeft = topLefts[shape]!;
      left = min(left, topLeft.xInMeters);
      top = min(top, topLeft.yInMeters);
    }
    var topLeftCorrection = OffsetInMeters(
      xInMeters: left * -1,
      yInMeters: top * -1,
    );
    xInMeters = 0.0;
    yInMeters = 0.0;
    for (var shape in topLefts.keys) {
      var topLeft = topLefts[shape]! + topLeftCorrection;
      topLefts[shape] = topLeft;
      var bottomRight = topLeft + shape.bottomRight;
      xInMeters = max(xInMeters, bottomRight.xInMeters);
      yInMeters = max(yInMeters, bottomRight.yInMeters);
    }
  }

  @override
  void paint(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  ) {
    for (var shape in topLefts.keys) {
      shape.paint(canvas, theme, offset + topLefts[shape]!, sizePerMeter);
    }
  }
}
