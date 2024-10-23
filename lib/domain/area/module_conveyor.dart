// ignore_for_file: avoid_renaming_method_parameters

import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/domain/area/speed_profile.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_conveyor.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module/module.dart';
import 'state_machine.dart';

class ModuleConveyor extends StateMachine implements PhysicalSystem {
  final double lengthInMeters;
  final SpeedProfile speedProfile;
  final LiveBirdHandlingArea area;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  late final ModuleConveyorShape shape = ModuleConveyorShape(this);

  static const double defaultLengthInMeters = 2.75;

  ModuleConveyor({
    required this.area,
    SpeedProfile? speedProfile,
    this.lengthInMeters = defaultLengthInMeters,
  })  : speedProfile = speedProfile ??
            area.productDefinition.speedProfiles.moduleConveyorWithoutStopper,
        super(
          initialState: CheckIfEmpty(),
        );

  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleInLink,
    directionToOtherLink: const CompassDirection.south(),
    feedInDuration: Duration.zero
    //TODO See BetweenModuleGroupPlaces.calculateDuration
    ,
    speedProfile: speedProfile,
    canFeedIn: () =>
        SimultaneousFeedOutFeedInModuleGroup.canFeedIn(currentState),
  );

  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleOutLink,
    directionToOtherLink: const CompassDirection.north(),
    feedOutDuration: Duration.zero
    //See BetweenModuleGroupPlaces.calculateDuration
    ,
    durationUntilCanFeedOut: () =>
        SimultaneousFeedOutFeedInModuleGroup.durationUntilCanFeedOut(
            currentState),
  );

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn,
    modulesOut
  ];

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late String name = 'ModuleConveyor$seqNr';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late final ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorEnd,
  );
}

class CheckIfEmpty extends DurationState<ModuleConveyor> {
  CheckIfEmpty()
      : super(
            durationFunction: (moduleConveyor) => moduleConveyor.speedProfile
                .durationOfDistance(moduleConveyor.lengthInMeters * 1.5),
            nextStateFunction: (moduleConveyor) =>
                SimultaneousFeedOutFeedInModuleGroup(
                    modulesIn: moduleConveyor.modulesIn,
                    modulesOut: moduleConveyor.modulesOut,
                    stateWhenCompleted: DoAgain()));

  @override
  String get name => 'CheckIfEmpty';
}

class DoAgain extends State<ModuleConveyor> {
  @override
  String get name => 'DoAgain';

  @override
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) =>
      SimultaneousFeedOutFeedInModuleGroup(
          modulesIn: moduleConveyor.modulesIn,
          modulesOut: moduleConveyor.modulesOut,
          stateWhenCompleted: this);
}

class SimultaneousFeedOutFeedInModuleGroup<STATE_MACHINE extends StateMachine>
    extends State<STATE_MACHINE>
    implements
        ModuleTransportStartedListener,
        ModuleTransportCompletedListener,
        Detailable {
  late final feedInStateMachine = FeedInStateMachine(this);
  late final feedOutStateMachine = FeedOutStateMachine(this);
  final ModuleGroupInLink modulesIn;
  final ModuleGroupOutLink modulesOut;
  final NextStateCondition nextStateCondition;
  final State<STATE_MACHINE> stateWhenCompleted;

  ModuleGroup? moduleGroupTransportedOut;

  final Duration inFeedDelay;

  SimultaneousFeedOutFeedInModuleGroup({
    required this.modulesIn,
    required this.modulesOut,
    required this.stateWhenCompleted,
    this.nextStateCondition =
        NextStateCondition.whenFeedInIsCompletedAndFeedOutIsCompleted,
    this.inFeedDelay = const Duration(seconds: 3),
  });

  @override
  String get name => 'SimultaneousFeedOutFeedInModuleGroup';

  bool get completed =>
      feedInStateMachine.currentState is FeedInCompleted &&
      (nextStateCondition ==
                  NextStateCondition.whenFeedInIsCompletedAndFeedOutIsStarted &&
              (feedOutStateMachine.currentState is FeedOut ||
                  feedOutStateMachine.currentState is FeedOutCompleted) ||
          nextStateCondition ==
                  NextStateCondition
                      .whenFeedInIsCompletedAndFeedOutIsCompleted &&
              feedOutStateMachine.currentState is FeedOutCompleted);

  static bool canFeedIn(currentState) =>
      (currentState is SimultaneousFeedOutFeedInModuleGroup) &&
      currentState.feedInStateMachine.currentState is WaitToFeedIn;

  static Duration durationUntilCanFeedOut(currentState) =>
      (currentState is SimultaneousFeedOutFeedInModuleGroup) &&
              currentState.feedOutStateMachine.currentState is WaitToFeedOut
          ? Duration.zero
          : unknownDuration;

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

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('in', feedInStateMachine.currentState.name)
      .appendProperty('out', feedOutStateMachine.currentState.name);
}

enum NextStateCondition {
  whenFeedInIsCompletedAndFeedOutIsStarted,
  whenFeedInIsCompletedAndFeedOutIsCompleted,
}

class FeedInStateMachine extends StateMachine
    implements
        ModuleTransportStartedListener,
        ModuleTransportCompletedListener {
  final SimultaneousFeedOutFeedInModuleGroup simultaneousFeedOutFeedIn;
  late final ModuleGroupInLink<PhysicalSystem> modulesIn =
      simultaneousFeedOutFeedIn.modulesIn;

  FeedInStateMachine(this.simultaneousFeedOutFeedIn)
      : super(initialState: WaitUntilThereIsSpaceToFeedIn());

  @override
  final String name = 'FeedInStateMachine';

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

class WaitUntilThereIsSpaceToFeedIn extends State<FeedInStateMachine> {
  @override
  final String name = "WaitUntilThereIsSpaceToFeedIn";

  Duration inFeedDelay = Duration.zero;

  @override
  void onStart(FeedInStateMachine feedInStateMachine) {
    inFeedDelay = feedInStateMachine.simultaneousFeedOutFeedIn.inFeedDelay;
  }

  @override
  void onUpdateToNextPointInTime(
      FeedInStateMachine feedInStateMachine, Duration jump) {
    var feedOutStateMachine =
        feedInStateMachine.simultaneousFeedOutFeedIn.feedOutStateMachine;
    if (feedOutStateMachine.currentState is FeedOut) {
      inFeedDelay -= jump;
    }
    if (inFeedDelay < Duration.zero ||
        feedOutStateMachine.currentState is FeedOutCompleted) {
      inFeedDelay = Duration.zero;
    }
  }

  @override
  State<FeedInStateMachine>? nextState(FeedInStateMachine feedInStateMachine) {
    var feedOutStateMachine =
        feedInStateMachine.simultaneousFeedOutFeedIn.feedOutStateMachine;

    if (hasSpaceToFeedIn(feedOutStateMachine)) {
      return WaitToFeedIn();
    } else {
      return null;
    }
  }

  bool hasSpaceToFeedIn(FeedOutStateMachine feedOutStateMachine) =>
      feedOutStateMachine.currentState is FeedOutCompleted ||
      feedOutStateMachine.currentState is FeedOut &&
          inFeedDelay == Duration.zero;
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
  final SimultaneousFeedOutFeedInModuleGroup simultaneousFeedOutFeedIn;
  late final ModuleGroupOutLink<PhysicalSystem> modulesOut =
      simultaneousFeedOutFeedIn.modulesOut;

  FeedOutStateMachine(this.simultaneousFeedOutFeedIn)
      : super(initialState: WaitToFeedOut());

  @override
  final String name = 'FeedOutStateMachine';

  bool get nextNeighborWaitingToFeedIn => modulesOut.linkedTo!.canFeedIn();

  bool get feedOutFirstStack =>
      modulesOut.linkedTo!.feedInSingleStack &&
      modulesOut.place.moduleGroup!.numberOfStacks > 1;

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
        betweenModuleGroupPlaces.source.system == modulesOut.place.system) {
      var listener = currentState as ModuleTransportCompletedListener;
      listener.onModuleTransportCompleted(betweenModuleGroupPlaces);
    }
  }
}

class WaitToFeedOut extends State<FeedOutStateMachine> {
  @override
  final String name = 'WaitToFeedOut';

  @override
  State<FeedOutStateMachine>? nextState(
      FeedOutStateMachine feedOutStateMachine) {
    if (!feedOutStateMachine.nextNeighborWaitingToFeedIn) {
      return null;
    }
    if (feedOutStateMachine.feedOutFirstStack) {
      return FeedOutFirstStack();
    } else {
      return FeedOut();
    }
  }
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

class FeedOutFirstStack extends State<FeedOutStateMachine>
    implements ModuleTransportCompletedListener {
  ModuleGroups get moduleGroups =>
      GetIt.instance<Player>().scenario!.area.moduleGroups;

  late final BetweenModuleGroupPlaces firstStackPosition;
  @override
  final String name = "FeedOutFirstStack";

  bool transportCompleted = false;

  @override
  void onStart(FeedOutStateMachine stateMachine) {
    var system = stateMachine.modulesOut.system;
    var centerPlace = stateMachine.modulesOut.place;
    var moduleGroup = centerPlace.moduleGroup!;
    var moduleGroupLengthInMeters = moduleGroup.shape.yInMeters;
    var moduleLengthInMeters = moduleGroup.moduleGroundSurface.yInMeters;
    var outFeedDuration = stateMachine.modulesOut.feedOutDuration;
    var remainingStacksModuleGroup = centerPlace.moduleGroup!;
    centerPlace.moduleGroup = null;

    var firstStack = remainingStacksModuleGroup.stacks.first;
    var firstStackModuleGroup = ModuleGroup(
      modules: firstStack,
      direction: remainingStacksModuleGroup.direction,
      destination: remainingStacksModuleGroup.destination,
      position: dummyPlace(stateMachine),
    );
    moduleGroups.add(firstStackModuleGroup);

    var firstStackPlace = ModuleGroupPlace(
        system: system,
        offsetFromCenterWhenSystemFacingNorth:
            centerPlace.offsetFromCenterWhenSystemFacingNorth.addY(
                moduleGroupLengthInMeters * -0.5 + moduleLengthInMeters * 0.5));
    firstStackPlace.moduleGroup = firstStackModuleGroup;

    firstStackPosition = BetweenModuleGroupPlaces(
        source: firstStackPlace,
        destination: stateMachine.modulesOut.linkedTo!.place,
        duration: outFeedDuration);
    firstStackModuleGroup.position = firstStackPosition;

    for (var position in firstStack.keys) {
      remainingStacksModuleGroup.remove(position);
    }
    var remainingStackPlace = ModuleGroupPlace(
        system: system,
        offsetFromCenterWhenSystemFacingNorth:
            centerPlace.offsetFromCenterWhenSystemFacingNorth.addY(
                moduleGroupLengthInMeters * 0.5 - moduleLengthInMeters * 0.5));
    remainingStackPlace.moduleGroup = remainingStacksModuleGroup;
    remainingStacksModuleGroup.position = BetweenModuleGroupPlaces(
        source: remainingStackPlace,
        destination: centerPlace,
        duration: outFeedDuration * 0.5);
  }

  AtModuleGroupPlace dummyPlace(FeedOutStateMachine stateMachine) =>
      AtModuleGroupPlace(stateMachine.modulesOut.place);

  @override
  State<FeedOutStateMachine>? nextState(FeedOutStateMachine stateMachine) {
    if (!transportCompleted) {
      return null;
    }
    var moduleGroup = stateMachine.modulesOut.place.moduleGroup;
    if (moduleGroup == null) {
      return FeedOutCompleted();
    } else {
      return WaitToFeedOut();
    }
  }

  @override
  void onModuleTransportCompleted(BetweenModuleGroupPlaces position) {
    if (position == firstStackPosition) {
      transportCompleted = true;
    }
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
