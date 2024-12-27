// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/fork_lift_truck.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/fork_lift_truck_route.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.domain.dart';
import 'package:user_command/user_command.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class UnLoadingForkLiftTruck extends VehicleStateMachine
    implements LinkedSystem {
  final LiveBirdHandlingArea area;
  final Duration pickUpOrLowerModuleGroupDuration;
  final Duration liftUpOrDown1ModuleDuration;
  final SpeedProfile driveSpeedProfile;
  final Direction turnAtConveyor;
  final Direction turnAtTruck;
  final bool stackModules;

  @override
  final ForkLiftTruckShape shape = ForkLiftTruckShape();
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  @override
  CompassDirection direction = const CompassDirection.north();

  @override
  int moduleGroupStartRotationInDegrees = 0;

  late ForkLiftTruckRoutes routes =
      routes = ForkLiftTruckRoutes.forUnLoadingForkLiftTruck(
    forkLiftTruck: this,
    turnAtConveyor: turnAtConveyor,
    turnAtTruck: turnAtTruck,
  );

  @override
  late AreaPosition position = FixedAreaPosition(OffsetInMeters.zero);

  UnLoadingForkLiftTruck({
    required this.area,
    this.pickUpOrLowerModuleGroupDuration = const Duration(seconds: 5),
    this.liftUpOrDown1ModuleDuration = const Duration(seconds: 7),
    this.stackModules = false,
    this.turnAtConveyor = Direction.counterClockWise,
    this.turnAtTruck = Direction.clockWise,
    this.driveSpeedProfile = const ForkLiftSpeedProfile(),
  }) : super(initialState: Initialize());

  late ModuleGroupInLink modulesIn = ModuleGroupInLink(
      place: moduleGroupPlaces.first,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: 0, yInMeters: sizeWhenFacingNorth.yInMeters * -0.5),
      directionToOtherLink: const CompassDirection.north(),
      transportDuration: (_) => Duration.zero,
      canFeedIn: () => currentState is WaitUntilConveyorCanFeedOut);

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
    modulesIn
  ];

  @override
  String name = 'UnLoadingForkLiftTruck';

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

abstract class ModuleUnLoadingConveyorInterface implements LinkedSystem {
  ModuleGroupPlace get moduleGroupPlace;

  LiveBirdHandlingArea get area;

  ModuleGroupOutLink get modulesOut;

  void moduleGroupFreeFromForkLiftTruck();
}

/// This state is needed because we can not start with a [Drive] state
/// because  [LiveBirdHandlingArea.layout] is not yet initilized.
class Initialize extends State<UnLoadingForkLiftTruck> {
  @override
  final String name = 'Initialize';

  @override
  State<UnLoadingForkLiftTruck>? nextState(
          UnLoadingForkLiftTruck forkLiftTruck) =>
      DriveToBeforeConveyor();
}

class DriveToBeforeConveyor extends Drive<UnLoadingForkLiftTruck> {
  DriveToBeforeConveyor()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.turnPointToBeforeConveyor,
            nextStateFunction: (forkLiftTruck) =>
                WaitUntilConveyorCanFeedOut());

  @override
  final String name = 'DriveToBeforeConveyor';
}

class WaitUntilConveyorCanFeedOut extends State<UnLoadingForkLiftTruck> {
  @override
  final String name = 'WaitUntilConveyorCanFeedOut';

  @override
  State<UnLoadingForkLiftTruck>? nextState(
          UnLoadingForkLiftTruck forkLiftTruck) =>
      moduleConveyorIsWaitingToFeedOut(forkLiftTruck)
          ? DriveInToModuleGroupOnConveyor()
          : null;

  bool moduleConveyorIsWaitingToFeedOut(UnLoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.modulesIn.linkedTo!.durationUntilCanFeedOut() ==
      Duration.zero;
}

class DriveInToModuleGroupOnConveyor extends Drive<UnLoadingForkLiftTruck> {
  @override
  final String name = 'DriveInToModuleGroupOnConveyor';

  DriveInToModuleGroupOnConveyor()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.beforeConveyorToAboveConveyor,
            nextStateFunction: (forkLiftTruck) =>
                needToStackModules(forkLiftTruck)
                    ? LiftModuleGroupFromConveyorToStackModules()
                    : LiftModuleGroupFromConveyorToDriveToTruck());

  static bool needToStackModules(UnLoadingForkLiftTruck forkLiftTruck) {
    var moduleGroupOnUnloadingConveyor =
        forkLiftTruck.modulesIn.linkedTo!.place.moduleGroup;
    return forkLiftTruck.stackModules &&
        !moduleGroupOnUnloadingConveyor!.isStacked;
  }

  @override
  void onCompleted(UnLoadingForkLiftTruck forkLiftTruck) {
    var moduleUnLoadingConveyor = forkLiftTruck.modulesIn.linkedTo!.system
        as ModuleUnLoadingConveyorInterface;
    forkLiftTruck.moduleGroupStartRotationInDegrees = moduleUnLoadingConveyor
        .moduleGroupPlace.moduleGroup!.direction
        .rotate(-forkLiftTruck.area.layout.rotationOf(forkLiftTruck).degrees)
        .degrees;
  }
}

class LiftModuleGroupFromConveyorToDriveToTruck
    extends DurationState<UnLoadingForkLiftTruck> {
  @override
  final String name = 'LiftModuleGroupFromConveyorToDriveToTruck';

  LiftModuleGroupFromConveyorToDriveToTruck()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.pickUpOrLowerModuleGroupDuration,
            nextStateFunction: (_) => DriveFromAboveConveyorToBeforeConveyor());

  @override
  void onCompleted(UnLoadingForkLiftTruck forkLiftTruck) {
    super.onCompleted(forkLiftTruck);
    moveModuleGroupFromConveyorToForks(forkLiftTruck);
  }

  void moveModuleGroupFromConveyorToForks(
      UnLoadingForkLiftTruck forkLiftTruck) {
    var moduleUnLoadingConveyor = forkLiftTruck.modulesIn.linkedTo!.system
        as ModuleUnLoadingConveyorInterface;
    var moduleGroup = moduleUnLoadingConveyor.moduleGroupPlace.moduleGroup!;
    // TODO if (moduleGroup.numberOfStacks > 1) {
    //   throw Exception('$name can only feed in a single stack at a time!');
    // }
    if (forkLiftTruck.modulesIn.linkedTo!.system
        is! ModuleUnLoadingConveyorInterface) {
      throw Exception(
          '$name must be linked to a ModuleUnLoadingConveyorInterface!');
    }
    moduleUnLoadingConveyor.moduleGroupPlace.moduleGroup = null;

    forkLiftTruck.moduleGroupPlaces.first.moduleGroup = moduleGroup;

    moduleGroup.position =
        AtModuleGroupPlace(forkLiftTruck.moduleGroupPlaces.first);
  }
}

class DriveFromAboveConveyorToBeforeConveyor
    extends Drive<UnLoadingForkLiftTruck> {
  @override
  final String name = 'DriveModuleGroupFromConveyor';

  DriveFromAboveConveyorToBeforeConveyor()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.aboveConveyorToBeforeConveyor,
            nextStateFunction: (forkLiftTruck) =>
                DriveFromBeforeConveyorAndTurn());

  ModuleUnLoadingConveyorInterface moduleUnLoadingConveyor(
          UnLoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.modulesIn.linkedTo!.system
          as ModuleUnLoadingConveyorInterface;

  @override
  void onCompleted(UnLoadingForkLiftTruck forkLiftTruck) {
    moduleUnLoadingConveyor(forkLiftTruck).moduleGroupFreeFromForkLiftTruck();
  }
}

class DriveFromBeforeConveyorAndTurn extends Drive<UnLoadingForkLiftTruck> {
  @override
  final String name = 'DriveFromBeforeConveyorAndTurn';

  DriveFromBeforeConveyorAndTurn()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.beforeConveyorToTurnPoint,
            nextStateFunction: (_) => WaitForTruck());
}

class WaitForTruck extends State<UnLoadingForkLiftTruck> {
  @override
  final String name = "WaitOnTruck";

  @override
  State<UnLoadingForkLiftTruck>? nextState(
      UnLoadingForkLiftTruck forkLiftTruck) {
    return DriveModuleGroupToTruck();
  }
}

class DriveModuleGroupToTruck extends Drive<UnLoadingForkLiftTruck> {
  DriveModuleGroupToTruck()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.turnPointToInToTruck,
            nextStateFunction: (_) => LowerModuleGroupOnTruck());

  @override
  final String name = 'DriveModuleGroupToTruck';
}

class LowerModuleGroupOnTruck extends DurationState<UnLoadingForkLiftTruck> {
  LowerModuleGroupOnTruck()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.pickUpOrLowerModuleGroupDuration,
            nextStateFunction: (forkLiftTruck) => DriveFromTruckAndTurn());

  @override
  final String name = 'LowerModuleGroupOnTruck';

  @override
  void onCompleted(UnLoadingForkLiftTruck forkLiftTruck) {
    removeModuleGroup(forkLiftTruck);
  }

  void removeModuleGroup(UnLoadingForkLiftTruck forkLiftTruck) {
    var moduleGroups = forkLiftTruck.area.moduleGroups;
    var moduleGroup = forkLiftTruck.moduleGroupPlaces.first.moduleGroup!;
    forkLiftTruck.moduleGroupPlaces.first.moduleGroup = null;
    moduleGroups.remove(moduleGroup);
  }
}

class DriveFromTruckAndTurn extends Drive<UnLoadingForkLiftTruck> {
  DriveFromTruckAndTurn()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.inTruckToTurnPoint,
            nextStateFunction: (forkLiftTruck) => DriveToBeforeConveyor());

  @override
  final String name = 'DriveFromTruckAndTurn';
}

/// ************************ Module Stacking ************************

class LiftModuleGroupFromConveyorToStackModules
    extends DurationState<UnLoadingForkLiftTruck> {
  @override
  final String name = 'LiftModuleGroupFromConveyorToStackModules';

  LiftModuleGroupFromConveyorToStackModules()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.liftUpOrDown1ModuleDuration,
            nextStateFunction: (_) => WaitUntil2ndModuleIsFedIn());

  ModuleUnLoadingConveyorInterface moduleUnLoadingConveyor(
          UnLoadingForkLiftTruck forkLiftTruck) =>
      forkLiftTruck.modulesIn.linkedTo!.system
          as ModuleUnLoadingConveyorInterface;

  @override
  void onCompleted(UnLoadingForkLiftTruck forkLiftTruck) {
    moduleUnLoadingConveyor(forkLiftTruck).moduleGroupFreeFromForkLiftTruck();
  }
}

class WaitUntil2ndModuleIsFedIn extends State<UnLoadingForkLiftTruck>
    implements ModuleTransportCompletedListener {
  bool completed = false;

  @override
  final String name = 'WaitUntil2ndModuleIsFedIn';

  @override
  State<UnLoadingForkLiftTruck>? nextState(
          UnLoadingForkLiftTruck stateMachine) =>
      completed ? LowerModuleOnModuleGroupOnConveyor() : null;

  @override
  void onModuleTransportCompleted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    completed = true;
  }
}

class LowerModuleOnModuleGroupOnConveyor
    extends DurationState<UnLoadingForkLiftTruck> {
  @override
  final String name = 'LowerModuleOnModuleGroupOnConveyor';

  LowerModuleOnModuleGroupOnConveyor()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.pickUpOrLowerModuleGroupDuration,
            nextStateFunction: (_) => DriveOutOfTopModuleOnConveyor());
  @override
  void onCompleted(UnLoadingForkLiftTruck forkLiftTruck) {
    mergeModuleGroups(forkLiftTruck);
  }

  void mergeModuleGroups(UnLoadingForkLiftTruck forkLiftTruck) {
    var moduleGroupOnConveyor =
        forkLiftTruck.moduleGroupPlaces.first.moduleGroup!;
    if (moduleGroupOnConveyor.numberOfStacks > 1) {
      throw Exception('$name can only stack a single stack at a time!');
    }

    var moduleGroups = forkLiftTruck.area.moduleGroups;

    var moduleGroupOnForks = forkLiftTruck.moduleGroupPlaces.first.moduleGroup!;

    moduleGroupOnConveyor[PositionWithinModuleGroup.firstTop] =
        moduleGroupOnForks[PositionWithinModuleGroup.firstBottom]!;
    if (moduleGroupOnForks.keys
        .contains(PositionWithinModuleGroup.secondBottom)) {
      moduleGroupOnConveyor[PositionWithinModuleGroup.secondTop] =
          moduleGroupOnForks[PositionWithinModuleGroup.secondBottom]!;
    }
    moduleGroups.remove(moduleGroupOnForks);
  }
}

class DriveOutOfTopModuleOnConveyor extends Drive<UnLoadingForkLiftTruck> {
  @override
  final String name = 'DriveOutOfTopModuleOnConveyor';

  DriveOutOfTopModuleOnConveyor()
      : super(
            speedProfileFunction: (forkLiftTruck) =>
                forkLiftTruck.driveSpeedProfile,
            routeFunction: (forkLiftTruck) =>
                forkLiftTruck.routes.aboveConveyorToBeforeConveyor,
            nextStateFunction: (_) => LowerForksToBottomModule());
}

class LowerForksToBottomModule extends DurationState<UnLoadingForkLiftTruck> {
  @override
  final String name = 'LowerForksToBottomModule';

  LowerForksToBottomModule()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.liftUpOrDown1ModuleDuration,
            nextStateFunction: (_) => WaitUntilConveyorCanFeedOut());
}
