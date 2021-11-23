import 'layout.dart';
import 'module.dart';
import 'state_machine.dart';

class ModuleTilter extends StateMachineCell {
  final CardinalDirection inFeedDirection;
  final CardinalDirection doorDirection;
  final Duration checkIfEmptyDuration;

  ModuleTilter({
    required Layout layout,
    required Position position,
    int? seqNr,
    required this.inFeedDirection,
    required this.doorDirection,
    this.checkIfEmptyDuration = const Duration(seconds: 18),
    Duration inFeedDuration = const Duration(seconds: 12),
    Duration outFeedDuration = const Duration(seconds: 12),
  }) : super(
          layout: layout,
          position: position,
          seqNr: seqNr,
          initialState: CheckIfEmpty(),
          inFeedDuration: inFeedDuration,
          outFeedDuration: outFeedDuration,
        );

  Cell get receivingNeighbour =>
      layout.neighbouringCell(this, inFeedDirection.opposite);

  Cell get sendingNeighbour => layout.neighbouringCell(this, inFeedDirection);

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


class CheckIfEmpty extends DurationState<ModuleTilter> {
  CheckIfEmpty()
      : super(
            durationFunction: (tilter) =>
                tilter.checkIfEmptyDuration,
            nextStateFunction: (tilter) => WaitToFeedIn());
}

class WaitToFeedIn extends State<ModuleTilter> {
  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_moduleGroupTransportedTo(tilter)) {
      return FeedIn();
    }
  }

  bool _moduleGroupTransportedTo(ModuleTilter tilter) {
    return tilter.layout.moduleGroups.any(
        (moduleGroup) => moduleGroup.position.destination == tilter);
  }
}

class FeedIn extends State<ModuleTilter> {
  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_transportCompleted(tilter)) {
      return WaitToFeedOut();
    }
  }

  bool _transportCompleted(ModuleTilter tilter) =>
      tilter.moduleGroup != null;

  @override
  void onCompleted(ModuleTilter tilter) {
    _verifyDoorDirection(tilter);
  }

  void _verifyDoorDirection(ModuleTilter tilter) {
    if (tilter.moduleGroup!.doorDirection.toCardinalDirection()!=tilter.doorDirection) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${tilter.name}');
    }
  }

}

class WaitToFeedOut extends State<ModuleTilter> {
  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_neighbourCanFeedIn(tilter) &&
        !_moduleGroupAtDestination(tilter)) {
      return FeedOut();
    }
  }

  bool _moduleGroupAtDestination(ModuleTilter tilter) =>
      tilter.moduleGroup!.destination == tilter;

  _neighbourCanFeedIn(ModuleTilter tilter) =>
      tilter.receivingNeighbour
          .waitingToFeedIn(tilter.inFeedDirection);
}

class FeedOut extends State<ModuleTilter> {
  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleTilter tilter) {
    transportedModuleGroup = tilter.moduleGroup;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: tilter,
        destination: tilter.receivingNeighbour as StateMachineCell);
  }

  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_transportCompleted(tilter)) {
      return WaitToFeedIn();
    }
  }

  bool _transportCompleted(ModuleTilter tilter) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != tilter;
}
