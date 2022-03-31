import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';

import '../../domain/area/player.dart';

class ModuleStackerWidget extends StatelessWidget {
  final ModuleStacker stacker;

  const ModuleStackerWidget(this.stacker, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          GetIt.instance<Player>().selectedCell = stacker;
        },
        child: RotationTransition(
            turns: AlwaysStoppedAnimation(
                stacker.inFeedDirection.opposite.toCompassDirection().degrees /
                    360),
            child: CustomPaint(painter: ModuleStackerPainter(stacker))));
  }
}

class ModuleStackerPainter extends CustomPainter {
  final ModuleStacker stacker;

  ModuleStackerPainter(this.stacker);

  @override
  void paint(Canvas canvas, Size size) {
    _drawRectangle(canvas, size);
    _drawSupports(canvas, size);
    _drawDirectionTriangle(canvas, size);
  }

  _drawDirectionTriangle(Canvas canvas, Size size) {
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

  _drawSupports(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    var x1 = size.width * 0.2;
    var y1 = size.height * 0.1;
    var x2 = size.width * 0.7;
    var y2 = size.height * 0.7;
    var width = size.width * 0.1;
    var height = size.height * 0.2;
    canvas.drawRect(Rect.fromLTWH(x1, y1, width, height), paint);
    canvas.drawRect(Rect.fromLTWH(x2, y1, width, height), paint);
    canvas.drawRect(Rect.fromLTWH(x1, y2, width, height), paint);
    canvas.drawRect(Rect.fromLTWH(x2, y2, width, height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
