// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/extensions.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_unloader.dart';

abstract class DrawerConveyor {
  /// * y: number of meters in north/south direction, e.g.:
  ///   * -3 = 3 meters north
  ///   * +2 = 2 meters south
  /// * x: number of meters in west/east direction, e.g.:
  ///   * -3 = 3 meters west
  ///   * +2 = 2 meters east
  late Vectors vectors;
  double metersPerSecond = 0;
  static const double chainWidthInMeters = 0.8;

  /// simple drawer conveyors protrude 0m
  /// drawer weighers, washers, rotators protrude 0,3m?
  /// hanging platform protrude 1m?
  late double machineProtrudesInMeters;

  /// outer size in meters when looking from to top
  late Size size;
  // distance from start of conveyor to top left in meters
  /// when looking from to top
  late Offset conveyorStartToTopLeft;

  /// distance from top left to start of conveyor in meters
  /// when looking from to top
  late Offset topLeftToConveyorEnd;
}

class DrawerConveyorStraight implements DrawerConveyor {
  @override
  late double machineProtrudesInMeters;

  @override
  late Vectors vectors;

  @override
  late double metersPerSecond;

  final CardinalDirection direction;
  DrawerConveyorStraight({
    required Distance length,
    required this.direction,
    required this.metersPerSecond,
    this.machineProtrudesInMeters = 0,
  }) : vectors = Vectors.straight(direction, length.as(meters));

  @override
  late Size size = _size();

  Size _size() {
    switch (direction) {
      case CardinalDirection.north:
      case CardinalDirection.south:
        var widthInMeters =
            DrawerConveyor.chainWidthInMeters + machineProtrudesInMeters * 2;
        var heightInMeters = vectors.outWard.height;
        return Size(widthInMeters, heightInMeters);
      case CardinalDirection.east:
      case CardinalDirection.west:
        var widthInMeters = vectors.outWard.width;
        var heightInMeters =
            DrawerConveyor.chainWidthInMeters + machineProtrudesInMeters * 2;
        return Size(widthInMeters, heightInMeters);
      default:
        throw Exception('Not supported direction');
    }
  }

  @override
  late Offset topLeftToConveyorEnd = _topLeftToConveyorEnd();

  Offset _topLeftToConveyorEnd() {
    switch (direction) {
      case CardinalDirection.north:
        return Offset(size.width / 2, 0);
      case CardinalDirection.south:
        return Offset(size.width / 2, size.height);
      case CardinalDirection.east:
        return Offset(size.width, size.height / 2);
      case CardinalDirection.west:
        return Offset(0, size.height / 2);
      default:
        throw Exception('Not supported direction');
    }
  }

  @override
  late Offset conveyorStartToTopLeft = _conveyorStartToTopLeft();

  Offset _conveyorStartToTopLeft() {
    switch (direction) {
      case CardinalDirection.north:
        return Offset(-size.width / 2, -size.height);
      case CardinalDirection.south:
        return Offset(-size.width / 2, 0);
      case CardinalDirection.east:
        return Offset(0, -size.height / 2);
      case CardinalDirection.west:
        return Offset(-size.width, -size.height / 2);
      default:
        throw Exception('Not supported direction');
    }
  }
}

class DrawerConveyor90Degrees implements DrawerConveyor {
  @override
  late double machineProtrudesInMeters;

  @override
  late Vectors vectors;

  @override
  late double metersPerSecond;

  final CardinalDirection startDirection;
  late CardinalDirection endDirection = startDirection
      .toCompassDirection()
      .rotate(clockwise ? 90 : -90)
      .toCardinalDirection()!;
  final bool clockwise;

  DrawerConveyor90Degrees(
      {double lengthInMeters = 4.3,
      required this.startDirection,
      required this.clockwise,
      required this.metersPerSecond})
      : vectors = Vectors.ninetyDegreeCorner(
            startDirection, clockwise, lengthInMeters.meters);

  @override
  late Size size = _size();
  Size _size() {
    var widthInMeters =
        DrawerConveyor.chainWidthInMeters + vectors.outWard.width;
    var heightInMeters =
        DrawerConveyor.chainWidthInMeters + vectors.outWard.height;
    return Size(widthInMeters, heightInMeters);
  }

  @override
  late Offset conveyorStartToTopLeft = _conveyorStartToTopLeft();

  Offset _conveyorStartToTopLeft() {
    switch (startDirection) {
      case CardinalDirection.north:
        return Offset(-size.width / 2, -size.height);
      case CardinalDirection.east:
        return Offset(0, -size.height / 2);
      case CardinalDirection.south:
        return Offset(-size.width / 2, 0);
      case CardinalDirection.west:
        return Offset(-size.width, -size.height / 2);
      default:
        throw Exception('Not supported direction');
    }
  }

  @override
  late Offset topLeftToConveyorEnd = _topLeftToConveyorEnd();

  Offset _topLeftToConveyorEnd() {
    switch (endDirection) {
      case CardinalDirection.north:
        return Offset(size.width / 2, 0);
      case CardinalDirection.east:
        return Offset(size.width, size.height / 2);
      case CardinalDirection.south:
        return Offset(size.width / 2, size.height);
      case CardinalDirection.west:
        return Offset(0, size.height / 2);
      default:
        throw Exception('Not supported direction');
    }
  }
}

class DrawerHangingConveyor extends DrawerConveyorStraight {
  DrawerHangingConveyor({
    required int hangers,
    required super.direction,
    required super.metersPerSecond,
    super.machineProtrudesInMeters = 1,
  }) : super(
          //TODO
          length: meters((hangers / 2).ceil() * 1),
        );
}

class DrawerSoakingConveyor extends DrawerConveyorStraight {
  DrawerSoakingConveyor({
    required super.direction,
    required super.metersPerSecond,
    super.machineProtrudesInMeters = 0.3,
  }) : super(
            length: meters(
                10.5) // includes up towards washer TODO fixed length or min residence time?
            );
}

class DrawerWashingConveyor extends DrawerConveyorStraight {
  DrawerWashingConveyor({
    required super.direction,
    required super.metersPerSecond,
    super.machineProtrudesInMeters = 0.3,
  }) : super(length: meters(8.5) //TODO fixed length or min residence time?
            );
}

class DrawerWeighingConveyor extends DrawerConveyorStraight {
  DrawerWeighingConveyor({
    required super.direction,
    required super.metersPerSecond,
    super.machineProtrudesInMeters = 0.2,
  }) : super(length: meters(1.4) //TODO verify
            );
}

class DrawerTurningConveyor extends DrawerConveyorStraight {
  DrawerTurningConveyor({
    required CardinalDirection startDirection,
    double diameter = 1 //TODO verify
    ,
    super.metersPerSecond = 2,
    super.machineProtrudesInMeters = 0.2,
  }) : super(
          length: meters(diameter),
          direction: startDirection,
        );

  /// The [DrawerTurningConveyorPainter] ends where it begins
  /// This is the reverse of [conveyorStartToTopLeft(size)]
  @override
  Offset _topLeftToConveyorEnd() {
    switch (direction) {
      case CardinalDirection.north:
        return Offset(size.width / 2, size.height);
      case CardinalDirection.south:
        return Offset(size.width / 2, 0);
      case CardinalDirection.east:
        return Offset(0, size.height / 2);
      case CardinalDirection.west:
        return Offset(size.width, size.height / 2);
      default:
        throw Exception('Not supported direction');
    }
  }
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
      CardinalDirection startDirection, bool clockwise, Distance length) {
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
      vector.length = length.as(meters) / steps;
      vectors.add(vector);
    }
    return Vectors(vectors);
  }

  late Outward outWard = Outward.forVectors(this);

  double get totalLength => map((v) => v.length).reduce((a, b) => a + b);
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

class GrandeDrawer implements TimeProcessor {
  int _nrOfBirds;
  Distance outSideLength = GrandeDrawerModuleType.drawerOutSideLength;
  double distanceTraveledInMeters = 0;
  BirdContents contents;
  DrawerPosition position;
  final Position startPosition;

  /// Distance traveled in meters from [startPosition]
  Offset traveledPath = Offset.zero;

  GrandeDrawer(
      {required this.startPosition,
      required int nrOfBirds,
      required this.contents,
      required this.position})
      : _nrOfBirds = nrOfBirds;

  CompassDirection get direction =>
      CardinalDirection.north.toCompassDirection(); //TODO get from vector;

  set nrOfBirds(int nrOfBirds) {
    if (nrOfBirds == 0) {
      contents = BirdContents.noBirds;
    }
    _nrOfBirds = nrOfBirds;
  }

  int get nrOfBirds => _nrOfBirds;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (position is TimeProcessor) {
      (position as TimeProcessor).onUpdateToNextPointInTime(jump);
    }
  }
}

abstract class DrawerPosition {
  /// returns the top left position of the [GrandeDrawer]
  /// relative to the top left position of a [DrawerConveyor]
  /// in meters
  Offset topLeft(Map<DrawerConveyor, Offset> topLeftPositionOfConveyors,
      double sizePerMeter);
}

class DrawerConveyors implements ActiveCell, BirdBuffer {
  @override
  late LiveBirdHandlingArea area;

  @override
  late Position position;

  @override
  late String name = "DrawerConveyors";

  final List<DrawerConveyor> conveyors;
  late double totalLengthInMeters = length(conveyors.map((c) => c.vectors));

  /// [drawers] in the REVERSE order of how they travel trough the system
  /// drawers[0] = drawer at the end of the conveyors
  /// drawers[1] = drawer behind drawers[0]
  /// drawers[2] = drawer behind drawers[1]
  /// drawers[3] = etc

  List<GrandeDrawer> drawers = [];

  GrandeDrawer? drawerAtEnd;

  DrawerConveyors(
      {required this.area, required this.position, required this.conveyors});

  UnloaderDrawerLift get unloaderLift {
    if (conveyors.isEmpty) {
      throw Exception('The DrawerConveyors does not contain conveyors!');
    }
    DrawerConveyor first = conveyors.first;
    if (first is! UnloaderDrawerLift) {
      throw Exception(
          'The DrawerConveyors must start with a $UnloaderDrawerLift!');
    }
    return first;
  }

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
  void onUpdateToNextPointInTime(Duration jump) {
    for (var conveyor in conveyors.whereType<TimeProcessor>()) {
      conveyor.onUpdateToNextPointInTime(jump);
    }
    for (var drawer in drawers) {
      drawer.onUpdateToNextPointInTime(jump);
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

  DrawerConveyor? findNextConveyor(DrawerConveyor previousConveyor) {
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
    if (lastDrawer.outSideLength < meters(lastConveyor.vectors.length)) {
      throw Exception('We assume the first conveyor is longer than a drawer. '
          'If not this method needs to be changed');
    }
    // if (lastDrawer.conveyor != conveyors.first) {
    //   return true;
    // }
    // TODO var emptySpace =
    //     meters(lastConveyor.vectors.length) - lastDrawer.distanceTraveledInMeters;
    // return emptySpace > lastDrawer.outSideLength;
    return true;
  }

  @override
  CardinalDirection get birdDirection =>
      unloaderLift.birdDirection; //TODO move to DrawerConveyorBirdHanging

  @override
  bool removeBird() => true; //TODO move to DrawerConveyorBirdHanging
}
