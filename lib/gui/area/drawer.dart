import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class GrandeDrawerWidget extends StatelessWidget {
  final SystemLayout layout;
  final GrandeDrawer drawer;

  GrandeDrawerWidget(this.layout, this.drawer) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return RotationTransition(
      turns: AlwaysStoppedAnimation(drawer.position.rotationInFraction(layout)),
      child: drawer.position is DrawerPositionAndSize
          ? Transform.scale(
              scale: (drawer.position as DrawerPositionAndSize).scale,
              child: CustomPaint(painter: DrawerPainter(drawer, theme)))
          : CustomPaint(painter: DrawerPainter(drawer, theme)),
    );
  }
}

class DrawerPainter extends CustomPainter {
  final GrandeDrawer drawer;
  final LiveBirdsHandlingTheme theme;
  DrawerPainter(this.drawer, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = _color();
    paint.style = PaintingStyle.stroke;

    // var path = Path();
    // //rectangle starting bottom left
    // var left = offset.dx;
    // var middle = (size.width * factor) / 2 + offset.dx;
    // var right = size.width * factor + offset.dx;
    // var top = offset.dy;
    // var bottom = size.height * factor + offset.dy;

    // // paint square
    // path.moveTo(left, bottom);
    // path.lineTo(left, top);
    // path.lineTo(right, top);
    // path.lineTo(right, bottom);
    // path.lineTo(left, bottom);

    // if (paintTriangle) {
    //   //paint triangle pointing north
    //   path.lineTo(middle, top);
    //   path.lineTo(right, bottom);
    // }
    // canvas.drawPath(path, paint);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  Color _color() {
    switch (drawer.contents) {
      case BirdContents.noBirds:
        return theme.withoutBirdsColor;
      case BirdContents.stunnedBirds:
        return theme.withStunnedBirdsColor;
      case BirdContents.birdsBeingStunned:
        return theme.withBirdsBeingStunnedColor;
      case BirdContents.awakeBirds:
        return theme.withAwakeBirdsColor;
    }
  }
}
