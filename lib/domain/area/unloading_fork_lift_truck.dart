import 'life_bird_handling_area.dart';
import 'state_machine.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class UnLoadingForkLiftTruck extends StateMachineCell {
  final CardinalDirection inFeedDirection;

  @override
  String get name => "UnLoadingForkLiftTruck${seqNr ?? ''}";

  UnLoadingForkLiftTruck({
    required LiveBirdHandlingArea area,
    required Position position,
    int? seqNr,
    required this.inFeedDirection,
    Duration putModuleGroupOnTruckDuration =
        const Duration(seconds: 5), //TODO 30s?
    Duration getStackFromConveyorDuration =
        const Duration(seconds: 5), //TODO 15s?
  }) : super(
            area: area,
            position: position,
            seqNr: seqNr,
            initialState: WaitingForFullConveyor(),
            inFeedDuration: putModuleGroupOnTruckDuration,
            outFeedDuration: getStackFromConveyorDuration);

  StateMachineCell get sendingNeighbour =>
      area.neighboringCell(this, inFeedDirection) as StateMachineCell;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => direction == inFeedDirection;

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
  String get name => 'WaitingForFullConveyor';

  @override
  State<UnLoadingForkLiftTruck>? nextState(
      // ignore: avoid_renaming_method_parameters
      UnLoadingForkLiftTruck forkLiftTruck) {
    if (_neighbourCanFeedOut(forkLiftTruck)) {
      return GetModuleGroupFromConveyor();
    }
    return null;
  }

  bool _neighbourCanFeedOut(UnLoadingForkLiftTruck forkLiftTruck) {
    return forkLiftTruck.area.moduleGroups.any(
        (moduleGroup) => moduleGroup.position.destination == forkLiftTruck);
  }
}

class GetModuleGroupFromConveyor extends State<UnLoadingForkLiftTruck> {
  @override
  String get name => 'GetModuleGroupFromConveyor';

  @override
  State<UnLoadingForkLiftTruck>? nextState(
      // ignore: avoid_renaming_method_parameters
      UnLoadingForkLiftTruck forkLiftTruck) {
    if (_transportCompleted(forkLiftTruck)) {
      return PutModuleGroupOnTruck();
    }
    return null;
  }

  bool _transportCompleted(UnLoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.area.moduleGroups
          .any((moduleGroup) => moduleGroup.position.source == forkLiftTruck);
}

class PutModuleGroupOnTruck extends DurationState<UnLoadingForkLiftTruck> {
  @override
  String get name => 'PutModuleGroupOnTruck';

  PutModuleGroupOnTruck()
      : super(
            durationFunction: (forkLiftTruck) => forkLiftTruck.inFeedDuration,
            nextStateFunction: (forkLiftTruck) => WaitingForFullConveyor());

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(UnLoadingForkLiftTruck forkLiftTruck) {
    //TODO keep track of trough put
    forkLiftTruck.area.moduleGroups.remove(forkLiftTruck.moduleGroup);
  }
}
