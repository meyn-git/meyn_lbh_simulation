import 'layout.dart';
import 'module.dart';
import 'module_cas.dart';
import 'state_machine.dart';

class ModuleRotatingConveyor extends StateMachineCell {
  CompassDirection currentDirection;
  final int degreesPerSecond;
  final CardinalDirection? defaultPositionWhenIdle;
  final List<CardinalDirection> oppositeInFeeds;
  final List<CardinalDirection> oppositeOutFeeds;

  Map<CardinalDirection, Duration> neighboursAlmostWaitingToFeedOutDurations = {
    CardinalDirection.north: Duration.zero,
    CardinalDirection.east: Duration.zero,
    CardinalDirection.south: Duration.zero,
    CardinalDirection.west: Duration.zero,
  };
  Map<CardinalDirection, Duration> neighboursWaitingToFeedOutDurations = {
    CardinalDirection.north: Duration.zero,
    CardinalDirection.east: Duration.zero,
    CardinalDirection.south: Duration.zero,
    CardinalDirection.west: Duration.zero,
  };
  Map<CardinalDirection, Duration> neighboursWaitingToFeedInDurations = {
    CardinalDirection.north: Duration.zero,
    CardinalDirection.east: Duration.zero,
    CardinalDirection.south: Duration.zero,
    CardinalDirection.west: Duration.zero,
  };

  ModuleRotatingConveyor({
    required Layout layout,
    required Position position,
    int? seqNr,

    /// 6 seconds per 90 degrees = 15 degrees per second.
    this.degreesPerSecond = 15,
    this.defaultPositionWhenIdle,
    this.oppositeInFeeds = const [],
    this.oppositeOutFeeds = const [],
    Duration inFeedDuration = const Duration(seconds: 12),
    Duration outFeedDuration = const Duration(seconds: 12),
  })  : currentDirection = calculateBeginPosition(defaultPositionWhenIdle),
        super(
          layout: layout,
          position: position,
          seqNr: seqNr,
          initialState: TurnToInFeed(),
          inFeedDuration: inFeedDuration,
          outFeedDuration: outFeedDuration,
        );

  onUpdateToNextPointInTime(Duration jump) {
    increaseNeighboursWaitingDurations(jump);
    super.onUpdateToNextPointInTime(jump);
  }

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) {
    var neighbour = layout.neighbouringCell(this, direction);
    if (neighbour is ModuleRotatingConveyor) {
      return true; // prevent endless loops between ModuleRotatingConveyor.isFeedIn and ModuleRotatingConveyor.isFeedOut
    }
    return neighbour.isFeedOut(direction.opposite);
  }

  @override
  bool waitingToFeedIn(CardinalDirection direction) {
    return direction == bestInFeedNeighbour &&
        currentDirection.toCardinalDirection() != null &&
        currentDirection.toCardinalDirection() == inFeedDirection &&
        currentState is TurnToInFeed;
  }

  @override
  bool isFeedOut(CardinalDirection direction) {
    var neighbour = layout.neighbouringCell(this, direction);
    if (neighbour is ModuleRotatingConveyor) {
      return true; // prevent endless loops between ModuleRotatingConveyor.isFeedIn and ModuleRotatingConveyor.isFeedOut
    }
    return neighbour.isFeedIn(direction.opposite);
  }

  @override
  bool waitingToFeedOut(CardinalDirection direction) {
    return moduleGroup != null &&
        direction == bestOutFeedNeighbour &&
        currentDirection.toCardinalDirection() != null &&
        currentDirection.toCardinalDirection() == outFeedDirection &&
        currentState is TurnToFeedOut;
  }

  void increaseNeighboursWaitingDurations(Duration jump) {
    CardinalDirection.values.forEach((direction) {
      var neighbour = layout.neighbouringCell(this, direction);
      if (neighbour.almostWaitingToFeedOut(direction.opposite)) {
        neighboursAlmostWaitingToFeedOutDurations[direction] = _noMoreThan1Hour(
            neighboursAlmostWaitingToFeedOutDurations[direction]! + jump);
      } else {
        neighboursAlmostWaitingToFeedOutDurations[direction] = Duration.zero;
      }
      if (neighbour.waitingToFeedOut(direction.opposite)) {
        neighboursWaitingToFeedOutDurations[direction] = _noMoreThan1Hour(
            neighboursWaitingToFeedOutDurations[direction]! + jump);
      } else {
        neighboursWaitingToFeedOutDurations[direction] = Duration.zero;
      }
      if (neighbour.waitingToFeedIn(direction.opposite)) {
        neighboursWaitingToFeedInDurations[direction] = _noMoreThan1Hour(
            neighboursWaitingToFeedInDurations[direction]! + jump);
      } else {
        neighboursWaitingToFeedInDurations[direction] = Duration.zero;
      }
    });
  }

  /// returns the neighbour cell that was waiting the longest to feed out.
  /// returns null when no neighbour cell are waiting (0 sec)
  CardinalDirection? longestWaitingNeighbour(
      Map<CardinalDirection, Duration> secondsThatNeighboursAreWaiting,
      {bool neighbourMustBeCASUnit = false}) {
    Duration highestValue = Duration.zero;
    CardinalDirection? directionWithHighestValue;

    secondsThatNeighboursAreWaiting.forEach((direction, secondsWaiting) {
      if ((!neighbourMustBeCASUnit ||
              layout.neighbouringCell(this, direction) is ModuleCas) &&
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
    const max = const Duration(hours: 1);
    if (duration >= max) {
      return max;
    } else {
      return duration;
    }
  }

  /// returns the best direction to feed in from
  /// returns null when there is no outcome
  CardinalDirection? get bestInFeedNeighbour {
    CardinalDirection? longestWaitingCasNeighbourOkToFeedOut =
        longestWaitingNeighbour(neighboursWaitingToFeedOutDurations,
            neighbourMustBeCASUnit: true);
    if (longestWaitingCasNeighbourOkToFeedOut != null) {
      return longestWaitingCasNeighbourOkToFeedOut;
    }

    CardinalDirection? longestWaitingCasNeighbourAlmostOkToFeedOut =
        longestWaitingNeighbour(neighboursAlmostWaitingToFeedOutDurations,
            neighbourMustBeCASUnit: true);
    if (longestWaitingCasNeighbourAlmostOkToFeedOut != null) {
      return longestWaitingCasNeighbourAlmostOkToFeedOut;
    }

    CardinalDirection? longestWaitingNeighbourOkToFeedOut =
        longestWaitingNeighbour(neighboursWaitingToFeedOutDurations);
    if (longestWaitingNeighbourOkToFeedOut != null) {
      return longestWaitingNeighbourOkToFeedOut;
    }

    CardinalDirection? longestWaitingNeighbourAlmostOkToFeedOut =
        longestWaitingNeighbour(neighboursAlmostWaitingToFeedOutDurations);
    if (longestWaitingNeighbourAlmostOkToFeedOut != null) {
      return longestWaitingNeighbourAlmostOkToFeedOut;
    }

    //stay where we are
    return null;
  }

  CardinalDirection? get inFeedDirection {
    var neighbourToFeedInFrom = bestInFeedNeighbour;
    if (neighbourToFeedInFrom == null) {
      if (defaultPositionWhenIdle != null) {
        return defaultPositionWhenIdle!;
      } else {
        return null;
      }
    }

    //note that in feed position in inverse by default!!!
    if (oppositeInFeeds.contains(neighbourToFeedInFrom)) {
      return neighbourToFeedInFrom;
    } else {
      return neighbourToFeedInFrom.opposite;
    }
  }

  CardinalDirection? get bestOutFeedNeighbour {
    if (moduleGroup == null) {
      return null;
    }
    for (var direction in CardinalDirection.values) {
      var destination = moduleGroup!.destination;
      var neighbour = layout.neighbouringCell(this, direction);

      if (neighbour is StateMachineCell && destination is StateMachineCell) {
        var route = layout.findRoute(
          source: neighbour,
          destination: destination,
          routeSoFar: Route([this]),
        );
        if (neighbour.isFeedIn(direction.opposite) && route != null) {
          return direction;
        }
      }
    }
    //no destination found: stay where we are
    return null;
  }

  CardinalDirection? get outFeedDirection {
    var neighbourToFeedOutFrom = bestOutFeedNeighbour;
    if (neighbourToFeedOutFrom == null) {
      return null;
    }
    if (oppositeOutFeeds.contains(neighbourToFeedOutFrom)) {
      return neighbourToFeedOutFrom.opposite;
    } else {
      return neighbourToFeedOutFrom;
    }
  }
}

class TurnToInFeed extends State<ModuleRotatingConveyor> {
  Duration elapsedTurnTime = Duration.zero;

  @override
  void onUpdateToNextPointInTime(
      ModuleRotatingConveyor rotatingConveyor, Duration jump) {
    var goToDirection = rotatingConveyor.inFeedDirection;

    if (goToDirection != null) {
      var currentDirection =
          rotatingConveyor.currentDirection.toCardinalDirection();
      if (currentDirection != goToDirection) {
        turn(rotatingConveyor, goToDirection, jump);
      }
    }
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (_moduleGroupTransportedTo(rotatingConveyor)) {
      return FeedIn();
    }
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

  /// Determines if the turn table needs to turn clock wise our counter clock wise
  bool _rotateClockWise(ModuleRotatingConveyor rotatingConveyor,
      CardinalDirection goToDirection) {
    // TODO make sure the table does not rotate over stopper using: var stopperDirection = ModuleRotatingConveyor.homingPosition.opposite;
    // TODO make sure the feed out direction is correct depending neighbour: e.g. Cell.requiredDoorDirectionToFeedIn
    var actualDirection = rotatingConveyor.currentDirection;
    var clockWiseDistance = actualDirection
        .clockWiseDistanceInDegrees(goToDirection.toCompassDirection());
    var counterClockWiseDistance = actualDirection
        .counterClockWiseDistanceInDegrees(goToDirection.toCompassDirection());
    bool clockWise =
        clockWiseDistance < counterClockWiseDistance; //TODO stopperDirection
    return clockWise;
  }

  bool _moduleGroupTransportedTo(ModuleRotatingConveyor rotatingConveyor) =>
      rotatingConveyor.layout.moduleGroups.any((moduleGroup) =>
          moduleGroup.position.destination == rotatingConveyor);
}

class FeedIn extends State<ModuleRotatingConveyor> {
  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (_transportCompleted(rotatingConveyor)) {

      //FOR SOME REASON THE CONVEYOR ALREADY ROTATED (BY TURN TO FEED IN???) WHEN STARTED TO TURN THE CONVEYOR WITH MODULE????
      var turnError = rotatingConveyor.currentDirection.degrees% 90;
      if (turnError!=0) {
        rotatingConveyor.currentDirection=rotatingConveyor.currentDirection.rotate(-turnError);
      }
      return TurnToFeedOut();
    }
  }

  bool _transportCompleted(ModuleRotatingConveyor rotatingConveyor) =>
      rotatingConveyor.moduleGroup != null;
}

class TurnToFeedOut extends State<ModuleRotatingConveyor> {
  Duration elapsedTurnTime = Duration.zero;

  @override
  void onUpdateToNextPointInTime(
      ModuleRotatingConveyor rotatingConveyor, Duration jump) {
    if (!_doneRotating(rotatingConveyor)) {
      turn(rotatingConveyor, jump);
    }
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (_neighbourOkToFeedIn(rotatingConveyor) &&
        _doneRotating(rotatingConveyor)) {
      return FeedOut();
    }
  }

  bool _doneRotating(ModuleRotatingConveyor rotatingConveyor) {
    var goToDirection = rotatingConveyor.outFeedDirection;
    var currentDirection =
        rotatingConveyor.currentDirection.toCardinalDirection();
    var doneRotating = goToDirection != null && goToDirection == currentDirection;
    return doneRotating;
  }

  bool _neighbourOkToFeedIn(ModuleRotatingConveyor rotatingConveyor) {
    CardinalDirection? neighbourPosition =
        rotatingConveyor.bestOutFeedNeighbour;
    if (neighbourPosition == null) {
      return false;
    }
    var receivingNeighbour = rotatingConveyor.layout
        .neighbouringCell(rotatingConveyor, neighbourPosition);
    return receivingNeighbour.waitingToFeedIn(neighbourPosition.opposite);
  }

  void turn(ModuleRotatingConveyor rotatingConveyor, Duration jump) {
    CardinalDirection? goToDirection = rotatingConveyor.outFeedDirection;
    if (goToDirection != null) {
      int degreesToTurnThisJump =
          _degreesToTurnThisJump(rotatingConveyor, jump, goToDirection);

      rotatingConveyor.currentDirection =
          rotatingConveyor.currentDirection.rotate(degreesToTurnThisJump);
      rotatingConveyor.moduleGroup!.doorDirection = rotatingConveyor
          .moduleGroup!.doorDirection
          .rotate(degreesToTurnThisJump);

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
    // TODO make sure the feed out direction is correct depending neighbour: e.g. Cell.requiredDoorDirectionToFeedIn
    var actualDirection = rotatingConveyor.currentDirection;
    var clockWiseDistance = actualDirection
        .clockWiseDistanceInDegrees(goToDirection.toCompassDirection());
    var counterClockWiseDistance = actualDirection
        .counterClockWiseDistanceInDegrees(goToDirection.toCompassDirection());
    bool clockWise =
        clockWiseDistance < counterClockWiseDistance; //TODO stopperDirection
    return clockWise;
  }

  bool _moduleGroupIsAtDestination(ModuleRotatingConveyor rotatingConveyor) =>
      rotatingConveyor.moduleGroup!.destination == rotatingConveyor;
}

class FeedOut extends State<ModuleRotatingConveyor> {
  @override
  void onStart(ModuleRotatingConveyor rotatingConveyor) {
    var transportedModuleGroup = rotatingConveyor.moduleGroup;
    var layout = rotatingConveyor.layout;
    var neighbourDirection = rotatingConveyor.bestOutFeedNeighbour;
    var receivingNeighbour = layout.neighbouringCell(
        rotatingConveyor, neighbourDirection!) as StateMachineCell;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: rotatingConveyor, destination: receivingNeighbour);
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (_transportCompleted(rotatingConveyor)) {
      return TurnToInFeed();
    }
  }

  bool _transportCompleted(ModuleRotatingConveyor rotatingConveyor) =>
      !rotatingConveyor.layout.moduleGroups.any(
          (moduleGroup) => moduleGroup.position.source == rotatingConveyor);
}