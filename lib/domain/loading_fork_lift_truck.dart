import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/module_cas_allocation.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class LoadingForkLiftTruck extends StateMachineCell {
  final CardinalDirection outFeedDirection;
  final CardinalDirection doorDirection;
  final bool loadsSingeModule;
  var sequenceNumber = 0;

  LoadingForkLiftTruck({
    required LiveBirdHandlingArea area,
    required Position position,
    int? seqNr,
    required this.outFeedDirection,
    required this.doorDirection,
    Duration getModuleGroupOnTruckDuration =
    const Duration(seconds: 5), //TODO 30s?
    Duration putModuleGroupOnConveyorDuration =
    const Duration(seconds: 5), //TODO 15s?
    this.loadsSingeModule = false,
  }) : super(
      area: area,
      position: position,
      seqNr: seqNr,
      initialState: GetModuleGroupFromTruck(),
      inFeedDuration: getModuleGroupOnTruckDuration,
      outFeedDuration: putModuleGroupOnConveyorDuration) {
    _verifyDirections();
  }

  void _verifyDirections() {
    if (outFeedDirection.isParallelTo(doorDirection)) {
      throw ArgumentError(
          "$LiveBirdHandlingArea error: $name: outFeedDirection and doorDirection must be perpendicular.");
    }
  }

  get receivingNeighbour =>
      area.neighbouringCell(this, outFeedDirection) as StateMachineCell;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => false;

  @override
  bool waitingToFeedIn(CardinalDirection direction) => false;

  @override
  bool isFeedOut(CardinalDirection direction) => direction == outFeedDirection;

  @override
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction == outFeedDirection && currentState is WaitingForEmptyConveyor;

  ModuleGroup createModuleGroup() {
    var moduleCombination = _randomModuleCombination();

    var moduleGroup = ModuleGroup(
        type: moduleCombination.firstModuleType,
        firstModule: Module(
          nrOfBirds: moduleCombination.firstModuleNumberOfBirds,
          sequenceNumber: ++sequenceNumber,
        ),
        secondModule: moduleCombination.secondModuleType == null
            ? null
            : Module(
          nrOfBirds: moduleCombination.secondModuleNumberOfBirds!,
          sequenceNumber: ++sequenceNumber,
        ),
        doorDirection: doorDirection.toCompassDirection(),
        destination: _findModuleDestination(),
        position: _createModulePosition());
    return moduleGroup;
  }

  ModuleCombination _randomModuleCombination() {
    var total = 0.0;
    double totalOccurrence = _totalOccurrence();
    var random = totalOccurrence * Random().nextDouble();
    for (var moduleCombination in area.productDefinition.moduleCombinations) {
      total += moduleCombination.occurrence;
      if (random <= total) {
        return moduleCombination;
      }
    }
    return area.productDefinition.moduleCombinations.last;
  }

  double _totalOccurrence() {
    var totalOccurrence = 0.0;
    for (var moduleCombination in area.productDefinition.moduleCombinations) {
      totalOccurrence += moduleCombination.occurrence;
    }
    return totalOccurrence;
  }

  ModulePosition _createModulePosition() =>
      ModulePosition.forCel(receivingNeighbour);

  StateMachineCell _findModuleDestination() {
    var moduleCasAllocation = _findModuleCasAllocation();
    var position=moduleCasAllocation.positionToAllocate;
    return area.cellForPosition(position) as StateMachineCell;
  }

  ModuleCasAllocation _findModuleCasAllocation() {
    //TODO what if there is only one CAS unit, we would not need the ModuleCasAllocation
    var moduleCasAllocation = area.cells.firstWhereOrNull((
        cell) => cell is ModuleCasAllocation);
    if (moduleCasAllocation == null) {
      throw Exception(
          'Could not find a $ModuleCasAllocation cell in the $LiveBirdHandlingArea');
    }
    return moduleCasAllocation as ModuleCasAllocation;
  }

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
    forkLiftTruck.area.moduleGroups.add(newModuleGroup);
    //ensure correct module group position
    newModuleGroup.position = ModulePosition.forCel(forkLiftTruck);
  }

  static _verifyDirections(LoadingForkLiftTruck forkLiftTruck,
      CardinalDirection direction1,
      CardinalDirection direction2,) {
    if (direction1.isParallelTo(direction2)) {
      throw ArgumentError(
          "${forkLiftTruck
              .name}: outFeedDirection and moduleDoorDirection must be perpendicular in layout configuration.");
    }
  }

  static void _verifyDestination(LoadingForkLiftTruck forkLiftTruck,
      StateMachineCell destination,) {
    var area = forkLiftTruck.area;
    if (destination is! StateMachineCell) {
      throw ArgumentError("stack.destination must point to a none empty cell");
    }
    var route = area.findRoute(source: forkLiftTruck, destination: destination);
    if (route == null) {
      throw ArgumentError(
          "${forkLiftTruck
              .name} can not reach destination: $destination in $LiveBirdHandlingArea configuration.");
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
      !forkLiftTruck.area.moduleGroups
          .any((moduleGroup) => moduleGroup.position.source == forkLiftTruck);
}
