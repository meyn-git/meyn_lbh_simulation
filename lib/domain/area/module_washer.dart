// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/state_machine.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_washer.dart';
import 'package:user_command/user_command.dart';

class ModuleWasherConveyor extends StateMachine implements PhysicalSystem {
  final Duration inFeedDuration;
  final Duration outFeedDuration;
  final Duration checkIfEmptyDuration;
  final double lengthInMeters;
  final LiveBirdHandlingArea area;
  static const double defaultLengthInMeters = 2.75;

  ModuleWasherConveyor({
    required this.area,
    this.checkIfEmptyDuration = const Duration(seconds: 18),
    Duration? inFeedDuration,
    Duration? outFeedDuration,
    this.lengthInMeters = defaultLengthInMeters,
  })  : inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration *
                (lengthInMeters / defaultLengthInMeters),
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        super(initialState: CheckIfEmpty());

  @override
  final String name = 'ModuleWasherConveyor';

  late final ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter,
  );

  late final modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleInLink,
    directionToOtherLink: const CompassDirection.south(),
    inFeedDuration: inFeedDuration,
    canFeedIn: () =>
        currentState is SimultaneousFeedOutFeedIn &&
        (currentState as SimultaneousFeedOutFeedIn).canFeedIn,
  );

  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleOutLink,
    directionToOtherLink: const CompassDirection.north(),
    outFeedDuration: outFeedDuration,
    durationUntilCanFeedOut: () => currentState is SimultaneousFeedOutFeedIn &&
            (currentState as SimultaneousFeedOutFeedIn).canFeedOut
        ? Duration.zero
        : unknownDuration,
  );

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn,
    modulesOut
  ];

  late final shape = ModuleWasherConveyorShape(this);

  bool get forceFeedOut => precedingNeighborWaitingToFeedOut(modulesIn);

  bool precedingNeighborWaitingToFeedOut(
      ModuleGroupInLink<PhysicalSystem> modulesIn) {
    var precedingNeighbor = modulesIn.linkedTo!.system;
    if (precedingNeighbor is ModuleWasherConveyor) {
      // recursive call
      return precedingNeighborWaitingToFeedOut(precedingNeighbor.modulesIn);
    } else {
      return modulesIn.linkedTo!.durationUntilCanFeedOut() == Duration.zero;
    }
  }

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  @override
  late final SizeInMeters sizeWhenFacingNorth = shape.size;
}

class CheckIfEmpty extends DurationState<ModuleWasherConveyor> {
  CheckIfEmpty()
      : super(
            durationFunction: (moduleWasher) =>
                moduleWasher.checkIfEmptyDuration,
            nextStateFunction: (moduleWasher) =>
                SimultaneousFeedOutFeedIn<ModuleWasherConveyor>(
                    modulesIn: moduleWasher.modulesIn,
                    modulesOut: moduleWasher.modulesOut,
                    stateWhenCompleted: Wash()));

  @override
  String get name => 'CheckIfEmpty';
}

class Wash extends State<ModuleWasherConveyor> {
  Duration? remainingDuration;

  @override
  final String name = "Wash";

  @override
  State<ModuleWasherConveyor>? nextState(ModuleWasherConveyor washer) =>
      feedOutAndFeedIn(washer)
          ? SimultaneousFeedOutFeedIn(
              modulesIn: washer.modulesIn,
              modulesOut: washer.modulesOut,
              stateWhenCompleted: Wash())
          : null;

  bool feedOutAndFeedIn(ModuleWasherConveyor stateMachine) =>
      remainingDuration == Duration.zero || stateMachine.forceFeedOut;

  @override
  void onUpdateToNextPointInTime(ModuleWasherConveyor washer, Duration jump) {
    remainingDuration ??= durationOfTwoModules(washer);
    if (remainingDuration! > Duration.zero) {
      remainingDuration = remainingDuration! - jump;
    } else {
      remainingDuration = Duration.zero;
    }
  }

  Duration durationOfTwoModules(ModuleWasherConveyor washer) {
    var productDefinition = washer.area.productDefinition;
    var averageProductsPerModuleGroup =
        productDefinition.averageProductsPerModuleGroup;
    var lineSpeedInShacklesPerHour =
        productDefinition.lineSpeedInShacklesPerHour;
    var modulesPerHour =
        lineSpeedInShacklesPerHour / averageProductsPerModuleGroup;
    return Duration(
        microseconds:
            (const Duration(hours: 1).inMicroseconds / modulesPerHour).round() *
                2);
  }
}

class SimultaneousFeedOutFeedIn<STATE_MACHINE extends StateMachine>
    extends State<STATE_MACHINE>
    implements
        ModuleTransportStartedListener,
        ModuleTransportCompletedListener {
  late final feedInStateMachine = FeedInStateMachine(this);
  late final feedOutStateMachine = FeedOutStateMachine(modulesOut);
  final ModuleGroupInLink modulesIn;
  final ModuleGroupOutLink modulesOut;
  final State<STATE_MACHINE> stateWhenCompleted;

  ModuleGroup? moduleGroupTransportedOut;

  SimultaneousFeedOutFeedIn({
    required this.modulesIn,
    required this.modulesOut,
    required this.stateWhenCompleted,
  });

  @override
  String get name => 'SimultaneousFeedOutFeedIn\n'
      '  in: ${feedInStateMachine.currentState.name}\n'
      '  out: ${feedOutStateMachine.currentState.name}\n';

  bool get completed =>
      feedInStateMachine.currentState is FeedInCompleted &&
      feedOutStateMachine.currentState is FeedOutCompleted;

  bool get canFeedIn => feedInStateMachine.currentState is WaitToFeedIn;

  bool get canFeedOut => feedOutStateMachine.currentState is WaitToFeedOut;

  bool get feedOutStarted => feedOutStateMachine.currentState is! WaitToFeedOut;

  @override
  void onStart(_) {
    var moduleGroup = modulesOut.place.moduleGroup;
    if (moduleGroup == null) {
      feedOutStateMachine.currentState = FeedOutCompleted();
    }
  }

  @override
  void onUpdateToNextPointInTime(STATE_MACHINE stateMachine, Duration jump) {
    feedInStateMachine.onUpdateToNextPointInTime(jump);
    feedOutStateMachine.onUpdateToNextPointInTime(jump);
  }

  @override
  State<STATE_MACHINE>? nextState(_) => completed ? stateWhenCompleted : null;

  @override
  void onModuleTransportStarted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    feedInStateMachine.onModuleTransportStarted(betweenModuleGroupPlaces);
    feedOutStateMachine.onModuleTransportStarted(betweenModuleGroupPlaces);
  }

  @override
  void onModuleTransportCompleted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    feedInStateMachine.onModuleTransportCompleted(betweenModuleGroupPlaces);
    feedOutStateMachine.onModuleTransportCompleted(betweenModuleGroupPlaces);
  }
}

class FeedInStateMachine extends StateMachine
    implements
        ModuleTransportStartedListener,
        ModuleTransportCompletedListener {
  final SimultaneousFeedOutFeedIn simultaneousFeedOutFeedIn;
  late final ModuleGroupInLink<PhysicalSystem> modulesIn =
      simultaneousFeedOutFeedIn.modulesIn;

  FeedInStateMachine(this.simultaneousFeedOutFeedIn)
      : super(initialState: WaitUntilFeedOutStarted());

  @override
  final String name = 'FeedInStateMachine';

  bool get feedOutStarted => simultaneousFeedOutFeedIn.feedOutStarted;

  @override
  void onModuleTransportStarted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    if (currentState is ModuleTransportStartedListener &&
        betweenModuleGroupPlaces.destination == modulesIn.place) {
      var listener = currentState as ModuleTransportStartedListener;
      listener.onModuleTransportStarted(betweenModuleGroupPlaces);
    }
  }

  @override
  void onModuleTransportCompleted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    if (currentState is ModuleTransportCompletedListener &&
        betweenModuleGroupPlaces.destination == modulesIn.place) {
      var listener = currentState as ModuleTransportCompletedListener;
      listener.onModuleTransportCompleted(betweenModuleGroupPlaces);
    }
  }
}

class WaitUntilFeedOutStarted extends State<FeedInStateMachine> {
  @override
  final String name = "WaitUntilFeedOutStarted";

  @override
  State<FeedInStateMachine>? nextState(FeedInStateMachine stateMachine) =>
      stateMachine.feedOutStarted ? WaitToFeedIn() : null;
}

class WaitToFeedIn extends State<FeedInStateMachine>
    implements ModuleTransportStartedListener {
  @override
  final String name = 'WaitToFeedIn';

  bool transportStarted = false;

  @override
  State<FeedInStateMachine>? nextState(FeedInStateMachine stateMachine) =>
      transportStarted ? FeedIn() : null;

  @override
  void onModuleTransportStarted(_) {
    transportStarted = true;
  }
}

class FeedIn extends State<FeedInStateMachine>
    implements ModuleTransportCompletedListener {
  @override
  final String name = "FeedIn";

  bool transportCompleted = false;

  @override
  State<FeedInStateMachine>? nextState(FeedInStateMachine stateMachine) =>
      transportCompleted ? FeedInCompleted() : null;

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class FeedInCompleted extends State<FeedInStateMachine> {
  @override
  final String name = "FeedInCompleted";

  /// Last state: never will return a next state
  @override
  State<FeedInStateMachine>? nextState(FeedInStateMachine stateMachine) => null;
}

class FeedOutStateMachine extends StateMachine
    implements
        ModuleTransportStartedListener,
        ModuleTransportCompletedListener {
  late final ModuleGroupOutLink<PhysicalSystem> modulesOut;

  FeedOutStateMachine(this.modulesOut) : super(initialState: WaitToFeedOut());

  @override
  final String name = 'FeedOutStateMachine';

  bool get nextNeighborWaitingToFeedIn => modulesOut.linkedTo!.canFeedIn();

  @override
  void onModuleTransportStarted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    if (currentState is ModuleTransportStartedListener &&
        betweenModuleGroupPlaces.destination == modulesOut.place) {
      var listener = currentState as ModuleTransportStartedListener;
      listener.onModuleTransportStarted(betweenModuleGroupPlaces);
    }
  }

  @override
  void onModuleTransportCompleted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    if (currentState is ModuleTransportCompletedListener &&
        betweenModuleGroupPlaces.destination == modulesOut.place) {
      var listener = currentState as ModuleTransportCompletedListener;
      listener.onModuleTransportCompleted(betweenModuleGroupPlaces);
    }
  }
}

class WaitToFeedOut extends State<FeedOutStateMachine> {
  @override
  final String name = 'WaitToFeedOut';

  @override
  State<FeedOutStateMachine>? nextState(FeedOutStateMachine stateMachine) =>
      stateMachine.nextNeighborWaitingToFeedIn ? FeedOut() : null;
}

class FeedOut extends State<FeedOutStateMachine>
    implements ModuleTransportCompletedListener {
  @override
  final String name = "FeedOut";

  bool transportCompleted = false;

  @override
  void onStart(FeedOutStateMachine stateMachine) {
    var moduleGroup = stateMachine.modulesOut.place.moduleGroup!;
    moduleGroup.position =
        BetweenModuleGroupPlaces.forModuleOutLink(stateMachine.modulesOut);
  }

  @override
  State<FeedOutStateMachine>? nextState(FeedOutStateMachine stateMachine) =>
      transportCompleted ? FeedOutCompleted() : null;

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class FeedOutCompleted extends State<FeedOutStateMachine> {
  @override
  final String name = "FeedOutCompleted";

  /// Last state: never will return a next state
  @override
  State<FeedOutStateMachine>? nextState(FeedOutStateMachine stateMachine) =>
      null;
}
