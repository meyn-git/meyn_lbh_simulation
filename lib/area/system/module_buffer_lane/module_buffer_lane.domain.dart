// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:user_command/user_command.dart';

import '../../area.domain.dart';
import '../../module/module.domain.dart';
import '../state_machine.domain.dart';

abstract class ModuleBufferSystem extends StateMachine
    implements PhysicalSystem {
  final LiveBirdHandlingArea area;
  final SpeedProfile conveyorSpeedProfile;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  Shape get shape;

  ModuleBufferSystem({
    required this.area,
    SpeedProfile? conveyorSpeedProfile,
  })  : conveyorSpeedProfile = conveyorSpeedProfile ??
            area.productDefinition.speedProfiles.moduleConveyor,
        super(
          initialState: WaitToFeedIn(),
        );

  ModuleGroupInLink get modulesIn;

  ModuleGroupOutLink get modulesOut;

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn,
    modulesOut
  ];

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late final ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: OffsetInMeters.zero,
  );

  Map<Type, State<ModuleBufferSystem> Function()> get nextState;
}

class ModuleBufferConveyor extends ModuleBufferSystem {
  @override
  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.bottomCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  @override
  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.topCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.north(),
    durationUntilCanFeedOut: () =>
        currentState is WaitToFeedOut ? Duration.zero : unknownDuration,
  );

  @override
  String get name => 'ModuleBufferConveyor$seqNr';

  @override
  final Map<Type, State<ModuleBufferSystem> Function()> nextState = {
    WaitToFeedIn: () => FeedIn(),
    FeedIn: () => WaitToFeedOut(),
    WaitToFeedOut: () => FeedOut(),
    FeedOut: () => WaitToFeedIn()
  };

  ModuleBufferConveyor({
    required super.area,
    super.conveyorSpeedProfile,
  });

  @override
  late final Shape shape = Box(
      xInMeters:
          area.productDefinition.truckRows.first.footprintOnSystem.yInMeters +
              0.27,
      yInMeters:
          area.productDefinition.truckRows.first.footprintOnSystem.xInMeters +
              0.2);
}

abstract class ModuleBufferAngleTransferSystem extends ModuleBufferSystem {
  final Direction moduleOutDirection;
  final Duration upDuration;
  final Duration downDuration;

  ModuleBufferAngleTransferSystem({
    required super.area,
    super.conveyorSpeedProfile,
    this.upDuration = const Duration(seconds: 4),
    this.downDuration = const Duration(seconds: 4),
    required this.moduleOutDirection,
  });
}

class ModuleBufferAngleTransferInFeed extends ModuleBufferAngleTransferSystem
    implements ModuleLoadingConveyorInterface {
  @override
  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.bottomCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  @override
  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth:
        (moduleOutDirection == Direction.counterClockWise
                ? shape.centerLeft
                : shape.centerRight) -
            shape.centerCenter,
    directionToOtherLink: moduleOutDirection == Direction.counterClockWise
        ? const CompassDirection.west()
        : const CompassDirection.east(),
    durationUntilCanFeedOut: () =>
        currentState is WaitToFeedOut ? Duration.zero : unknownDuration,
  );

  @override
  String get name => 'ModuleBufferAngleTransferInFeed$seqNr';

  @override
  late final Shape shape = Box(
      xInMeters:
          area.productDefinition.truckRows.first.footprintOnSystem.xInMeters +
              0.2,
      yInMeters:
          area.productDefinition.truckRows.first.footprintOnSystem.yInMeters +
              0.27);

  ///TODO add frame left or right based on [moduleOutDirection]

  @override
  final Map<Type, State<ModuleBufferSystem> Function()> nextState = {
    WaitToFeedIn: () => FeedIn(),
    FeedIn: () => Down(),
    Down: () => WaitToFeedOut(),
    WaitToFeedOut: () => FeedOut(),
    FeedOut: () => Up(),
    Up: () => WaitToFeedIn(),
  };

  ModuleBufferAngleTransferInFeed(
      {required super.area,
      super.conveyorSpeedProfile,
      super.upDuration,
      super.downDuration,
      required super.moduleOutDirection});

  @override
  void moduleGroupFreeFromForkLiftTruck() {
    currentState = nextState[FeedIn]!();
    currentState.onStart(this);
  }
}

class ModuleBufferAngleTransferOutFeed extends ModuleBufferAngleTransferSystem
    implements ModuleUnLoadingConveyorInterface {
  @override
  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.bottomCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  @override
  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth:
        (moduleOutDirection == Direction.counterClockWise
                ? shape.centerLeft
                : shape.centerRight) -
            shape.centerCenter,
    directionToOtherLink: moduleOutDirection == Direction.counterClockWise
        ? const CompassDirection.west()
        : const CompassDirection.east(),
    durationUntilCanFeedOut: () =>
        currentState is WaitToFeedOut ? Duration.zero : unknownDuration,
  );

  @override
  String get name => 'ModuleBufferAngleTransferOutFeed$seqNr';

  @override
  late final Shape shape = Box(
      xInMeters:
          area.productDefinition.truckRows.first.footprintOnSystem.yInMeters +
              0.27,
      yInMeters:
          area.productDefinition.truckRows.first.footprintOnSystem.xInMeters +
              0.2);

  ///TODO add frame left or right based on [moduleOutDirection]

  @override
  final Map<Type, State<ModuleBufferSystem> Function()> nextState = {
    WaitToFeedIn: () => FeedIn(),
    FeedIn: () => Up(),
    Up: () => WaitToFeedOut(),
    WaitToFeedOut: () => FeedOut(),
    FeedOut: () => Down(),
    Down: () => WaitToFeedIn(),
  };

  ModuleBufferAngleTransferOutFeed(
      {required super.area,
      super.conveyorSpeedProfile,
      super.upDuration,
      super.downDuration,
      required super.moduleOutDirection});

  @override
  void moduleGroupFreeFromForkLiftTruck() {
    currentState = nextState[FeedOut]!();
    currentState.onStart(this);
  }
}

class WaitToFeedIn extends State<ModuleBufferSystem>
    implements ModuleTransportStartedListener {
  var transportStarted = false;

  @override
  String get name => 'WaitToFeedIn';

  @override
  State<ModuleBufferSystem>? nextState(ModuleBufferSystem system) {
    if (transportStarted) {
      return system.nextState[WaitToFeedIn]!();
    }
    return null;
  }

  @override
  void onModuleTransportStarted(_) {
    transportStarted = true;
  }
}

class FeedIn extends State<ModuleBufferSystem>
    implements ModuleTransportCompletedListener {
  @override
  String get name => 'FeedIn';
  bool transportCompleted = false;

  @override
  State<ModuleBufferSystem>? nextState(ModuleBufferSystem system) {
    if (transportCompleted) {
      return system.nextState[FeedIn]!();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class WaitToFeedOut extends State<ModuleBufferSystem> {
  @override
  String get name => 'WaitToFeedOut';

  @override
  State<ModuleBufferSystem>? nextState(ModuleBufferSystem system) {
    if (neighborCanFeedIn(system) && !_moduleGroupAtDestination(system)) {
      return system.nextState[WaitToFeedOut]!();
    }
    return null;
  }

  bool neighborCanFeedIn(ModuleBufferSystem conveyor) =>
      conveyor.modulesOut.linkedTo!.canFeedIn();

  bool _moduleGroupAtDestination(ModuleBufferSystem conveyor) =>
      conveyor.moduleGroupPlace.moduleGroup!.destination == conveyor;
}

class FeedOut extends State<ModuleBufferSystem>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOut';

  @override
  void onStart(ModuleBufferSystem system) {
    var transportedModuleGroup = system.moduleGroupPlace.moduleGroup!;
    transportedModuleGroup.position =
        BetweenModuleGroupPlaces.forModuleOutLink(system.modulesOut);
  }

  @override
  State<ModuleBufferSystem>? nextState(ModuleBufferSystem system) {
    if (transportCompleted) {
      return system.nextState[FeedOut]!();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class Up extends DurationState<ModuleBufferSystem> {
  Up()
      : super(
            durationFunction: (system) =>
                (system as ModuleBufferAngleTransferSystem).upDuration,
            nextStateFunction: (system) => system.nextState[Up]!());

  @override
  String get name => 'Up';
}

class Down extends DurationState<ModuleBufferSystem> {
  Down()
      : super(
            durationFunction: (system) =>
                (system as ModuleBufferAngleTransferSystem).downDuration,
            nextStateFunction: (system) => system.nextState[Down]!());

  @override
  String get name => 'Down';
}
