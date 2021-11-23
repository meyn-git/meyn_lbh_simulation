import 'package:collection/src/iterable_extensions.dart';
import 'package:meyn_lbh_simulation/domain/unloading_fork_lift_truck.dart';

import 'layout.dart';
import 'module.dart';
import 'state_machine.dart';

class ModuleCas extends StateMachineCell {
  /// the [CardinalDirection] the in and out feed is pointed towards
  final CasRecipe recipe;
  final CardinalDirection inAndOutFeedDirection;
  final CardinalDirection doorDirection;
  final Duration closeSlideDoorDuration;
  final Duration openSlideDoorDuration;

  ModuleCas({
    required Layout layout,
    required Position position,
    int? seqNr,

    this.recipe = const CasRecipe([
      Duration(seconds: 60),
      Duration(seconds: 60),
      Duration(seconds: 60),
      Duration(seconds: 60),
      Duration(seconds: 120)
    ], Duration(seconds: 30)),
    required this.inAndOutFeedDirection,
    required this.doorDirection,
    this.closeSlideDoorDuration = const Duration(seconds: 3),
    this.openSlideDoorDuration = const Duration(seconds: 3),
    Duration inFeedDuration = const Duration(seconds: 14),
    Duration outFeedDuration = const Duration(seconds: 14),
  }) :  super(
          layout: layout,
          position: position,
          seqNr: seqNr,
          initialState: WaitToFeedIn(),
          inFeedDuration: inFeedDuration,
          outFeedDuration: outFeedDuration,
        ) {
    _verifyDirections();
  }

  StateMachineCell get neighbour =>
      layout.neighbouringCell(this, inAndOutFeedDirection) as StateMachineCell;

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
          "$name: inAndOutFeedDirection and doorDirection must be perpendicular in layout configuration.");
    }
  }


  StateMachineCell get moduleGroupDestinationAfterStunning {
    var unloadingCell=layout.cells.firstWhereOrNull((cell) => cell is UnLoadingForkLiftTruck);
    if (unloadingCell==null) {
      throw Exception('The layout MUST have a $UnLoadingForkLiftTruck.');
    }
    return unloadingCell as StateMachineCell;
  }
}

class CasRecipe {
  final List<Duration> stunStageDurations;
  final Duration exhaustDuration;

  const CasRecipe(this.stunStageDurations, this.exhaustDuration);
}

class WaitToFeedIn extends State<ModuleCas> {
  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_moduleGroupTransportedTo(cas)) {
      return FeedIn();
    }
  }

  bool _moduleGroupTransportedTo(ModuleCas cas) => cas.layout.moduleGroups
      .any((moduleGroup) => moduleGroup.position.destination == cas);
}

class FeedIn extends State<ModuleCas> {
  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_transportCompleted(cas)) {
      return WaitForStart();
    }
  }

  bool _transportCompleted(ModuleCas cas) => cas.moduleGroup != null;

  @override
  void onCompleted(ModuleCas cas) {
    _verifyDoorDirection(cas);
  }

  void _verifyDoorDirection(ModuleCas cas) {
    if (cas.moduleGroup!.doorDirection.toCardinalDirection()!=cas.doorDirection) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${cas.name}');
    }
  }

}

class WaitForStart extends State<ModuleCas> {
  @override
  State<ModuleCas>? nextState(ModuleCas moduleCas) {
    //TODO wait for start from
    return CloseSlideDoor();
  }
}

class CloseSlideDoor extends DurationState<ModuleCas> {
  CloseSlideDoor()
      : super(
          durationFunction: (cas) => cas.closeSlideDoorDuration,
          nextStateFunction: (cas) => StunStage(1),
        );
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
  String get name => '${super.name}$stageNumber';

  @override
  String toString() => '$name (remaining: ${remainingDuration.inSeconds}sec)';

  @override
  void onStart(ModuleCas cas) {
    super.onStart(cas);
    if (stageNumber == 1) {
      cas.moduleGroup!.startedStunning();
    }
  }
}

class ExhaustStage extends DurationState<ModuleCas> {
  ExhaustStage()
      : super(
            durationFunction: (cas) => cas.recipe.exhaustDuration,
            nextStateFunction: (cas) => OpenSlideDoor());

  @override
  void onStart(ModuleCas cas) {
    super.onStart(cas);
    var destination=cas.moduleGroupDestinationAfterStunning;
    cas.moduleGroup!.destination = destination;
  }
}

class OpenSlideDoor extends DurationState<ModuleCas> {
  OpenSlideDoor()
      : super(
          durationFunction: (cas) => cas.openSlideDoorDuration,
          nextStateFunction: (cas) => WaitToFeedOut(),
        );
}

class WaitToFeedOut extends State<ModuleCas> {
  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_neighbourOkToFeedIn(cas)) {
      return FeedOut();
    }
  }

  bool _neighbourOkToFeedIn(ModuleCas cas) =>
      cas.neighbour.waitingToFeedIn(cas.inAndOutFeedDirection.opposite);
}

class FeedOut extends State<ModuleCas> {
  @override
  void onStart(ModuleCas cas) {
    cas.moduleGroup!.position =
        ModulePosition.betweenCells(source: cas, destination: cas.neighbour);
  }

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_transportCompleted(cas)) {
      return WaitToFeedIn();
    }
  }

  bool _transportCompleted(ModuleCas cas) => cas.moduleGroup == null;
}
