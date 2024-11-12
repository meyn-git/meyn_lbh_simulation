import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/speed_profile.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/system/vehicle/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/system/vehicle/route/route.domain.dart';

class ForkLiftTruckRoutes {
  late VehicleRoute beforeConveyorToAboveConveyor;
  late VehicleRoute aboveConveyorToBeforeConveyor;
  late VehicleRoute beforeConveyorToTurnPoint;
  late VehicleRoute turnPointToInToTruck;
  late VehicleRoute inTruckToTurnPoint;
  late VehicleRoute turnPointToBeforeConveyor;
  late List<VehicleRoute> all;

  /// [forkLiftTurnRadiusInMeter] for a 4 wheel forklift
  /// is typically between 2.5 and 4 meter.
  static const double forkLiftTurnRadiusInMeter = 3.3;
  static const double straightAtTurnPointInMeter = 1;
  static const double straightAfterTurnPointInMeter = 10;

  ForkLiftTruckRoutes(
      {required this.beforeConveyorToAboveConveyor,
      required this.aboveConveyorToBeforeConveyor,
      required this.beforeConveyorToTurnPoint,
      required this.turnPointToInToTruck,
      required this.inTruckToTurnPoint,
      required this.turnPointToBeforeConveyor});

  ForkLiftTruckRoutes.forLoadingForkLiftTruck(
      {required LoadingForkLiftTruck forkLiftTruck,
      required Direction turnAtConveyor,
      required Direction turnAtTruck}) {
    var moduleLoadingConveyor = forkLiftTruck.modulesOut.linkedTo!.system
        as ModuleLoadingConveyorInterface;

    var area = moduleLoadingConveyor.area;
    var layout = area.layout;

//TODO infeedModuleConveyor.modulesIn.directionToOtherLink should be different when loading single column modules from the side
    var infeedDirection = layout.rotationOf(moduleLoadingConveyor);
    //TODO infeedModuleConveyor.modulesIn.offsetFromCenterWhenFacingNorth should be different when loading single column modules from the side
    var conveyorLinkPosition = layout.positionOnSystem(moduleLoadingConveyor,
        moduleLoadingConveyor.modulesIn.offsetFromCenterWhenFacingNorth);
    var forkLiftTruckAboveConveyorPosition = conveyorLinkPosition +
        forkLiftTruck.shape.centerToFrontForkCariage
            .rotate(infeedDirection.opposite);

    var moduleGroupFootPrint =
        area.productDefinition.truckRows.first.footprintOnSystem;

    aboveConveyorToBeforeConveyor = _aboveConveyorToBeforeConveyor(
      infeedDirection,
      forkLiftTruckAboveConveyorPosition,
      moduleGroupFootPrint,
    );
    beforeConveyorToAboveConveyor = _beforeConveyorToAboveConveyor(
      infeedDirection,
      aboveConveyorToBeforeConveyor,
    );
    beforeConveyorToTurnPoint = _beforeConveyorToTurnPoint(
      turnAtConveyor,
      moduleGroupFootPrint,
      aboveConveyorToBeforeConveyor,
    );

    turnPointToInToTruck = _turnPointToInToTruck(
      turnAtConveyor,
      beforeConveyorToTurnPoint,
    );
    inTruckToTurnPoint = _inTruckToTurnPoint(
      turnAtTruck,
      moduleGroupFootPrint,
      turnPointToInToTruck,
    );
    turnPointToBeforeConveyor = _turnPointToBeforeConveyor(
      turnAtTruck,
      inTruckToTurnPoint: inTruckToTurnPoint,
      beforeConveyorToAboveConveyor: beforeConveyorToAboveConveyor,
    );
    all = [
      beforeConveyorToAboveConveyor,
      aboveConveyorToBeforeConveyor,
      beforeConveyorToTurnPoint,
      turnPointToInToTruck,
      inTruckToTurnPoint,
      turnPointToBeforeConveyor,
    ];
  }

  _beforeConveyorToAboveConveyor(CompassDirection startDirection,
          VehicleRoute aboveConveyorToBeforeConveyor) =>
      VehicleRoute(
              routeStartDirection: startDirection,
              startPoint: aboveConveyorToBeforeConveyor.points.last)
          .addStraight(aboveConveyorToBeforeConveyor.lengthInMeters);

  VehicleRoute _aboveConveyorToBeforeConveyor(CompassDirection startDirection,
          OffsetInMeters startPoint, SizeInMeters moduleGroupFootPrint) =>
      VehicleRoute(
              routeStartDirection: startDirection.opposite,
              startPoint: startPoint,
              vehicleDirection: VehicleDirection.reverse)
          .addStraight(moduleGroupFootPrint.yInMeters * 1.5);

  VehicleRoute _beforeConveyorToTurnPoint(
    Direction turnAtConveyor,
    SizeInMeters moduleGroupFootPrint,
    VehicleRoute aboveConveyorToBeforeConveyor,
  ) =>
      VehicleRoute(
        routeStartDirection: aboveConveyorToBeforeConveyor.lastDirection,
        startPoint: aboveConveyorToBeforeConveyor.points.last,
        vehicleDirection: VehicleDirection.reverse,
      )
          .addCurve(forkLiftTurnRadiusInMeter, turnAtConveyor.sign * 90)
          .addStraight(straightAtTurnPointInMeter);

  VehicleRoute _emptyRoute() => VehicleRoute(
      routeStartDirection: const CompassDirection.north(),
      startPoint: OffsetInMeters.zero);

  VehicleRoute _turnPointToInToTruck(
          Direction turnAtConveyor, VehicleRoute aboveConveyorToTurnPoint) =>
      VehicleRoute(
              routeStartDirection:
                  aboveConveyorToTurnPoint.lastDirection.opposite,
              startPoint: aboveConveyorToTurnPoint.points.last)
          .addStraight(straightAtTurnPointInMeter)
          .addCurve(forkLiftTurnRadiusInMeter, turnAtConveyor.sign * 90)
          .addStraight(straightAfterTurnPointInMeter);

  VehicleRoute _inTruckToTurnPoint(
          Direction turnAtTruck,
          SizeInMeters moduleGroupFootPrint,
          VehicleRoute turnPointToInToTruck) =>
      VehicleRoute(
        routeStartDirection: turnPointToInToTruck.lastDirection.opposite,
        startPoint: turnPointToInToTruck.points.last,
        vehicleDirection: VehicleDirection.reverse,
      )
          .addStraight(moduleGroupFootPrint.yInMeters)
          .addCurve(forkLiftTurnRadiusInMeter, turnAtTruck.sign * 90)
          .addStraight(straightAtTurnPointInMeter);

  VehicleRoute _turnPointToBeforeConveyor(
    Direction turnAtTruck, {
    required VehicleRoute inTruckToTurnPoint,
    required VehicleRoute beforeConveyorToAboveConveyor,
  }) =>
      VehicleRoute(
              routeStartDirection: inTruckToTurnPoint.lastDirection.opposite,
              startPoint: inTruckToTurnPoint.points.last)
          .addStraight(straightAtTurnPointInMeter)
          .addCurve(forkLiftTurnRadiusInMeter, turnAtTruck.sign * 90)
          .addToPoint(beforeConveyorToAboveConveyor.points.first);
}

class ForkLiftSpeedProfile extends SpeedProfile {
  const ForkLiftSpeedProfile()
      : super(

            /// The typical speed of a forklift truck varies based on its type and surroundings,
            /// but generally indoors for safety reasons, often around 8 km/h (2.2 m/s),
            /// as forklifts need to maneuver precisely and avoid accidents in confined spaces.
            maxSpeed: 8000 / 3600,

            /// The acceleration and deceleration of a forklift truck carrying a load of 2400 kg
            /// are generally limited due to safety and stability concerns.
            /// Typical values for a loaded forklift are
            /// between 0.5 to 1 m/s². We use a low value to compensate for fork positioning
            acceleration: 0.5,
            deceleration: 0.5);
}
