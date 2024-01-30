  // ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';

class DrawerConveyor {
  /// * y: number of meters in north/south direction, e.g.:
  ///   * -3 = 3 meters north
  ///   * +2 = 2 meters south
  /// * x: number of meters in west/east direction, e.g.:
  ///   * -3 = 3 meters west
  ///   * +2 = 2 meters east
  final Vector2 vector;
  double metersPerSecond;

  factory DrawerConveyor.straight(
      {required double meters,
      required CardinalDirection direction,
      required double metersPerSecond}) {
    return DrawerConveyor(
        metersPerSecond: metersPerSecond,
        vector: _createStraightVector(direction, meters));
  }

  factory DrawerConveyor.corner(
      {required double meters,
      required CardinalDiagonalDirection direction,
      required double metersPerSecond}) {
    return DrawerConveyor(
        metersPerSecond: metersPerSecond,
        vector: _createDiagonalVector(direction, meters));
  }

  DrawerConveyor({
    required this.vector,
    required this.metersPerSecond,
  });

  static Vector2 _createStraightVector(
      CardinalDirection direction, double distanceInMeters) {
    switch (direction) {
      case CardinalDirection.north:
        return Vector2(0, -distanceInMeters);
      case CardinalDirection.east:
        return Vector2(distanceInMeters, 0);
      case CardinalDirection.south:
        return Vector2(0, distanceInMeters);
      case CardinalDirection.west:
        return Vector2(-distanceInMeters, 0);
      default:
        throw Exception('Unknown direction');
    }
  }

  static Vector2 _createDiagonalVector(
    CardinalDiagonalDirection direction,
    double distanceInMeters,
  ) {
    switch (direction) {
      case CardinalDiagonalDirection.northEast:
        var vector = Vector2(1, -1);
        vector.length = distanceInMeters;
        return vector;
      case CardinalDiagonalDirection.southEast:
        var vector = Vector2(1, 1);
        vector.length = distanceInMeters;
        return vector;
      case CardinalDiagonalDirection.southWest:
        var vector = Vector2(-1, 1);
        vector.length = distanceInMeters;
        return vector;
      case CardinalDiagonalDirection.northWest:
        var vector = Vector2(-1, -1);
        vector.length = distanceInMeters;
        return vector;
      default:
        throw Exception('Unknown direction');
    }
  }
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
  late double totalLengthInMeters = length(conveyors.map((c) => c.vector));

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
    if (lastDrawer.outSideLengthInMeters < lastConveyor.vector.length) {
      throw Exception('We assume the first conveyor is longer than a drawer. '
          'If not this method needs to be changed');
    }
    if (lastDrawer.conveyor != conveyors.first) {
      return true;
    }
    var emptySpace =
        lastConveyor.vector.length - lastDrawer.remainingMetersOnConveyor;
    return emptySpace > lastDrawer.outSideLengthInMeters;
  }
}
