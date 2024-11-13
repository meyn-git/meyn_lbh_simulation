// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/speed_profile.dart';
import 'package:meyn_lbh_simulation/domain/area/state_machine.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/system/module_unloading_conveyor/module_unloading_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/system/vehicle/unloading_fork_lift_truck.domain.dart';
import 'package:user_command/user_command.dart';

class ModuleUnLoadingConveyor extends StateMachine
    implements ModuleUnLoadingConveyorInterface {
  final double lengthInMeters;
  final SpeedProfile speedProfile;
  @override
  final LiveBirdHandlingArea area;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  late final shape = ModuleUnLoadingConveyorShape(this);

  static const double defaultLengthInMeters = 3.75;

  ModuleUnLoadingConveyor({
    required this.area,
    SpeedProfile? speedProfile,
    this.lengthInMeters = defaultLengthInMeters,
  })  : speedProfile =
            speedProfile ?? area.productDefinition.speedProfiles.moduleConveyor,
        super(
          initialState: CheckIfEmpty(),
        );

  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleInLink,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, speedProfile),
    canFeedIn: () => currentState is WaitingToFeedIn,
  );

  @override
  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleOutLink,
    directionToOtherLink: const CompassDirection.north(),
    durationUntilCanFeedOut: () =>
        currentState is WaitingUntilUnloadedByForkLiftTruck?
            ? Duration.zero
            : unknownDuration,
  );

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn,
    modulesOut
  ];

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late String name = 'ModuleUnLoadingConveyor$seqNr';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  @override
  late final ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToModuleGroupPlace,
  );

  @override
  void moduleGroupFreeFromForkLiftTruck() {
    if (currentState is WaitingUntilUnloadedByForkLiftTruck) {
      (currentState as WaitingUntilUnloadedByForkLiftTruck)
          .freeFromForkLiftTruck = true;
    }
  }
}

class CheckIfEmpty extends DurationState<ModuleUnLoadingConveyor> {
  CheckIfEmpty()
      : super(
            durationFunction: (moduleConveyor) => moduleConveyor.speedProfile
                .durationOfDistance(moduleConveyor.lengthInMeters * 1.5),
            nextStateFunction: (moduleConveyor) => WaitingToFeedIn());

  @override
  String get name => 'CheckIfEmpty';
}

class WaitingToFeedIn extends State<ModuleUnLoadingConveyor>
    implements ModuleTransportStartedListener {
  bool started = false;

  @override
  String get name => 'WaitingToFeedIn';

  @override
  State<ModuleUnLoadingConveyor>? nextState(
          ModuleUnLoadingConveyor moduleConveyor) =>
      started ? FeedIn() : null;

  @override
  void onModuleTransportStarted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    started = true;
  }
}

class FeedIn extends State<ModuleUnLoadingConveyor>
    implements ModuleTransportCompletedListener {
  bool completed = false;

  @override
  final String name = 'FeedIn';

  @override
  State<ModuleUnLoadingConveyor>? nextState(
          ModuleUnLoadingConveyor stateMachine) =>
      completed ? WaitingUntilUnloadedByForkLiftTruck() : null;

  @override
  void onModuleTransportCompleted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    completed = true;
  }
}

class WaitingUntilUnloadedByForkLiftTruck
    extends State<ModuleUnLoadingConveyor> {
  bool freeFromForkLiftTruck = false;

  @override
  String get name => 'WaitingUntilUnloadedByForkLiftTruck';

  @override
  State<ModuleUnLoadingConveyor>? nextState(
          ModuleUnLoadingConveyor moduleConveyor) =>
      freeFromForkLiftTruck ? WaitingToFeedIn() : null;
}
