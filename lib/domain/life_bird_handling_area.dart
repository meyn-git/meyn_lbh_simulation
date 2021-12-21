import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/bird_hanging_conveyor.dart';

import 'module.dart';
import 'module_cas.dart';
import 'state_machine.dart';

abstract class LiveBirdHandlingArea implements TimeProcessor {
  final String lineName;
  final ProductDefinition productDefinition;
  final CasRecipe? casRecipe;
  final List<ActiveCell> cells = [];
  final List<ModuleGroup> moduleGroups = [];
  Duration durationSinceStart = Duration.zero;
  int moduleSequenceNumber = 0;

  LiveBirdHandlingArea({
    required this.lineName,
    required this.productDefinition,
    this.casRecipe,
  });

  String get name => '$lineName-$productDefinition';

  Cell neighbouringCell(ActiveCell cell, CardinalDirection direction) {
    Position relativePosition = cell.position.neighbour(direction);
    return cellForPosition(relativePosition);
  }

  void put(ActiveCell cell) {
    checkIfPositionIsUnique(cell.position);
    checkIfNameIsUnique(cell);
    cells.add(cell);
  }

  void checkIfPositionIsUnique(Position position) {
    if (cells.map((cell) => cell.position).contains(position))
      throw new Exception('$position was already defined');
  }

  checkIfNameIsUnique(ActiveCell cell) {
    bool exists = cells
        .any((existingStateMachine) => cell.name == existingStateMachine.name);
    if (exists)
      throw Exception('StateMachine name: ${cell.name} is not unique');
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
    cells.forEach((cell) {
      cell.onUpdateToNextPointInTime(jump);
    });
    moduleGroups.forEach((moduleGroup) {
      moduleGroup.onUpdateToNextPointInTime(jump);
    });
  }

  Route? findRoute({
    required StateMachineCell source,
    required StateMachineCell destination,
    Route routeSoFar = const Route.empty(),
  }) {
    if (source is! StateMachineCell || destination is! StateMachineCell) {
      return null;
    }
    if (source.position == destination.position) {
      return Route([...routeSoFar, destination]);
    }
    routeSoFar = Route([...routeSoFar, source]);
    for (var direction in CardinalDirection.values) {
      var neighbour = neighbouringCell(source, direction);
      if (neighbour is StateMachineCell &&
          neighbour.isFeedIn(direction.opposite) &&
          !routeSoFar.contains(neighbour)) {
        // recursive call
        var foundRoute = findRoute(
          source: neighbour,
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

  Position neighbour(CardinalDirection relativePosition) {
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
  bool isFeedIn(CardinalDirection inFeedDirection);

  /// waiting to feed in a [ModuleGroup] from the preceding transport system
  /// e.g.: when a [StateMachineCell] is in WaitToFeedIn
  bool waitingToFeedIn(CardinalDirection inFeedDirection);

  /// whether a given direction can feed out modules
  bool isFeedOut(CardinalDirection outFeedDirection);

  /// used to request to turn the turn table to this position in advance.
  bool almostWaitingToFeedOut(CardinalDirection outFeedDirection);

  /// module(s) waiting to feed out to next transport system
  /// e.g. when a [StateMachineCell] is WaitToFeedOut
  bool waitingToFeedOut(CardinalDirection outFeedDirection);

  /// to be increased with [nrOfModules] when the StateMachine has fed out
  int nrOfModulesMoved = 0;

  ModuleGroup? get moduleGroup;
}

class EmptyCell extends Cell {
  static EmptyCell _emptyCell = EmptyCell._();

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
  static final int max = 360;

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
    if (this.degrees < destination.degrees) {
      return destination.degrees - this.degrees;
    } else {
      return max - this.degrees + destination.degrees;
    }
  }

  int counterClockWiseDistanceInDegrees(CompassDirection destination) {
    if (this.degrees > destination.degrees) {
      return this.degrees - destination.degrees;
    } else {
      return this.degrees + max - destination.degrees;
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

    // factor is high when no modules are on route, otherwise lower for each module that is blocking the route
    int factor = 20 - numberOfModulesOnRoute;

    if (casIsOkToFeedIn) {
      return (length + 0.3) * factor;
    } else if (casIsOkToFeedOut) {
      return (length + 0.2) * factor;
    } else if (casIsAlmostOkToFeedOut) {
      return (length + 0.1) * factor;
    } else {
      return 0;
    }
  }

  int get numberOfModulesOnRoute {
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

  bool _moduleGroupGoingTo(ModuleCas cas) => cas.area.moduleGroups
      .any((moduleGroup) => moduleGroup.destination == cas);

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
  final LoadFactor loadFactor;
  final int lineSpeedInShacklesPerHour;
  final List<ModuleCombination> moduleCombinations;
  final List<LiveBirdHandlingArea> Function(ProductDefinition) areaFactory;

  ProductDefinition({
    required this.areaFactory,
    required this.birdType,
    required this.loadFactor,
    required this.lineSpeedInShacklesPerHour,
    required this.moduleCombinations,
  });

  List<LiveBirdHandlingArea> get areas => areaFactory(this);

  double get averageProductsPerModuleGroup {
    var totalBirds = 0;
    var totalOccurrence = 0.0;
    for (var moduleCombination in moduleCombinations) {
      totalBirds += moduleCombination.firstModuleNumberOfBirds;
      totalOccurrence += moduleCombination.occurrence;
      if (moduleCombination.secondModuleNumberOfBirds != null) {
        totalBirds += moduleCombination.secondModuleNumberOfBirds!;
        totalOccurrence += moduleCombination.occurrence;
      }
    }
    return totalBirds / totalOccurrence;
  }

  @override
  String toString() {
    return '$birdType-$loadFactor-${lineSpeedInShacklesPerHour}b/h';
  }
}

enum LoadFactor { minimum, average, max }

class ModuleCombination {
  // how often this Module Combination is loaded on to the system
  final double occurrence;
  final ModuleType firstModuleType;
  final int firstModuleNumberOfBirds;
  final ModuleType? secondModuleType;
  final int? secondModuleNumberOfBirds;

  ModuleCombination(
      {this.occurrence = 1,
      required this.firstModuleType,
      required this.firstModuleNumberOfBirds,
      this.secondModuleType,
      this.secondModuleNumberOfBirds}) {
    _validateIfSecondModuleIsComplete();
    _validateFirstAndSecondModule();
  }

  void _validateFirstAndSecondModule() {
    if (secondModuleType != null) {
      if (firstModuleType.shape != secondModuleType!.shape) {
        throw Exception(
            'The first module shape (${firstModuleType.shape}) and second module shape (${secondModuleType!.shape}) must be identical');
      }
      if (firstModuleType.birdType != secondModuleType!.birdType) {
        throw Exception(
            'The first module bird type (${firstModuleType.birdType}) and second module bird type (${secondModuleType!.birdType}) must be identical');
      }
    }
  }

  void _validateIfSecondModuleIsComplete() {
    if (secondModuleType != null && secondModuleNumberOfBirds == null ||
        secondModuleType == null && secondModuleNumberOfBirds != null) {
      throw Exception(
          'You must eiter define secondModuleType with secondModuleNumberOfBirds or none.');
    }
  }
}
