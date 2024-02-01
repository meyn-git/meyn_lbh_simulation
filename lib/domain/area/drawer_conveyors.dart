// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';

class DrawerConveyor {
  /// * y: number of meters in north/south direction, e.g.:
  ///   * -3 = 3 meters north
  ///   * +2 = 2 meters south
  /// * x: number of meters in west/east direction, e.g.:
  ///   * -3 = 3 meters west
  ///   * +2 = 2 meters east
  final Vectors vectors;
  double metersPerSecond;
  final double machineProtrudesInMeters; //must be less than 2 meters!!!

  DrawerConveyor(
      {required this.vectors,
      required this.metersPerSecond,

      /// simple drawer conveyors protrude 0m
      /// drawer weighers, washers, rotators protrude 0,3m?
      /// hanging platform protrude 1m?
      this.machineProtrudesInMeters = 0});
}

class DrawerConveyorStraight extends DrawerConveyor {
  final CardinalDirection direction;
  DrawerConveyorStraight({
    required double lengthInMeters,
    required this.direction,
    required double metersPerSecond,
    double machineProtrudesInMeters = 0,
  }) : super(
            metersPerSecond: metersPerSecond,
            vectors: Vectors.straight(direction, lengthInMeters),
            machineProtrudesInMeters: machineProtrudesInMeters);
}

class DrawerConveyor90Degrees extends DrawerConveyor {
  final double lengthInMeters;
  final CardinalDirection startDirection;
  late CardinalDirection endDirection = startDirection
      .toCompassDirection()
      .rotate(clockwise ? 90 : -90)
      .toCardinalDirection()!;
  final bool clockwise;
  DrawerConveyor90Degrees(
      {required this.lengthInMeters,
      required this.startDirection,
      required this.clockwise,
      required super.metersPerSecond})
      : super(
            vectors: Vectors.ninetyDegreeCorner(
                startDirection, clockwise, lengthInMeters));
}

class DrawerHangingConveyor extends DrawerConveyorStraight {
  DrawerHangingConveyor({
    required int hangers,
    required super.direction,
    required double metersPerSecond,
    double machineProtrudesInMeters = 1,
  }) : super(
          //TODO
          lengthInMeters: (hangers / 2).ceil() * 1,
          metersPerSecond: metersPerSecond,
          machineProtrudesInMeters: machineProtrudesInMeters,
        );
}

class DrawerSoakingConveyor extends DrawerConveyorStraight {
  DrawerSoakingConveyor({
    //TODO fixed length or min recidence time?
    double meters = 10,
    required super.direction,
    required double metersPerSecond,
    double machineProtrudesInMeters = 0.3,
  }) : super(
          lengthInMeters: meters,
          metersPerSecond: metersPerSecond,
          machineProtrudesInMeters: machineProtrudesInMeters,
        );
}

class DrawerWashingConveyor extends DrawerConveyorStraight {
  DrawerWashingConveyor({
    //TODO fixed length or min recidence time?
    double meters = 10,
    required super.direction,
    required double metersPerSecond,
    double machineProtrudesInMeters = 0.3,
  }) : super(
          lengthInMeters: meters,
          metersPerSecond: metersPerSecond,
          machineProtrudesInMeters: machineProtrudesInMeters,
        );
}

class DrawerWeighingConveyor extends DrawerConveyorStraight {
  DrawerWeighingConveyor({
    double meters = 1.4,
    required super.direction,
    required double metersPerSecond,
    double machineProtrudesInMeters = 0.2,
  }) : super(
            lengthInMeters: meters,
            metersPerSecond: metersPerSecond,
            machineProtrudesInMeters: machineProtrudesInMeters);
}

class DrawerTurningConveyor extends DrawerConveyorStraight {
  DrawerTurningConveyor({
    required CardinalDirection startDirection,
    double diameter = 1,
    super.metersPerSecond = 2,
    super.machineProtrudesInMeters = 0.2,
  }) : super(
          lengthInMeters: diameter,
          direction: startDirection,
        );
}

class Vectors extends DelegatingList<Vector2> {
  Vectors(super.base);

  factory Vectors.straight(CardinalDirection direction, double meters) {
    switch (direction) {
      case CardinalDirection.north:
        return Vectors([Vector2(0, -meters)]);
      case CardinalDirection.east:
        return Vectors([Vector2(meters, 0)]);
      case CardinalDirection.south:
        return Vectors([Vector2(0, meters)]);
      case CardinalDirection.west:
        return Vectors([Vector2(-meters, 0)]);
      default:
        throw Exception('Unknown direction');
    }
  }

  factory Vectors.ninetyDegreeCorner(
      CardinalDirection startDirection, bool clockwise, double lengthInMeters) {
    const steps = 6; //preferably a multitude of 3 (360 degrees)
    var vectors = <Vector2>[];
    var angle = startDirection.toCompassDirection();
    for (int i = 0; i < steps; i++) {
      var stepRotationInDegrees =
          (90 / (steps + 1)).round() * (clockwise ? 1 : -1);
      angle = angle.rotate(stepRotationInDegrees);
      var x = sin(angle.radians);
      var y = -cos(angle.radians); //up is negative
      var vector = Vector2(x, y);
      vector.length = lengthInMeters / steps;
      vectors.add(vector);
    }
    return Vectors(vectors);
  }

  late Outward outWard = Outward.forVectors(this);
}

class Outward {
  final double up;
  final double right;
  final double down;
  final double left;

  Outward({
    required this.up,
    required this.right,
    required this.down,
    required this.left,
  });

  factory Outward.forVectors(List<Vector2> vectors) {
    var left = 0.0;
    var right = 0.0;
    var up = 0.0;
    var down = 0.0;
    var point = Vector2.zero();
    for (var vector in vectors) {
      point += vector;
      if (point.x < 0) {
        left = min(left, point.x);
      }
      if (point.x > 0) {
        right = max(right, point.x);
      }
      if (point.y < 0) {
        up = min(up, point.y);
      }
      if (point.y > 0) {
        down = max(down, point.y);
      }
    }
    return Outward(up: up, right: right, down: down, left: left);
  }

  late double width = (left - right).abs();
  late double height = (up - down).abs();
}

class Drawer {
  Drawer(
      {required this.birds,
      required this.outSideLengthInMeters,
      required this.inSideLengthInMeters,
      required this.conveyor,
      required this.remainingMetersOnConveyor});
  int birds;
  double outSideLengthInMeters;
  double inSideLengthInMeters;
  DrawerConveyor conveyor;
  double remainingMetersOnConveyor;
}

class DrawerConveyors extends ActiveCell {
  /// [conveyors]  in order that the drawers travel through them:
  /// conveyors[0] = drawer conveyor after unloader
  /// conveyors[1] = drawer conveyor after conveyor[0]
  /// conveyors[2] = drawer conveyor after conveyor[1]
  /// conveyors[3] = etc
  final List<DrawerConveyor> conveyors;
  late double totalLengthInMeters = length(conveyors.map((c) => c.vectors));

  /// [drawers] in the REVERSE order of how they travel trough the system
  /// drawers[0] = drawer at the end of the conveyors
  /// drawers[1] = drawer behind drawers[0]
  /// drawers[2] = drawer behind drawers[1]
  /// drawers[3] = etc

  List<Drawer> drawers = [];

  Drawer? drawerAtEnd;

  DrawerConveyors(
      {required LiveBirdHandlingArea area,
      required Position position,
      required this.conveyors})
      : super(area, position);

  // returns the length of the vectors in meters.
  double length(Iterable<dynamic> vectors) =>
      vectors.reduce((a, b) => a.length + b.length);

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) {
    // TODO: implement almostWaitingToFeedOut
    throw UnimplementedError();
  }

  @override
  bool isFeedIn(CardinalDirection direction) {
    // TODO: implement isFeedIn
    throw UnimplementedError();
  }

  @override
  bool isFeedOut(CardinalDirection direction) {
    // TODO: implement isFeedOut
    throw UnimplementedError();
  }

  @override
  // TODO: implement moduleGroup
  ModuleGroup? get moduleGroup => throw UnimplementedError();

  @override
  // TODO: implement name
  String get name => 'DrawerConveyors';

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    for (var drawer in drawers) {
      moveDrawer(drawer, jump);
    }
  }

  @override
  bool waitingToFeedIn(CardinalDirection direction) {
    // TODO: implement waitingToFeedIn
    throw UnimplementedError();
  }

  @override
  bool waitingToFeedOut(CardinalDirection direction) {
    // TODO: implement waitingToFeedOut
    throw UnimplementedError();
  }

  void moveDrawer(Drawer drawer, Duration jump) {
    var secondsOfTravel = jump.inMicroseconds / 1000000;
    var metersPerSecond = drawer.conveyor.metersPerSecond;
    var metersToTravel = metersPerSecond * secondsOfTravel;
    var remainingMetersOnConveyor = drawer.remainingMetersOnConveyor;
    if (metersToTravel <= remainingMetersOnConveyor) {
      drawer.remainingMetersOnConveyor -= metersToTravel;
    } else {
      var remainingDuration = Duration(
          microseconds: metersPerSecond / remainingMetersOnConveyor ~/ 1000000);
      var _nextConveyor = nextConveyor(drawer.conveyor);
      if (_nextConveyor == null) {
        drawerAtEnd = drawer;
        //TODO remove when loaded into ReloaderDrawerLift
        drawers.remove(drawer);
      } else {
        drawer.conveyor = _nextConveyor;
        // recursive call
        moveDrawer(drawer, remainingDuration);
      }
    }
    //TODO do not overlap other drawers!
  }

  DrawerConveyor? nextConveyor(DrawerConveyor previousConveyor) {
    int nextIndex = conveyors.indexOf(previousConveyor) + 1;
    if (nextIndex >= conveyors.length) {
      return null;
    }
    return conveyors[nextIndex];
  }

  bool get hasSpaceForNewDrawer {
    if (drawers.isEmpty) {
      return true;
    }
    var lastDrawer = drawers.last;
    var lastConveyor = conveyors.first;
    if (lastDrawer.outSideLengthInMeters < lastConveyor.vectors.length) {
      throw Exception('We assume the first conveyor is longer than a drawer. '
          'If not this method needs to be changed');
    }
    if (lastDrawer.conveyor != conveyors.first) {
      return true;
    }
    var emptySpace =
        lastConveyor.vectors.length - lastDrawer.remainingMetersOnConveyor;
    return emptySpace > lastDrawer.outSideLengthInMeters;
  }
}
