import 'dart:math';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_cas.dart';
import 'state_machine.dart';

class ModuleRotatingConveyor extends StateMachineCell {
  CompassDirection currentDirection;
  final int degreesPerSecond;
  final CardinalDirection? defaultPositionWhenIdle;
  final List<CardinalDirection> oppositeInFeeds;
  final List<CardinalDirection> oppositeOutFeeds;

  Map<CardinalDirection, Duration> neighborsAlmostWaitingToFeedOutDurations = {
    CardinalDirection.north: Duration.zero,
    CardinalDirection.east: Duration.zero,
    CardinalDirection.south: Duration.zero,
    CardinalDirection.west: Duration.zero,
  };
  Map<CardinalDirection, Duration> neighborsWaitingToFeedOutDurations = {
    CardinalDirection.north: Duration.zero,
    CardinalDirection.east: Duration.zero,
    CardinalDirection.south: Duration.zero,
    CardinalDirection.west: Duration.zero,
  };
  Map<CardinalDirection, Duration> neighborsWaitingToFeedInDurations = {
    CardinalDirection.north: Duration.zero,
    CardinalDirection.east: Duration.zero,
    CardinalDirection.south: Duration.zero,
    CardinalDirection.west: Duration.zero,
  };

  @override
  String get name => "ModuleRotatingConveyor${seqNr ?? ''}";

  ModuleRotatingConveyor({
    required LiveBirdHandlingArea area,
    required Position position,
    int? seqNr,
    int? degreesPerSecond,
    this.defaultPositionWhenIdle,
    this.oppositeInFeeds = const [],
    this.oppositeOutFeeds = const [],
    State<ModuleRotatingConveyor>? initialState,
    Duration? inFeedDuration,
    Duration? outFeedDuration,
  })  : currentDirection = calculateBeginPosition(defaultPositionWhenIdle),
        degreesPerSecond = degreesPerSecond ??
            area.productDefinition.moduleSystem.turnTableDegreesPerSecond,
        super(
          area: area,
          position: position,
          seqNr: seqNr,
          initialState: initialState ?? TurnToInFeed(),
          inFeedDuration: inFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
          outFeedDuration: outFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
        );

  bool get moduleGroupFeedingIn => area.moduleGroups
      .any((moduleGroup) => moduleGroup.position.destination == this);

  int _neighborInFeedScore(CardinalDirection direction) {
    if (_neighborModuleNeedsToWaitUntilDestinationCasUnitOkToFeedIn(
        direction)) {
      return 0;
    }

    return max(neighborsWaitingToFeedOutDurations[direction]!.inMilliseconds,
        neighborsAlmostWaitingToFeedOutDurations[direction]!.inMilliseconds);
  }

  @override
  onUpdateToNextPointInTime(Duration jump) {
    increaseNeighborsWaitingDurations(jump);

    super.onUpdateToNextPointInTime(jump);
  }

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) {
    var neighbor = area.neighboringCell(this, direction);
    if (neighbor is ModuleRotatingConveyor) {
      return true; // prevent endless loops between ModuleRotatingConveyor.isFeedIn and ModuleRotatingConveyor.isFeedOut
    }
    return neighbor.isFeedOut(direction.opposite);
  }

  @override
  bool waitingToFeedIn(CardinalDirection direction) {
    var bestInFeedNeighborDirection = bestInFeedNeighbor;
    var waitingToFeedIn = bestInFeedNeighborDirection != null &&
        direction == bestInFeedNeighborDirection &&
        currentDirection.toCardinalDirection() != null &&
        currentDirection.toCardinalDirection() == inFeedDirection &&
        currentState is TurnToInFeed;

    return waitingToFeedIn;
  }

  @override
  bool isFeedOut(CardinalDirection direction) {
    var neighbor = area.neighboringCell(this, direction);
    if (neighbor is ModuleRotatingConveyor) {
      return true; // prevent endless loops between ModuleRotatingConveyor.isFeedIn and ModuleRotatingConveyor.isFeedOut
    }
    return neighbor.isFeedIn(direction.opposite);
  }

  @override
  bool waitingToFeedOut(CardinalDirection direction) {
    return moduleGroup != null &&
        direction == bestOutFeedNeighbor &&
        currentDirection.toCardinalDirection() != null &&
        currentDirection.toCardinalDirection() == outFeedDirection &&
        currentState is TurnToFeedOut;
  }

  void increaseNeighborsWaitingDurations(Duration jump) {
    for (var direction in CardinalDirection.values) {
      var neighbor = area.neighboringCell(this, direction);
      if (neighbor.almostWaitingToFeedOut(direction.opposite)) {
        neighborsAlmostWaitingToFeedOutDurations[direction] = _noMoreThan1Hour(
            neighborsAlmostWaitingToFeedOutDurations[direction]! + jump);
      } else {
        neighborsAlmostWaitingToFeedOutDurations[direction] = Duration.zero;
      }
      if (neighbor.waitingToFeedOut(direction.opposite)) {
        neighborsWaitingToFeedOutDurations[direction] = _noMoreThan1Hour(
            neighborsWaitingToFeedOutDurations[direction]! + jump);
      } else {
        neighborsWaitingToFeedOutDurations[direction] = Duration.zero;
      }
      if (neighbor.waitingToFeedIn(direction.opposite)) {
        neighborsWaitingToFeedInDurations[direction] = _noMoreThan1Hour(
            neighborsWaitingToFeedInDurations[direction]! + jump);
      } else {
        neighborsWaitingToFeedInDurations[direction] = Duration.zero;
      }
    }
  }

  /// returns the neighbor cell that was waiting the longest to feed out.
  /// returns null when no neighbor cell are waiting (0 sec)
  CardinalDirection? longestWaitingNeighbor(
      Map<CardinalDirection, Duration> secondsThatNeighborsAreWaiting,
      {bool neighborMustBeCASUnit = false}) {
    Duration highestValue = Duration.zero;
    CardinalDirection? directionWithHighestValue;

    secondsThatNeighborsAreWaiting.forEach((direction, secondsWaiting) {
      if ((!neighborMustBeCASUnit ||
              area.neighboringCell(this, direction) is ModuleCas) &&
          secondsWaiting > Duration.zero &&
          secondsWaiting > highestValue) {
        highestValue = secondsWaiting;
        directionWithHighestValue = direction;
      }
    });
    return directionWithHighestValue;
  }

  static CompassDirection calculateBeginPosition(
      CardinalDirection? defaultPositionWhenIdle) {
    if (defaultPositionWhenIdle == null) {
      return CardinalDirection.north.toCompassDirection();
    } else {
      return defaultPositionWhenIdle.toCompassDirection();
    }
  }

  Duration _noMoreThan1Hour(Duration duration) {
    const max = Duration(hours: 1);
    if (duration >= max) {
      return max;
    } else {
      return duration;
    }
  }

  Map<CardinalDirection, int> get neighborInFeedScores {
    Map<CardinalDirection, int> scores = {};
    for (var direction in CardinalDirection.values) {
      scores[direction] = _neighborInFeedScore(direction);
    }
    return scores;
  }

  /// returns the best direction to feed in from
  /// returns null when there is no outcome
  CardinalDirection? get bestInFeedNeighbor {
    var topScore = 0;
    CardinalDirection? topScoreDirection;
    for (var direction in CardinalDirection.values) {
      var score = _neighborInFeedScore(direction);
      if (score > topScore) {
        topScore = score;
        topScoreDirection = direction;
      }
    }
    if (name == 'ModuleRotatingConveyor1') {
      //print('direction:=$topScoreDirection $neighborInFeedScores');
    }

    return topScoreDirection;
  }

  CardinalDirection? get inFeedDirection {
    var neighborToFeedInFrom = bestInFeedNeighbor;
    if (neighborToFeedInFrom == null) {
      if (defaultPositionWhenIdle != null) {
        return defaultPositionWhenIdle!;
      } else {
        return null;
      }
    }

    //note that in feed position is in inverse by default!!!
    if (oppositeInFeeds.contains(neighborToFeedInFrom)) {
      return neighborToFeedInFrom;
    } else {
      return neighborToFeedInFrom.opposite;
    }
  }

  CardinalDirection? get bestOutFeedNeighbor {
    if (moduleGroup == null) {
      return null;
    }
    var destination = moduleGroup!.destination;

    var onlyOutFeedNeighbor = findOnlyNeighbor();
    if (onlyOutFeedNeighbor != null) {
      return onlyOutFeedNeighbor;
    }

    //TODO scores for longest waiting
    for (var direction in CardinalDirection.values) {
      var neighbor = area.neighboringCell(this, direction);

      if (neighbor is StateMachineCell &&
          neighbor.isFeedIn(direction.opposite)) {
        var route = area.findRoute(
          source: neighbor,
          destination: destination,
          routeSoFar: Route([this]),
        );
        if (route != null) {
          return direction;
        }
      }
    }
    //no destination found: stay where we are
    return null;
  }

  CardinalDirection? get outFeedDirection {
    var neighborToFeedOutFrom = bestOutFeedNeighbor;
    if (neighborToFeedOutFrom == null) {
      return null;
    }
    if (oppositeOutFeeds.contains(neighborToFeedOutFrom)) {
      return neighborToFeedOutFrom.opposite;
    } else {
      return neighborToFeedOutFrom;
    }
  }

  CardinalDirection? findOnlyNeighbor() {
    CardinalDirection? foundNeighbor;
    for (var direction in CardinalDirection.values) {
      var neighbor = area.neighboringCell(this, direction);
      if (neighbor is StateMachineCell &&
          neighbor.isFeedIn(direction.opposite)) {
        if (foundNeighbor == null) {
          foundNeighbor = direction;
        } else {
          // found multiple neighbors: return null
          return null;
        }
      }
    }
    return foundNeighbor;
  }

  bool _neighborModuleNeedsToWaitUntilDestinationCasUnitOkToFeedIn(
      CardinalDirection direction) {
    var inFeedNeighbor = area.neighboringCell(this, direction);
    return inFeedNeighbor is StateMachineCell &&
        inFeedNeighbor is! ModuleCas &&
        inFeedNeighbor.moduleGroup != null &&
        inFeedNeighbor.isFeedOut(direction.opposite) &&
        _hasNeighboringCasUnitNotOkToFeedIn(
            inFeedNeighbor.moduleGroup!.destination);
  }

  bool _hasNeighboringCasUnitNotOkToFeedIn(
      StateMachineCell stateMachineCellToFind) {
    for (var direction in CardinalDirection.values) {
      var neighbor = area.neighboringCell(this, direction);
      var found = neighbor == stateMachineCellToFind &&
          neighbor is ModuleCas &&
          neighbor.isFeedIn(direction.opposite) &&
          !neighbor.waitingToFeedIn(direction.opposite);
      if (found) {
        return true;
      }
    }
    return false;
  }
}

class TurnToInFeed extends State<ModuleRotatingConveyor> {
  @override
  String get name => 'TurnToInFeed';
  Duration elapsedTurnTime = Duration.zero;

  @override
  void onUpdateToNextPointInTime(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor,
      Duration jump) {
    var goToDirection = rotatingConveyor.inFeedDirection;

    if (_needsToTurn(rotatingConveyor, goToDirection)) {
      turn(rotatingConveyor, goToDirection!, jump);
    }
  }

  bool _needsToTurn(ModuleRotatingConveyor rotatingConveyor,
      CardinalDirection? goToDirection) {
    return goToDirection != null &&
        rotatingConveyor.currentDirection.toCardinalDirection() !=
            goToDirection &&
        !rotatingConveyor.moduleGroupFeedingIn;
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (rotatingConveyor.moduleGroupFeedingIn) {
      return FeedIn();
    }
    return null;
  }

  void turn(ModuleRotatingConveyor rotatingConveyor,
      CardinalDirection goToDirection, Duration jump) {
    int degreesToTurnThisJump =
        _degreesToTurnThisJump(rotatingConveyor, jump, goToDirection);

    rotatingConveyor.currentDirection =
        rotatingConveyor.currentDirection.rotate(degreesToTurnThisJump);
  }

  int _degreesToTurnThisJump(ModuleRotatingConveyor rotatingConveyor,
      Duration jump, CardinalDirection goToDirection) {
    elapsedTurnTime += jump;

    int degreesToTurnThisJump = (rotatingConveyor.degreesPerSecond *
            elapsedTurnTime.inMilliseconds /
            1000)
        .round();
    if (degreesToTurnThisJump > 0) {
      elapsedTurnTime = Duration.zero;
    }

    int degreesToTurnTotal = (rotatingConveyor.currentDirection.degrees -
            goToDirection.toCompassDirection().degrees)
        .abs();
    if (degreesToTurnTotal < 90 &&
        degreesToTurnTotal % 90 < degreesToTurnThisJump) {
      degreesToTurnThisJump = degreesToTurnTotal % 90;
    }

    bool clockWise = _rotateClockWise(rotatingConveyor, goToDirection);
    return clockWise ? degreesToTurnThisJump : -degreesToTurnThisJump;
  }
}

/// Determines if the turn table needs to turn clock wise our counter clock wise
bool _rotateClockWise(
    ModuleRotatingConveyor rotatingConveyor, CardinalDirection goToDirection) {
  // TODO make sure the table does not rotate over stopper using: var stopperDirection = ModuleRotatingConveyor.homingPosition.opposite;
  // TODO make sure the feed out direction is correct depending neighbor: e.g. Cell.requiredDoorDirectionToFeedIn
  var actualDirection = rotatingConveyor.currentDirection;
  var clockWiseDistance = actualDirection
      .clockWiseDistanceInDegrees(goToDirection.toCompassDirection());
  var counterClockWiseDistance = actualDirection
      .counterClockWiseDistanceInDegrees(goToDirection.toCompassDirection());
  bool clockWise =
      clockWiseDistance < counterClockWiseDistance; //TODO stopperDirection
  return clockWise;
}

class FeedIn extends State<ModuleRotatingConveyor> {
  @override
  String get name => 'FeedIn';
  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (transportCompleted(rotatingConveyor)) {
      return TurnToFeedOut();
    }
    return null;
  }

  bool transportCompleted(ModuleRotatingConveyor rotatingConveyor) =>
      rotatingConveyor.moduleGroup != null;
}

class TurnToFeedOut extends State<ModuleRotatingConveyor> {
  @override
  String get name => 'TurnToFeedOut';

  Duration elapsedTurnTime = Duration.zero;

  @override
  void onUpdateToNextPointInTime(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor,
      Duration jump) {
    if (!doneRotating(rotatingConveyor)) {
      turn(rotatingConveyor, jump);
    }
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (neighborOkToFeedIn(rotatingConveyor) &&
        doneRotating(rotatingConveyor) &&
        rotatingConveyor.moduleGroup!.destination != rotatingConveyor) {
      return FeedOut();
    }
    return null;
  }

  bool doneRotating(ModuleRotatingConveyor rotatingConveyor) {
    var goToDirection = rotatingConveyor.outFeedDirection;
    var currentDirection =
        rotatingConveyor.currentDirection.toCardinalDirection();
    var doneRotating =
        goToDirection != null && goToDirection == currentDirection;
    return doneRotating;
  }

  bool neighborOkToFeedIn(ModuleRotatingConveyor rotatingConveyor) {
    CardinalDirection? neighborPosition = rotatingConveyor.bestOutFeedNeighbor;
    if (neighborPosition == null) {
      return false;
    }
    var receivingNeighbor = rotatingConveyor.area
        .neighboringCell(rotatingConveyor, neighborPosition);
    return receivingNeighbor.waitingToFeedIn(neighborPosition.opposite);
  }

  void turn(ModuleRotatingConveyor rotatingConveyor, Duration jump) {
    CardinalDirection? goToDirection = rotatingConveyor.outFeedDirection;
    if (goToDirection != null) {
      int degreesToTurnThisJump =
          _degreesToTurnThisJump(rotatingConveyor, jump, goToDirection);

      rotatingConveyor.currentDirection =
          rotatingConveyor.currentDirection.rotate(degreesToTurnThisJump);
      rotatingConveyor.moduleGroup!.direction =
          rotatingConveyor.moduleGroup!.direction.rotate(degreesToTurnThisJump);
    }
  }

  int _degreesToTurnThisJump(ModuleRotatingConveyor rotatingConveyor,
      Duration jump, CardinalDirection goToDirection) {
    elapsedTurnTime += jump;
    int degreesToTurnThisJump = (rotatingConveyor.degreesPerSecond *
            elapsedTurnTime.inMilliseconds /
            1000)
        .round();
    if (degreesToTurnThisJump > 0) {
      elapsedTurnTime = Duration.zero;
    }
    int degreesToTurnTotal = (rotatingConveyor.currentDirection.degrees -
            goToDirection.toCompassDirection().degrees)
        .abs();
    if (degreesToTurnTotal < 90 &&
        degreesToTurnTotal % 90 < degreesToTurnThisJump) {
      degreesToTurnThisJump = degreesToTurnTotal % 90;
    }

    bool clockWise = _rotateClockWise(rotatingConveyor, goToDirection);
    return clockWise ? degreesToTurnThisJump : -degreesToTurnThisJump;
  }

  /// Determines if the turn table needs to turn clock wise our counter clock wise
  bool _rotateClockWise(ModuleRotatingConveyor rotatingConveyor,
      CardinalDirection goToDirection) {
    // TODO make sure the rotatingConveyor does not rotate over stopper using: var stopperDirection = ModuleRotatingConveyor.homingPosition.opposite;
    // TODO make sure the feed out direction is correct depending neighbor: e.g. Cell.requiredDoorDirectionToFeedIn
    var actualDirection = rotatingConveyor.currentDirection;
    var clockWiseDistance = actualDirection
        .clockWiseDistanceInDegrees(goToDirection.toCompassDirection());
    var counterClockWiseDistance = actualDirection
        .counterClockWiseDistanceInDegrees(goToDirection.toCompassDirection());
    bool clockWise =
        clockWiseDistance < counterClockWiseDistance; //TODO stopperDirection
    return clockWise;
  }
}

class FeedOut extends State<ModuleRotatingConveyor> {
  @override
  String get name => 'FeedOut';
  @override
  // ignore: avoid_renaming_method_parameters
  void onStart(ModuleRotatingConveyor rotatingConveyor) {
    var transportedModuleGroup = rotatingConveyor.moduleGroup;
    var area = rotatingConveyor.area;
    var neighborDirection = rotatingConveyor.bestOutFeedNeighbor;
    var receivingNeighbor = area.neighboringCell(
        rotatingConveyor, neighborDirection!) as StateMachineCell;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: rotatingConveyor, destination: receivingNeighbor);
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (transportCompleted(rotatingConveyor)) {
      return TurnToInFeed();
    }
    return null;
  }

  bool transportCompleted(ModuleRotatingConveyor rotatingConveyor) =>
      !rotatingConveyor.area.moduleGroups.any(
          (moduleGroup) => moduleGroup.position.source == rotatingConveyor);
}
