// ignore_for_file: avoid_renaming_method_parameters

import 'dart:math';

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module/module.dart';
import 'state_machine.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class LoadingForkLiftTruck extends StateMachine
    implements PhysicalSystem, AdditionalRotation {
  final LiveBirdHandlingArea area;
  final bool loadsSingleModule;
  final ModuleBirdExitDirection moduleBirdExitDirection;
  final Duration getModuleGroupFromTruckDuration;
  final Duration putModuleGroupOnConveyorDuration;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  var sequenceNumber = 0;

  @override
  LoadingForkLiftTruck({
    required this.area,
    required this.moduleBirdExitDirection,
    this.getModuleGroupFromTruckDuration =
        const Duration(seconds: 5), //TODO 30s?
    this.putModuleGroupOnConveyorDuration =
        const Duration(seconds: 5), //TODO 15s?
    this.loadsSingleModule = false,
  }) : super(initialState: GetModuleGroupFromTruck());

  CompassDirection get moduleGroupDirection =>
      area.layout.rotationOf(this).rotate(moduleGroupDoorDirection);

  ///Extra rotation based on [moduleBirdExitDirection]
  int get moduleGroupDoorDirection =>
      moduleBirdExitDirection == ModuleBirdExitDirection.left ? 180 : 0;

  ModuleGroup createModuleGroup() {
    var truckRow = _randomTruckRow();

    var moduleGroup = ModuleGroup(
        direction: moduleGroupDirection,
        destination: _findModuleGroupDestination(),
        position: AtModuleGroupPlace(moduleGroupPlace),
        modules: truckRow.map((position, template) => MapEntry(
            position,
            Module(
              variant: template.variant,
              nrOfBirds: template.numberOfBirds,
              sequenceNumber: ++sequenceNumber,
            ))));

    return moduleGroup;
  }

  TruckRow _randomTruckRow() {
    var total = 0.0;
    double totalOccurrence = _totalOccurrence();
    var random = totalOccurrence * Random().nextDouble();
    for (var truckRow in area.productDefinition.truckRows) {
      total += truckRow.occurrence;
      if (random <= total) {
        return truckRow;
      }
    }
    return area.productDefinition.truckRows.last;
  }

  double _totalOccurrence() {
    var totalOccurrence = 0.0;
    for (var moduleCombination in area.productDefinition.truckRows) {
      totalOccurrence += moduleCombination.occurrence;
    }
    return totalOccurrence;
  }

  PhysicalSystem _findModuleGroupDestination() {
    var casUnits = area.systems.whereType<ModuleCas>();
    var found = findSingleSystemOnRoute(casUnits as Iterable<PhysicalSystem>);
    if (found != null) {
      return found;
    }

    var systemsThatAllocateToCasUnits = area.systems
        .whereType<ModuleCasAllocation>()
        .map((e) => e.allocationPlace.system);
    found = findSingleSystemOnRoute(systemsThatAllocateToCasUnits);
    if (found != null) {
      return found;
    }

    var unLoadingForkLiftTrucks =
        area.systems.whereType<UnLoadingForkLiftTruck>();
    found = findSingleSystemOnRoute(unLoadingForkLiftTrucks);
    if (found != null) {
      return found;
    }
    throw Exception('Could not find an destination');
  }

  PhysicalSystem? findSingleSystemOnRoute(Iterable<PhysicalSystem> candidates) {
    PhysicalSystem? found;
    for (var candidate in candidates) {
      var route = modulesOut.findRoute(destination: candidate);
      if (route != null) {
        if (found == null) {
          found = candidate;
        } else {
          /// not the only one
          return null;
        }
      }
    }
    return found;
  }

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
      place: moduleGroupPlace,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: 0, yInMeters: sizeWhenFacingNorth.yInMeters * -0.5),
      directionToOtherLink: const CompassDirection.north(),
      durationUntilCanFeedOut: () => currentState is WaitingForEmptyConveyor
          ? Duration.zero
          : unknownDuration);

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesOut
  ];

  @override
  String name = 'LoadingForkLiftTruck';

  @override
  late SizeInMeters sizeWhenFacingNorth =
      const SizeInMeters(xInMeters: 1.5, yInMeters: 5);

  @override
  CompassDirection get additionalRotation =>
      currentState is GetModuleGroupFromTruck
          ? const CompassDirection(180)
          : const CompassDirection(0);

  late ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth:
        const OffsetInMeters(xInMeters: 0, yInMeters: -1.4),
  );
}

/// driving to truck
/// unloading stack
/// driving to in feed conveyor
class GetModuleGroupFromTruck extends DurationState<LoadingForkLiftTruck> {
  GetModuleGroupFromTruck()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.getModuleGroupFromTruckDuration,
            nextStateFunction: (forkLiftTruck) => WaitingForEmptyConveyor());

  @override
  String get name => 'GetModuleGroupFromTruck';

  @override
  void onCompleted(LoadingForkLiftTruck forkLiftTruck) {
    if (forkLiftTruck.moduleGroupPlace.moduleGroup == null) {
      var newModuleGroup = forkLiftTruck.createModuleGroup();
      _verifyDestination(forkLiftTruck, newModuleGroup.destination);
      forkLiftTruck.area.moduleGroups.add(newModuleGroup);
      forkLiftTruck.moduleGroupPlace.moduleGroup = newModuleGroup;
    }
  }

  void _verifyDestination(
    LoadingForkLiftTruck forkLiftTruck,
    PhysicalSystem destination,
  ) {
    // TODO
    // var area = forkLiftTruck.area;

    // var route = area.findCellRoute(source: forkLiftTruck, destination: destination);
    // if (route == null) {
    //   throw ArgumentError(
    //       "${forkLiftTruck.name} can not reach destination: $destination in $LiveBirdHandlingArea configuration.");
    // }
  }
}

class WaitingForEmptyConveyor extends State<LoadingForkLiftTruck> {
  @override
  String get name => 'WaitingForEmptyConveyor';

  @override
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) {
    if (forkLiftTruck.modulesOut.linkedTo!.canFeedIn()) {
      return PutModuleGroupOnConveyor();
    }
    return null;
  }
}

/// Drive module stack above in feed conveyor
/// lower stack on in feed conveyor and adjust when needed
/// drive backward to clear lifting spoons
/// push button to feed in
class PutModuleGroupOnConveyor extends State<LoadingForkLiftTruck>
    implements ModuleTransportCompletedListener {
  @override
  String get name => 'PutModuleGroupOnConveyor';
  bool transportCompleted = false;

  @override
  void onStart(LoadingForkLiftTruck forkLiftTruck) {
    var moduleGroup = forkLiftTruck.moduleGroupPlace.moduleGroup!;

    if (forkLiftTruck.loadsSingleModule) {
      if (moduleGroup.numberOfModules > 1) {
        if (moduleGroup.numberOfStacks > 1) {
          throw (Exception('$name can only de-stack single stacks'));
        }
        Module module = moduleGroup[PositionWithinModuleGroup.firstBottom]!;
        moduleGroup.remove(PositionWithinModuleGroup.firstBottom);

        var newModuleGroup = ModuleGroup(
            modules: {PositionWithinModuleGroup.firstBottom: module},
            direction: moduleGroup.direction,
            destination: moduleGroup.destination,
            position: AtModuleGroupPlace(forkLiftTruck.moduleGroupPlace));
        forkLiftTruck.area.moduleGroups.add(newModuleGroup);
        forkLiftTruck.moduleGroupPlace.moduleGroup = newModuleGroup;
      }
    }

    moduleGroup.position =
        BetweenModuleGroupPlaces.forModuleOutLink(forkLiftTruck.modulesOut);
    moduleGroup.loadedOnToSystem();
  }

  @override
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) {
    if (transportCompleted) {
      if (_putSecondModuleOnConveyor(forkLiftTruck)) {
        return WaitingForEmptyConveyor(); //PutModuleGroupOnConveyor();
      } else {
        return GetModuleGroupFromTruck();
      }
    }
    return null;
  }

  bool _putSecondModuleOnConveyor(LoadingForkLiftTruck forkLiftTruck) {
    var moduleGroup = forkLiftTruck.moduleGroupPlace.moduleGroup;
    return forkLiftTruck.loadsSingleModule &&
        moduleGroup != null &&
        moduleGroup.numberOfModules == 1 &&
        forkLiftTruck.modulesOut.linkedTo!.canFeedIn();
  }

  /// called by [ModuleTransport.forModuleOutLink()]
  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}
