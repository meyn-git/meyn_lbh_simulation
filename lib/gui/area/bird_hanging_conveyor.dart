import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/bird_hanging_conveyor.dart';
import 'package:user_command/user_command.dart';

import '../../domain/area/player.dart';

class BirdHangingConveyorWidget extends StatelessWidget {
  final BirdHangingConveyor birdHangingConveyor;

  const BirdHangingConveyorWidget(this.birdHangingConveyor, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        CommandPopupMenu(context, _commands, title: "Bird Hanging Conveyor");
      },
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(
            birdHangingConveyor.direction.toCompassDirection().degrees / 360),
        child: CustomPaint(
            painter: BirdHangingConveyorPainter(birdHangingConveyor)),
      ),
    );
  }

  List<Command> get _commands => [_startCommand, _stopCommand, _monitorCommand];

  Command get _startCommand => Command.dynamic(
        name: () => 'Start line',
        visible: () => !birdHangingConveyor.running,
        icon: () => null,
        action: () {
          birdHangingConveyor.running = true;
        },
      );

  Command get _stopCommand => Command.dynamic(
        name: () => 'Stop line',
        visible: () => birdHangingConveyor.running,
        icon: () => null,
        action: () {
          birdHangingConveyor.running = false;
        },
      );

  Player get player => GetIt.instance<Player>();

  Command get _monitorCommand => Command.dynamic(
        name: () => 'Monitor',
        visible: () => player.objectsToMonitor != birdHangingConveyor,
        icon: () => null,
        action: () {
          player.objectsToMonitor.add(birdHangingConveyor);
        },
      );
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
    var shackleLine = birdHangingConveyor.shackleLine;
    var fillPaint = Paint();
    fillPaint.color = Colors.black;
    fillPaint.style = PaintingStyle.fill;
    var strokePaint = Paint();
    strokePaint.color = Colors.black;
    strokePaint.style = PaintingStyle.stroke;

    for (int i = 0; i < 10; i++) {
      bool fullShackle = shackleLine.hasBirdInShackle(i);
      Paint paint = fullShackle ? fillPaint : strokePaint;
      canvas.drawCircle(Offset(x, y), size.width / 30, paint);
      y += shackleDistance;
    }
  }
}
