import 'dart:math';

import 'package:meyn_lbh_simulation/domain/area/module/module_variant_builder.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_lift_position.dart';

class SpeedProfile {
  /// e.g. distance (meters or degrees) per second
  final double maxSpeed;

  /// e.g. distance (meters or degrees) per second per second
  final double acceleration;

  /// e.g. distance (meters or degrees) per second per second
  final double deceleration;

  const SpeedProfile({
    required this.maxSpeed,
    required this.acceleration,
    required this.deceleration,
  });

  // Factory constructor to calculate and return a new instance of TravelSpeed
  factory SpeedProfile.total({
    required double totalDistance,
    required double totalDurationInSeconds,
    required double accelerationInSeconds,
    required double decelerationInSeconds,
  }) {
    // Calculate the time spent at constant speed
    double constantSpeedTime = totalDurationInSeconds -
        (accelerationInSeconds + decelerationInSeconds);

    // Calculate the maximum speed
    double maxSpeed = totalDistance /
        (0.5 * accelerationInSeconds +
            constantSpeedTime +
            0.5 * decelerationInSeconds);

    // Calculate acceleration and deceleration
    double acceleration = maxSpeed / accelerationInSeconds;
    double deceleration = maxSpeed / decelerationInSeconds;

    // Return an instance of TravelSpeed with calculated values
    return SpeedProfile(
      maxSpeed: maxSpeed,
      acceleration: acceleration,
      deceleration: deceleration,
    );
  }

  /// [distance] in meters or in degrees
  Duration durationOfDistance(double distance) {
    distance = distance.abs();
    double distanceAccel = (maxSpeed * maxSpeed) / (2 * acceleration);
    double distanceDecel = (maxSpeed * maxSpeed) / (2 * deceleration);

    if (maxSpeedIsReached(distance, distanceAccel, distanceDecel)) {
      // Calculate time to reach max speed during acceleration and deceleration
      double timeAccel = maxSpeed / acceleration;
      double timeDecel = maxSpeed / deceleration;

      // Calculate the remaining distance to travel at max speed
      double distanceConst = distance - (distanceAccel + distanceDecel);
      double timeConst = distanceConst / maxSpeed;

      // Calculate total travel time
      return Duration(
          milliseconds: ((timeAccel + timeConst + timeDecel) * 1000).round());
    } else {
      // If the distance is too short to reach max speed, solve with only acceleration and deceleration
      // Solve for time using kinematic equations (quadratic solution)
      double timeAccel = sqrt(2 *
          distance /
          (acceleration +
              (acceleration * deceleration / (acceleration + deceleration))));
      double timeDecel = timeAccel * (acceleration / deceleration);
      return Duration(milliseconds: ((timeAccel + timeDecel) * 1000).round());
    }
  }

  bool maxSpeedIsReached(
          double distance, double distanceAccel, double distanceDecel) =>
      distance > (distanceAccel + distanceDecel);

  @override
  String toString() {
    return 'maxSpeed: ${maxSpeed.toStringAsFixed(2)} distance/s, '
        'acceleration: ${acceleration.toStringAsFixed(2)} distance/s², '
        'deceleration: ${deceleration.toStringAsFixed(2)} distance/s²';
  }
}

class ElectricModuleLiftSpeedProfile extends SpeedProfile {
  static const totalDistanceInMeters =
      DefaultLiftPositionHeights.containerHeightInMeters +
          DefaultLiftPositionHeights.clearanceHeightInMeters;
  static const totalDurationInSeconds = 10;
  static const accelerationInSeconds = 3;
  static const decelerationInSeconds = 3;
  static const maxConstSpeed = totalDistanceInMeters /
      (0.5 * accelerationInSeconds +
          (totalDurationInSeconds -
              accelerationInSeconds -
              decelerationInSeconds) +
          0.5 * decelerationInSeconds);

  const ElectricModuleLiftSpeedProfile()
      : super(
            maxSpeed: maxConstSpeed,
            acceleration: maxConstSpeed / accelerationInSeconds,
            deceleration: maxConstSpeed / decelerationInSeconds);
}

/// values are based on 7113 Tyson Union City VDL system
/// and are validated at several VDL and Grande drawer systems
class TurnTableSpeedProfileForContainersOrModulesWith2OrMoreCompartmentsPerLevel
    extends SpeedProfile {
  static const _totalDistanceInDegrees = 90;
  static const _totalDurationInSeconds = 6;
  static const _accelerationInSeconds = 2;
  static const _decelerationInSeconds = 2;
  static const _maxSpeed = _totalDistanceInDegrees /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const TurnTableSpeedProfileForContainersOrModulesWith2OrMoreCompartmentsPerLevel()
      : super(
            maxSpeed: _maxSpeed,
            acceleration: _maxSpeed / _accelerationInSeconds,
            deceleration: _maxSpeed / _decelerationInSeconds);
}

/// values are based on measurements at: 7696-Dabe-Germanyk
class TurnTableSpeedProfileForContainersOrModulesWith1CompartmentPerLevel
    extends SpeedProfile {
  static const _totalDistanceInDegrees = 90;
  static const _totalDurationInSeconds = 9;
  static const _accelerationInSeconds = 2;
  static const _decelerationInSeconds = 2;
  static const _maxSpeed = _totalDistanceInDegrees /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const TurnTableSpeedProfileForContainersOrModulesWith1CompartmentPerLevel()
      : super(
            maxSpeed: _maxSpeed,
            acceleration: _maxSpeed / _accelerationInSeconds,
            deceleration: _maxSpeed / _decelerationInSeconds);
}

/// values are based on measurements at: 8052-Indrol Grodzisk
class TurnTableSpeedProfileForOmniaContainers extends SpeedProfile {
  static const _totalDistanceInDegrees = 90;
  static const _totalDurationInSeconds = 11.5;
  static const _accelerationInSeconds = 4;
  static const _decelerationInSeconds = 4;
  static const _maxSpeed = _totalDistanceInDegrees /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const TurnTableSpeedProfileForOmniaContainers()
      : super(
            maxSpeed: _maxSpeed,
            acceleration: _maxSpeed / _accelerationInSeconds,
            deceleration: _maxSpeed / _decelerationInSeconds);
}

/// values are based on 7113 Tyson Union City VDL system
/// and are validated at several VDL and Grande drawer systems
class ConveyorWithoutStopperSpeedProfileForModulesWith2CompartmentsOrMorePerLevel
    extends SpeedProfile {
  static const _totalDistanceInMeters = ModuleConveyor.defaultLengthInMeters;
  static const _totalDurationInSeconds = 12;
  static const _accelerationInSeconds = 1.5;
  static const _decelerationInSeconds = 0.7;
  static const _maxSpeed = _totalDistanceInMeters /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const ConveyorWithoutStopperSpeedProfileForModulesWith2CompartmentsOrMorePerLevel()
      : super(
            maxSpeed: _maxSpeed,
            acceleration: _maxSpeed / _accelerationInSeconds,
            deceleration: _maxSpeed / _decelerationInSeconds);
}


/// values are based on 7113 Tyson Union City VDL system
/// and are validated at several VDL and Grande drawer systems
class ConveyorWithStopperSpeedProfileForModulesWith2CompartmentsOrMorePerLevel
    extends SpeedProfile {
  static const _totalDistanceInMeters = ModuleConveyor.defaultLengthInMeters;
  static const _totalDurationInSeconds = 14;
  static const _accelerationInSeconds = 1.5;
  static const _decelerationInSeconds = 4.7;//effectively 2 seconds longer due to break sensor
  static const _maxSpeed = _totalDistanceInMeters /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const ConveyorWithStopperSpeedProfileForModulesWith2CompartmentsOrMorePerLevel()
      : super(
            maxSpeed: _maxSpeed,
            acceleration: _maxSpeed / _accelerationInSeconds,
            deceleration: _maxSpeed / _decelerationInSeconds);
}

/// values are based on measurements at: 7696-Dabe-Germanyk
class ConveyorWithoutStopperSpeedProfileForModulesWith1CompartmentPerLevel
    extends SpeedProfile {
  static const _totalDistanceInMeters = ModuleConveyor.defaultLengthInMeters;
  static const _totalDurationInSeconds = 13.4;
  static const _accelerationInSeconds = 1.5;
  static const _decelerationInSeconds = 0.7;
  static const _maxSpeed = _totalDistanceInMeters /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const ConveyorWithoutStopperSpeedProfileForModulesWith1CompartmentPerLevel()
      : super(
            maxSpeed: _maxSpeed,
            acceleration: _maxSpeed / _accelerationInSeconds,
            deceleration: _maxSpeed / _decelerationInSeconds);
}

/// values are based on measurements at: 7696-Dabe-Germanyk
class ConveyorWithStopperSpeedProfileForModulesWith1CompartmentPerLevel
    extends SpeedProfile {
  static const _totalDistanceInMeters = ModuleConveyor.defaultLengthInMeters;
  static const _totalDurationInSeconds = 18.7;
  static const _accelerationInSeconds = 1.5;
  static const _decelerationInSeconds = 11.3;//effectively 18.7-13.4=5.3 seconds longer due to break sensor = 2*5.3+0.7=11.3s
  static const _maxSpeed = _totalDistanceInMeters /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const ConveyorWithStopperSpeedProfileForModulesWith1CompartmentPerLevel()
      : super(
            maxSpeed: _maxSpeed,
            acceleration: _maxSpeed / _accelerationInSeconds,
            deceleration: _maxSpeed / _decelerationInSeconds);
}

/// values are based on measurements at: 8052-Indrol Grodzisk
/// Was 19s, but can be improved to 14 acording to Maurizio test at Indrol; on 2024-09-18
class ConveyorWithoutStopperSpeedProfileForOmniaContainers
    extends SpeedProfile {
  static const _totalDistanceInMeters = ModuleConveyor.defaultLengthInMeters;
  static const _totalDurationInSeconds = 14;
  static const _accelerationInSeconds = 2;
  static const _decelerationInSeconds = 2;
  static const _maxSpeed = _totalDistanceInMeters /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const ConveyorWithoutStopperSpeedProfileForOmniaContainers()
      : super(
            maxSpeed: _maxSpeed,
            acceleration: _maxSpeed / _accelerationInSeconds,
            deceleration: _maxSpeed / _decelerationInSeconds);
}


/// values are based on measurements at: 8052-Indrol Grodzisk
class ConveyorWithStopperSpeedProfileForOmniaContainers
    extends SpeedProfile {
  static const _totalDistanceInMeters = ModuleConveyor.defaultLengthInMeters;
  static const _totalDurationInSeconds = 19;
  static const _accelerationInSeconds = 2;
  static const _decelerationInSeconds = 2;
  static const _maxSpeed = _totalDistanceInMeters /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const ConveyorWithStopperSpeedProfileForOmniaContainers()
      : super(
            maxSpeed: _maxSpeed,
            acceleration: _maxSpeed / _accelerationInSeconds,
            deceleration: _maxSpeed / _decelerationInSeconds);
}

enum SpeedProfiles {
  /// values are based on 7113 Tyson Union City VDL system
  /// and are validated at several VDL and Grande drawer systems
  containersOrModulesWith2OrMoreCompartmentsPerLevel(
     //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7 (additional 2 seconds to stop on stopper?)
    conveyorTransportDuration: Duration(seconds: 12),
    moduleConveyorWithoutStopper:
        ConveyorWithoutStopperSpeedProfileForModulesWith2CompartmentsOrMorePerLevel(),
moduleConveyorWithStopper: ConveyorWithStopperSpeedProfileForModulesWith2CompartmentsOrMorePerLevel(),
stackerInFeedDuration: Duration(
        seconds:
            14), //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7 (additional 2 seconds to stop on stopper?)
    deStackerInFeedDuration: Duration(
        seconds:
            14),
    casTransportDuration: Duration(
        seconds:
            14), //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7 (additional 2 seconds to stop on stopper?)
    turnTableTurn:
        TurnTableSpeedProfileForContainersOrModulesWith2OrMoreCompartmentsPerLevel(),
    lift: ElectricModuleLiftSpeedProfile(),
  ),

  /// values are based on measurements at: 7696-Dabe-Germanyk
  containersOrModulesWith1CompartmentsPerLevel(
    conveyorTransportDuration: Duration(microseconds: 13400),
    moduleConveyorWithoutStopper:
        ConveyorWithoutStopperSpeedProfileForModulesWith1CompartmentPerLevel(),
moduleConveyorWithStopper:
        ConveyorWithStopperSpeedProfileForModulesWith1CompartmentPerLevel(),
    
    stackerInFeedDuration: Duration(
        milliseconds:
            18700), //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7 (additional 2 seconds to stop on stopper?)
    deStackerInFeedDuration: Duration(
        milliseconds:
            18700), //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7 (additional 2 seconds to stop on stopper?)
    casTransportDuration: Duration(
        milliseconds:
            18700), //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7 (additional 2 seconds to stop on stopper?)
    turnTableTurn:
        TurnTableSpeedProfileForContainersOrModulesWith1CompartmentPerLevel(),
    lift: ElectricModuleLiftSpeedProfile(),
  ),

  ///values are based on measurements at: 8052-Indrol Grodzisk
  meynOmnia(
    conveyorTransportDuration: Duration(seconds: 14),
    //Was 19, but can be improved to 14 acording to Maurizio test at Indrol; on 2024-09-18
    moduleConveyorWithoutStopper:
        ConveyorWithoutStopperSpeedProfileForOmniaContainers(),
    moduleConveyorWithStopper: ConveyorWithStopperSpeedProfileForOmniaContainers(),
    //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7
    stackerInFeedDuration: Duration(
        seconds:
            19), //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7 (additional 2 seconds to stop on stopper?)
    deStackerInFeedDuration: Duration(
        seconds:
            19), //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7 (additional 2 seconds to stop on stopper?)
    casTransportDuration: Duration(
        seconds:
            19), //TODO change to TravelSpeed, typical rampup=1.5s, typical ramp down=0,7 (additional 2 seconds to stop on stopper?)
    turnTableTurn: TurnTableSpeedProfileForOmniaContainers(),

    /// lift speed profile is assumed to be identical to other systems (not verified)
    lift: ElectricModuleLiftSpeedProfile(),
  ),
  ;

  const SpeedProfiles({
    required this.moduleConveyorWithStopper,
    required this.stackerInFeedDuration,
    required this.deStackerInFeedDuration,
    required this.moduleConveyorWithoutStopper,
    required this.conveyorTransportDuration,
    required this.casTransportDuration,
    required this.turnTableTurn,
    required this.lift,
  });

  final SpeedProfile moduleConveyorWithStopper;
  final Duration stackerInFeedDuration;
  final Duration deStackerInFeedDuration;
  final SpeedProfile moduleConveyorWithoutStopper;
  //TODO replace with moduleConveyorWithoutStopper
  final Duration conveyorTransportDuration;
  final Duration casTransportDuration;
  final SpeedProfile turnTableTurn;
  final SpeedProfile lift;

  static SpeedProfiles ofVariantBase(ModuleVariantBase base) {
    if (base.family == 'Omnia') {
      return SpeedProfiles.meynOmnia;
    }
    if (base.compartmentsPerLevel == 1) {
      return SpeedProfiles.containersOrModulesWith1CompartmentsPerLevel;
    }
    return SpeedProfiles.containersOrModulesWith2OrMoreCompartmentsPerLevel;
  }
}
