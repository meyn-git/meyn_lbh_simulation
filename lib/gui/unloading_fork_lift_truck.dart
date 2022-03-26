import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/unloading_fork_lift_truck.dart';

class UnLoadingForkLiftTruckWidget extends StatelessWidget {
  final UnLoadingForkLiftTruck forkLiftTruck;

  const UnLoadingForkLiftTruckWidget(this.forkLiftTruck, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: forkLiftTruck.toString(),
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(paintDirection.degrees / 360),
        child: CustomPaint(painter: UnLoadingForkLiftTruckPainter()),
      ),
    );
  }

  CompassDirection get paintDirection {
    if (forkLiftTruck.currentState is PutModuleGroupOnTruck) {
      return forkLiftTruck.inFeedDirection.opposite.toCompassDirection();
    } else {
      return forkLiftTruck.inFeedDirection.toCompassDirection();
    }
  }
}

class UnLoadingForkLiftTruckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    var path = Path();

    path.moveTo(size.width * 0.30, size.height * 0.90);
    path.lineTo(size.width * 0.30, size.height * 0.50);
    path.lineTo(size.width * 0.35, size.height * 0.50);
    path.lineTo(size.width * 0.35, size.height * 0.10);
    path.lineTo(size.width * 0.40, size.height * 0.10);
    path.lineTo(size.width * 0.40, size.height * 0.50);
    path.lineTo(size.width * 0.60, size.height * 0.50);
    path.lineTo(size.width * 0.60, size.height * 0.10);
    path.lineTo(size.width * 0.65, size.height * 0.10);
    path.lineTo(size.width * 0.65, size.height * 0.50);
    path.lineTo(size.width * 0.70, size.height * 0.50);
    path.lineTo(size.width * 0.70, size.height * 0.90);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width * 0.3, size.height * 0.9);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
