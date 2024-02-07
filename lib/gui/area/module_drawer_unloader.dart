import 'package:fling_units/fling_units.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_unloader.dart';
import 'package:meyn_lbh_simulation/gui/area/drawer_conveyor.dart';

import '../../domain/area/player.dart';

class ModuleDrawerUnloaderWidget extends StatelessWidget {
  final ModuleDrawerUnloader unloader;

  const ModuleDrawerUnloaderWidget(this.unloader, {super.key});

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

// class UnloaderDrawerLiftWidget extends StatelessWidget {
//   final UnloaderDrawerLift drawerLift;

//   const UnloaderDrawerLiftWidget(this.drawerLift, {super.key});

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () {
//         GetIt.instance<Player>().selectedCell = drawerLift;
//       },
//       child: RotationTransition(
//         turns: AlwaysStoppedAnimation(
//             drawerLift.birdDirection.opposite.toCompassDirection().degrees /
//                 360),
//         child: CustomPaint(painter: UnloaderDrawerLiftPainter(drawerLift)),
//       ),
//     );
//   }
// }

class UnloaderDrawerLiftPainter extends DrawerConveyorPainter {
  final UnloaderDrawerLift drawerLift;

  UnloaderDrawerLiftPainter(this.drawerLift);

  @override
  void paint(Canvas canvas, Size size) {
    double sizePerMeter = size.width / drawerLift.size.width;
    for (int level = 0; level < drawerLift.nrOfLiftPositions; level++) {
      _drawDrawer(canvas, sizePerMeter, drawerLift.topLeftToLiftLevel(level));
    }
  }

  _drawDrawer(
    Canvas canvas,
    double sizePerMeter,
    Offset topLeftToLiftLevel,
  ) {
    var paint = Paint();
    paint.color = Colors.grey;
    paint.style = PaintingStyle.stroke;

    var x1 = topLeftToLiftLevel.dx * sizePerMeter;
    var y1 = topLeftToLiftLevel.dy * sizePerMeter;
    var drawerLengthInMeters =
        GrandeDrawerModuleType.drawerOutSideLength.as(meters);
    var x2 = x1 + drawerLengthInMeters * sizePerMeter;
    var y2 = y1 + drawerLengthInMeters * sizePerMeter;
    canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
