// ignore_for_file: avoid_renaming_method_parameters

import 'dart:math';

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/route/route.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.presentation.dart';

abstract class Vehicle implements VisibleSystem {
  AreaPosition get position;
  set position(AreaPosition position);
  CompassDirection get direction;
  set direction(CompassDirection compassDirection);
  VehicleShape get shape;

  List<ModuleGroupPlace> get moduleGroupPlaces;
  int get moduleGroupStartRotationInDegrees;
}

abstract class VehicleStateMachine extends StateMachine implements Vehicle {
  VehicleStateMachine({required super.initialState});
}

abstract class Drive<T extends VehicleStateMachine> extends State<T> {
  final State<T> Function(T vehicle) nextStateFunction;
  final SpeedProfile Function(T vehicle) speedProfileFunction;
  final VehicleRoute Function(T vehicle) routeFunction;
  Duration elapsed = Duration.zero;
  late VehicleRoute route;
  late Duration duration;
  bool atDestination = false;

  Drive({
    required this.speedProfileFunction,
    required this.routeFunction,
    required this.nextStateFunction,
  });

  @override
  void onStart(T vehicle) {
    route = routeFunction(vehicle);
    var speedProfile = speedProfileFunction(vehicle);
    duration = speedProfile.durationOfDistance(route.lengthInMeters);
    super.onStart(vehicle);
  }

  @override
  State<T>? nextState(T vehicle) {
    if (atDestination) {
      return nextStateFunction(vehicle);
    } else {
      return null;
    }
  }

  @override
  void onUpdateToNextPointInTime(T vehicle, Duration jump) {
    if (!atDestination) {
      elapsed += jump;
      if (elapsed >= duration) {
        atDestination = true;
      }

      var traveledInMeters =
          route.lengthInMeters *
          elapsed.inMilliseconds /
          duration.inMilliseconds;
      var centerToAxleCenterInMeters = vehicle.shape.centerToAxleCenterInMeters;
      var frontAxlePosition = route.pointAlongRoute(
        traveledInMeters +
            (centerToAxleCenterInMeters * route.vehicleDirection.sign * -1),
      );
      var backAxlePosition = route.pointAlongRoute(
        traveledInMeters +
            (centerToAxleCenterInMeters * route.vehicleDirection.sign),
      );

      var betweenAxle = backAxlePosition - frontAxlePosition;
      var centerPosition = (backAxlePosition + frontAxlePosition) * 0.5;

      vehicle.position = FixedAreaPosition(centerPosition);
      var radians = betweenAxle.directionInRadians;
      vehicle.direction = CompassDirection(radians * 180 ~/ pi);

      for (var place in vehicle.moduleGroupPlaces) {
        if (place.moduleGroup != null) {
          var moduleGroup = place.moduleGroup!;
          moduleGroup.direction = vehicle.direction.rotate(
            vehicle.moduleGroupStartRotationInDegrees,
          );
        }
      }
    }
  }
}
