import 'package:collection/collection.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';
import 'unloading_fork_lift_truck.dart';

class ModuleCas extends StateMachineCell {
  /// the [CardinalDirection] the in and out feed is pointed towards
  late final CasRecipe recipe;
  final CardinalDirection inAndOutFeedDirection;
  final CardinalDirection doorDirection;
  final Duration closeSlideDoorDuration;
  final Duration openSlideDoorDuration;
  Duration waitingForStartDuration = Duration.zero;

  @override
  String get name => "ModuleCas${seqNr ?? ''}";

  ModuleCas({
    required LiveBirdHandlingArea area,
    required Position position,
    int? seqNr,
    required this.inAndOutFeedDirection,
    required this.doorDirection,
    this.closeSlideDoorDuration = const Duration(seconds: 6),
    this.openSlideDoorDuration = const Duration(seconds: 6),
    Duration? inFeedDuration,
    Duration? outFeedDuration,
  }) : super(
          area: area,
          position: position,
          seqNr: seqNr,
          initialState: WaitToFeedIn(),
          inFeedDuration: inFeedDuration ??
              area.productDefinition.moduleType.casTransportDuration,
          outFeedDuration: outFeedDuration ??
              area.productDefinition.moduleType.casTransportDuration,
        ) {
    _verifyDirections();
    _verifyCasRecipeIsDefined();
    recipe = area.productDefinition.casRecipe!;
  }

  StateMachineCell get neighbour =>
      area.neighbouringCell(this, inAndOutFeedDirection) as StateMachineCell;

  @override
  bool isFeedIn(CardinalDirection direction) =>
      direction == inAndOutFeedDirection;

  @override
  bool waitingToFeedIn(CardinalDirection direction) =>
      direction == inAndOutFeedDirection && currentState is WaitToFeedIn;

  @override
  bool isFeedOut(CardinalDirection direction) =>
      direction == inAndOutFeedDirection;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) =>
      direction == inAndOutFeedDirection &&
      (currentState is ExhaustStage ||
          currentState is OpenSlideDoor ||
          currentState is WaitToFeedOut ||
          currentState is FeedOut);

  @override
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction == inAndOutFeedDirection && currentState is WaitToFeedOut;

  void _verifyDirections() {
    if (inAndOutFeedDirection.isParallelTo(doorDirection)) {
      throw ArgumentError(
          "$LiveBirdHandlingArea error: $name: inAndOutFeedDirection and doorDirection must be perpendicular.");
    }
  }

  StateMachineCell get moduleGroupDestinationAfterStunning {
    var unloadingCell =
        area.cells.firstWhereOrNull((cell) => cell is UnLoadingForkLiftTruck);
    if (unloadingCell == null) {
      throw Exception(
          'The $LiveBirdHandlingArea MUST have a $UnLoadingForkLiftTruck.');
    }
    return unloadingCell as StateMachineCell;
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

class WaitToFeedIn extends State<ModuleCas> {
  @override
  String get name => 'WaitToFeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_moduleGroupTransportedTo(cas)) {
      return FeedIn();
    }
    return null;
  }

  bool _moduleGroupTransportedTo(ModuleCas cas) => cas.area.moduleGroups
      .any((moduleGroup) => moduleGroup.position.destination == cas);
}

class FeedIn extends State<ModuleCas> {
  @override
  String get name => 'FeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_transportCompleted(cas)) {
      return WaitForStart();
    }
    return null;
  }

  bool _transportCompleted(ModuleCas cas) => cas.moduleGroup != null;

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleCas cas) {
    _verifyDoorDirection(cas);
  }

  void _verifyDoorDirection(ModuleCas cas) {
    var moduleGroup = cas.moduleGroup!;
    var hasDoors = moduleGroup.type.compartmentType == CompartmentType.door;
    if (hasDoors &&
        moduleGroup.direction.toCardinalDirection() != cas.doorDirection) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${cas.name}');
    }
  }
}

class WaitForStart extends State<ModuleCas> {
  @override
  String get name => 'WaitForStart';

  bool _start = false;

  @override
  // ignore: avoid_renaming_method_parameters
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
  // ignore: avoid_renaming_method_parameters
  void onStart(ModuleCas cas) {
    super.onStart(cas);
    if (stageNumber == 1) {
      cas.moduleGroup!.startStunning();
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
  // ignore: avoid_renaming_method_parameters
  void onStart(ModuleCas cas) {
    super.onStart(cas);
    var destination = cas.moduleGroupDestinationAfterStunning;
    cas.moduleGroup!.endStunning();
    cas.moduleGroup!.destination = destination;
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
  // ignore: avoid_renaming_method_parameters
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_neighbourOkToFeedIn(cas)) {
      return FeedOut();
    }
    return null;
  }

  bool _neighbourOkToFeedIn(ModuleCas cas) =>
      cas.neighbour.waitingToFeedIn(cas.inAndOutFeedDirection.opposite);
}

class FeedOut extends State<ModuleCas> {
  @override
  String get name => 'FeedOut';

  @override
  // ignore: avoid_renaming_method_parameters
  void onStart(ModuleCas cas) {
    cas.moduleGroup!.position =
        ModulePosition.betweenCells(source: cas, destination: cas.neighbour);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_transportCompleted(cas)) {
      return WaitToFeedIn();
    }
    return null;
  }

  bool _transportCompleted(ModuleCas cas) => cas.moduleGroup == null;
}
