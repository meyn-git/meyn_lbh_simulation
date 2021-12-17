import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/life_bird_handling_area.dart';

class BirdHangingConveyorWidget extends StatelessWidget {
  final BirdHangingConveyor birdHangingConveyor;

  BirdHangingConveyorWidget(this.birdHangingConveyor);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        birdHangingConveyor.running=!birdHangingConveyor.running;
      },
      child: Tooltip(
        message: birdHangingConveyor.toString(),
        child: RotationTransition(
          turns: AlwaysStoppedAnimation(
              birdHangingConveyor.direction.toCompassDirection().degrees / 360),
          child: CustomPaint(
              painter: BirdHangingConveyorPainter(birdHangingConveyor)),
        ),
      ),
    );
  }
}

class BirdHangingConveyorPainter extends CustomPainter {
  final BirdHangingConveyor birdHangingConveyor;

  BirdHangingConveyorPainter(this.birdHangingConveyor);

  @override
  void paint(Canvas canvas, Size size) {
    _paintLine(canvas, size);
    _paintShackles(canvas, size);
  }

  _paintLine(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
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
    var shackleLine=birdHangingConveyor.shackleLine;
    var fillPaint = Paint();
    fillPaint.color = Colors.black;
    fillPaint.style = PaintingStyle.fill;
    var strokePaint = Paint();
    strokePaint.color = Colors.black;
    strokePaint.style = PaintingStyle.stroke;

    for (int i=0;i<10;i++) {
      bool fullShackle=shackleLine.hasBirdInShackle(i);
      Paint paint=fullShackle?fillPaint:strokePaint;
      canvas.drawCircle(Offset(x,y), size.width/30, paint);
      y+=shackleDistance;
    }
  }
}
