import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_shuttle/module_suttle.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class ModuleShuttlePainter extends ShapePainter {
  ModuleShuttlePainter(ModuleShuttle shuttle, LiveBirdsHandlingTheme theme)
      : super(shape: shuttle.shape, theme: theme);
}

class ModuleShuttleFrameShape extends CompoundShape {
  static const double sectionWidthInMeters = 2.8;
  late List<OffsetInMeters> moduleGroupCenters;

  late Map<ShuttleLinkLocation, OffsetInMeters> linkLocationOffsets;

  ModuleShuttleFrameShape(ModuleShuttle shuttle) {
    var widthInMeters = shuttle.nrOfSections * sectionWidthInMeters;
    var outLine = Box(
        xInMeters: widthInMeters,
        yInMeters: ModuleShuttleCarrierShape.lengthInMeters);
    add(OffsetInMeters.zero, outLine);

    moduleGroupCenters = [
      for (int i = 0; i < shuttle.nrOfSections; i++)
        OffsetInMeters(
                xInMeters: (i + 0.5) * sectionWidthInMeters,
                yInMeters: ModuleShuttleCarrierShape.lengthInMeters / 2) -
            centerCenter
    ];

    linkLocationOffsets = {
      for (var linkLocation in shuttle.linkLocations)
        linkLocation: OffsetInMeters(
                xInMeters: (linkLocation.position + 0.5) * sectionWidthInMeters,
                yInMeters: linkLocation.side.direction ==
                        const CompassDirection.north()
                    ? 0
                    : ModuleShuttleCarrierShape.lengthInMeters) -
            centerCenter
    };
  }
}

class ModuleShuttleCarrierPainter extends ShapePainter {
  ModuleShuttleCarrierPainter(
      ModuleShuttleCarrier carrier, LiveBirdsHandlingTheme theme)
      : super(shape: carrier.shape, theme: theme);
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
  double get centerToAxcelCenterInMeters => widthInMeters / 2;
}
