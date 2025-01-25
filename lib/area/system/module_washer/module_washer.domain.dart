// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.presentation.dart';
import 'package:user_command/user_command.dart';

class ModuleWasherConveyor extends StateMachine implements LinkedSystem {
  final double lengthInMeters;
  final LiveBirdHandlingArea area;
  final SpeedProfile conveyorSpeedProfile;
  static const double defaultLengthInMeters = 2.75;

  ModuleWasherConveyor({
    required this.area,
    SpeedProfile? conveyorSpeedProfile,
    this.lengthInMeters = defaultLengthInMeters,
  })  : conveyorSpeedProfile = conveyorSpeedProfile ??
            area.productDefinition.speedProfiles.moduleConveyor,
        super(initialState: CheckIfEmpty());

  @override
  late final String name = 'ModuleWasherConveyor$seqNr';

  late final seqNr = area.systems.seqNrOf(this);

  late final ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter,
  );

  late final modulesIn = ModuleGroupInLink<LinkedSystem>(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleInLink,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () =>
        SimultaneousFeedOutFeedInModuleGroup.canFeedIn(currentState),
  );

  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleOutLink,
    directionToOtherLink: const CompassDirection.north(),
    durationUntilCanFeedOut: () =>
        SimultaneousFeedOutFeedInModuleGroup.durationUntilCanFeedOut(
            currentState),
  );

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
    modulesIn,
    modulesOut
  ];

  late final ModuleWasherConveyorShape shape = ModuleWasherConveyorShape(this);

  bool get forceFeedOut => precedingNeighborWaitingToFeedOut(modulesIn);

  bool precedingNeighborWaitingToFeedOut(
      ModuleGroupInLink<LinkedSystem> modulesIn) {
    var precedingNeighbor = modulesIn.linkedTo!.system;
    if (precedingNeighbor is ModuleWasherConveyor) {
      // recursive call
      return precedingNeighborWaitingToFeedOut(precedingNeighbor.modulesIn);
    } else {
      return modulesIn.linkedTo!.durationUntilCanFeedOut() == Duration.zero;
    }
  }

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  @override
  late final SizeInMeters sizeWhenFacingNorth = shape.size;
}

class CheckIfEmpty extends DurationState<ModuleWasherConveyor> {
  CheckIfEmpty()
      : super(
            durationFunction: (moduleWasher) => moduleWasher
                .conveyorSpeedProfile
                .durationOfDistance(moduleWasher.lengthInMeters),
            nextStateFunction: (moduleWasher) =>
                SimultaneousFeedOutFeedInModuleGroup<ModuleWasherConveyor>(
                    modulesIn: moduleWasher.modulesIn,
                    modulesOut: moduleWasher.modulesOut,
                    stateWhenCompleted: Wash()));

  @override
  String get name => 'CheckIfEmpty';
}

class Wash extends State<ModuleWasherConveyor> {
  Duration? remainingDuration;

  @override
  final String name = "Wash";

  @override
  State<ModuleWasherConveyor>? nextState(ModuleWasherConveyor washer) =>
      feedOutAndFeedIn(washer)
          ? SimultaneousFeedOutFeedInModuleGroup(
              modulesIn: washer.modulesIn,
              modulesOut: washer.modulesOut,
              stateWhenCompleted: Wash())
          : null;

  bool feedOutAndFeedIn(ModuleWasherConveyor stateMachine) =>
      remainingDuration == Duration.zero || stateMachine.forceFeedOut;

  @override
  void onUpdateToNextPointInTime(ModuleWasherConveyor washer, Duration jump) {
    remainingDuration ??= durationOfTwoModules(washer);
    if (remainingDuration! > Duration.zero) {
      remainingDuration = remainingDuration! - jump;
    } else {
      remainingDuration = Duration.zero;
    }
  }

  Duration durationOfTwoModules(ModuleWasherConveyor washer) {
    var productDefinition = washer.area.productDefinition;
    var averageProductsPerModuleGroup =
        productDefinition.averageProductsPerModuleGroup;
    var lineSpeedInShacklesPerHour =
        productDefinition.lineSpeedInShacklesPerHour;
    var modulesPerHour =
        lineSpeedInShacklesPerHour / averageProductsPerModuleGroup;
    return Duration(
        microseconds:
            (const Duration(hours: 1).inMicroseconds / modulesPerHour).round() *
                2);
  }
}
