import 'layout.dart';
import 'module.dart';
import 'state_machine.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class LoadingForkLiftTruck extends StateMachineCell {
  final CardinalDirection outFeedDirection;
  final ModuleGroup Function() createModuleGroup;

  LoadingForkLiftTruck({
    required Layout layout,
    required Position position,
    int? seqNr,
    required this.outFeedDirection,
    required this.createModuleGroup,
    Duration getModuleGroupOnTruckDuration =
        const Duration(seconds: 5), //TODO 30s?
    Duration putModuleGroupOnConveyorDuration =
        const Duration(seconds: 5), //TODO 15s?
  }) : super(
            layout: layout,
            position: position,
            seqNr: seqNr,
            initialState: GetModuleGroupFromTruck(),
            inFeedDuration: getModuleGroupOnTruckDuration,
            outFeedDuration: putModuleGroupOnConveyorDuration);

  get receivingNeighbour =>
      layout.neighbouringCell(this, outFeedDirection) as StateMachineCell;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => false;

  @override
  bool waitingToFeedIn(CardinalDirection direction) => false;

  @override
  bool isFeedOut(CardinalDirection direction) => direction==outFeedDirection;

  @override
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction==outFeedDirection && currentState is WaitingForEmptyConveyor;
}

/// driving to truck
/// unloading stack
/// driving to in feed conveyor
class GetModuleGroupFromTruck extends DurationState<LoadingForkLiftTruck> {
  GetModuleGroupFromTruck()
      : super(
            durationFunction: (forkLiftTruck) => forkLiftTruck.inFeedDuration,
            nextStateFunction: (forkLiftTruck) => WaitingForEmptyConveyor());

  @override
  void onCompleted(LoadingForkLiftTruck forkLiftTruck) {
    var newModuleGroup = forkLiftTruck.createModuleGroup();
    _verifyDirections(
      forkLiftTruck,
      forkLiftTruck.outFeedDirection,
      newModuleGroup.doorDirection.toCardinalDirection()!,
    );
    _verifyDestination(forkLiftTruck, newModuleGroup.destination);
    forkLiftTruck.layout.moduleGroups.add(newModuleGroup);
    //ensure correct module group position
    newModuleGroup.position=ModulePosition.forCel(forkLiftTruck);
  }

  static _verifyDirections(
    LoadingForkLiftTruck forkLiftTruck,
    CardinalDirection direction1,
    CardinalDirection direction2,
  ) {
    if (direction1.isParallelTo(direction2)) {
      throw ArgumentError(
          "${forkLiftTruck.name}: outFeedDirection and moduleDoorDirection must be perpendicular in layout configuration.");
    }
  }

  static void _verifyDestination(
    LoadingForkLiftTruck forkLiftTruck,
    StateMachineCell destination,
  ) {
    var layout = forkLiftTruck.layout;
    if (destination is! StateMachineCell) {
      throw ArgumentError("stack.destination must point to a none empty cell");
    }
    var route =
        layout.findRoute(source: forkLiftTruck, destination: destination);
    if (route == null) {
      throw ArgumentError(
          "${forkLiftTruck.name} can not reach destination: $destination in layout configuration.");
    }
  }
}

class WaitingForEmptyConveyor extends State<LoadingForkLiftTruck> {
  @override
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) {
    if (_neighbourCanFeedIn(forkLiftTruck)) {
      return PutModuleGroupOnConveyor();
    }
  }

  bool _neighbourCanFeedIn(LoadingForkLiftTruck forkLiftTruck) {
    return forkLiftTruck.receivingNeighbour
        .waitingToFeedIn(forkLiftTruck.outFeedDirection.opposite);
  }
}

/// Drive module stack above in feed conveyor
/// lower stack on in feed conveyor and adjust when needed
/// drive backward to clear lifting spoons
/// push button to feed in
class PutModuleGroupOnConveyor extends State<LoadingForkLiftTruck> {
  @override
  void onStart(LoadingForkLiftTruck forkLiftTruck) {
    var moduleGroup = forkLiftTruck.moduleGroup!;
    moduleGroup.position = ModulePosition.betweenCells(
        source: forkLiftTruck,
        destination: forkLiftTruck.receivingNeighbour,
        duration: forkLiftTruck.outFeedDuration);
    moduleGroup.loadedOnToSystem();
  }

  @override
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) {
    if (_transportCompleted(forkLiftTruck)) {
      return GetModuleGroupFromTruck();
    }
  }

  bool _transportCompleted(LoadingForkLiftTruck forkLiftTruck) =>
      !forkLiftTruck.layout.moduleGroups
          .any((moduleGroup) => moduleGroup.position.source == forkLiftTruck);
}
