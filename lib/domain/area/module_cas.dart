// ignore_for_file: avoid_renaming_method_parameters

import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_cas.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';
import 'unloading_fork_lift_truck.dart';

class ModuleCas extends StateMachine implements PhysicalSystem {
  final LiveBirdHandlingArea area;
  final Duration inFeedDuration;
  final Duration outFeedDuration;
  late CasRecipe recipe;
  final bool gasDuctsLeft;
  final bool slideDoorLeft;
  final Duration closeSlideDoorDuration;
  final Duration openSlideDoorDuration;
  Duration waitingForStartDuration = Duration.zero;
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  late final CompassDirection doorDirection = shape.gasDuctsDirection.opposite
      .rotate(area.layout.rotationOf(this).degrees);

  ModuleCas({
    required this.area,
    required this.slideDoorLeft,
    required this.gasDuctsLeft,
    this.closeSlideDoorDuration = const Duration(seconds: 6),
    this.openSlideDoorDuration = const Duration(seconds: 6),
    Duration? inFeedDuration,
    Duration? outFeedDuration,
  })  : inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.casTransportDuration,
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.casTransportDuration,
        super(
          initialState: WaitToFeedIn(),
        ) {
    _verifyCasRecipeIsDefined();
    recipe = area.productDefinition.casRecipe!;
  }

  late final seqNr = area.systems.seqNrOf(this);

  bool get canFeedIn => currentState is WaitToFeedIn || currentState is FeedIn;

  bool get almostWaitingToFeedOut => durationUntilCanFeedOut != unknownDuration;

  bool get waitingToFeedOut => currentState is WaitToFeedOut;

  PhysicalSystem get moduleGroupDestinationAfterStunning {
    var unLoadingForkLiftTruck = area.systems.physicalSystems
        .firstWhereOrNull((system) => system is UnLoadingForkLiftTruck);
    if (unLoadingForkLiftTruck == null) {
      throw Exception(
          'The $LiveBirdHandlingArea MUST have a $UnLoadingForkLiftTruck.');
    }
    return unLoadingForkLiftTruck;
  }

  @override
  onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    if (currentState is WaitForStart) {
      waitingForStartDuration += jump;
    } else {
      waitingForStartDuration = Duration.zero;
    }
  }

  ///Called by [ModuleCasStart]
  start() {
    if (currentState is WaitForStart) {
      (currentState as WaitForStart).start();
    } else {
      throw Exception(
          'Can not start $name, because it is in $currentState state and not in $WaitForStart state.');
    }
  }

  void _verifyCasRecipeIsDefined() {
    if (area.productDefinition.casRecipe == null) {
      throw ArgumentError(
          '$LiveBirdHandlingArea error: You must specify the casRecipe in the layout when it contains one or more $ModuleCas');
    }
  }

  late ModuleCasShape shape = ModuleCasShape(this);

  late ModuleGroupInLink modulesIn = ModuleGroupInLink(
      position: moduleGroupPosition,
      offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupInOutLink,
      directionToOtherLink: const CompassDirection.south(),
      inFeedDuration: inFeedDuration,
      canFeedIn: () => canFeedIn);

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
      position: moduleGroupPosition,
      offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupInOutLink,
      directionToOtherLink: const CompassDirection.south(),
      outFeedDuration: outFeedDuration,
      durationUntilCanFeedOut: () => durationUntilCanFeedOut);

  get durationUntilCanFeedOut {
    if (currentState is OpenSlideDoor) {
      return (currentState as OpenSlideDoor).remainingDuration;
    }
    if (currentState is ExhaustStage) {
      return (currentState as ExhaustStage).remainingDuration +
          openSlideDoorDuration;
    }
    if (currentState is WaitToFeedOut || currentState is FeedOut) {
      return Duration.zero;
    }
    return unknownDuration;
  }

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn,
    modulesOut
  ];

  @override
  late String name = 'ModuleCas$seqNr';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late ModuleGroupPlace moduleGroupPosition = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToCabinCenter,
  );
}

class CasRecipe {
  final List<Duration> stunStageDurations;
  final Duration exhaustDuration;

  const CasRecipe(this.stunStageDurations, this.exhaustDuration);

  const CasRecipe.standardChickenRecipe()
      : this(const [
          Duration(seconds: 60), //18%
          Duration(seconds: 60), //28%
          Duration(seconds: 60), //33%
          Duration(seconds: 60), //38%
          Duration(seconds: 120) //67%
        ], const Duration(seconds: 30));

  const CasRecipe.standardTurkeyRecipe()
      : this(const [
          Duration(seconds: 40), //22%
          Duration(seconds: 40), //34%
          Duration(seconds: 40), //43%
          Duration(seconds: 120) //67%
        ], const Duration(seconds: 30));

  const CasRecipe.turkeyRecipeAtIndrol()
      : this(const [
          Duration(seconds: 35), //35%
          Duration(seconds: 35), //43%
          Duration(seconds: 30), //58%
          Duration(seconds: 110) //72%
        ], const Duration(seconds: 30));
}

class WaitToFeedIn extends State<ModuleCas>
    implements ModuleTransportStartedListener {
  bool transportStarted = false;

  @override
  String get name => 'WaitToFeedIn';

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (transportStarted) {
      return FeedIn();
    }
    return null;
  }

  @override
  void onModuleTransportStarted() {
    transportStarted = true;
  }
}

class FeedIn extends State<ModuleCas>
    implements ModuleTransportCompletedListener {
  bool completed = false;

  @override
  String get name => 'FeedIn';

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (completed) {
      return WaitForStart();
    }
    return null;
  }

  @override
  void onCompleted(ModuleCas cas) {
    _verifyDoorDirection(cas);
  }

  void _verifyDoorDirection(ModuleCas cas) {
    var moduleGroup = cas.moduleGroupPosition.moduleGroup!;
    if (moduleGroup.moduleFamily.compartmentType.hasDoor &&
        moduleGroup.direction.rotate(-90) != cas.doorDirection) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${cas.name}');
    }
  }

  @override
  void onModuleTransportCompleted() {
    completed = true;
  }
}

class WaitForStart extends State<ModuleCas> {
  @override
  String get name => 'WaitForStart';

  bool _start = false;

  @override
  State<ModuleCas>? nextState(ModuleCas moduleCas) {
    if (_start) {
      _start = false;
      return CloseSlideDoor();
    }
    return null;
  }

  void start() {
    _start = true;
  }
}

class CloseSlideDoor extends DurationState<ModuleCas> {
  CloseSlideDoor()
      : super(
          durationFunction: (cas) => cas.closeSlideDoorDuration,
          nextStateFunction: (cas) => StunStage(1),
        );

  @override
  String get name => 'CloseSlideDoor';
}

class StunStage extends DurationState<ModuleCas> {
  final int stageNumber;

  StunStage(this.stageNumber)
      : super(
            durationFunction: (cas) => findDuration(cas),
            nextStateFunction: (cas) => findNextStage(cas, stageNumber));

  static State<ModuleCas> findNextStage(ModuleCas cas, int currentStageNumber) {
    if (currentStageNumber >= numberOfStages(cas)) {
      return ExhaustStage();
    } else {
      return StunStage(++currentStageNumber);
    }
  }

  static int numberOfStages(ModuleCas cas) =>
      cas.recipe.stunStageDurations.length;

  static findDuration(ModuleCas cas) {
    var currentState = cas.currentState;
    if (currentState is StunStage) {
      var currentStageNumber = currentState.stageNumber;
      return cas.recipe.stunStageDurations[currentStageNumber - 1];
    }
    throw Exception('Unknown StunStage duration');
  }

  @override
  String get name => 'StunStage$stageNumber';

  @override
  String toString() => '$name (remaining: ${remainingDuration.inSeconds}sec)';

  @override
  void onStart(ModuleCas cas) {
    super.onStart(cas);
    if (stageNumber == 1) {
      cas.moduleGroupPosition.moduleGroup!.startStunning();
    }
  }
}

class ExhaustStage extends DurationState<ModuleCas> {
  ExhaustStage()
      : super(
            durationFunction: (cas) => cas.recipe.exhaustDuration,
            nextStateFunction: (cas) => OpenSlideDoor());

  @override
  String get name => 'ExhaustStage';

  @override
  void onStart(ModuleCas cas) {
    super.onStart(cas);
    var destination = cas.moduleGroupDestinationAfterStunning;
    var moduleGroup = cas.moduleGroupPosition.moduleGroup!;
    moduleGroup.endStunning();
    moduleGroup.destination = destination;
  }
}

class OpenSlideDoor extends DurationState<ModuleCas> {
  OpenSlideDoor()
      : super(
          durationFunction: (cas) => cas.openSlideDoorDuration,
          nextStateFunction: (cas) => WaitToFeedOut(),
        );

  @override
  String get name => 'OpenSlideDoor';
}

class WaitToFeedOut extends State<ModuleCas> {
  @override
  String get name => 'WaitToFeedOut';

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_neighborOkToFeedIn(cas)) {
      return FeedOut();
    }
    return null;
  }

  bool _neighborOkToFeedIn(ModuleCas cas) =>
      cas.modulesOut.linkedTo!.canFeedIn();
}

class FeedOut extends State<ModuleCas>
    implements ModuleTransportCompletedListener {
  bool completed = false;

  @override
  String get name => 'FeedOut';

  @override
  void onStart(ModuleCas cas) {
    cas.moduleGroupPosition.moduleGroup!.position =
        BetweenModuleGroupPlaces.forModuleOutLink(cas.modulesOut);
  }

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (completed) {
      return WaitToFeedIn();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted() {
    completed = true;
  }
}
