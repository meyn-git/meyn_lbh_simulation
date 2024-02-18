import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/gui/style.dart';

class LoadingForkLiftTruckWidget extends StatelessWidget {
  final LoadingForkLiftTruck forkLiftTruck;

  const LoadingForkLiftTruckWidget(this.forkLiftTruck, {super.key});

  @override
  Widget build(BuildContext context) {
    var style = LiveBirdsHandlingStyle.of(context);
    return RotationTransition(
      turns: AlwaysStoppedAnimation(paintDirection.toFraction()),
      child: CustomPaint(painter: LoadingForkLiftTruckPainter(style)),
    );
  }

  CompassDirection get paintDirection {
    if (forkLiftTruck.currentState is GetModuleGroupFromTruck) {
      return forkLiftTruck.outFeedDirection.opposite.toCompassDirection();
    } else {
      return forkLiftTruck.outFeedDirection.toCompassDirection();
    }
  }
}

class LoadingForkLiftTruckPainter extends CustomPainter {
  final LiveBirdsHandlingStyle style;
  LoadingForkLiftTruckPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = style.machineColor;
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
