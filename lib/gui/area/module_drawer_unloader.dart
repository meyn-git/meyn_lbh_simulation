import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_unloader.dart';

import '../../domain/area/player.dart';

class ModuleDrawerUnloaderWidget extends StatelessWidget {
  final ModuleDrawerUnloader unloader;

  const ModuleDrawerUnloaderWidget(this.unloader, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        GetIt.instance<Player>().selectedCell = unloader;
      },
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(
            unloader.inFeedDirection.opposite.toCompassDirection().degrees /
                360),
        child: CustomPaint(painter: ModuleDrawerUnloaderPainter(unloader)),
      ),
    );
  }
}

class ModuleDrawerUnloaderPainter extends CustomPainter {
  final ModuleDrawerUnloader unloader;

  ModuleDrawerUnloaderPainter(this.unloader);

  @override
  void paint(Canvas canvas, Size size) {
    _drawConveyor(canvas, size);
    _drawDirectionTriangle(size, canvas);
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class UnloaderDrawerLiftWidget extends StatelessWidget {
  final UnloaderDrawerLift drawerLift;

  const UnloaderDrawerLiftWidget(this.drawerLift, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        GetIt.instance<Player>().selectedCell = drawerLift;
      },
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(
            drawerLift.birdDirection.opposite.toCompassDirection().degrees /
                360),
        child: CustomPaint(painter: UnloaderDrawerLiftPainter(drawerLift)),
      ),
    );
  }
}

class UnloaderDrawerLiftPainter extends CustomPainter {
  final UnloaderDrawerLift drawerLift;

  UnloaderDrawerLiftPainter(this.drawerLift);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < drawerLift.nrOfPositions; i++) {
      _drawDrawer(canvas, size, i / (drawerLift.nrOfPositions - 1),
          drawerLift.positions[i]);
    }
  }

  _drawDrawer(
    Canvas canvas,
    Size size,
    //number between 0 and 1
    double offset,
    bool positionHasDrawer,
  ) {
    var paint = Paint();
    paint.color = positionHasDrawer ? Colors.black : Colors.grey.shade400;
    paint.style = PaintingStyle.stroke;
    const maxOffset = 0.3;
    var offset2 = offset * maxOffset - (maxOffset / 2);
    var x1 = size.width * 0.35;
    var x2 = size.width * 0.65;
    var y1 = size.height * (0.35 + offset2);
    var y2 = size.height * (0.65 + offset2);
    if (offset == 1) {
      canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), paint);
    } else {
      canvas.drawLine(Offset(x1, y2), Offset(x1, y1), paint);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y1), paint);
      canvas.drawLine(Offset(x2, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
