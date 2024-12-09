import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck_route.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.presentation.dart';
import 'package:user_command/user_command.dart';

abstract class TrailerPuller {
  Trailer? trailer;
}

abstract class Truck extends VehicleStateMachine implements TrailerPuller {
  final TruckRoutes routes;
  Truck({required this.routes, required super.initialState});

  double get turnRadiusInMeter;
  SpeedProfile get speedProfile;
  @override
  TrailerPullerShape get shape;
}

abstract class TrailerPullerShape extends VehicleShape
    implements ModuleGroupsShape {
  double get centerToHitch;
}

abstract class Trailer extends TrailerPuller {
  TrailerShape get shape;
}

abstract class TrailerShape extends TrailerPullerShape {
  double get centerToCoupler;
}

class BoxTruck extends Truck implements ModuleGroupsSystem {
  /// The typical turning radius for a 10-meter box truck is generally around 10 to 13.7 meters
  @override
  final double turnRadiusInMeter = 11;

  @override
  CompassDirection direction = const CompassDirection.north();

  @override
  AreaPosition position = FixedAreaPosition(OffsetInMeters.zero);

  @override
  Trailer? trailer;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  final double cabinLengthInMeter;

  final double widthInMeter;

  final double cargoFloorLengthInMeter;

  BoxTruck({
    required super.routes,
    this.widthInMeter = 2.55,
    this.cabinLengthInMeter = 2.5,
    this.cargoFloorLengthInMeter = 7.5,
  }) : super(initialState: DriveToUnloadPoint());

  @override
  late List<ModuleGroupPlace> moduleGroupPlaces =
      ModuleGroupPlaceFactory().create(this);

  @override
  // TODO: implement moduleGroupStartRotationInDegrees
  int get moduleGroupStartRotationInDegrees => 0;

  @override
  String get name => 'Truck';

  @override
  late TrailerPullerShape shape = TruckShape(this);

  /// The typical speed of a large box truck varies based on its type and surroundings,
  /// but generally indoors for safety reasons, often around 8 km/h (2.2 m/s),
  /// as trucks need to maneuver precisely and avoid accidents in confined spaces.
  static const maxSpeedInMetersPerSecond = 8000 / 3600;

  /// For a large box truck and trailer carrying a load of 12 stacks x 2100 kg (25,200 kg total)
  /// with a maximum speed of 8 km/h (approximately 2.22 m/s),
  /// the acceleration is about 0.5 to 1.0 m/s²
  static const acceleration = 0.5;

  /// For a large box truck and trailer carrying a load of 12 stacks x 2100 kg (25,200 kg total)
  /// with a maximum speed of 8 km/h (approximately 2.22 m/s),
  /// the deceleration is about 0.5 to 1.0 m/s²
  static const deceleration = 0.5;

  @override
  final SpeedProfile speedProfile = const SpeedProfile(
      maxSpeed: maxSpeedInMetersPerSecond,
      acceleration: acceleration,
      deceleration: deceleration);

  @override
  late LiveBirdHandlingArea area = super.routes.area;
}

class DriveToUnloadPoint extends Drive<Truck> {
  @override
  final String name = 'DriveToUnloadPoint';

  DriveToUnloadPoint()
      : super(
          speedProfileFunction: (truck) => truck.speedProfile,
          routeFunction: (truck) => truck.routes.fromEntranceToUnLoadPoint,
          nextStateFunction: (truck) => WaitUntilModulesUnloaded(),
        );

  @override
  void onUpdateToNextPointInTime(Truck vehicle, Duration jump) {
    // TODO: implement onUpdateToNextPointInTime
    super.onUpdateToNextPointInTime(vehicle, jump);
  }
}

class WaitUntilModulesUnloaded extends State<Truck> {
  @override
  final String name = 'WaitUntilModulesUnloaded';

  @override
  State<Truck>? nextState(Truck stateMachine) {
    // TODO: check if truck is unloaded
    return null;
  }
}

// /// Links a LoadForkLiftTruckRoute with a TuckRoute
// class TruckRouteOutLink<OWNER extends TruckRoutes>
//     extends Link<OWNER, LoadingForkLiftTruckInLink> {
//   TruckRouteOutLink({required super.system, required super.offsetFromCenterWhenFacingNorth, required super.directionToOtherLink});

// }

// /// Links a UnloadForkLiftTruckRoute with a TuckRoute
// class TruckRouteInLink<OWNER extends TruckRoutes>
//     extends Link<OWNER, UnloadingForkLiftTruckOutLink> {
//   TruckRouteInLink({required super.system, required super.offsetFromCenterWhenFacingNorth, required super.directionToOtherLink});

// }
