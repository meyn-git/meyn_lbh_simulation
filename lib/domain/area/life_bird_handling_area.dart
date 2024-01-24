import 'dart:math';

import 'package:collection/collection.dart';

import 'module.dart';
import 'module_cas.dart';
import 'state_machine.dart';

abstract class LiveBirdHandlingArea implements TimeProcessor {
  final String lineName;
  final ProductDefinition productDefinition;
  final List<ActiveCell> cells = [];
  final List<ModuleGroup> moduleGroups = [];
  Duration durationSinceStart = Duration.zero;
  int moduleSequenceNumber = 0;

  LiveBirdHandlingArea({
    required this.lineName,
    required this.productDefinition,
  });

  String get name => '$lineName-$productDefinition';

  CellRange get cellRange => CellRange(cells);

  Cell neighboringCell(ActiveCell cell, CardinalDirection direction) {
    Position relativePosition = cell.position.neighbor(direction);
    return cellForPosition(relativePosition);
  }

  void put(ActiveCell cell) {
    checkIfPositionIsUnique(cell.position);
    checkIfNameIsUnique(cell);
    cells.add(cell);
  }

  void checkIfPositionIsUnique(Position position) {
    if (cells.map((cell) => cell.position).contains(position)) {
      throw Exception('$position was already defined');
    }
  }

  checkIfNameIsUnique(ActiveCell cell) {
    bool exists = cells
        .any((existingStateMachine) => cell.name == existingStateMachine.name);
    if (exists) {
      throw Exception('StateMachine name: ${cell.name} is not unique');
    }
  }

  Cell cellForPosition(Position positionToFind) {
    var foundCell =
        cells.firstWhereOrNull((cell) => cell.position == positionToFind);
    return foundCell ?? EmptyCell();
  }

  /// Updates all the [ActiveCell]s and [ModuleGroup]s
  @override
  onUpdateToNextPointInTime(Duration jump) {
    durationSinceStart = durationSinceStart + jump;
    for (var cell in cells) {
      cell.onUpdateToNextPointInTime(jump);
    }
    for (var moduleGroup in moduleGroups) {
      moduleGroup.onUpdateToNextPointInTime(jump);
    }
  }

  Route? findRoute({
    required StateMachineCell source,
    required StateMachineCell destination,
    Route routeSoFar = const Route.empty(),
  }) {
    if (source.position == destination.position) {
      return Route([...routeSoFar, destination]);
    }
    routeSoFar = Route([...routeSoFar, source]);
    for (var direction in CardinalDirection.values) {
      var neighbor = neighboringCell(source, direction);
      if (neighbor is StateMachineCell &&
          neighbor.isFeedIn(direction.opposite) &&
          !routeSoFar.contains(neighbor)) {
        // recursive call
        var foundRoute = findRoute(
          source: neighbor,
          destination: destination,
          routeSoFar: routeSoFar,
        );
        if (foundRoute != null) {
          return foundRoute;
        }
      }
    }
    // tried all directions, no success
    return null;
  }

  @override
  String toString() {
    return '$lineName-$productDefinition';
  }
}

class CellRange {
  int? _minX;
  int? _maxX;
  int? _minY;
  int? _maxY;

  CellRange(List<ActiveCell> cells) {
    if (cells.isEmpty) {
      throw ('You must put cells in the area as part of the Area constructor');
    }
    Position firstPosition = cells.first.position;
    _minX = firstPosition.x;
    _maxX = firstPosition.x;
    _minY = firstPosition.y;
    _maxY = firstPosition.y;
    cells.map<Position>((cell) => cell.position).forEach((position) {
      _minX = min(_minX!, position.x);
      _maxX = max(_maxX!, position.x);
      _minY = min(_minY!, position.y);
      _maxY = max(_maxY!, position.y);
    });
  }

  int get minX => _minX!;

  int get maxX => _maxX!;

  int get minY => _minY!;

  int get maxY => _maxY!;

  int get width => (minX - maxX).abs() + 1;

  int get height => (minY - maxY).abs() + 1;
}

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return 'Position{x: $x, y: $y}';
  }

  Position neighbor(CardinalDirection relativePosition) {
    switch (relativePosition) {
      case CardinalDirection.north:
        return Position(x, y - 1);
      case CardinalDirection.east:
        return Position(x + 1, y);
      case CardinalDirection.south:
        return Position(x, y + 1);
      case CardinalDirection.west:
        return Position(x - 1, y);
    }
  }
}

abstract class Cell {
  /// whether a given direction can feed out modules
  bool isFeedIn(CardinalDirection direction);

  /// waiting to feed in a [ModuleGroup] from the preceding transport system
  /// e.g.: when a [StateMachineCell] is in WaitToFeedIn
  bool waitingToFeedIn(CardinalDirection direction);

  /// whether a given direction can feed out modules
  bool isFeedOut(CardinalDirection direction);

  /// used to request to turn the turn table to this position in advance.
  bool almostWaitingToFeedOut(CardinalDirection direction);

  /// module(s) waiting to feed out to next transport system
  /// e.g. when a [StateMachineCell] is WaitToFeedOut
  bool waitingToFeedOut(CardinalDirection direction);

  /// to be increased with [nrOfModules] when the StateMachine has fed out
  int nrOfModulesMoved = 0;

  ModuleGroup? get moduleGroup;
}

class EmptyCell extends Cell {
  static final EmptyCell _emptyCell = EmptyCell._();

  EmptyCell._();

  factory EmptyCell() => _emptyCell;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedIn(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => false;

  @override
  bool isFeedOut(CardinalDirection direction) => false;

  @override
  ModuleGroup? get moduleGroup => null;
}

enum CardinalDirection { north, east, south, west }

extension CardinalDirectionExtension on CardinalDirection {
  CompassDirection toCompassDirection() {
    switch (this) {
      case CardinalDirection.north:
        return CompassDirection(0);
      case CardinalDirection.east:
        return CompassDirection(90);
      case CardinalDirection.south:
        return CompassDirection(180);
      case CardinalDirection.west:
        return CompassDirection(270);
    }
  }

  CardinalDirection get opposite {
    switch (this) {
      case CardinalDirection.north:
        return CardinalDirection.south;
      case CardinalDirection.east:
        return CardinalDirection.west;
      case CardinalDirection.south:
        return CardinalDirection.north;
      case CardinalDirection.west:
        return CardinalDirection.east;
    }
  }

  bool isParallelTo(CardinalDirection otherDirection) =>
      this == otherDirection || this == otherDirection.opposite;

  bool isPerpendicularTo(CardinalDirection otherDirection) =>
      !isParallelTo(otherDirection);
}

class CompassDirection {
  final int degrees;
  static const int max = 360;

  CompassDirection(int degrees) : degrees = degrees % max;

  CompassDirection rotate(int rotation) {
    return CompassDirection(degrees + rotation);
  }

  CardinalDirection? toCardinalDirection() {
    for (var cardinalDirection in CardinalDirection.values) {
      if (cardinalDirection.toCompassDirection().degrees == degrees) {
        return cardinalDirection;
      }
    }
    return null;
  }

  int clockWiseDistanceInDegrees(CompassDirection destination) {
    if (degrees < destination.degrees) {
      return destination.degrees - degrees;
    } else {
      return max - degrees + destination.degrees;
    }
  }

  int counterClockWiseDistanceInDegrees(CompassDirection destination) {
    if (degrees > destination.degrees) {
      return degrees - destination.degrees;
    } else {
      return degrees + max - destination.degrees;
    }
  }

  @override
  String toString() => degrees.toString();
}

abstract class TimeProcessor {
  /// method to change the state of the object to the next point in time
  void onUpdateToNextPointInTime(Duration jump);
}

abstract class ActiveCell extends Cell implements TimeProcessor {
  final LiveBirdHandlingArea area;
  final Position position;

  ActiveCell(this.area, this.position);

  String get name;
}

/// A list of [StateMachineCell]s to get to a [ModuleCas] within a [LiveBirdHandlingArea]
class Route extends DelegatingList<StateMachineCell> {
  Route(
    List<StateMachineCell> cellRoute,
  ) : super(cellRoute);

  const Route.empty() : super(const []);

  /// [ModuleCas] score for getting a new, un-stunned [ModuleGroup].
  /// =0 when [ModuleCas] is NOT waiting for a new un-stunned [ModuleGroup]
  ///    or there is already a new un-stunned [ModuleGroup].
  /// >0 the higher the score the higher the priority (e.g. when more [Route]s are competing
  ///    - the longest route has the highest score (send stacks to furthest units first)
  ///    - the [ModuleCas] that is most ready to receive a module will get the highest
  ///      score when routes of equal length are competing (see .3, .2, .1).
  double get casNewStackScore {
    if (_moduleGroupGoingTo(cas)) {
      return 0;
    }
    var score = _casReadinessScore * 3 +
        _troughPutScore * 2 +
        _distanceToTravelScore * 1;
    return score;
  }

  /// A score between 1 (=100%) and 0 (=0%)
  /// high (1) = when no modules are on route, otherwise
  /// lower for each module that is blocking the route
  double get _troughPutScore => 1 / (1 + numberOfModulesGroupsOnRoute);

  /// A score between 1 (=100%) and 0 (=0%)
  /// high (near 1) = longest route
  /// low (towards 0) = shortest route
  double get _distanceToTravelScore => 1 - (1 / length);

  /// A score between 1 (=100%) and 0 (=0%)
  /// 1= waiting to feed in
  /// 0.7= waiting to feed out
  /// 0.4= almost waiting to feed in
  double get _casReadinessScore {
    if (casIsOkToFeedIn) {
      return 1;
    } else if (casIsOkToFeedOut) {
      return 0.7;
    } else if (casIsAlmostOkToFeedOut) {
      return 0.4;
    } else {
      return 0;
    }
  }

  int get numberOfModulesGroupsOnRoute {
    int total = 0;
    for (StateMachineCell stateMachine in this) {
      if (stateMachine.moduleGroup != null &&
          stateMachine != first &&
          stateMachine != last) {
        total++;
      }
    }
    return total;
  }

  bool _moduleGroupGoingTo(ModuleCas cas) =>
      cas.area.moduleGroups.any((moduleGroup) =>
          moduleGroup.position.source != first &&
          moduleGroup.destination == cas);

  bool get casIsOkToFeedIn => cas.waitingToFeedIn(cas.inAndOutFeedDirection);

  bool get casIsOkToFeedOut => cas.waitingToFeedOut(cas.inAndOutFeedDirection);

  bool get casIsAlmostOkToFeedOut =>
      cas.almostWaitingToFeedOut(cas.inAndOutFeedDirection);

  ModuleCas get cas {
    var destination = last;
    if (destination is ModuleCas) {
      return destination;
    } else {
      throw Exception('The last cell in the route is not a $ModuleCas');
    }
  }
}

abstract class BirdBuffer {
  /// returns the direction that the bird buffer is heading towards (e.g. the relative direction of a [BirdHangingConveyor]
  CardinalDirection get birdDirection;

  /// Removes a bird from the buffer. returns true if the buffer still had one.
  bool removeBird();
}

class ProductDefinition {
  final String birdType;
  final int lineSpeedInShacklesPerHour;
  final ModuleFamily moduleFamily;
  final List<ModuleGroupCapacity> moduleGroupCapacities;
  final CasRecipe? casRecipe;
  final ModuleSystem moduleSystem;
  final List<LiveBirdHandlingArea> Function(ProductDefinition) areaFactory;

  ProductDefinition({
    required this.areaFactory,
    required this.moduleSystem,
    required this.birdType,
    required this.lineSpeedInShacklesPerHour,
    required this.moduleFamily,
    required this.moduleGroupCapacities,
    required this.casRecipe,
  }) {
    _verifyModuleGroupCapacities();
  }

  List<LiveBirdHandlingArea> get areas => areaFactory(this);

  double get averageProductsPerModuleGroup {
    var totalBirds = 0;
    var totalOccurrence = 0.0;
    for (var moduleGroupCapacity in moduleGroupCapacities) {
      totalBirds += moduleGroupCapacity.numberOfBirds;
      totalOccurrence += moduleGroupCapacity.occurrence;
    }
    return totalBirds / totalOccurrence;
  }

  @override
  String toString() {
    return '$birdType-${lineSpeedInShacklesPerHour}b/h-${moduleGroupCapacities.join(' ')}';
  }

  void _verifyModuleGroupCapacities() {
    if (moduleGroupCapacities.isEmpty) {
      throw ArgumentError('May not be empty', 'moduleGroupCapacities');
    }
  }
}

enum LoadFactor { minimum, average, max }
