import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class LoadingForkLiftTruck extends StateMachineCell {
  final CardinalDirection outFeedDirection;
  final CardinalDirection doorDirection;
  final bool loadsSingeModule;
  var sequenceNumber = 0;

  @override
  String get name => "LoadingForkLiftTruck${seqNr ?? ''}";

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

  StateMachineCell get receivingNeighbour =>
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
    var moduleGroupCapacity = _randomModuleGroupCapacity();

    var moduleGroup = ModuleGroup(
        type: area.productDefinition.moduleType,
        firstModule: Module(
          nrOfBirds: moduleGroupCapacity.firstModule.numberOfBirds,
          sequenceNumber: ++sequenceNumber,
        ),
        secondModule: moduleGroupCapacity.secondModule == null
            ? null
            : Module(
                nrOfBirds: moduleGroupCapacity.secondModule!.numberOfBirds,
                sequenceNumber: ++sequenceNumber,
              ),
        direction: doorDirection.toCompassDirection(),
        destination: _findModuleDestination(),
        position: _createModulePosition());
    return moduleGroup;
  }

  ModuleGroupCapacity _randomModuleGroupCapacity() {
    var total = 0.0;
    double totalOccurrence = _totalOccurrence();
    var random = totalOccurrence * Random().nextDouble();
    for (var moduleCombination
        in area.productDefinition.moduleGroupCapacities) {
      total += moduleCombination.occurrence;
      if (random <= total) {
        return moduleCombination;
      }
    }
    return area.productDefinition.moduleGroupCapacities.last;
  }

  double _totalOccurrence() {
    var totalOccurrence = 0.0;
    for (var moduleCombination
        in area.productDefinition.moduleGroupCapacities) {
      totalOccurrence += moduleCombination.occurrence;
    }
    return totalOccurrence;
  }

  ModulePosition _createModulePosition() =>
      ModulePosition.forCel(receivingNeighbour);

  StateMachineCell _findModuleDestination() {
    var moduleCasAllocation = _findModuleCasAllocation();
    var position = moduleCasAllocation.positionToAllocate;
    return area.cellForPosition(position) as StateMachineCell;
  }

  ModuleCasAllocation _findModuleCasAllocation() {
    //TODO what if there is only one CAS unit, we would not need the ModuleCasAllocation
    var moduleCasAllocation =
        area.cells.firstWhereOrNull((cell) => cell is ModuleCasAllocation);
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
  String get name => 'GetModuleGroupFromTruck';

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(LoadingForkLiftTruck forkLiftTruck) {
    if (forkLiftTruck.moduleGroup == null) {
      var newModuleGroup = forkLiftTruck.createModuleGroup();
      _verifyDirections(
        forkLiftTruck,
        forkLiftTruck.outFeedDirection,
        newModuleGroup.direction,
      );
      _verifyDestination(forkLiftTruck, newModuleGroup.destination);
      forkLiftTruck.area.moduleGroups.add(newModuleGroup);
      //ensure correct module group position
      newModuleGroup.position = ModulePosition.forCel(forkLiftTruck);
    }
  }

  static _verifyDirections(
    LoadingForkLiftTruck forkLiftTruck,
    CardinalDirection doorDirection1,
    CompassDirection? doorDirection2,
  ) {
    if (doorDirection2 != null &&
        doorDirection1.isParallelTo(doorDirection2.toCardinalDirection()!)) {
      throw ArgumentError(
          "${forkLiftTruck.name}: outFeedDirection and moduleDoorDirection must be perpendicular in layout configuration.");
    }
  }

  static void _verifyDestination(
    LoadingForkLiftTruck forkLiftTruck,
    StateMachineCell destination,
  ) {
    var area = forkLiftTruck.area;

    var route = area.findRoute(source: forkLiftTruck, destination: destination);
    if (route == null) {
      throw ArgumentError(
          "${forkLiftTruck.name} can not reach destination: $destination in $LiveBirdHandlingArea configuration.");
    }
  }
}

class WaitingForEmptyConveyor extends State<LoadingForkLiftTruck> {
  @override
  String get name => 'WaitingForEmptyConveyor';

  @override
  // ignore: avoid_renaming_method_parameters
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) {
    if (_neighbourCanFeedIn(forkLiftTruck)) {
      return PutModuleGroupOnConveyor();
    }
    return null;
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
  String get name => 'PutModuleGroupOnConveyor';

  @override
  // ignore: avoid_renaming_method_parameters
  void onStart(LoadingForkLiftTruck forkLiftTruck) {
    var moduleGroup = forkLiftTruck.moduleGroup!;

    if (forkLiftTruck.loadsSingeModule) {
      if (moduleGroup.numberOfModules > 1) {
        forkLiftTruck.area.moduleGroups.add(moduleGroup.split()!);
      }
    }

    moduleGroup.position = ModulePosition.betweenCells(
        source: forkLiftTruck,
        destination: forkLiftTruck.receivingNeighbour,
        duration: forkLiftTruck.outFeedDuration);
    moduleGroup.loadedOnToSystem();
  }

  @override
  // ignore: avoid_renaming_method_parameters
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) {
    if (_putSecondModuleOnConveyor(forkLiftTruck)) {
      return PutModuleGroupOnConveyor();
    } else if (_transportCompleted(forkLiftTruck)) {
      return GetModuleGroupFromTruck();
    }
    return null;
  }

  bool _transportCompleted(LoadingForkLiftTruck forkLiftTruck) =>
      !forkLiftTruck.area.moduleGroups
          .any((moduleGroup) => moduleGroup.position.source == forkLiftTruck);

  bool _putSecondModuleOnConveyor(LoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.loadsSingeModule &&
      forkLiftTruck.moduleGroup != null &&
      forkLiftTruck.moduleGroup!.numberOfModules == 1 &&
      forkLiftTruck.receivingNeighbour
          .waitingToFeedIn(forkLiftTruck.outFeedDirection.opposite);
}
