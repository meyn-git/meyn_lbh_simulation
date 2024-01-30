import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyors.dart';

class DrawerConveyorWidget extends StatelessWidget {
  final DrawerConveyor drawerConveyor;

  DrawerConveyorWidget(this.drawerConveyor) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: DrawerConveyorPainter(drawerConveyor));
}

class DrawerConveyorPainter extends CustomPainter {
  final DrawerConveyor drawerConveyor;

  DrawerConveyorPainter(this.drawerConveyor);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;

    var path = Path();

    // paint line TODO diagnol lines using vector for direction
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
