import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';

import '../../domain/area/player.dart';

class ModuleConveyorWidget extends StatelessWidget {
  final ModuleConveyor moduleConveyor;

  const ModuleConveyorWidget(this.moduleConveyor, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        GetIt.instance<Player>().selectedCell = moduleConveyor;
      },
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(moduleConveyor.inFeedDirection.opposite
                .toCompassDirection()
                .degrees /
            360),
        child: CustomPaint(painter: ModuleConveyorPainter()),
      ),
    );
  }
}

class ModuleConveyorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    drawRectangle(canvas, size);
    drawDirectionTriangle(size, canvas);
  }

  void drawDirectionTriangle(Size size, Canvas canvas) {
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

  drawRectangle(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    var x1 = size.width * 0.3;
    var x2 = size.width * 0.7;
    var y1 = size.height * 0.1;
    var y2 = size.height * 0.9;
    canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
