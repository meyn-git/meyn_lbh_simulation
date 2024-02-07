import 'package:meyn_lbh_simulation/domain/area/direction.dart';

import 'state_machine.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class UnLoadingForkLiftTruck extends StateMachineCell {
  final CardinalDirection inFeedDirection;

  UnLoadingForkLiftTruck({
    required super.area,
    required super.position,
    super.name = 'UnLoadingForkLiftTruck',
    super.seqNr,
    required this.inFeedDirection,
    Duration putModuleGroupOnTruckDuration =
        const Duration(seconds: 5), //TODO 30s?
    Duration getStackFromConveyorDuration =
        const Duration(seconds: 5), //TODO 15s?
  }) : super(
            initialState: WaitingForFullConveyor(),
            inFeedDuration: putModuleGroupOnTruckDuration,
            outFeedDuration: getStackFromConveyorDuration);

  StateMachineCell get sendingNeighbor =>
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
    if (_neighborCanFeedOut(forkLiftTruck)) {
      return GetModuleGroupFromConveyor();
    }
    return null;
  }

  bool _neighborCanFeedOut(UnLoadingForkLiftTruck forkLiftTruck) {
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
