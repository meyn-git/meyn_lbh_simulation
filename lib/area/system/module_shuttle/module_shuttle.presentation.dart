import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_shuttle/module_shuttle.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class ModuleShuttlePainter extends ShapePainter {
  ModuleShuttlePainter(ModuleShuttle shuttle, LiveBirdsHandlingTheme theme)
    : super(shape: shuttle.shape, theme: theme);
}

class ModuleShuttleFrameShape extends CompoundShape {
  static const double sideWidthInMeters = 1.8;
  late List<OffsetInMeters> moduleGroupCenters;

  late Map<ShuttleLinkLocation, OffsetInMeters> linkLocationOffsets;

  ModuleShuttleFrameShape(ModuleShuttle shuttle) {
    var widthInMeters =
        sideWidthInMeters +
        shuttle.betweenPositionsInMeters.reduce((a, b) => a + b) +
        sideWidthInMeters;
    var outLine = Box(
      xInMeters: widthInMeters,
      yInMeters: ModuleShuttleCarrierShape.lengthInMeters,
    );
    add(OffsetInMeters.zero, outLine);

    moduleGroupCenters = [
      for (int i = 0; i < shuttle.nrOfPositions; i++)
        OffsetInMeters(
              xInMeters: xInMetersForPosition(shuttle, i),
              yInMeters: ModuleShuttleCarrierShape.lengthInMeters / 2,
            ) -
            centerCenter,
    ];

    linkLocationOffsets = {
      for (var linkLocation in shuttle.linkLocations)
        linkLocation:
            OffsetInMeters(
              xInMeters: xInMetersForPosition(shuttle, linkLocation.position),
              yInMeters:
                  linkLocation.side.direction == const CompassDirection.north()
                  ? 0
                  : ModuleShuttleCarrierShape.lengthInMeters,
            ) -
            centerCenter,
    };
  }

  double xInMetersForPosition(ModuleShuttle shuttle, int position) {
    if (position == 0) {
      return sideWidthInMeters;
    }
    if (position == 1) {
      return sideWidthInMeters + shuttle.betweenPositionsInMeters.first;
    }
    return sideWidthInMeters +
        shuttle.betweenPositionsInMeters.take(position).reduce((a, b) => a + b);
  }
}

class ModuleShuttleCarrierPainter extends ShapePainter {
  ModuleShuttleCarrierPainter(
    ModuleShuttleCarrier carrier,
    LiveBirdsHandlingTheme theme,
  ) : super(shape: carrier.shape, theme: theme);
}

class ModuleShuttleCarrierShape extends VehicleShape {
  static const double lengthInMeters = 3.0;
  static const double widthInMeters = 1.3;

  late List<OffsetInMeters> moduleCenters;

  late Map<ShuttleLinkLocation, OffsetInMeters> linkLocationOffsets;

  ModuleShuttleCarrierShape() {
    var carrier = Box(xInMeters: widthInMeters, yInMeters: lengthInMeters);
    add(OffsetInMeters.zero, carrier);
  }

  @override
  double get centerToAxleCenterInMeters => widthInMeters / 2;
}
