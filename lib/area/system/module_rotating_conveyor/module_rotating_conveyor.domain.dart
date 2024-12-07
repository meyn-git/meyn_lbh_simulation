// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.presentation.dart';
import 'package:user_command/user_command.dart';

import '../../area.domain.dart';
import '../../module/module.domain.dart';
import '../module_cas/module_cas.domain.dart';
import '../state_machine.domain.dart';

enum ModuleRotatingConveyorDiameter {
  short(2.75),
  beforeModuleCas(3.2),
  omnia(3.5),
  twoSingleColumnModules(3.6);

  final double inMeters;
  const ModuleRotatingConveyorDiameter(this.inMeters);
}

class ModuleRotatingConveyor extends StateMachine
    implements LinkedSystem, AdditionalRotation {
  final LiveBirdHandlingArea area;
  CompassDirection currentDirection = const CompassDirection.unknown();
  final SpeedProfile turnSpeedProfile;
  final SpeedProfile conveyorSpeedProfile;
  final TurnPosition? defaultFeedInTurnPosition;

  final ModuleRotatingConveyorDiameter diameter;

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
    SpeedProfile? turnSpeedProfile,
    SpeedProfile? conveyorSpeedProfile,
    this.defaultFeedInTurnPosition,
    required this.turnPositions,
    required this.diameter,
    State<ModuleRotatingConveyor>? initialState,
  })  : turnSpeedProfile = turnSpeedProfile ??
            area.productDefinition.speedProfiles.turnTableTurn,
        conveyorSpeedProfile = conveyorSpeedProfile ??
            area.productDefinition.speedProfiles.moduleConveyor

        ///TODO should be different for single stack or multiple stacks
        ,
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

  /// The higher the score, the more priority the neighbor
  /// should get to feed in to the [ModuleRotatingConveyor]
  /// A score 0= do not feed in from this position
  double _neighborFeedInScore(TurnPosition turnPosition) {
    var neighborModuleOutLink =
        modulesIns[turnPositionIndex(turnPosition)].linkedTo;
    if (neighborModuleOutLink == null) {
      return 0;
    }
    var neighborModuleGroup = neighborModuleOutLink.place.moduleGroup;
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
      var rotationDistance = degreesToRotate(feedInDirection);
      var durationToRotate =
          turnSpeedProfile.durationOfDistance(rotationDistance.toDouble());
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
      ModuleGroupOutLink<LinkedSystem> neighborModuleOutLink,
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
          place: moduleGroupPlace,
          offsetFromCenterWhenFacingNorth:
              shape.centerToModuleGroupLink(turnPosition.direction),
          directionToOtherLink: turnPosition.direction,
          transportDuration: (inLink) =>
              moduleTransportDuration(inLink, conveyorSpeedProfile),
          canFeedIn: () => canFeedIn(turnPosition)));
    }
    return inLinks;
  }

  List<ModuleGroupOutLink> _createModuleGroupOutLinks() {
    var outLinks = <ModuleGroupOutLink>[];
    for (var turnPosition in turnPositions) {
      outLinks.add(ModuleGroupOutLink(
          place: moduleGroupPlace,
          offsetFromCenterWhenFacingNorth:
              shape.centerToModuleGroupLink(turnPosition.direction),
          directionToOtherLink: turnPosition.direction,
          durationUntilCanFeedOut: () =>
              canFeedOut(turnPosition) ? Duration.zero : unknownDuration));
    }
    return outLinks;
  }

  late final List<ModuleGroupInLink> modulesIns = _createModuleGroupInLinks();

  late final List<ModuleGroupOutLink> modulesOuts =
      _createModuleGroupOutLinks();

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
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
    offsetFromCenterWhenSystemFacingNorth: OffsetInMeters.zero,
  );

  bool _linkedTo(LinkedSystem system) => modulesOuts
      .any((modulesOutLink) => modulesOutLink.linkedTo?.system == system);

  void initCurrentDirection() {
    if (currentDirection == const CompassDirection.unknown()) {
      currentDirection = startDirection;
    }
  }

  TurnPosition? findTurnPositionForDestination(LinkedSystem destination) {
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

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendProperty('currentDirection', currentDirection);

  bool _neighborModuleGroupAtDestination(
          ModuleGroupOutLink<LinkedSystem> neighborModuleOutLink,
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
  int rotationDistance = 0;

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
          .rotate((rotationDistance * completionFactor).round());
    }
  }

  void initRotation(
      ModuleRotatingConveyor rotatingConveyor, CompassDirection goToDirection) {
    conveyorStartDirection = rotatingConveyor.currentDirection;
    conveyorEndDirection = goToDirection;
    rotationDistance = rotatingConveyor.degreesToRotate(goToDirection);
    duration = rotatingConveyor.turnSpeedProfile
        .durationOfDistance(rotationDistance.toDouble());
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
  void onModuleTransportStarted(_) {
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
  void onModuleTransportCompleted(_) {
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
        .rotate((rotationDistance * completionFactor).round());
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
  void onModuleTransportCompleted(_) {
    completed = true;
  }
}
