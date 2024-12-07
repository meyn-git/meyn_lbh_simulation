// ignore_for_file: avoid_renaming_method_parameters

import 'dart:math';

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_allocation.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/fork_lift_truck.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/fork_lift_truck_route.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.domain.dart';
import 'package:user_command/user_command.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class LoadingForkLiftTruck extends VehicleStateMachine implements LinkedSystem {
  final LiveBirdHandlingArea area;
  final bool unStackModules;

  /// TODO [moduleBirdExitDirection] should be detimined by the truck and how it is unloaded by the forklift
  final ModuleBirdExitDirection moduleBirdExitDirection;
  final Duration liftUpModuleGroupDuration;
  final Duration putModuleGroupOnConveyorDuration;
  final Duration liftUpOrDown1ModuleDuration;
  final SpeedProfile driveSpeedProfile;
  final Direction turnAtConveyor;
  final Direction turnAtTruck;
  late ForkLiftTruckRoutes routes =
      routes = ForkLiftTruckRoutes.forLoadingForkLiftTruck(
    forkLiftTruck: this,
    turnAtConveyor: turnAtConveyor,
    turnAtTruck: turnAtTruck,
  );

  @override
  late AreaPosition position = FixedAreaPosition(OffsetInMeters.zero);
  @override
  final ForkLiftTruckShape shape = ForkLiftTruckShape();
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  var sequenceNumber = 0;
  @override
  CompassDirection direction = const CompassDirection.north();

  @override
  LoadingForkLiftTruck({
    required this.area,
    required this.moduleBirdExitDirection,
    this.liftUpModuleGroupDuration = const Duration(seconds: 5),
    this.putModuleGroupOnConveyorDuration = const Duration(seconds: 10),
    this.liftUpOrDown1ModuleDuration = const Duration(seconds: 7),
    this.unStackModules = false,
    this.turnAtConveyor = Direction.counterClockWise,
    this.turnAtTruck = Direction.clockWise,
    this.driveSpeedProfile = const ForkLiftSpeedProfile(),
  }) : super(initialState: Initialize());

  /// Addition rotation based on [moduleBirdExitDirection]
  /// Note that:
  /// * if the doors are left the rotation should be 180 when beeing loaded
  ///   on the conveyor but the forklift truck rotates 180 from truck to
  ///   conveyor so the start position is 180+180=0
  /// * if the doors are right the rotation should be 0 when beeing loaded
  ///   on the conveyor but the forklift truck rotates 180 from truck to
  ///   conveyor so the start position is 0+180=180
  @override
  int get moduleGroupStartRotationInDegrees =>
      moduleBirdExitDirection == ModuleBirdExitDirection.left ? 0 : 180;

  ModuleGroup createModuleGroup() {
    var truckRow = _randomTruckRow();

    var moduleGroupDirection = routes.turnPointToInToTruck.lastDirection
        .rotate(moduleGroupStartRotationInDegrees);
    var moduleGroup = ModuleGroup(
        direction: moduleGroupDirection,
        destination: _findModuleGroupDestination(),
        position: _createModuleGroupPosition(),
        modules: truckRow.map((position, template) => MapEntry(
            position,
            Module(
              variant: template.variant,
              nrOfBirds: template.numberOfBirds,
              sequenceNumber: ++sequenceNumber,
            ))));
    area.moduleGroups.add(moduleGroup);
    return moduleGroup;
  }

  FixedAreaPosition _createModuleGroupPosition() {
    var moduleGroundSurface =
        area.productDefinition.truckRows.first.footprintOnSystem;
    var direction = routes.turnPointToInToTruck.lastDirection;
    var offset = shape.centerToFrontForkCariage
        .addY(moduleGroundSurface.yInMeters * -0.5)
        .rotate(direction);
    return FixedAreaPosition(routes.turnPointToInToTruck.points.last + offset);
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

  LinkedSystem _findModuleGroupDestination() {
    var casUnits = area.systems.whereType<ModuleCas>();
    var found = findSingleSystemOnRoute(casUnits as Iterable<LinkedSystem>);
    if (found != null) {
      return found;
    }

    var systemsThatAllocateToCasUnits = area.systems
        .whereType<ModuleCasAllocation>()
        .map((e) => e.allocationPlace.system as LinkedSystem);
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

  LinkedSystem? findSingleSystemOnRoute(Iterable<LinkedSystem> candidates) {
    LinkedSystem? found;
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
      place: moduleGroupPlaces.first,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: 0, yInMeters: sizeWhenFacingNorth.yInMeters * -0.5),
      directionToOtherLink: const CompassDirection.north(),
      durationUntilCanFeedOut: () => unknownDuration);

  /// used to link to [TruckRoutes]
  late ModuleGroupInLink modulesIn = ModuleGroupInLink(
      place: moduleGroupPlaces.first,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: 0, yInMeters: sizeWhenFacingNorth.yInMeters * -0.5),
      directionToOtherLink: const CompassDirection.south(),
      canFeedIn: () => true,
      transportDuration: (_) => Duration.zero);

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
    modulesOut,
    modulesIn
  ];

  @override
  String name = 'LoadingForkLiftTruck';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  @override
  late List<ModuleGroupPlace> moduleGroupPlaces = [
    ModuleGroupPlace(
      system: this,
      offsetFromCenterWhenSystemFacingNorth: shape.centerToModuleGroupCenter,
    )
  ];
}

abstract class ModuleLoadingConveyorInterface implements LinkedSystem {
  ModuleGroupPlace get moduleGroupPlace;

  LiveBirdHandlingArea get area;

  ModuleGroupInLink get modulesIn;

  void moduleGroupFreeFromForkLiftTruck();
}

/// This state is needed because we can not start with a [Drive] state
/// because  [LiveBirdHandlingArea.layout] is not yet initilized.
class Initialize extends State<LoadingForkLiftTruck> {
  @override
  final String name = 'Initialize';

  @override
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck stateMachine) =>
      WaitForTruck();
}

class WaitForTruck extends State<LoadingForkLiftTruck> {
  @override
  final String name = "WaitOnTruck";

  @override
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) {
    // TODO change logic when trucks drive in and out
    var moduleGroup = forkLiftTruck.createModuleGroup();
    return DriveIntoTruck(moduleGroup);
  }
}

class DriveIntoTruck extends Drive<LoadingForkLiftTruck> {
  final ModuleGroup moduleGroup;
  DriveIntoTruck(this.moduleGroup)
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.turnPointToInToTruck,
            nextStateFunction: (_) => LiftModuleGroupFromTruck());

  @override
  final String name = 'DriveIntoModuleGroupOnTruck';

  @override
  void onCompleted(LoadingForkLiftTruck forkLiftTruck) {
    var place = forkLiftTruck.moduleGroupPlaces.first;
    moduleGroup.position = AtModuleGroupPlace(place);
    place.moduleGroup = moduleGroup;
  }
}

class LiftModuleGroupFromTruck extends DurationState<LoadingForkLiftTruck> {
  LiftModuleGroupFromTruck()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.liftUpModuleGroupDuration,
            nextStateFunction: (forkLiftTruck) =>
                DriveModuleGroupFromTruckAndTurn());

  @override
  final String name = 'LiftModuleGroupFromTruck';
}

class DriveModuleGroupFromTruckAndTurn extends Drive<LoadingForkLiftTruck> {
  DriveModuleGroupFromTruckAndTurn()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.inTruckToTurnPoint,
            nextStateFunction: (forkLiftTruck) => DriveToBeforeConveyor());

  @override
  final String name = 'DriveModuleGroupFromTruckAndTurn';
}

class DriveToBeforeConveyor extends Drive<LoadingForkLiftTruck> {
  DriveToBeforeConveyor()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.turnPointToBeforeConveyor,
            nextStateFunction: (forkLiftTruck) => WaitUntilConveyorIsEmpty());

  @override
  final String name = 'DriveToBeforeConveyor';
}

class WaitUntilConveyorIsEmpty extends State<LoadingForkLiftTruck> {
  @override
  final String name = 'WaitUntilConveyorIsEmpty';

  @override
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) =>
      moduleConveyorIsWaitingToFeedIn(forkLiftTruck)
          ? DriveModuleGroupAboveConveyor()
          : null;

  bool moduleConveyorIsWaitingToFeedIn(LoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.modulesOut.linkedTo!.canFeedIn();
}

class DriveModuleGroupAboveConveyor extends Drive<LoadingForkLiftTruck> {
  @override
  final String name = 'DriveModuleGroupAboveConveyor';

  DriveModuleGroupAboveConveyor()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.beforeConveyorToAboveConveyor,
            nextStateFunction: (_) => LowerModuleGroupOnConveyor());
}

class LowerModuleGroupOnConveyor extends DurationState<LoadingForkLiftTruck> {
  @override
  final String name = 'LowerModuleGroupOnConveyor';

  LowerModuleGroupOnConveyor()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.putModuleGroupOnConveyorDuration,
            nextStateFunction: (_) => DriveOutOfModuleGroupOnConveyor());

  @override
  void onCompleted(LoadingForkLiftTruck forkLiftTruck) {
    super.onCompleted(forkLiftTruck);
    moveModuleGroupFromForksToModuleLoadingConveyor(forkLiftTruck);
  }

  void moveModuleGroupFromForksToModuleLoadingConveyor(
      LoadingForkLiftTruck forkLiftTruck) {
    var moduleGroup = forkLiftTruck.moduleGroupPlaces.first.moduleGroup!;
    // TODO if (moduleGroup.numberOfStacks > 1) {
    //   throw Exception('$name can only feed in a single stack at a time!');
    // }
    if (forkLiftTruck.modulesOut.linkedTo!.system
        is! ModuleLoadingConveyorInterface) {
      throw Exception(
          '$name must be linked to a ModuleLoadingConveyorInterface!');
    }
    forkLiftTruck.moduleGroupPlaces.first.moduleGroup = null;
    var moduleLoadingConveyor = forkLiftTruck.modulesOut.linkedTo!.system
        as ModuleLoadingConveyorInterface;
    moduleLoadingConveyor.moduleGroupPlace.moduleGroup = moduleGroup;
    moduleGroup.position =
        AtModuleGroupPlace(moduleLoadingConveyor.moduleGroupPlace);
  }
}

class DriveOutOfModuleGroupOnConveyor extends Drive<LoadingForkLiftTruck> {
  @override
  final String name = 'DriveOutOfModuleGroupOnConveyor';

  DriveOutOfModuleGroupOnConveyor()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.aboveConveyorToBeforeConveyor,
            nextStateFunction: (forkLiftTruck) =>
                needToUnstackModules(forkLiftTruck)
                    ? LiftToTopModuleBeforeModuleConveyor()
                    : WaitToFeedOut());

  static bool needToUnstackModules(LoadingForkLiftTruck forkLiftTruck) {
    var moduleLoadingConveyor = forkLiftTruck.modulesOut.linkedTo!.system
        as ModuleLoadingConveyorInterface;
    var moduleGroupOnLoadingConveyor =
        moduleLoadingConveyor.moduleGroupPlace.moduleGroup;
    return forkLiftTruck.unStackModules &&
        moduleGroupOnLoadingConveyor != null &&
        moduleGroupOnLoadingConveyor.isStacked;
  }
}

class LiftToTopModuleBeforeModuleConveyor
    extends DurationState<LoadingForkLiftTruck> {
  @override
  final String name = 'LiftToTopModuleBeforeModuleConveyor';

  LiftToTopModuleBeforeModuleConveyor()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.liftUpOrDown1ModuleDuration,
            nextStateFunction: (_) => DriveInTopModuleGroupOnConveyor());
}

class DriveInTopModuleGroupOnConveyor extends Drive<LoadingForkLiftTruck> {
  @override
  final String name = 'DriveInTopModuleGroupOnConveyor';

  DriveInTopModuleGroupOnConveyor()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.beforeConveyorToAboveConveyor,
            nextStateFunction: (_) => LiftUpTopModuleOnModuleConveyor());
}

class LiftUpTopModuleOnModuleConveyor
    extends DurationState<LoadingForkLiftTruck> {
  @override
  final String name = 'LiftUpTopModuleOnModuleConveyor';

  LiftUpTopModuleOnModuleConveyor()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.liftUpModuleGroupDuration,
            nextStateFunction: (_) => WaitToFeedOut());
  @override
  void onCompleted(LoadingForkLiftTruck forkLiftTruck) {
    var moduleGroupOnConveyor =
        forkLiftTruck.moduleGroupPlaces.first.moduleGroup!;
    if (moduleGroupOnConveyor.numberOfStacks > 1) {
      throw Exception('$name can only de-stack a single stack at a time!');
    }

    var moduleGroups = forkLiftTruck.area.moduleGroups;

    var moduleGroupOnForks = ModuleGroup(
        modules: {
          PositionWithinModuleGroup.firstBottom:
              moduleGroupOnConveyor[PositionWithinModuleGroup.firstTop]!
        },
        direction: moduleGroupOnConveyor.direction,
        destination: moduleGroupOnConveyor.destination,
        position: AtModuleGroupPlace(forkLiftTruck.moduleGroupPlaces.first));

    moduleGroups.add(moduleGroupOnForks);
    forkLiftTruck.moduleGroupPlaces.first.moduleGroup = moduleGroupOnForks;

    moduleGroupOnConveyor.remove(PositionWithinModuleGroup.firstTop);
    moduleGroupOnConveyor.position =
        BetweenModuleGroupPlaces.forModuleOutLink(forkLiftTruck.modulesOut);
  }
}

class WaitToFeedOut extends State<LoadingForkLiftTruck> {
  @override
  final String name = 'WaitToFeedOut';

  @override
  void onStart(LoadingForkLiftTruck forkLiftTruck) {
    moduleLoadingConveyor(forkLiftTruck).moduleGroupFreeFromForkLiftTruck();
  }

  @override
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) {
    if (topModuleOnForkLiftForks(forkLiftTruck)) {
      if (moduleLoadingConveyorCanFeedIn(forkLiftTruck)) {
        return LowerModuleGroupOnConveyor();
      } else {
        return null;
      }
    }
    return DriveFromBeforeConveyorAndTurn();
  }

  bool topModuleOnForkLiftForks(LoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.moduleGroupPlaces.first.moduleGroup != null;

  bool moduleLoadingConveyorCanFeedIn(LoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.modulesOut.linkedTo!.canFeedIn();

  ModuleLoadingConveyorInterface moduleLoadingConveyor(
          LoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.modulesOut.linkedTo!.system
          as ModuleLoadingConveyorInterface;
}

class DriveFromBeforeConveyorAndTurn extends Drive<LoadingForkLiftTruck> {
  @override
  final String name = 'DriveFromConveyorAndTurn';

  DriveFromBeforeConveyorAndTurn()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.beforeConveyorToTurnPoint,
            nextStateFunction: (_) => WaitForTruck());
}
