import 'package:flutter/material.dart' as material;
import 'package:meyn_lbh_simulation/state_machine_widgets/layout.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

import 'module.dart';
import 'module_cas.dart';

class ModuleRotatingConveyor extends StateMachineCell {
  CompassDirection actualDirection;
  final double degreesPerSecond;
  final CardinalDirection? defaultPositionWhenIdle;

  /// Note that you can note rotate more than 180 degrees left or right
  /// from the home position (in order to protect the cables)
  final CardinalDirection homingDirection;
  Map<CardinalDirection, Duration> neighboursAreAlmostOkToFeedOutDurations = {
    CardinalDirection.north: Duration.zero,
    CardinalDirection.east: Duration.zero,
    CardinalDirection.south: Duration.zero,
    CardinalDirection.west: Duration.zero,
  };
  Map<CardinalDirection, Duration> neighboursAreOkToFeedOutDurations = {
    CardinalDirection.north: Duration.zero,
    CardinalDirection.east: Duration.zero,
    CardinalDirection.south: Duration.zero,
    CardinalDirection.west: Duration.zero,
  };
  Map<CardinalDirection, Duration> neighboursAreOkToFeedInDurations = {
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
  })  : actualDirection = calculateBeginPosition(defaultPositionWhenIdle),
        super(
          layout: layout,
          position: position,
          seqNr: seqNr,
          initialState: TurnToFeedIn(),
          inFeedDuration: inFeedDuration,
          outFeedDuration: outFeedDuration,
        );

  processNextTimeFrame(Duration jump) {
    increaseNeighboursWaitingDurations(jump);
    super.processNextTimeFrame(jump);
  }

  @override
  bool almostOkToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) {
    var neighbour = layout.neighbouringCell(this, direction);
    if (neighbour is ModuleRotatingConveyor) {
      return true; // prevent endless loops between ModuleRotatingConveyor.isFeedIn and ModuleRotatingConveyor.isFeedOut
    }
    return neighbour.isFeedOut(direction.opposite);
  }

  @override
  bool okToFeedIn(CardinalDirection direction) {
    var neighbour = layout.neighbouringCell(this, direction);
    var neighbourOkToFeedOut = neighbour.okToFeedOut(direction.opposite);
    if (neighbourOkToFeedOut == false) {
      return false;
    }
    var moduleGroupToTransport = neighbour.moduleGroup;
    if (moduleGroupToTransport == null) {
      return false;
    } else {
      var destination =
          layout.cellForPosition(moduleGroupToTransport.destination)
              as StateMachineCell;
      return layout.findRoute(source: this, destination: destination) != null;
    }
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
  bool okToFeedOut(CardinalDirection direction) =>
      direction == actualDirection.toCardinalDirection() && moduleGroup != null;

  void increaseNeighboursWaitingDurations(Duration jump) {
    CardinalDirection.values.forEach((direction) {
      var neighbour = layout.neighbouringCell(this, direction);
      if (neighbour.almostOkToFeedOut(direction.opposite)) {
        neighboursAreAlmostOkToFeedOutDurations[direction] = noMoreThan1Hour(
            neighboursAreAlmostOkToFeedOutDurations[direction]! + jump);
      } else {
        neighboursAreAlmostOkToFeedOutDurations[direction] = Duration.zero;
      }
      if (neighbour.okToFeedOut(direction.opposite)) {
        neighboursAreOkToFeedOutDurations[direction] = noMoreThan1Hour(
            neighboursAreOkToFeedOutDurations[direction]! + jump);
      } else {
        neighboursAreOkToFeedOutDurations[direction] = Duration.zero;
      }
      if (neighbour.okToFeedIn(direction.opposite)) {
        neighboursAreOkToFeedInDurations[direction] = noMoreThan1Hour(
            neighboursAreOkToFeedInDurations[direction]! + jump);
      } else {
        neighboursAreOkToFeedInDurations[direction] = Duration.zero;
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

  @override
  String toolTipText() => "$name\n"
      "${currentState.name}"
      "\n${currentState is DurationState ? '${(currentState as DurationState).remainingSeconds} sec' : 'waiting'}"
      "\nrotation :$actualDirection"
      "${moduleGroup == null ? '' : '\n${moduleGroup!.numberOfModules} modules'}"
      "${moduleGroup == null ? '' : '\ndestination: ${(layout.cellForPosition(moduleGroup!.destination) as StateMachineCell).name}'}";

  Duration noMoreThan1Hour(Duration duration) {
    const max = const Duration(hours: 1);
    if (duration >= max) {
      return max;
    } else {
      return duration;
    }
  }

  @override
  material.Widget get widget => material.Tooltip(
        message: toolTipText(),
        child: material.RotationTransition(
          turns: material.AlwaysStoppedAnimation(actualDirection.degrees / 360),
          child: material.CustomPaint(painter: ModuleRotatingConveyorPainter()),
        ),
      );
}

class ModuleRotatingConveyorPainter extends material.CustomPainter {
  @override
  void paint(material.Canvas canvas, material.Size size) {
    drawRectangle(canvas, size);
    drawDirectionTriangle(size, canvas);
    drawCircle(canvas, size);
  }

  void drawDirectionTriangle(material.Size size, material.Canvas canvas) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.fill;
    var path = material.Path();
    path.moveTo(size.width * 0.45, size.height * 0.45);
    path.lineTo(size.width * 0.55, size.height * 0.45);
    path.lineTo(size.width * 0.50, size.height * 0.4);
    path.close();
    canvas.drawPath(path, paint);
  }

  material.Paint drawRectangle(material.Canvas canvas, material.Size size) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.stroke;
    canvas.drawRect(
        material.Rect.fromCenter(
            center: material.Offset(size.width / 2, size.height / 2),
            width: size.width * 0.4,
            height: size.width * 0.8),
        paint);
    return paint;
  }

  material.Paint drawCircle(material.Canvas canvas, material.Size size) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.stroke;
    canvas.drawCircle(
      material.Offset(size.width / 2, size.height / 2),
      size.height * 0.45,
      paint,
    );
    return paint;
  }

  @override
  bool shouldRepaint(covariant material.CustomPainter oldDelegate) => true;
}

class TurnToFeedIn extends State<ModuleRotatingConveyor> {
  @override
  State<StateMachineCell>? process(ModuleRotatingConveyor rotatingConveyor) {
    var goToDirection = feedInDirection(rotatingConveyor);
    if (goToDirection != null) {
      if (_doneTurning(rotatingConveyor, goToDirection)) {
        // Go to next state when neighbour is waiting to feed out
        if (rotatingConveyor.okToFeedIn(goToDirection)) {
          return FeedingIn();
        }
      } else {
        bool clockWise = _rotateClockWise(rotatingConveyor, goToDirection);
        turn1second(rotatingConveyor, clockWise);
      }
    }

    // todo: show degrees in statemachine (state.toString???)
  }

  void turn1second(ModuleRotatingConveyor rotatingConveyor, bool clockWise) {
    rotatingConveyor.actualDirection = rotatingConveyor.actualDirection.rotate(
        clockWise
            ? rotatingConveyor.degreesPerSecond
            : -rotatingConveyor.degreesPerSecond);
  }

  /// Determines if the turn table needs to turn clock wise our counter clock wise
  bool _rotateClockWise(ModuleRotatingConveyor rotatingConveyor,
      CardinalDirection goToDirection) {
    // TODO make sure the table does not rotate over stopper using: var stopperDirection = ModuleRotatingConveyor.homingPosition.opposite;
    // TODO make sure the feed out direction is correct depending neighbour: e.g. Cell.requiredDoorDirectionToFeedIn
    var actualDirection = rotatingConveyor.actualDirection;
    var clockWiseDistance = actualDirection
        .clockWiseDistanceInDegrees(goToDirection.toCompassDirection());
    var counterClockWiseDistance = actualDirection
        .counterClockWiseDistanceInDegrees(goToDirection.toCompassDirection());
    bool clockWise =
        clockWiseDistance < counterClockWiseDistance; //TODO stopperDirection
    return clockWise;
  }

  bool _doneTurning(ModuleRotatingConveyor rotatingConveyor,
          CardinalDirection goToDirection) =>
      rotatingConveyor.actualDirection.toCardinalDirection() == goToDirection;

  CardinalDirection? feedInDirection(ModuleRotatingConveyor rotatingConveyor) {
    CardinalDirection? longestWaitingCasNeighbourOkToFeedOut =
        rotatingConveyor.longestWaitingNeighbour(
            rotatingConveyor.neighboursAreOkToFeedOutDurations,
            neighbourMustBeCASUnit: true);
    if (longestWaitingCasNeighbourOkToFeedOut != null) {
      return longestWaitingCasNeighbourOkToFeedOut;
    }

    CardinalDirection? longestWaitingCasNeighbourAlmostOkToFeedOut =
        rotatingConveyor.longestWaitingNeighbour(
            rotatingConveyor.neighboursAreAlmostOkToFeedOutDurations,
            neighbourMustBeCASUnit: true);
    if (longestWaitingCasNeighbourAlmostOkToFeedOut != null) {
      return longestWaitingCasNeighbourAlmostOkToFeedOut;
    }

    CardinalDirection? longestWaitingNeighbourOkToFeedOut =
        rotatingConveyor.longestWaitingNeighbour(
            rotatingConveyor.neighboursAreOkToFeedOutDurations);
    if (longestWaitingNeighbourOkToFeedOut != null) {
      return longestWaitingNeighbourOkToFeedOut;
    }

    CardinalDirection? longestWaitingNeighbourAlmostOkToFeedOut =
        rotatingConveyor.longestWaitingNeighbour(
            rotatingConveyor.neighboursAreAlmostOkToFeedOutDurations);
    if (longestWaitingNeighbourAlmostOkToFeedOut != null) {
      return longestWaitingNeighbourAlmostOkToFeedOut;
    }

    if (rotatingConveyor.defaultPositionWhenIdle != null) {
      return rotatingConveyor.defaultPositionWhenIdle!;
    }

    //stay where we are
    return null;
  }
}

class FeedingIn extends DurationState<ModuleRotatingConveyor> {
  int nrOfModulesBeingTransported = 0;

  static ModuleGroup? moduleGroupToTransport;

  FeedingIn()
      : super(
          duration: (rotatingConveyor) => rotatingConveyor.inFeedDuration,
          onStart: (rotatingConveyor) {
            var direction =
                rotatingConveyor.actualDirection.toCardinalDirection();
            if (direction != null) {
              var inFeedNeighbouringCell = rotatingConveyor.layout
                      .neighbouringCell(rotatingConveyor, direction)
                  as StateMachineCell;
              moduleGroupToTransport = inFeedNeighbouringCell.moduleGroup!;
              //TODO moduleGroupToTransport.position=ModulePosition.betweenCells(source: inFeedNeighbouringCell, destination: rotatingConveyor);
            }
          },
          onCompleted: (rotatingConveyor) {
            moduleGroupToTransport!.position =
                ModulePosition.forCel(rotatingConveyor);

            /// TODO change to transition
          },
          nextState: (rotatingConveyor) => TurnToFeedOut(),
        );
}

class TurnToFeedOut extends State<ModuleRotatingConveyor> {
  @override
  State<StateMachineCell>? process(ModuleRotatingConveyor rotatingConveyor) {
    var goToDirection = feedOutDirection(rotatingConveyor);
    if (goToDirection != null) {
      if (_doneTurning(rotatingConveyor, goToDirection)) {
        // Go to next state when neighbour is waiting to feed in
        if (_neighbourOkToFeedIn(rotatingConveyor, goToDirection)) {
          return FeedingOut();
        }
      } else {
        bool clockWise = _rotateClockWise(rotatingConveyor, goToDirection);
        turn1second(rotatingConveyor, clockWise);
      }
    }
  }

  void turn1second(ModuleRotatingConveyor rotatingConveyor, bool clockWise) {
    //TODO use duration
    var rotation = clockWise
        ? rotatingConveyor.degreesPerSecond
        : -rotatingConveyor.degreesPerSecond;
    rotatingConveyor.actualDirection =
        rotatingConveyor.actualDirection.rotate(rotation);
    rotatingConveyor.moduleGroup!.doorDirection =
        rotatingConveyor.moduleGroup!.doorDirection.rotate(rotation);
  }

  /// Determines if the turn table needs to turn clock wise our counter clock wise
  bool _rotateClockWise(ModuleRotatingConveyor rotatingConveyor,
      CardinalDirection goToDirection) {
    // TODO make sure the rotatingConveyor does not rotate over stopper using: var stopperDirection = ModuleRotatingConveyor.homingPosition.opposite;
    // TODO make sure the feed out direction is correct depending neighbour: e.g. Cell.requiredDoorDirectionToFeedIn
    var actualDirection = rotatingConveyor.actualDirection;
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
    var okToFeedIn = neighbour.okToFeedIn(goToDirection.opposite);
    return okToFeedIn;
  }

  bool _doneTurning(ModuleRotatingConveyor rotatingConveyor,
          CardinalDirection goToDirection) =>
      rotatingConveyor.actualDirection.toCardinalDirection() == goToDirection;

  CardinalDirection? feedOutDirection(ModuleRotatingConveyor rotatingConveyor) {
    for (var direction in CardinalDirection.values) {
      var layout = rotatingConveyor.layout;
      var destination =
          layout.cellForPosition(rotatingConveyor.moduleGroup!.destination)
              as ActiveCell;
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
}

class FeedingOut extends DurationState<ModuleRotatingConveyor> {
  FeedingOut()
      : super(
            duration: (rotatingConveyor) => rotatingConveyor.outFeedDuration,
            nextState: (rotatingConveyor) => TurnToFeedIn());
}
