// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module/module.dart';
import 'state_machine.dart';

abstract class ModuleBufferSystem extends StateMachine
    implements PhysicalSystem {
  final Duration inFeedDuration;
  final Duration outFeedDuration;
  final LiveBirdHandlingArea area;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  Shape get shape;

  ModuleBufferSystem({
    required this.area,
    Duration? feedInDuration,
    Duration? feedOutDuration,
  })  : inFeedDuration = feedInDuration ??
            area.productDefinition.speedProfiles.conveyorTransportDuration,
        outFeedDuration = feedOutDuration ??
            area.productDefinition.speedProfiles.conveyorTransportDuration,
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
    inFeedDuration: inFeedDuration,
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  @override
  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.topCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.north(),
    outFeedDuration: outFeedDuration,
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
    super.feedInDuration,
    super.feedOutDuration,
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
    super.feedInDuration,
    super.feedOutDuration,
    this.upDuration = const Duration(seconds: 4),
    this.downDuration = const Duration(seconds: 4),
    required this.moduleOutDirection,
  });
}

class ModuleBufferAngleTransferInFeed extends ModuleBufferAngleTransferSystem {
  @override
  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.bottomCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.south(),
    inFeedDuration: inFeedDuration,
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
    outFeedDuration: outFeedDuration,
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
      super.feedInDuration,
      super.feedOutDuration,
      super.upDuration,
      super.downDuration,
      required super.moduleOutDirection});
}

class ModuleBufferAngleTransferOutFeed extends ModuleBufferAngleTransferSystem {
  @override
  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.bottomCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.south(),
    inFeedDuration: inFeedDuration,
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
    outFeedDuration: outFeedDuration,
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
      super.feedInDuration,
      super.feedOutDuration,
      super.upDuration,
      super.downDuration,
      required super.moduleOutDirection});
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
