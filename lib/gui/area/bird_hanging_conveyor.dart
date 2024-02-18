import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/style.dart';

import '../../domain/area/player.dart';

class BirdHangingConveyorWidget extends StatelessWidget {
  final BirdHangingConveyor birdHangingConveyor;

  const BirdHangingConveyorWidget(this.birdHangingConveyor, {super.key});

  @override
  Widget build(BuildContext context) {
    var style = LiveBirdsHandlingStyle.of(context);
    return RotationTransition(
      turns: AlwaysStoppedAnimation(
          birdHangingConveyor.direction.toCompassDirection().toFraction()),
      child: CustomPaint(
          painter: BirdHangingConveyorPainter(birdHangingConveyor, style)),
    );
  }

  Player get player => GetIt.instance<Player>();
}

class BirdHangingConveyorPainter extends CustomPainter {
  final BirdHangingConveyor birdHangingConveyor;
  final LiveBirdsHandlingStyle style;
  BirdHangingConveyorPainter(this.birdHangingConveyor, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    _paintLine(canvas, size);
    _paintShackles(canvas, size);
  }

  _paintLine(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = style.machineColor;
    canvas.drawLine(
      Offset(size.width / 2, 0.0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void _paintShackles(Canvas canvas, Size size) {
    var shackleDistance = size.height / 10;
    var x = size.width / 2;
    var y = shackleDistance *
        (birdHangingConveyor.elapsedTime.inMilliseconds /
            birdHangingConveyor.timePerBird.inMilliseconds);
    var shackleLine = birdHangingConveyor.shackleLine;
    var fillPaint = Paint();
    fillPaint.color = style.machineColor;
    fillPaint.style = PaintingStyle.fill;
    var strokePaint = Paint();
    strokePaint.color = style.machineColor;
    strokePaint.style = PaintingStyle.stroke;

    for (int i = 0; i < 10; i++) {
      bool fullShackle = shackleLine.hasBirdInShackle(i);
      Paint paint = fullShackle ? fillPaint : strokePaint;
      canvas.drawCircle(Offset(x, y), size.width / 30, paint);
      y += shackleDistance;
    }
  }
}
