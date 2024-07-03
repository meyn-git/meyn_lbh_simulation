// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_rotating_conveyor.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_cas.dart';
import 'state_machine.dart';

class ModuleRotatingConveyor extends StateMachine
    implements PhysicalSystem, AdditionalRotation {
  final LiveBirdHandlingArea area;
  CompassDirection currentDirection = const CompassDirection.unknown();
  final int degreesPerSecond;
  final TurnPosition? defaultFeedInTurnPosition;
  final Duration inFeedDuration;
  final Duration outFeedDuration;

  /// [diameter]:
  /// * 2.75 meter = normally
  /// * 3.2 meter = in front of CAS units (because of CAS unit width)   OR IS IT 3m conveyor frame, 3.2 meter diameter???
  /// * 3.2 meter = for double 1/2 modules?
  final double lengthInMeters;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  /// for each [TurnPosition] the time the neighbor was ready to feed out
  Map<int, Duration> neighborsWaitingToFeedOutDurations = {};

  /// for each [TurnPosition] the time the neighbor was ready to feed in
  Map<int, Duration> neighborsWaitingToFeedInDurations = {};

  /// See [_verifyTurnPositions]
  final List<TurnPosition> turnPositions;

  late final ModuleRotatingConveyorShape shape =
      ModuleRotatingConveyorShape(this);

  ModuleRotatingConveyor({
    required this.area,
    int? degreesPerSecond,
    this.defaultFeedInTurnPosition,
    required this.turnPositions,
    required this.lengthInMeters,
    State<ModuleRotatingConveyor>? initialState,
    Duration? inFeedDuration,
    Duration? outFeedDuration,
  })  : degreesPerSecond = degreesPerSecond ??
            area.productDefinition.moduleSystem.turnTableDegreesPerSecond,
        inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        super(
          initialState: initialState ?? TurnToFeedIn(),
        ) {
    _verifyTurnPositions();
    _initWaitingDurations();
  }

  void _initWaitingDurations() {
    for (int i = 0; i < turnPositions.length; i++) {
      neighborsWaitingToFeedOutDurations[i] = Duration.zero;
      neighborsWaitingToFeedInDurations[i] = Duration.zero;
    }
  }

  @override
  onUpdateToNextPointInTime(Duration jump) {
    initCurrentDirection();
    _increaseNeighborsWaitingDurations(jump);
    super.onUpdateToNextPointInTime(jump);
  }

  bool canFeedIn(TurnPosition turnPosition) {
    if (currentState is! TurnToFeedIn ||
        (currentState as TurnToFeedIn).feedInStarted) {
      return false;
    }

    var best = bestFeedInTurnPosition;
    if (best == null || best != turnPosition) {
      return false;
    }

    var onFeedInPosition = currentDirection == best.feedInDirection;

    return onFeedInPosition;
  }

  bool canFeedOut(TurnPosition turnPosition) {
    if (currentState is FeedOut) {
      return true;
    }
    if (currentState is! TurnToFeedOut) {
      return false;
    }
    var best = bestOutFeedTurnPosition;
    if (best == null || best != turnPosition) {
      return false;
    }
    var onOutFeedPosition = currentDirection == best.feedOutDirection;
    return onOutFeedPosition;
  }

  void _increaseNeighborsWaitingDurations(Duration jump) {
    for (int i = 0; i < turnPositions.length; i++) {
      if (_neighborCanFeedOut(i)) {
        neighborsWaitingToFeedOutDurations[i] =
            _noMoreThan1Hour(neighborsWaitingToFeedOutDurations[i]! + jump);
      } else {
        neighborsWaitingToFeedOutDurations[i] = Duration.zero;
      }

      if (_neighborCanFeedIn(i)) {
        neighborsWaitingToFeedInDurations[i] =
            _noMoreThan1Hour(neighborsWaitingToFeedInDurations[i]! + jump);
      } else {
        neighborsWaitingToFeedInDurations[i] = Duration.zero;
      }
    }
  }

  bool _neighborCanFeedIn(int turnPositionIndex) {
    var neighborModuleGroupIn = modulesOuts[turnPositionIndex].linkedTo;
    return neighborModuleGroupIn != null && neighborModuleGroupIn.canFeedIn();
  }

  bool _neighborCanFeedOut(int turnPositionIndex) {
    var neighborModuleGroupOut = modulesIns[turnPositionIndex].linkedTo;
    return neighborModuleGroupOut != null &&
        neighborModuleGroupOut.durationUntilCanFeedOut() == Duration.zero;
  }

  // /// returns the [TurnPosition] index of the neighbor that
  // ///   was waiting the longest to feed out.
  // /// returns null when no neighbor cell are waiting (0 sec)
  // int? _turnPositionIndexOfLongestWaitingNeighbor(
  //     Map<int, Duration> neighborsWaitingDurations,
  //     {bool neighborMustBeCASUnit = false}) {
  //   Duration highestValue = Duration.zero;
  //   int? turnPosition;

  //   for (int i = 0; i < turnPositions.length; i++) {
  //     var duration = neighborsWaitingDurations[i]!;
  //     if ((!neighborMustBeCASUnit || links[i].linkedTo is ModuleCas) &&
  //         duration > Duration.zero &&
  //         duration > highestValue) {
  //       highestValue = duration;
  //       turnPosition = i;
  //     }
  //   }
  //   ;
  //   return turnPosition;
  // }

  CompassDirection get startDirection =>
      feedInDirection ?? firstFeedInDirection ?? const CompassDirection.north();

  CompassDirection? get firstFeedInDirection =>
      (feedInTurnPositionsOtherThanCas.isEmpty
          ? null
          : feedInTurnPositionsOtherThanCas.first.feedInDirection);

  Duration _noMoreThan1Hour(Duration duration) {
    const max = Duration(hours: 1);
    if (duration >= max) {
      return max;
    } else {
      return duration;
    }
  }

  /// The higher the score, whe more priority the neighbor
  /// should get priority to feed in to the [ModuleRotatingConveyor]
  /// A score 0= do not feed in from this position
  double _neighborFeedInScore(TurnPosition turnPosition) {
    var neighborModuleOutLink =
        modulesIns[turnPositionIndex(turnPosition)].linkedTo;
    if (neighborModuleOutLink == null) {
      return 0;
    }
    var neighborModuleGroup = neighborModuleOutLink.position.moduleGroup;
    if (neighborModuleGroup == null) {
      return 0;
    }
    if (_neighborModuleGroupAtDestination(
            neighborModuleOutLink, neighborModuleGroup) ||
        _neighborModuleNeedsToWaitUntilDestinationCasUnitOkToFeedIn(
            neighborModuleOutLink, neighborModuleGroup)) {
      return 0;
    }

    var index = turnPositionIndex(turnPosition);
    if (modulesIns[index].linkedTo == null) {
      return 0;
    }

    var durationUntilCanFeedOut =
        modulesIns[index].linkedTo!.durationUntilCanFeedOut();
    if (durationUntilCanFeedOut != Duration.zero) {
      var feedInDirection = turnPosition.feedInDirection;
      var rotation = degreesToRotate(feedInDirection);
      var durationToRotate = rotateDuration(rotation);
      if (durationToRotate < durationUntilCanFeedOut) {
        return 0;
      } else {
        var score = 1 -
            (durationUntilCanFeedOut.inMicroseconds /
                durationToRotate.inMicroseconds);
        return score;
      }
    }

    return neighborsWaitingToFeedOutDurations[index]!.inMilliseconds + 2;
  }

  /// returns the best direction to feed in from
  /// returns null when there is no outcome
  TurnPosition? get bestFeedInTurnPosition {
    var bestScore = 0.0;
    TurnPosition? bestTurnPosition;
    for (var turnPosition in turnPositions) {
      var score = _neighborFeedInScore(turnPosition);
      if (score > bestScore) {
        bestScore = score;
        bestTurnPosition = turnPosition;
      }
    }
    return bestTurnPosition;
  }

  CompassDirection? get feedInDirection {
    var best = bestFeedInTurnPosition;
    return best?.feedInDirection ??
        onlyFeedInTurnPositionOtherThanCas?.feedInDirection ??
        defaultFeedInTurnPosition?.feedInDirection;
  }

  late TurnPosition? onlyFeedInTurnPositionOtherThanCas =
      feedInTurnPositionsOtherThanCas.length == 1
          ? feedInTurnPositionsOtherThanCas.first
          : null;

  late Iterable<TurnPosition> feedInTurnPositionsOtherThanCas =
      turnPositions.where((turnPosition) =>
          modulesIns[turnPositionIndex(turnPosition)].linkedTo != null &&
          modulesIns[turnPositionIndex(turnPosition)].linkedTo!.system
              is! ModuleCas);

  TurnPosition? get bestOutFeedTurnPosition {
    var moduleGroup = moduleGroupPlace.moduleGroup;
    if (moduleGroupPlace.moduleGroup == null) {
      return null;
    }

    if (onlyOutFeedPosition != null) {
      return onlyOutFeedPosition;
    }

    var destination = moduleGroup!.destination;
    return findTurnPositionForDestination(destination);
  }

  CompassDirection? get feedOutDirection =>
      bestOutFeedTurnPosition?.feedOutDirection;

  late TurnPosition? onlyOutFeedPosition =
      outFeedPositions.length == 1 ? outFeedPositions.first : null;

  late Iterable<TurnPosition> outFeedPositions = turnPositions.where(
      (turnPosition) =>
          modulesOuts[turnPositionIndex(turnPosition)].linkedTo != null);

  int turnPositionIndex(TurnPosition turnPosition) =>
      turnPositions.indexOf(turnPosition);

  bool _neighborModuleNeedsToWaitUntilDestinationCasUnitOkToFeedIn(
      ModuleGroupOutLink<PhysicalSystem> neighborModuleOutLink,
      ModuleGroup neighborModuleGroup) {
    var destination = neighborModuleGroup.destination;
    if (destination is! ModuleCas) {
      return false;
    }

    if (!_linkedTo(destination)) {
      return false;
    }
    return !destination.modulesIn.canFeedIn();
  }

  List<ModuleGroupInLink> _createModuleGroupInLinks() {
    var inLinks = <ModuleGroupInLink>[];
    for (var turnPosition in turnPositions) {
      inLinks.add(ModuleGroupInLink(
          position: moduleGroupPlace,
          offsetFromCenterWhenFacingNorth:
              shape.centerToModuleGroupLink(turnPosition.direction),
          directionToOtherLink: turnPosition.direction,
          inFeedDuration: inFeedDuration,
          canFeedIn: () => canFeedIn(turnPosition)));
    }
    return inLinks;
  }

  List<ModuleGroupOutLink> _createModuleGroupOutLinks() {
    var outLinks = <ModuleGroupOutLink>[];
    for (var turnPosition in turnPositions) {
      outLinks.add(ModuleGroupOutLink(
          position: moduleGroupPlace,
          offsetFromCenterWhenFacingNorth:
              shape.centerToModuleGroupLink(turnPosition.direction),
          directionToOtherLink: turnPosition.direction,
          outFeedDuration: outFeedDuration,
          durationUntilCanFeedOut: () =>
              canFeedOut(turnPosition) ? Duration.zero : unknownDuration));
    }
    return outLinks;
  }

  late final List<ModuleGroupInLink> modulesIns = _createModuleGroupInLinks();

  late final List<ModuleGroupOutLink> modulesOuts =
      _createModuleGroupOutLinks();

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    ...modulesIns,
    ...modulesOuts
  ];

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late String name = 'ModuleRotatingConveyor$seqNr';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  @override
  CompassDirection get additionalRotation => currentDirection;

  void _verifyTurnPositions() {
    if (turnPositions.isEmpty) {
      throw ArgumentError(
          'must contain at least one turn position', 'turnPositions');
    }
    if (turnPositions.length > 4) {
      throw ArgumentError(
          'can not contain more then 4 turn positions', 'turnPositions');
    }
    for (var i = 0; i < turnPositions.length; i++) {
      var turnPosition = turnPositions[i];
      var others = [...turnPositions];
      others.removeAt(i);
      _verifyNoOverlappingTurnPosition(turnPosition, others);
    }
  }

  void _verifyNoOverlappingTurnPosition(
    TurnPosition turnPosition,
    List<TurnPosition> others,
  ) {
    const noOverlapInDegrees = 90;
    for (var other in others) {
      if (turnPosition.direction
                  .counterClockWiseDistanceInDegrees(other.direction) <
              noOverlapInDegrees * 0.5 ||
          turnPosition.direction.clockWiseDistanceInDegrees(other.direction) <
              noOverlapInDegrees * 0.5) {
        throw ArgumentError(
            'directions must be $noOverlapInDegrees degrees apart',
            'turnPositions');
      }
    }
  }

  late final ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    moduleGroups: area.moduleGroups,
    offsetFromCenterWhenSystemFacingNorth: OffsetInMeters.zero,
  );

  bool _linkedTo(PhysicalSystem system) => modulesOuts
      .any((modulesOutLink) => modulesOutLink.linkedTo?.system == system);

  void initCurrentDirection() {
    if (currentDirection == const CompassDirection.unknown()) {
      currentDirection = startDirection;
    }
  }

  TurnPosition? findTurnPositionForDestination(PhysicalSystem destination) {
    for (int i = 0; i < turnPositions.length; i++) {
      var moduleGroupOutLink = modulesOuts[i];
      var route = moduleGroupOutLink.findRoute(destination: destination);
      if (route != null) {
        /// found a valid route for the [ModuleGroup.destination]
        return turnPositions[i];
      }
    }
    return null;
  }

  int degreesToRotate(CompassDirection goToDirection) {
    var clockWiseDistance =
        currentDirection.clockWiseDistanceInDegrees(goToDirection);
    var counterClockWiseDistance =
        currentDirection.counterClockWiseDistanceInDegrees(goToDirection);
    bool clockWise =
        clockWiseDistance < counterClockWiseDistance; //TODO stopperDirection
    return clockWise ? clockWiseDistance : -counterClockWiseDistance;
  }

  Duration rotateDuration(int degreesToRotate) => Duration(
      microseconds:
          (degreesToRotate.abs() / degreesPerSecond * 1000000).round());

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState.name)
      .appendProperty('currentDirection', currentDirection)
      .appendProperty('moduleGroup', area.moduleGroups.at(moduleGroupPlace));

  bool _neighborModuleGroupAtDestination(
          ModuleGroupOutLink<PhysicalSystem> neighborModuleOutLink,
          ModuleGroup neighborModuleGroup) =>
      neighborModuleOutLink.system == neighborModuleGroup.destination;
}

class TurnPosition {
  final CompassDirection direction;

  /// feeds in a [ModuleGroup] in reverse, direction = direction + 180 degrees
  final bool reverseFeedIn;

  /// feeds out a [ModuleGroup] in reverse, direction = direction + 180 degrees
  final bool reverseFeedOut;

  TurnPosition({
    required this.direction,

    /// oppositeInFeed = false by default (= will use opposite direction)
    this.reverseFeedIn = false,
    this.reverseFeedOut = false,
  });

  CompassDirection get feedInDirection =>
      reverseFeedIn ? direction : direction.opposite;
  CompassDirection get feedOutDirection =>
      reverseFeedOut ? direction.opposite : direction;
}

abstract class TurnState extends State<ModuleRotatingConveyor> {
  CompassDirection conveyorStartDirection = const CompassDirection.north();
  CompassDirection? conveyorEndDirection;
  Duration duration = Duration.zero;
  Duration elapsed = Duration.zero;
  int degreesToRotate = 0;

  double get completionFactor => duration == Duration.zero
      ? 0
      : elapsed.inMicroseconds / duration.inMicroseconds;

  void turn(
    ModuleRotatingConveyor rotatingConveyor,
    CompassDirection? goToDirection,
    Duration jump,
  ) {
    if (goToDirection != null) {
      if (conveyorEndDirection != goToDirection) {
        initRotation(rotatingConveyor, goToDirection);
      }
      if (elapsed < duration) {
        elapsed += jump;
      } else {
        elapsed = duration;
      }
      rotatingConveyor.currentDirection = conveyorStartDirection
          .rotate((degreesToRotate * completionFactor).round());
    }
  }

  void initRotation(
      ModuleRotatingConveyor rotatingConveyor, CompassDirection goToDirection) {
    conveyorStartDirection = rotatingConveyor.currentDirection;
    conveyorEndDirection = goToDirection;
    degreesToRotate = rotatingConveyor.degreesToRotate(goToDirection);
    duration = rotatingConveyor.rotateDuration(degreesToRotate);
    elapsed = Duration.zero;
  }
}

class TurnToFeedIn extends TurnState implements ModuleTransportStartedListener {
  bool feedInStarted = false;
  @override
  String get name => 'TurnToFeedIn';

  @override
  void onUpdateToNextPointInTime(
      ModuleRotatingConveyor rotatingConveyor, Duration jump) {
    if (!feedInStarted) {
      // this prevents turning while committed to feeding in
      var goToDirection = rotatingConveyor.feedInDirection;
      turn(rotatingConveyor, goToDirection, jump);
    }
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (feedInStarted) {
      return FeedIn();
    }
    return null;
  }

  bool startFeedIn(ModuleRotatingConveyor rotatingConveyor) {
    var best = rotatingConveyor.bestFeedInTurnPosition;
    if (best == null) {
      // unknown where to feed in from
      return false;
    }
    var onFeedInPosition =
        rotatingConveyor.currentDirection == best.feedInDirection;
    var index = rotatingConveyor.turnPositionIndex(best);
    var neighborCanFeedOut = rotatingConveyor.modulesIns[index].linkedTo!
            .durationUntilCanFeedOut() ==
        Duration.zero;
    return onFeedInPosition && neighborCanFeedOut;
  }

  @override
  void onModuleTransportStarted() {
    feedInStarted = true;
  }
}

class FeedIn extends State<ModuleRotatingConveyor>
    implements ModuleTransportCompletedListener {
  bool completed = false;

  @override
  String get name => 'FeedIn';
  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (completed) {
      return TurnToFeedOut();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted() {
    completed = true;
  }
}

class TurnToFeedOut extends TurnState {
  late ModuleGroup moduleGroup;
  late CompassDirection moduleGroupStartDirection;

  @override
  String get name => 'TurnToFeedOut';

  @override
  void onUpdateToNextPointInTime(
      ModuleRotatingConveyor rotatingConveyor, Duration jump) {
    var goToDirection = rotatingConveyor.feedOutDirection;
    turn(rotatingConveyor, goToDirection, jump);
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (startFeedOut(rotatingConveyor)) {
      return FeedOut();
    }
    return null;
  }

  bool startFeedOut(ModuleRotatingConveyor rotatingConveyor) {
    var best = rotatingConveyor.bestOutFeedTurnPosition;
    if (best == null) {
      // unknown where to feed out to
      return false;
    }
    var onOutFeedPosition =
        rotatingConveyor.currentDirection == best.feedOutDirection;
    var index = rotatingConveyor.turnPositionIndex(best);
    var neighborCanFeedIn =
        rotatingConveyor.modulesOuts[index].linkedTo!.canFeedIn();
    return onOutFeedPosition && neighborCanFeedIn;
  }

  @override
  void initRotation(
      ModuleRotatingConveyor rotatingConveyor, CompassDirection goToDirection) {
    super.initRotation(rotatingConveyor, goToDirection);
    initModuleGroupRotation(rotatingConveyor);
  }

  void initModuleGroupRotation(ModuleRotatingConveyor rotatingConveyor) {
    moduleGroup = rotatingConveyor.moduleGroupPlace.moduleGroup!;
    moduleGroupStartDirection = moduleGroup.direction;
  }

  @override
  void turn(
    ModuleRotatingConveyor rotatingConveyor,
    CompassDirection? goToDirection,
    Duration jump,
  ) {
    if (goToDirection != null) {
      super.turn(rotatingConveyor, goToDirection, jump);
      turnModuleGroup();
    }
  }

  void turnModuleGroup() {
    moduleGroup.direction = moduleGroupStartDirection
        .rotate((degreesToRotate * completionFactor).round());
  }
}

class FeedOut extends State<ModuleRotatingConveyor>
    implements ModuleTransportCompletedListener {
  bool completed = false;

  @override
  String get name => 'FeedOut';
  @override
  void onStart(ModuleRotatingConveyor rotatingConveyor) {
    var moduleGroup = rotatingConveyor.moduleGroupPlace.moduleGroup!;
    var index = rotatingConveyor.turnPositions
        .indexOf(rotatingConveyor.bestOutFeedTurnPosition!);
    var moduleOut = rotatingConveyor.modulesOuts[index];
    moduleGroup.position = BetweenModuleGroupPlaces.forModuleOutLink(moduleOut);
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      ModuleRotatingConveyor rotatingConveyor) {
    if (completed) {
      return TurnToFeedIn();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted() {
    completed = true;
  }
}
