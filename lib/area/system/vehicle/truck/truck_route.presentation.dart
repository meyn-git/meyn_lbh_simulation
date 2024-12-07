import 'package:meyn_lbh_simulation/area/system/vehicle/route/route.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck_route.domain.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class TruckRoutesPainter extends RoutePainter {
  TruckRoutesPainter(TruckRoutes system, LiveBirdsHandlingTheme theme)
      : super(system.fullRoute, theme);
}
