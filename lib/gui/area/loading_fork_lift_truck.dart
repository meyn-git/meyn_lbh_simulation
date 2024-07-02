import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class LoadingForkLiftTruckPainter extends CustomPainter {
  final LiveBirdsHandlingTheme theme;
  LoadingForkLiftTruckPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = theme.machineColor;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(forkLiftTruckPathFacingNorth(size), paint);
  }

  static const xWheelOutside = 0.0;
  static const xBody = 0.07;
  static const xForkOutside = 0.14;
  static const xWheelInside = 0.21;
  static const xForkInside = 0.28;

  static const yForkCurveTop = 0.0;
  static const yForkCurveBottom = 0.025;
  static const yForkCarriageTop = 0.475;
  static const yMastTop = 0.5;
  static const yWheelTop = 0.525;
  static const yBodyTop = 0.55;
  static const yWheelBottom = 0.675;
  static const yCabinBottom = 0.8;
  static const yCabinCurveBottom = 0.825;
  static const yBodyBottom = 0.90;
  static const yBodyCurveBottom = 1;

  Path forkLiftTruckPathFacingNorth(Size size) {
    var path = Path();
    addLeftForkToPath(path, size);
    addRightForkToPath(path, size);
    addForkCarriageToPath(path, size);
    addMastToPath(path, size);
    addLeftWheelToPath(path, size);
    addRightWheelToPath(path, size);
    addBodyToPath(path, size);
    addCabinToPath(path, size);
    return path;
  }

  void addBodyToPath(Path path, Size size) {
    // bottom left
    path.moveTo(size.width * xBody, size.height * yBodyBottom);
    // top left
    path.lineTo(size.width * xBody, size.height * yBodyTop);
    // top right
    path.lineTo(size.width * (1 - xBody), size.height * yBodyTop);
    // bottom right
    path.lineTo(size.width * (1 - xBody), size.height * yBodyBottom);
    // curved bottom
    path.quadraticBezierTo(size.width * 0.5, size.height * yBodyCurveBottom,
        size.width * xBody, size.height * yBodyBottom);
  }

  void addRightWheelToPath(Path path, Size size) {
    // bottom left
    path.moveTo(size.width * (1 - xBody), size.height * yWheelBottom);
    // bottom right
    path.lineTo(size.width * (1 - xWheelOutside), size.height * yWheelBottom);
    // top right
    path.lineTo(size.width * (1 - xWheelOutside), size.height * yWheelTop);
    // top left
    path.lineTo(size.width * (1 - xWheelInside), size.height * yWheelTop);
  }

  void addForkCarriageToPath(Path path, Size size) {
    // fork carriage
    path.addRect(Rect.fromLTRB(
        size.width * xWheelOutside,
        size.height * yForkCarriageTop,
        size.width * (1 - xWheelOutside),
        size.height * yMastTop));
  }

  void addLeftWheelToPath(Path path, Size size) {
    // bottom right
    path.moveTo(size.width * xBody, size.height * yWheelBottom);
    // bottom left
    path.lineTo(size.width * xWheelOutside, size.height * yWheelBottom);
    // top left
    path.lineTo(size.width * xWheelOutside, size.height * yWheelTop);
    // top right
    path.lineTo(size.width * xWheelInside, size.height * yWheelTop);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  void addLeftForkToPath(Path path, Size size) {
    // bottom left
    path.moveTo(size.width * xForkOutside, size.height * yForkCarriageTop);
    // top left
    path.lineTo(size.width * xForkOutside, size.height * yForkCurveBottom);
    // curve
    path.quadraticBezierTo(
        size.width * (xForkOutside + ((xForkInside - xForkOutside) / 2)),
        size.height * yForkCurveTop,
        size.width * xForkInside,
        size.height * yForkCurveBottom);
    // bottom right
    path.lineTo(size.width * xForkInside, size.height * yForkCarriageTop);
  }

  void addRightForkToPath(Path path, Size size) {
    // bottom right
    path.moveTo(
        size.width * (1 - xForkOutside), size.height * yForkCarriageTop);
    // top right
    path.lineTo(
        size.width * (1 - xForkOutside), size.height * yForkCurveBottom);
    // curve
    path.quadraticBezierTo(
        size.width * (1 - (xForkOutside + ((xForkInside - xForkOutside) / 2))),
        size.height * yForkCurveTop,
        size.width * (1 - xForkInside),
        size.height * yForkCurveBottom);
    // bottom left
    path.lineTo(size.width * (1 - xForkInside), size.height * yForkCarriageTop);
  }

  void addMastToPath(Path path, Size size) {
    path.addRect(Rect.fromLTRB(
        size.width * xWheelInside,
        size.height * yMastTop,
        size.width * (1 - xWheelInside),
        size.height * yBodyTop));
  }

  void addCabinToPath(Path path, Size size) {
    // bottom left
    path.moveTo(size.width * xWheelInside, size.height * yCabinBottom);
    // top left
    path.lineTo(size.width * xWheelInside, size.height * yBodyTop);
    // top right
    path.lineTo(size.width * (1 - xWheelInside), size.height * yBodyTop);
    // bottom right
    path.lineTo(size.width * (1 - xWheelInside), size.height * yCabinBottom);
    // curved bottom
    path.quadraticBezierTo(size.width * 0.5, size.height * yCabinCurveBottom,
        size.width * xWheelInside, size.height * yCabinBottom);
  }
}
