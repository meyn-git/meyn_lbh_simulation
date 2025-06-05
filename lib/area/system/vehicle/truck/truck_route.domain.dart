import 'dart:math';

import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/route/route.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck.domain.dart';
import 'package:user_command/user_command.dart';

/// A [TruckRoute]:
/// * defines the routes that trucks are driving
/// * creates trucks and controlls their position on the route
class TruckRoutes extends LinkedSystem implements TimeProcessor {
  late VehicleRoute fromEntranceToUnLoadPoint;
  late VehicleRoute fromUnloadPointToLoadPoint;
  late VehicleRoute fromLoadPointToExit;
  final OffsetInMeters fromUnloadPointToInFeedConveyor;
  late List<VehicleRoute> all = [
    fromEntranceToUnLoadPoint,
    fromUnloadPointToLoadPoint,
    fromLoadPointToExit,
  ];
  final LiveBirdHandlingArea area;

  TruckRoutes({
    required this.area,
    required this.fromEntranceToUnLoadPoint,
    required this.fromUnloadPointToLoadPoint,
    required this.fromLoadPointToExit,
    required this.fromUnloadPointToInFeedConveyor,
  });

  TruckRoutes.forTrailerPuller({
    required this.area,
    CompassDirection direction = const CompassDirection.south(),
    double truckLengthInMeter = 15,
    this.fromUnloadPointToInFeedConveyor = const OffsetInMeters(
      xInMeters: 0,
      yInMeters: 10,
    ),
  }) {
    fromEntranceToUnLoadPoint = VehicleRoute(
      routeStartDirection: direction,
      startPoint: OffsetInMeters.zero,
    ).addStraight(truckLengthInMeter * 1.5);
    fromUnloadPointToLoadPoint = VehicleRoute(
      routeStartDirection: direction,
      startPoint: OffsetInMeters.zero,
    ).addStraight(truckLengthInMeter * 1.5);
    fromLoadPointToExit = VehicleRoute(
      routeStartDirection: direction,
      startPoint: OffsetInMeters.zero,
    ).addStraight(truckLengthInMeter * 1.5);
  }

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  @override
  List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> get links => [
    modulesOut,
  ];

  /// only used to position these [TruckRoutes] relative to the rest of the systems
  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: fromUnloadPointToInFeedConveyor,
    directionToOtherLink: CompassDirection(
      fromUnloadPointToInFeedConveyor.directionInRadians * pi ~/ 180,
    ),
    durationUntilCanFeedOut: () => unknownDuration,
  );

  late ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    offsetFromCenterWhenSystemFacingNorth: OffsetInMeters.zero,
    system: this,
  );

  @override
  final String name = 'TruckRoutes';

  @override
  ObjectDetails get objectDetails => ObjectDetails(name);

  @override
  late SizeInMeters sizeWhenFacingNorth = calculateSizeWhenFacingNorth();

  late VehicleRoute fullRoute = VehicleRoute(
    routeStartDirection: const CompassDirection.south(),
    startPoint: all.first.points.first,
  )..points.addAll(all.expand((route) => route.points));

  List<Truck> trucks = [];

  bool newTruckNeeded = true;

  SizeInMeters calculateSizeWhenFacingNorth() {
    var allPoints = all.expand((route) => route.points).toList();
    var allX = allPoints.map((position) => position.xInMeters);
    var allY = allPoints.map((position) => position.yInMeters);
    var minX = allX.reduce((a, b) => min(a, b)) - 2;
    var minY = allY.reduce((a, b) => min(a, b)) - 2;
    var maxX = allX.reduce((a, b) => max(a, b)) + 2;
    var maxY = allY.reduce((a, b) => max(a, b)) + 2;
    // var correction=OffsetInMeters(xInMeters: minX<0?minX*-1:0, yInMeters: minY<0?minY*-1:0);
    // minX=minX+correction.xInMeters;
    //  minY=minY+correction.yInMeters;
    //   maxX=maxX+correction.xInMeters;
    //  maxY=maxY+correction.yInMeters;
    return SizeInMeters(xInMeters: maxX - minX, yInMeters: maxY - minY);
  }

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (newTruckNeeded) {
      var truck = _createTruck();
      area.systems.add(truck);
      trucks.add(truck);
      newTruckNeeded = false;
    }
  }

  //TODO truck should be created from Area.ProductDefinition
  Truck _createTruck() => BoxTruck(routes: this);
}
