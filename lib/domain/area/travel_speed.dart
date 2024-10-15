import 'dart:math';

import 'package:meyn_lbh_simulation/domain/area/module_lift_position.dart';

// class TravelSpeed {
//   /// in meters per seconds or
//   /// in degrees per second
//   final double maxSpeed;
//   /// in meters per seconds per second or
//   /// in degrees per seconds per second
//   final double acceleration;
//   /// in meters per seconds per second
//   /// in degrees per seconds per second
//   final double deceleration;

//   const TravelSpeed({
//     required this.maxSpeed,
//     required this.acceleration,
//     required this.deceleration,
//   });

//   factory TravelSpeed.total({ required int totalDistance, required int totalDurationInSeconds, required int accelerationInSeconds, required int decelerationInSeconds}):
//    // totalDistance = 0.5 * a * t_a^2 + v * t_const + 0.5 * a_d * t_d^2
//   maxSpeed = totalDistance/(totalDurationInSeconds-accelerationInSeconds-decelerationInSeconds),

//   // Calculate acceleration (a = v_max / t_a)
//    acceleration = totalDistance/totalDurationInSeconds / accelerationInSeconds,

//   // Calculate deceleration (a_d = v_max / t_d)
//    deceleration = totalDistance/totalDurationInSeconds / decelerationInSeconds;

//   /// [distance] in meters or in degrees
//   double duration(double distance) {
//     double distanceAccel = (maxSpeed * maxSpeed) / (2 * acceleration);
//     double distanceDecel = (maxSpeed * maxSpeed) / (2 * deceleration);

//     if (maxSpeedIsReached(distance, distanceAccel, distanceDecel)) {
//       // Calculate time to reach max speed during acceleration and deceleration
//       double timeAccel = maxSpeed / acceleration;
//       double timeDecel = maxSpeed / deceleration;

//       // Calculate the remaining distance to travel at max speed
//       double distanceConst = distance - (distanceAccel + distanceDecel);
//       double timeConst = distanceConst / maxSpeed;

//       // Calculate total travel time
//       return timeAccel + timeConst + timeDecel;
//     } else {
//       // If the distance is too short to reach max speed, solve with only acceleration and deceleration
//       // Solve for time using kinematic equations (quadratic solution)
//       double timeAccel = sqrt(2 *
//           distance /
//           (acceleration +
//               (acceleration * deceleration / (acceleration + deceleration))));
//       double timeDecel = timeAccel * (acceleration / deceleration);
//       return timeAccel + timeDecel;
//     }
//   }

//   bool maxSpeedIsReached(
//           double distance, double distanceAccel, double distanceDecel) =>
//       distance > (distanceAccel + distanceDecel);

// }

class TravelSpeed {
  /// e.g. distance (meters or degrees) per second
  final double maxSpeed;

  /// e.g. distance (meters or degrees) per second per second
  final double acceleration;

  /// e.g. distance (meters or degrees) per second per second
  final double deceleration;

  const TravelSpeed({
    required this.maxSpeed,
    required this.acceleration,
    required this.deceleration,
  });

  // Factory constructor to calculate and return a new instance of TravelSpeed
  factory TravelSpeed.total({
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
    return TravelSpeed(
      maxSpeed: maxSpeed,
      acceleration: acceleration,
      deceleration: deceleration,
    );
  }

  /// [distance] in meters or in degrees
  Duration durationOfDistance(double distance) {
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

class ElectricModuleLiftSpeed extends TravelSpeed {
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

  const ElectricModuleLiftSpeed()
      : super(
            maxSpeed: maxConstSpeed,
            acceleration: maxConstSpeed / accelerationInSeconds,
            deceleration: maxConstSpeed / decelerationInSeconds);
}
