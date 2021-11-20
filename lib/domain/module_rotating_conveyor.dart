import 'layout.dart';
import 'module.dart';
import 'module_cas.dart';
import 'state_machine.dart';

class ModuleRotatingConveyor extends StateMachineCell {
  CompassDirection currentDirection;
  final int degreesPerSecond;
  final CardinalDirection? defaultPositionWhenIdle;

  /// Note that you can note rotate more than 180 degrees left or right
  /// from the home position (in order to protect the cables)
  final CardinalDirection homingDirection;
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
    /// This must be a number that adds up to multitudes of 90
    this.degreesPerSecond = 15,
    this.defaultPositionWhenIdle,
    required this.homingDirection,
    Duration inFeedDuration = const Duration(seconds: 12),
    Duration outFeedDuration = const Duration(seconds: 12),
  })  : currentDirection = calculateBeginPosition(defaultPositionWhenIdle),
        super(
          layout: layout,
          position: position,
          seqNr: seqNr,
          initialState: TurnToFeedIn(),
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
    return direction.opposite == currentDirection.toCardinalDirection() &&
        direction.opposite == bestInFeedDirection && currentState is TurnToFeedIn;
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
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction == currentDirection.toCardinalDirection() &&
      moduleGroup != null && currentState is TurnToFeedOut;

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

  // @override
  // String toolTipText() => "$name\n"
  //     "${currentState.name}"
  //     "\n${currentState is DurationState ? '${(currentState as DurationState).remainingDuration} sec' : 'waiting'}"
  //     "\nrotation :$actualDirection"
  //     "${moduleGroup == null ? '' : '\n${moduleGroup!.numberOfModules} modules'}"
  //     "${moduleGroup == null ? '' : '\ndestination: ${(layout.cellForPosition(moduleGroup!.destination) as StateMachineCell).name}'}";

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
  CardinalDirection? get bestInFeedDirection {
    CardinalDirection? longestWaitingCasNeighbourOkToFeedOut =
        longestWaitingNeighbour(neighboursWaitingToFeedOutDurations,
            neighbourMustBeCASUnit: true);
    if (longestWaitingCasNeighbourOkToFeedOut != null) {
      return longestWaitingCasNeighbourOkToFeedOut.opposite;
    }

    CardinalDirection? longestWaitingCasNeighbourAlmostOkToFeedOut =
        longestWaitingNeighbour(neighboursAlmostWaitingToFeedOutDurations,
            neighbourMustBeCASUnit: true);
    if (longestWaitingCasNeighbourAlmostOkToFeedOut != null) {
      return longestWaitingCasNeighbourAlmostOkToFeedOut.opposite;
    }

    CardinalDirection? longestWaitingNeighbourOkToFeedOut =
        longestWaitingNeighbour(neighboursWaitingToFeedOutDurations);
    if (longestWaitingNeighbourOkToFeedOut != null) {
      return longestWaitingNeighbourOkToFeedOut.opposite;
    }

    CardinalDirection? longestWaitingNeighbourAlmostOkToFeedOut =
        longestWaitingNeighbour(neighboursAlmostWaitingToFeedOutDurations);
    if (longestWaitingNeighbourAlmostOkToFeedOut != null) {
      return longestWaitingNeighbourAlmostOkToFeedOut.opposite;
    }

    if (defaultPositionWhenIdle != null) {
      return defaultPositionWhenIdle!;
    }

    //stay where we are
    return null;
  }
}


class TurnToFeedIn extends State<ModuleRotatingConveyor> {
  @override
  void onUpdateToNextPointInTime(
      ModuleRotatingConveyor rotatingConveyor, Duration jump) {
    var bestInFeedDirection = rotatingConveyor.bestInFeedDirection;

    // if (rotatingConveyor.seqNr==1) {
    //   print('$bestInFeedDirection  ${rotatingConveyor.currentDirection.degrees}');
    // }



    if (bestInFeedDirection != null) {
      var currentDirection =
          rotatingConveyor.currentDirection.toCardinalDirection();
      if (currentDirection != bestInFeedDirection) {
        turn(rotatingConveyor, bestInFeedDirection, jump);
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
    int degreesToTurnThisJump =
        (rotatingConveyor.degreesPerSecond * jump.inMilliseconds / 1000)
            .round();
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
      return TurnToFeedOut();
    }
  }

  bool _transportCompleted(ModuleRotatingConveyor rotatingConveyor) =>
      rotatingConveyor.moduleGroup != null;
}

class TurnToFeedOut extends State<ModuleRotatingConveyor> {
  bool goToNextState = false;

  @override
  void onUpdateToNextPointInTime(
      ModuleRotatingConveyor rotatingConveyor, Duration jump) {
    goToNextState = false;
    var goToDirection = feedOutDirection(rotatingConveyor);
    if (goToDirection != null) {
      if (_doneTurning(rotatingConveyor, goToDirection)) {
        if (_neighbourOkToFeedIn(rotatingConveyor, goToDirection) &&
            !_moduleGroupIsAtDestination(rotatingConveyor)) {
          goToNextState = true;
        }
      } else {
        turn(rotatingConveyor, goToDirection, jump);
      }
    }
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (goToNextState) {
      return FeedOut();
    }
  }

  void turn(ModuleRotatingConveyor rotatingConveyor,
      CardinalDirection goToDirection, Duration jump) {
    int degreesToTurnThisJump =
        _degreesToTurnThisJump(rotatingConveyor, jump, goToDirection);

    rotatingConveyor.currentDirection =
        rotatingConveyor.currentDirection.rotate(degreesToTurnThisJump);
    rotatingConveyor.moduleGroup!.doorDirection = rotatingConveyor
        .moduleGroup!.doorDirection
        .rotate(degreesToTurnThisJump);
  }

  int _degreesToTurnThisJump(ModuleRotatingConveyor rotatingConveyor,
      Duration jump, CardinalDirection goToDirection) {
    int degreesToTurnThisJump =
        (rotatingConveyor.degreesPerSecond * jump.inMilliseconds / 1000)
            .round();
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

  bool _neighbourOkToFeedIn(ModuleRotatingConveyor rotatingConveyor,
      CardinalDirection goToDirection) {
    var layout = rotatingConveyor.layout;
    var neighbour = layout.neighbouringCell(rotatingConveyor, goToDirection);
    var okToFeedIn = neighbour.waitingToFeedIn(goToDirection.opposite);
    return okToFeedIn;
  }

  bool _doneTurning(ModuleRotatingConveyor rotatingConveyor,
          CardinalDirection goToDirection) =>
      rotatingConveyor.currentDirection.toCardinalDirection() == goToDirection;

  CardinalDirection? feedOutDirection(ModuleRotatingConveyor rotatingConveyor) {
    for (var direction in CardinalDirection.values) {
      var layout = rotatingConveyor.layout;
      var destination = rotatingConveyor.moduleGroup!.destination;
      var neighbour = layout.neighbouringCell(rotatingConveyor, direction);

      if (neighbour is StateMachineCell && destination is StateMachineCell) {
        var route = layout.findRoute(
          source: neighbour,
          destination: destination,
          routeSoFar: Route([rotatingConveyor]),
        );
        if (neighbour.isFeedIn(direction.opposite) && route != null) {
          return direction;
        }
      }
    }
    //no destination found: stay where we are
    return null;
  }

  bool _moduleGroupIsAtDestination(ModuleRotatingConveyor rotatingConveyor) =>
      rotatingConveyor.moduleGroup!.destination == rotatingConveyor;
}

class FeedOut extends State<ModuleRotatingConveyor> {
  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleRotatingConveyor rotatingConveyor) {
    transportedModuleGroup = rotatingConveyor.moduleGroup;
    var layout = rotatingConveyor.layout;
    var direction = rotatingConveyor.currentDirection.toCardinalDirection();
    var receivingNeighbour = layout.neighbouringCell(
        rotatingConveyor, direction!) as StateMachineCell;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: rotatingConveyor, destination: receivingNeighbour);
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (_transportCompleted(rotatingConveyor)) {
      return TurnToFeedIn();
    }
  }

  bool _transportCompleted(ModuleRotatingConveyor rotatingConveyor) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != rotatingConveyor;
}
