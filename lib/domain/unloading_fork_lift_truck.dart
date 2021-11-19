import 'layout.dart';
import 'state_machine.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class UnLoadingForkLiftTruck extends StateMachineCell {
  final CardinalDirection inFeedDirection;

  UnLoadingForkLiftTruck({
    required Layout layout,
    required Position position,
    int? seqNr,
    required this.inFeedDirection,
    Duration putModuleGroupOnTruckDuration =
        const Duration(seconds: 5), //TODO 30s?
    Duration getStackFromConveyorDuration =
        const Duration(seconds: 5), //TODO 15s?
  }) : super(
            layout: layout,
            position: position,
            seqNr: seqNr,
            initialState: WaitingForFullConveyor(),
            inFeedDuration: putModuleGroupOnTruckDuration,
            outFeedDuration: getStackFromConveyorDuration);

  StateMachineCell get sendingNeighbour =>
      layout.neighbouringCell(this, inFeedDirection) as StateMachineCell;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => direction == inFeedDirection ;

  @override
  bool waitingToFeedIn(CardinalDirection direction) =>
      direction == inFeedDirection && currentState is WaitingForFullConveyor;

  @override
  bool isFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) => false;
}

class WaitingForFullConveyor extends State<UnLoadingForkLiftTruck> {
  @override
  State<UnLoadingForkLiftTruck>? nextState(
      UnLoadingForkLiftTruck forkLiftTruck) {
    if (_neighbourCanFeedOut(forkLiftTruck)) {
      return GetModuleGroupFromConveyor();
    }
  }

  bool _neighbourCanFeedOut(UnLoadingForkLiftTruck forkLiftTruck) {
    return forkLiftTruck.layout.moduleGroups.any(
        (moduleGroup) => moduleGroup.position.destination == forkLiftTruck);
  }
}

class GetModuleGroupFromConveyor extends State<UnLoadingForkLiftTruck> {
  @override
  @override
  State<UnLoadingForkLiftTruck>? nextState(
      UnLoadingForkLiftTruck forkLiftTruck) {
    if (_transportCompleted(forkLiftTruck)) {
      return PutModuleGroupOnTruck();
    }
  }

  bool _transportCompleted(UnLoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.layout.moduleGroups
          .any((moduleGroup) => moduleGroup.position.source == forkLiftTruck);
}

class PutModuleGroupOnTruck extends DurationState<UnLoadingForkLiftTruck> {
  PutModuleGroupOnTruck()
      : super(
            durationFunction: (forkLiftTruck) => forkLiftTruck.inFeedDuration,
            nextStateFunction: (forkLiftTruck) => WaitingForFullConveyor());

  @override
  void onCompleted(UnLoadingForkLiftTruck forkLiftTruck) {
    //TODO keep track of trough put
    forkLiftTruck.layout.moduleGroups.remove(forkLiftTruck.moduleGroup);
  }
}
