// ignore_for_file: avoid_renaming_method_parameters

import 'dart:math';

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/speed_profile.dart';
import 'package:meyn_lbh_simulation/domain/area/state_machine.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/system/vehicle/fork_lift_truck.presentation.dart';
import 'package:meyn_lbh_simulation/system/vehicle/route/fork_lift_truck_route.domain.dart';
import 'package:meyn_lbh_simulation/system/vehicle/route/route.domain.dart';
import 'package:meyn_lbh_simulation/system/vehicle/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/system/vehicle/vehicle.domain.dart';
import 'package:user_command/user_command.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class LoadingForkLiftTruck extends StateMachine implements Vehicle {
  final LiveBirdHandlingArea area;
  final bool loadsSingleModule;

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
    this.loadsSingleModule = false,
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
  int get moduleGroupStartDirection =>
      moduleBirdExitDirection == ModuleBirdExitDirection.left ? 0 : 180;

  ModuleGroup createModuleGroup() {
    var truckRow = _randomTruckRow();

    var moduleGroupDirection = routes.turnPointToInToTruck.lastDirection
        .rotate(moduleGroupStartDirection);
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
      place: moduleGroupPlaceOnForks,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: 0, yInMeters: sizeWhenFacingNorth.yInMeters * -0.5),
      directionToOtherLink: const CompassDirection.north(),
      durationUntilCanFeedOut: () => unknownDuration);

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesOut
  ];

  @override
  String name = 'LoadingForkLiftTruck';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late ModuleGroupPlace moduleGroupPlaceOnForks = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToModuleGroupCenter,
  );
}

abstract class Drive extends State<LoadingForkLiftTruck> {
  final State<LoadingForkLiftTruck> Function(LoadingForkLiftTruck forkLiftTruck)
      nextStateFunction;
  final SpeedProfile Function(LoadingForkLiftTruck forkLiftTruck)
      speedProfileFunction;
  final VehicleRoute Function(LoadingForkLiftTruck forkLiftTruck) routeFunction;
  Duration elapsed = Duration.zero;
  late VehicleRoute route;
  late Duration duration;
  bool atDestination = false;

  Drive(
      {required this.speedProfileFunction,
      required this.routeFunction,
      required this.nextStateFunction});

  @override
  void onStart(LoadingForkLiftTruck forkLiftTruck) {
    route = routeFunction(forkLiftTruck);
    var speedProfile = speedProfileFunction(forkLiftTruck);
    duration = speedProfile.durationOfDistance(route.lengthInMeters);
    super.onStart(forkLiftTruck);
  }

  @override
  State<LoadingForkLiftTruck>? nextState(LoadingForkLiftTruck forkLiftTruck) {
    if (atDestination) {
      return nextStateFunction(forkLiftTruck);
    } else {
      return null;
    }
  }

  @override
  void onUpdateToNextPointInTime(
      LoadingForkLiftTruck forkLiftTruck, Duration jump) {
    if (!atDestination) {
      elapsed += jump;
      if (elapsed >= duration) {
        atDestination = true;
      }

      var traveledInMeters = route.lengthInMeters *
          elapsed.inMilliseconds /
          duration.inMilliseconds;
      var centerToAxcelCenterInMeters =
          forkLiftTruck.shape.centerToAxcelCenterInMeters;
      var frontAxcelPosition = route.pointAlongRoute(traveledInMeters +
          (centerToAxcelCenterInMeters * route.vehicleDirection.sign * -1));
      var backAxcelPosition = route.pointAlongRoute(traveledInMeters +
          (centerToAxcelCenterInMeters * route.vehicleDirection.sign));

      // var betweenAxcels = backAxcelPosition - frontAxcelPosition;
      // var centerPosition = frontAxcelPosition + betweenAxcels * 0.5;

      var betweenAxcels = backAxcelPosition - frontAxcelPosition;
      var centerPosition = (backAxcelPosition + frontAxcelPosition) * 0.5;

      forkLiftTruck.position = FixedAreaPosition(centerPosition);
      var radians = betweenAxcels.directionInRadians;
      forkLiftTruck.direction = CompassDirection(radians * 180 ~/ pi);

      if (forkLiftTruck.moduleGroupPlaceOnForks.moduleGroup != null) {
        var moduleGroup = forkLiftTruck.moduleGroupPlaceOnForks.moduleGroup!;
        moduleGroup.direction = forkLiftTruck.direction
            .rotate(forkLiftTruck.moduleGroupStartDirection);
      }
    }
  }
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

class DriveIntoTruck extends Drive {
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
    var place = forkLiftTruck.moduleGroupPlaceOnForks;
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

class DriveModuleGroupFromTruckAndTurn extends Drive {
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

class DriveToBeforeConveyor extends Drive {
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

class DriveModuleGroupAboveConveyor extends Drive {
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
    var moduleGroup = forkLiftTruck.moduleGroupPlaceOnForks.moduleGroup!;
    // TODO if (moduleGroup.numberOfStacks > 1) {
    //   throw Exception('$name can only feed in a single stack at a time!');
    // }
    if (forkLiftTruck.modulesOut.linkedTo!.system is! ModuleLoadingConveyor) {
      throw Exception('$name must be linked to a ModuleLoadingConveyor!');
    }
    forkLiftTruck.moduleGroupPlaceOnForks.moduleGroup = null;
    var moduleLoadingConveyor =
        forkLiftTruck.modulesOut.linkedTo!.system as ModuleLoadingConveyor;
    moduleLoadingConveyor.moduleGroupPlace.moduleGroup = moduleGroup;
    moduleGroup.position =
        AtModuleGroupPlace(moduleLoadingConveyor.moduleGroupPlace);
  }
}

class DriveOutOfModuleGroupOnConveyor extends Drive {
  @override
  final String name = 'DriveOutOfModuleGroupOnConveyor';

  DriveOutOfModuleGroupOnConveyor()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.aboveConveyorToBeforeConveyor,
            nextStateFunction: (forkLiftTruck) =>
                needToPickUpTopModule(forkLiftTruck)
                    ? LiftToTopModuleBeforeModuleConveyor()
                    : WaitToFeedOut());

  static bool needToPickUpTopModule(LoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.loadsSingleModule &&
      forkLiftTruck.moduleGroupPlaceOnForks.moduleGroup!.isStacked;
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

class DriveInTopModuleGroupOnConveyor extends Drive {
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
        forkLiftTruck.moduleGroupPlaceOnForks.moduleGroup!;
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
        position: AtModuleGroupPlace(forkLiftTruck.moduleGroupPlaceOnForks));

    moduleGroups.add(moduleGroupOnForks);
    forkLiftTruck.moduleGroupPlaceOnForks.moduleGroup = moduleGroupOnForks;

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
      forkLiftTruck.moduleGroupPlaceOnForks.moduleGroup != null;

  bool moduleLoadingConveyorCanFeedIn(LoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.modulesOut.linkedTo!.canFeedIn();

  ModuleLoadingConveyor moduleLoadingConveyor(
          LoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.modulesOut.linkedTo!.system as ModuleLoadingConveyor;
}

class DriveFromBeforeConveyorAndTurn extends Drive {
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
