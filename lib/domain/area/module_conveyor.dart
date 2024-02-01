import 'package:meyn_lbh_simulation/domain/area/direction.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

class ModuleConveyor extends StateMachineCell {
  final CardinalDirection inFeedDirection;

  int nrOfModulesFeedingIn = 0;

  final Duration checkIfEmptyDuration;

  @override
  String get name => "ModuleConveyor${seqNr ?? ''}";

  ModuleConveyor({
    required LiveBirdHandlingArea area,
    required Position position,
    int? seqNr,
    required this.inFeedDirection,
    this.checkIfEmptyDuration = const Duration(seconds: 18),
    Duration? inFeedDuration,
    Duration? outFeedDuration,
  }) : super(
          area: area,
          position: position,
          seqNr: seqNr,
          initialState: CheckIfEmpty(),
          inFeedDuration: inFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
          outFeedDuration: outFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
        );

  Cell get receivingNeighbor =>
      area.neighboringCell(this, inFeedDirection.opposite);

  Cell get sendingNeighbor => area.neighboringCell(this, inFeedDirection);

  @override
  bool isFeedIn(CardinalDirection direction) => direction == inFeedDirection;

  @override
  bool waitingToFeedIn(CardinalDirection direction) =>
      direction == inFeedDirection && currentState is WaitToFeedIn;

  @override
  bool isFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite && currentState is WaitToFeedOut;
}

class CheckIfEmpty extends DurationState<ModuleConveyor> {
  CheckIfEmpty()
      : super(
            durationFunction: (moduleConveyor) =>
                moduleConveyor.checkIfEmptyDuration,
            nextStateFunction: (moduleConveyor) => WaitToFeedIn());

  @override
  String get name => 'CheckIfEmpty';
}

class WaitToFeedIn extends State<ModuleConveyor> {
  @override
  String get name => 'WaitToFeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (_moduleGroupTransportedTo(moduleConveyor)) {
      return FeedIn();
    }
    return null;
  }

  bool _moduleGroupTransportedTo(ModuleConveyor moduleConveyor) {
    return moduleConveyor.area.moduleGroups.any(
        (moduleGroup) => moduleGroup.position.destination == moduleConveyor);
  }
}

class FeedIn extends State<ModuleConveyor> {
  @override
  String get name => 'FeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (_transportCompleted(moduleConveyor)) {
      return WaitToFeedOut();
    }
    return null;
  }

  bool _transportCompleted(ModuleConveyor moduleConveyor) =>
      moduleConveyor.moduleGroup != null;
}

class WaitToFeedOut extends State<ModuleConveyor> {
  @override
  String get name => 'WaitToFeedOut';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (_neighborCanFeedIn(moduleConveyor) &&
        !_moduleGroupAtDestination(moduleConveyor)) {
      return FeedOut();
    }
    return null;
  }

  bool _moduleGroupAtDestination(ModuleConveyor moduleConveyor) =>
      moduleConveyor.moduleGroup!.destination == moduleConveyor;

  _neighborCanFeedIn(ModuleConveyor moduleConveyor) =>
      moduleConveyor.receivingNeighbor
          .waitingToFeedIn(moduleConveyor.inFeedDirection);
}

class FeedOut extends State<ModuleConveyor> {
  @override
  String get name => 'FeedOut';

  ModuleGroup? transportedModuleGroup;

  @override
  // ignore: avoid_renaming_method_parameters
  void onStart(ModuleConveyor moduleConveyor) {
    transportedModuleGroup = moduleConveyor.moduleGroup;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: moduleConveyor,
        destination: moduleConveyor.receivingNeighbor as StateMachineCell);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (_transportCompleted(moduleConveyor)) {
      return WaitToFeedIn();
    }
    return null;
  }

  bool _transportCompleted(ModuleConveyor moduleConveyor) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != moduleConveyor;
}
