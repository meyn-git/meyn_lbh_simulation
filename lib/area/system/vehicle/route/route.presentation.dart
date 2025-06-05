import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/route/route.domain.dart';

class RouteWidget extends StatelessWidget {
  final VehicleRoute route;

  RouteWidget(this.route) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return CustomPaint(painter: RoutePainter(route, theme));
  }
}

class RoutePainter extends CustomPainter {
  final VehicleRoute route;
  final LiveBirdsHandlingTheme theme;

  RoutePainter(this.route, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint routePaint = Paint()
      ..color = theme.machineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    var sizePerMeter = size.width / route.size.xInMeters;
    final path = Path()
      ..moveTo(
        route.points[0].xInMeters * sizePerMeter,
        route.points[0].yInMeters * sizePerMeter,
      );
    for (int i = 1; i < route.points.length; i++) {
      path.lineTo(
        route.points[i].xInMeters * sizePerMeter,
        route.points[i].yInMeters * sizePerMeter,
      );
    }
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
