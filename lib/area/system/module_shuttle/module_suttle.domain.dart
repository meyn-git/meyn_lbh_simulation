// ignore_for_file: public_member_api_docs, sort_constructors_first, avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_shuttle/module_suttle.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.presentation.dart';
import 'package:user_command/user_command.dart';

class ModuleShuttle extends StateMachine implements LinkedSystem, Detailable {
  /// normally 2 or 3
  late final int nrOfPositions = betweenPositionsInMeters.length + 1;
  final LiveBirdHandlingArea area;
  final SpeedProfile conveyorSpeedProfile;
  late ModuleShuttleFrameShape shape = ModuleShuttleFrameShape(this);
  final SpeedProfile carrierSpeedProfile;
  final Duration unlockDuration;
  final Duration lockDuration;
  final Duration conveyorSimultaneousFeedInDelay;

  /// e.g. 7524 Florida
  /// pos0: CAS3 is at left position
  ///   in between 2.488m
  /// pos1: CAS1+2 is at middle position
  ///   in between 2.488m
  /// pos2: Infeedconveyor and destacker are at right position
  /// results in [2.488, 2.488]
  final List<double> betweenPositionsInMeters;
  late ModuleShuttleCarrier carrier = ModuleShuttleCarrier(this);
  late Map<ShuttleLinkLocation, Duration> neighborsWaitingToFeedOutDurations = {
    for (var linkLocation in linkLocations) linkLocation: Duration.zero,
  };
  Duration? durationPerStack;
  Durations durationsPerStack = Durations(maxSize: 20);

  ModuleShuttle({
    required this.area,
    required this.betweenPositionsInMeters,

    /// duration is from: 7524 Florida - Spain\2024-12-16 calculate capacity
    this.lockDuration = const Duration(seconds: 4),

    /// duration is from: 7524 Florida - Spain\2024-12-16 calculate capacity
    this.unlockDuration = const Duration(seconds: 4),
    // 7 sec based on 7524 Florida startup video
    // 4 sec based on 9423 Wech measured by ewon on 2025-01-22 by Roel
    this.conveyorSimultaneousFeedInDelay = const Duration(seconds: 7),
    this.conveyorSpeedProfile = const ShuttleConveyorSpeedProfile(),
    this.carrierSpeedProfile = const ShuttleCarrierSpeedProfile(),
  }) : super(initialState: OverrideNeighboringConveyorSpeeds()) {
    Future.delayed(const Duration(seconds: 2), () {
      area.systems.add(carrier);
    });
  }

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
    ...modulesIns.values,
    ...modulesOuts.values,
  ];

  late List<ShuttleLinkLocation> linkLocations = [
    for (int position = 0; position < nrOfPositions; position++)
      for (var side in ShuttleSide.values)
        ShuttleLinkLocation(position: position, side: side),
  ];

  late Map<ShuttleLinkLocation, ModuleGroupInLink> modulesIns = {
    for (var linkLocation in linkLocations)
      linkLocation: ModuleGroupInLink(
        place: modulePlaces[linkLocation.position],
        offsetFromCenterWhenFacingNorth:
            shape.linkLocationOffsets[linkLocation]!,
        directionToOtherLink: linkLocation.side.direction,
        transportDuration: (inLink) =>
            moduleTransportDuration(inLink, conveyorSpeedProfile),
        canFeedIn: () => _canFeedIn(linkLocation),
      ),
  };

  bool _canFeedIn(ShuttleLinkLocation linkLocation) =>
      _inCorrectPosition(linkLocation) && _isWaitingToFeedIn(linkLocation);

  bool _inCorrectPosition(ShuttleLinkLocation linkLocation) =>
      carrier.position is AtCarrierPosition &&
      (carrier.position as AtCarrierPosition).positionNumber ==
          linkLocation.position &&
      (carrier.position as AtCarrierPosition).positionNumber ==
          task?.location.position;

  bool _isWaitingToFeedIn(ShuttleLinkLocation linkLocation) {
    if (currentState is WaitToFeedIn) {
      return linkLocation.side == task?.location.side;
    }
    if (currentState is SimultaneousFeedOutFeedInModuleGroup) {
      return task?.location.side.opposite == linkLocation.side &&
          SimultaneousFeedOutFeedInModuleGroup.canFeedIn(currentState);
    }
    return false;
  }

  late Map<ShuttleLinkLocation, ModuleGroupOutLink> modulesOuts = {
    for (var linkLocation in linkLocations)
      linkLocation: ModuleGroupOutLink(
        place: modulePlaces[linkLocation.position],
        offsetFromCenterWhenFacingNorth:
            shape.linkLocationOffsets[linkLocation]!,
        directionToOtherLink: linkLocation.side.direction,
        durationUntilCanFeedOut: () =>
            _canFeedOut(linkLocation) ? Duration.zero : unknownDuration,
      ),
  };

  bool _canFeedOut(ShuttleLinkLocation linkLocation) =>
      currentState is WaitToFeedOut &&
      _inCorrectPosition(linkLocation) &&
      linkLocation.side == task?.location.side;

  late int seqNr = area.systems.seqNrOf(this);

  @override
  late String name = 'ModuleShuttle$seqNr';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late List<ModuleGroupPlace> modulePlaces = [
    for (int i = 0; i < nrOfPositions; i++)
      ModuleGroupPlace(
        system: this,
        offsetFromCenterWhenSystemFacingNorth: shape.moduleGroupCenters[i],
      ),
  ];

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendProperty(
        'speed',
        '${durationsPerStack.averagePerHour.toStringAsFixed(1)} stacks/hour',
      )
      .appendProperty('task', task);

  @override
  onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    updateNeighborWaitingDurations(jump);
    updateCarrierPosition(jump);
    updateDurationPerStack(jump);
  }

  void updateNeighborWaitingDurations(Duration jump) {
    for (var linkLocation in linkLocations) {
      if (_neighborCanFeedOut(linkLocation)) {
        neighborsWaitingToFeedOutDurations[linkLocation] =
            neighborsWaitingToFeedOutDurations[linkLocation]! + jump;
      } else {
        neighborsWaitingToFeedOutDurations[linkLocation] = Duration.zero;
      }
    }
  }

  bool _neighborCanFeedOut(ShuttleLinkLocation linkLocation) {
    var modulesIn = modulesIns[linkLocation];
    if (modulesIn == null) {
      return false;
    }
    var neighborOutLink = modulesIn.linkedTo;
    if (neighborOutLink == null) {
      return false;
    }
    if (neighborOutLink.system is ModuleCas) {
      return neighborOutLink.durationUntilCanFeedOut() <=
          (unlockDuration +
              carrier.transportDuration(linkLocation.position) +
              lockDuration);
    }
    var infeedConveyorOutLink = neighborOutLink;
    return _infeedConveyorCanFeedOut(infeedConveyorOutLink);
  }

  bool _infeedConveyorCanFeedOut(
    ModuleGroupOutLink<LinkedSystem> infeedConveyorOutLink,
  ) {
    if (infeedConveyorOutLink.durationUntilCanFeedOut() != Duration.zero) {
      return false;
    }
    var moduleGroup = infeedConveyorOutLink.place.moduleGroup;
    if (moduleGroup == null) {
      return false;
    }
    var destination = moduleGroup.destination;
    if (destination is! ModuleCas) {
      return false;
    }
    return _routeToCasIsEmpty(destination);
  }

  bool _routeToCasIsEmpty(ModuleCas cas) {
    return cas.moduleGroupPlace.moduleGroup == null;
  }

  //The task being executed
  ShuttleTask? task;

  ShuttleTask? get nextTask {
    if (carrier.position is! AtCarrierPosition) {
      return null;
    }
    var moduleGroup = carrier.moduleGroup;
    if (moduleGroup == null) {
      return _createFeedInTask();
    } else {
      return _createFeedOutTask(moduleGroup.destination);
    }
  }

  ShuttleTask? _createFeedInTask() {
    Duration longestDuration = Duration.zero;
    ShuttleLinkLocation? longestDurationLinkLocation;
    for (var linkLocation in linkLocations) {
      if (neighborsWaitingToFeedOutDurations[linkLocation]! > longestDuration) {
        longestDuration = neighborsWaitingToFeedOutDurations[linkLocation]!;
        longestDurationLinkLocation = linkLocation;
      }
    }
    if (longestDurationLinkLocation != null) {
      return ShuttleTask(
        goal: ShuttleTaskGoal.feedIn,
        location: longestDurationLinkLocation,
      );
    }
    return null;
  }

  ShuttleTask _createFeedOutTask(LinkedSystem destination) {
    for (var linkLocation in linkLocations) {
      var neighbor = modulesOuts[linkLocation]!.linkedTo?.system;
      if (neighbor is ModuleCas && neighbor == destination) {
        return ShuttleTask(
          goal: ShuttleTaskGoal.feedOut,
          location: linkLocation,
        );
      }
      if (isFeedOutConveyor(neighbor)) {
        return ShuttleTask(
          goal: ShuttleTaskGoal.feedOut,
          location: linkLocation,
        );
      }
    }
    throw Exception('Shuttle can not feed out');
  }

  bool isFeedOutConveyor(LinkedSystem? neighbor) =>
      neighbor != null && neighbor is! ModuleCas;

  void updateCarrierPosition(Duration jump) {
    if (carrier.position is TimeProcessor) {
      (carrier.position as TimeProcessor).onUpdateToNextPointInTime(jump);
    }
  }

  void updateDurationPerStack(Duration jump) {
    if (durationPerStack == null) {
      durationPerStack = Duration.zero;
    } else {
      durationPerStack = durationPerStack! + jump;
    }
  }
}

class OverrideNeighboringConveyorSpeeds extends State<ModuleShuttle> {
  @override
  final String name = 'OverrideNeighboringConveyorSpeeds';

  @override
  State<ModuleShuttle>? nextState(ModuleShuttle shuttle) {
    for (var inLink in shuttle.modulesIns.values) {
      if (inLink.linkedTo != null) {
        var neighbor = inLink.linkedTo!.system;
        if (neighbor is ModuleCas) {
          neighbor.conveyorSpeedProfile = shuttle.conveyorSpeedProfile;
        }
        if (neighbor is ModuleConveyor) {
          neighbor.conveyorSpeedProfile = shuttle.conveyorSpeedProfile;
        }
        if (neighbor is ModuleLoadingConveyor) {
          neighbor.conveyorSpeedProfile = shuttle.conveyorSpeedProfile;
        }
      }
    }
    return Decide();
  }
}

class ModuleShuttleCarrier implements Vehicle, LinkedSystem {
  final ModuleShuttle shuttle;

  /// Normally [AtCarrierPosition] or [BetweenCarrierPositions]
  @override
  late AreaPosition position;

  ModuleShuttleCarrier(this.shuttle) : position = AtCarrierPosition(shuttle, 0);

  @override
  late CompassDirection direction = shuttle.area.layout.rotationOf(shuttle);

  @override
  List<Command> get commands => [RemoveFromMonitorPanel(this)];

  /// The Carrier does not have a [ModuleGroupPlace]. It uses those of the [ModuleShuttle]
  @override
  List<ModuleGroupPlace> get moduleGroupPlaces => [];

  ModuleGroup? get moduleGroup => position is AtCarrierPosition
      ? shuttle
            .modulePlaces[(position as AtCarrierPosition).positionNumber]
            .moduleGroup
      : null;

  @override
  late int moduleGroupStartRotationInDegrees = direction.degrees;

  late int seqNr = shuttle.area.systems.seqNrOf(this);

  @override
  String get name => 'ModuleShuttleCarrier$seqNr';

  @override
  ObjectDetails get objectDetails =>
      ObjectDetails(name).appendProperty('position', position);

  @override
  final VehicleShape shape = ModuleShuttleCarrierShape();

  /// No links here because the position of this [Vehicle] is not linked to other [LinkedSystem]s.
  /// See [position]
  @override
  final List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [];

  late final speedProfile = shuttle.carrierSpeedProfile;

  @override
  SizeInMeters get sizeWhenFacingNorth => shape.size;

  Duration transportDuration(int destinationPosition) {
    if (shuttle.carrier.position is BetweenCarrierPositions) {
      return (shuttle.carrier.position as BetweenCarrierPositions).remaining;
    }
    int currentPosition =
        (shuttle.carrier.position as AtCarrierPosition).positionNumber;
    if (currentPosition == destinationPosition) {
      return Duration.zero;
    }
    var distanceInMeters = calculateDistanceInMeters(
      currentPosition,
      destinationPosition,
    );
    var duration = shuttle.carrier.speedProfile.durationOfDistance(
      distanceInMeters,
    );
    return duration;
  }

  double calculateDistanceInMeters(int currentPosition, int finalPosition) {
    var inverse = currentPosition > finalPosition;
    var start = inverse ? finalPosition : currentPosition;
    var end = inverse ? currentPosition : finalPosition;
    return shuttle.betweenPositionsInMeters
        .sublist(start, end)
        .reduce((a, b) => a + b);
  }
}

class Decide extends State<ModuleShuttle> {
  @override
  final String name = 'Decide';

  @override
  void onStart(ModuleShuttle shuttle) {
    shuttle.task = null;
  }

  @override
  State<ModuleShuttle>? nextState(ModuleShuttle shuttle) {
    var task = shuttle.nextTask;
    if (task == null) {
      return null;
    }
    shuttle.task = task;
    if (_carrierIsInPosition(shuttle)) {
      if (task.goal == ShuttleTaskGoal.feedIn) {
        return WaitToFeedIn();
      } else {
        return WaitToFeedOut();
      }
    } else {
      return Unlock(task);
    }
  }

  bool _carrierIsInPosition(ModuleShuttle shuttle) =>
      shuttle.carrier.position is AtCarrierPosition &&
      (shuttle.carrier.position as AtCarrierPosition).positionNumber ==
          shuttle.task?.location.position;
}

class ShuttleTask implements Detailable {
  final ShuttleTaskGoal goal;
  final ShuttleLinkLocation location;

  ShuttleTask({required this.goal, required this.location});

  bool get simultaneousFeedOutFeedIn => false;

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('goal', goal)
      .appendProperty('position', location.position)
      .appendProperty('side', location.side);

  @override
  String get name => 'ShuttleTask';
}

enum ShuttleTaskGoal {
  /// feed in onto shuttle
  feedIn,
  // feed out from shuttle
  feedOut,
}

enum ShuttleSide {
  a(CompassDirection.south()),
  b(CompassDirection.north());

  final CompassDirection direction;

  ShuttleSide get opposite =>
      this == ShuttleSide.a ? ShuttleSide.b : ShuttleSide.a;

  const ShuttleSide(this.direction);
}

class ShuttleLinkLocation {
  final int position;
  final ShuttleSide side;

  ShuttleLinkLocation({required this.position, required this.side});

  @override
  bool operator ==(Object other) =>
      other is ShuttleLinkLocation &&
      other.runtimeType == runtimeType &&
      other.position == position &&
      other.side == side;

  @override
  int get hashCode => Object.hash(position, side);
}

class Unlock extends DurationState<ModuleShuttle> {
  final ShuttleTask task;

  @override
  final String name = 'Unlock';

  Unlock(this.task)
    : super(
        durationFunction: (shuttle) => shuttle.unlockDuration,
        nextStateFunction: (_) => MoveCarrier(task),
      );
}

class MoveCarrier extends State<ModuleShuttle> implements Detailable {
  final ShuttleTask task;
  BetweenCarrierPositions? carrierPosition;

  MoveCarrier(this.task);

  @override
  void onStart(ModuleShuttle shuttle) {
    if (shuttle.carrier.position is! AtCarrierPosition) {
      throw Exception('Shuttle carrier is between positions');
    }
    var moduleGroup = shuttle.carrier.moduleGroup;
    carrierPosition = BetweenCarrierPositions(
      shuttle: shuttle,
      destinationPositionNumber: task.location.position,
    );
    shuttle.carrier.position = carrierPosition!;

    if (moduleGroup != null) {
      moduleGroup.position = BetweenModuleGroupPlaces(
        source: shuttle.modulePlaces[carrierPosition!.startPositionNumber],
        destination:
            shuttle.modulePlaces[carrierPosition!.destinationPositionNumber],
        duration: carrierPosition!.duration,
      );
    }
  }

  @override
  late String name = 'MoveCarrier';

  /// will be set by [BetweenCarrierPositions] when it is done
  bool completed = false;

  @override
  State<ModuleShuttle>? nextState(ModuleShuttle stateMachine) =>
      completed ? Lock(task) : null;

  @override
  void onCompleted(ModuleShuttle shuttle) {
    shuttle.carrier.position = AtCarrierPosition(
      shuttle,
      task.location.position,
    );
  }

  @override
  ObjectDetails get objectDetails => ObjectDetails(
    name,
  ).appendProperty('remaining', carrierPosition?.remaining);
}

class Lock extends DurationState<ModuleShuttle> {
  final ShuttleTask task;

  @override
  final String name = 'Lock';

  Lock(this.task)
    : super(
        durationFunction: (shuttle) => shuttle.lockDuration,
        nextStateFunction: (shuttle) => task.goal == ShuttleTaskGoal.feedIn
            ? WaitToFeedIn()
            : WaitToFeedOut(),
      );
}

class WaitToFeedIn extends State<ModuleShuttle>
    implements ModuleTransportStartedListener {
  @override
  final String name = 'WaitToFeedIn';

  bool transportStarted = false;

  WaitToFeedIn();

  @override
  State<ModuleShuttle>? nextState(ModuleShuttle shuttle) =>
      transportStarted ? FeedIn() : null;

  @override
  void onModuleTransportStarted(_) {
    transportStarted = true;
  }
}

class FeedIn extends State<ModuleShuttle>
    implements ModuleTransportCompletedListener {
  @override
  final String name = "FeedIn";

  bool transportCompleted = false;

  @override
  State<ModuleShuttle>? nextState(ModuleShuttle shuttle) =>
      transportCompleted ? Decide() : null;

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class WaitToFeedOut extends State<ModuleShuttle> {
  @override
  final String name = 'WaitToFeedOut';

  WaitToFeedOut();

  @override
  State<ModuleShuttle>? nextState(ModuleShuttle shuttle) {
    var shuttleOutLink = shuttle.modulesOuts[shuttle.task!.location]!;
    var shuttleInLink =
        shuttle.modulesIns[ShuttleLinkLocation(
          position: shuttle.task!.location.position,
          side: shuttle.task!.location.side.opposite,
        )]!;

    if (shuttleOutLink.linkedTo!.canFeedIn()) {
      if (shuttleInLink.linkedTo?.durationUntilCanFeedOut() == Duration.zero) {
        return SimultaneousFeedOutFeedInModuleGroup(
          modulesIn: shuttleInLink,
          modulesOut: shuttleOutLink,
          inFeedDelay: shuttle.conveyorSimultaneousFeedInDelay,
          stateWhenCompleted: Decide(),
        );
      }

      return FeedOut();
    }
    return null;
  }

  @override
  void onCompleted(ModuleShuttle shuttle) {
    if (_feedOutToExit(shuttle)) {
      if (!_firstStack(shuttle)) {
        shuttle.durationsPerStack.add(shuttle.durationPerStack);
      }
      shuttle.durationPerStack = Duration.zero;
    }
  }

  bool _firstStack(ModuleShuttle shuttle) =>
      shuttle.carrier.moduleGroup!.values.first.sequenceNumber == 1;

  bool _feedOutToExit(ModuleShuttle shuttle) =>
      shuttle.modulesOuts[shuttle.task!.location]!.linkedTo!.system
          is! ModuleCas;
}

class FeedOut extends State<ModuleShuttle>
    implements ModuleTransportCompletedListener {
  @override
  final String name = "FeedOut";

  bool transportCompleted = false;

  FeedOut();

  @override
  void onStart(ModuleShuttle shuttle) {
    var moduleGroup = shuttle.carrier.moduleGroup!;
    moduleGroup.position = BetweenModuleGroupPlaces.forModuleOutLink(
      shuttle.modulesOuts[shuttle.task!.location]!,
    );
  }

  @override
  State<ModuleShuttle>? nextState(ModuleShuttle shuttle) =>
      transportCompleted ? Decide() : null;

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

/// Position is relative to the [ModuleShuttle.shape.moduleGroupCenters]
abstract class CarrierPosition implements AreaPosition {}

/// Position is one of the [ModuleShuttle.shape.moduleGroupCenters]
class AtCarrierPosition implements CarrierPosition {
  final ModuleShuttle shuttle;

  /// 0=most west position when [ModuleShuttle] is pointing north
  /// 1= 1 position east of position 0
  /// 2= 2 positions east of position 0
  final int positionNumber;
  OffsetInMeters? _center;

  AtCarrierPosition(this.shuttle, this.positionNumber);

  @override
  OffsetInMeters center(SystemLayout layout) => _center ?? _calulateCenter();

  OffsetInMeters _calulateCenter() => shuttle.area.layout.positionOnSystem(
    shuttle,
    shuttle.shape.moduleGroupCenters[positionNumber],
  );
}

/// Position is between 2 [ModuleShuttle.shape.moduleGroupCenters]
class BetweenCarrierPositions implements CarrierPosition, TimeProcessor {
  /// 0=most west position when [ModuleShuttle] is pointing north
  /// 1= 1 position east of position 0
  /// 2= 2 positions east of position 0
  late int startPositionNumber;
  late OffsetInMeters startPosition;

  /// 0=most west position when [ModuleShuttle] is pointing north
  /// 1= 1 position east of position 0
  /// 2= 2 positions east of position 0
  late int destinationPositionNumber;
  late OffsetInMeters vector;

  late Duration duration;
  Duration elapsed = Duration.zero;
  final ModuleShuttle shuttle;

  BetweenCarrierPositions({
    required this.shuttle,
    required this.destinationPositionNumber,
  }) {
    startPositionNumber =
        (shuttle.carrier.position as AtCarrierPosition).positionNumber;
    startPosition = shuttle.area.layout.positionOnSystem(
      shuttle,
      shuttle.shape.moduleGroupCenters[startPositionNumber],
    );
    vector =
        shuttle.area.layout.positionOnSystem(
          shuttle,
          shuttle.shape.moduleGroupCenters[destinationPositionNumber],
        ) -
        startPosition;
    duration = shuttle.carrier.transportDuration(destinationPositionNumber);

    /// following for print only TODO remove later
    int currentPosition =
        (shuttle.carrier.position as AtCarrierPosition).positionNumber;
    var distanceInMeters = shuttle.carrier.calculateDistanceInMeters(
      currentPosition,
      destinationPositionNumber,
    );
    print(
      '** Shuttle: from: $currentPosition to: $destinationPositionNumber, distance:$distanceInMeters duration:$duration',
    );
  }

  Duration get remaining => duration - elapsed;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (elapsed < duration) {
      elapsed = elapsed + jump;
    } else {
      elapsed = duration;
      if (shuttle.currentState is MoveCarrier) {
        (shuttle.currentState as MoveCarrier).completed = true;
      }
    }
  }

  @override
  OffsetInMeters center(SystemLayout layout) =>
      startPosition +
      vector * (elapsed.inMilliseconds / duration.inMilliseconds);
}

class ShuttleConveyorSpeedProfile extends SpeedProfile {
  static const Duration startDelayFeedOutFeedIn = Duration(seconds: 7);

  static const _totalDistanceInMeters = ModuleConveyor.defaultLengthInMeters;
  static const _totalDurationInSeconds = 20;
  static const _accelerationInSeconds = 1.5;
  static const _decelerationInSeconds = 0.7;
  static const _maxSpeed =
      _totalDistanceInMeters /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const ShuttleConveyorSpeedProfile()
    : super(
        maxSpeed: _maxSpeed,
        acceleration: _maxSpeed / _accelerationInSeconds,
        deceleration: _maxSpeed / _decelerationInSeconds,
      );
}

///SpeedProfile.total(totalDistance: 2*2.488, totalDurationInSeconds: 16, accelerationInSeconds: 2, decelerationInSeconds: 2)
class ShuttleCarrierSpeedProfile extends SpeedProfile {
  static const Duration startDelayFeedOutFeedIn = Duration(seconds: 7);

  // 7524 Florida - Spain based on layout for 2 positions = 2*2.488m
  static const _totalDistanceInMeters = 2 * 2.488;
  // 7524 Florida - Spain based on start-up videofor 2 positions
  static const _totalDurationInSeconds = 16;
  // assumption
  static const _accelerationInSeconds = 2;
  // assumption
  static const _decelerationInSeconds = 2;
  static const _maxSpeed =
      _totalDistanceInMeters /
      (0.5 * _accelerationInSeconds +
          (_totalDurationInSeconds -
              _accelerationInSeconds -
              _decelerationInSeconds) +
          0.5 * _decelerationInSeconds);

  const ShuttleCarrierSpeedProfile()
    : super(
        maxSpeed: _maxSpeed,
        acceleration: _maxSpeed / _accelerationInSeconds,
        deceleration: _maxSpeed / _decelerationInSeconds,
      );
}
