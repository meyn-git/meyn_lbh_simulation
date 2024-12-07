// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:user_command/user_command.dart';

class ModuleLoadingConveyor extends StateMachine
    implements ModuleLoadingConveyorInterface {
  final double lengthInMeters;
  final SpeedProfile speedProfile;
  @override
  final LiveBirdHandlingArea area;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  late final shape = ModuleLoadingConveyorShape(this);

  static const double defaultLengthInMeters = 3.75;

  ModuleLoadingConveyor({
    required this.area,
    SpeedProfile? speedProfile,
    this.lengthInMeters = defaultLengthInMeters,
  })  : speedProfile =
            speedProfile ?? area.productDefinition.speedProfiles.moduleConveyor,
        super(
          initialState: CheckIfEmpty(),
        );

  @override
  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleInLink,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, speedProfile),
    canFeedIn: () => currentState is WaitingToFeedIn,
  );

  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleOutLink,
    directionToOtherLink: const CompassDirection.north(),
    durationUntilCanFeedOut: () =>
        currentState is WaitingToFeedOut ? Duration.zero : unknownDuration,
  );

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
    modulesIn,
    modulesOut
  ];

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late String name = 'ModuleLoadingConveyor$seqNr';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  @override
  late final ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToModuleGroupPlace,
  );

  @override
  void moduleGroupFreeFromForkLiftTruck() {
    if (currentState is WaitingUntilFreeFromForkLiftTruck) {
      (currentState as WaitingUntilFreeFromForkLiftTruck)
          .freeFromForkLiftTruck = true;
    }
  }
}

class CheckIfEmpty extends DurationState<ModuleLoadingConveyor> {
  CheckIfEmpty()
      : super(
            durationFunction: (moduleConveyor) => moduleConveyor.speedProfile
                .durationOfDistance(moduleConveyor.lengthInMeters * 1.5),
            nextStateFunction: (moduleConveyor) => WaitingToFeedIn());

  @override
  String get name => 'CheckIfEmpty';
}

class WaitingToFeedIn extends State<ModuleLoadingConveyor> {
  @override
  String get name => 'WaitingToFeedIn';

  @override
  State<ModuleLoadingConveyor>? nextState(
          ModuleLoadingConveyor moduleConveyor) =>
      isLoaded(moduleConveyor) ? WaitingUntilFreeFromForkLiftTruck() : null;

  bool isLoaded(ModuleLoadingConveyor moduleConveyor) =>
      moduleConveyor.moduleGroupPlace.moduleGroup != null;
}

class WaitingUntilFreeFromForkLiftTruck extends State<ModuleLoadingConveyor> {
  bool freeFromForkLiftTruck = false;

  @override
  String get name => 'WaitingUntilFreeFromForkLiftTruck';

  @override
  State<ModuleLoadingConveyor>? nextState(
          ModuleLoadingConveyor moduleConveyor) =>
      freeFromForkLiftTruck ? WaitingToFeedOut() : null;
}

class WaitingToFeedOut extends State<ModuleLoadingConveyor> {
  @override
  String get name => 'WaitingToFeedOut';

  @override
  State<ModuleLoadingConveyor>? nextState(
          ModuleLoadingConveyor moduleConveyor) =>
      canFeedOut(moduleConveyor) ? FeedOut() : null;

  bool canFeedOut(ModuleLoadingConveyor moduleConveyor) =>
      moduleConveyor.modulesOut.linkedTo!.canFeedIn();
}

class FeedOut extends State<ModuleLoadingConveyor>
    implements ModuleTransportCompletedListener {
  bool completed = false;

  @override
  String get name => 'FeedOut';

  @override
  void onStart(ModuleLoadingConveyor moduleLoadingConveyor) {
    var moduleGroup = moduleLoadingConveyor.moduleGroupPlace.moduleGroup!;
    moduleGroup.position = BetweenModuleGroupPlaces.forModuleOutLink(
        moduleLoadingConveyor.modulesOut);
  }

  @override
  State<ModuleLoadingConveyor>? nextState(
          ModuleLoadingConveyor moduleConveyor) =>
      completed ? WaitingToFeedIn() : null;

  @override
  void onModuleTransportCompleted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces) {
    completed = true;
  }
}
