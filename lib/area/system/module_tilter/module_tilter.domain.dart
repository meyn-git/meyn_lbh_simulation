// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module_variant_builder.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter.presentation.dart';
import 'package:user_command/user_command.dart';

import '../../object_details.domain.dart';
import '../../area.domain.dart';
import '../../module/module.domain.dart';
import '../state_machine.domain.dart';

class ModuleTilter extends StateMachine implements PhysicalSystem {
  final LiveBirdHandlingArea area;
  final Direction tiltDirection;

  Duration? durationPerModule;

  Durations durationsPerModule = Durations(maxSize: 8);

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];
  late final ModuleTilterShape shape = ModuleTilterShape(this);

  final Duration tiltForwardDuration;
  final Duration tiltBackDuration;
  final SpeedProfile conveyorSpeedProfile;

  late final CompassDirection doorDirection =
      (tiltDirection == Direction.counterClockWise
              ? const CompassDirection.west()
              : const CompassDirection.east())
          .rotate(area.layout.rotationOf(this).degrees);

  ModuleTilter({
    required this.area,
    required this.tiltDirection,
    SpeedProfile? conveyorSpeedProfile,
    this.tiltForwardDuration = const Duration(seconds: 9),
    this.tiltBackDuration = const Duration(seconds: 5),
    Duration? outFeedDuration,
  })  : conveyorSpeedProfile = conveyorSpeedProfile ??
            area.productDefinition.speedProfiles.moduleConveyor,
        super(
          initialState: CheckIfEmpty(),
        ) {
    _verifyDirections();
  }

  late final int seqNr = area.systems.seqNrOf(this);

  void _verifyDirections() {
    // TODO
    // if (inFeedDirection.isParallelTo(birdDirection)) {
    //   throw ArgumentError(
    //       "$LiveBirdHandlingArea error: $name: inFeedDirection and birdDirection must be perpendicular in layout configuration.");
    // }
  }

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendProperty('speed',
          '${durationsPerModule.averagePerHour.toStringAsFixed(1)} modules/hour')
      .appendProperty('moduleGroup', moduleGroupPlace.moduleGroup);

  @override
  late String name = 'ModuleTilter$seqNr';

  late final moduleGroupPlace = ModuleGroupPlace(
      system: this,
      offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter);

  late final modulesIn = ModuleGroupInLink<PhysicalSystem>(
      place: moduleGroupPlace,
      offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupInLink,
      directionToOtherLink: const CompassDirection.south(),
      transportDuration: (inLink) =>
          moduleTransportDuration(inLink, conveyorSpeedProfile),
      feedInSingleStack: true,
      canFeedIn: () =>
          SimultaneousFeedOutFeedInModuleGroup.canFeedIn(currentState));

  late final modulesOut = ModuleGroupOutLink(
      place: moduleGroupPlace,
      offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupOutLink,
      directionToOtherLink: const CompassDirection.north(),
      durationUntilCanFeedOut: () =>
          SimultaneousFeedOutFeedInModuleGroup.durationUntilCanFeedOut(
              currentState));

  late final birdsOut = BirdsOutLink(
    system: this,
    offsetFromCenterWhenFacingNorth: shape.centerToBirdsOutLink,
    directionToOtherLink: tiltDirection == Direction.counterClockWise
        ? const CompassDirection.west()
        : const CompassDirection.east(),
  );

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn,
    modulesOut,
    birdsOut,
  ];

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    if (durationPerModule != null) {
      durationPerModule = durationPerModule! + jump;
    }
  }

  void onEndOfCycle() {
    durationsPerModule.add(durationPerModule);
    durationPerModule = Duration.zero;
  }

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;
}

class CheckIfEmpty extends DurationState<ModuleTilter> {
  @override
  String get name => 'CheckIfEmpty';

  CheckIfEmpty()
      : super(
            durationFunction: (tilter) =>
                tilter.conveyorSpeedProfile
                    .durationOfDistance(tilter.shape.yInMeters) *
                1.5,
            nextStateFunction: (tilter) => SimultaneousFeedOutFeedInModuleGroup(
                modulesIn: tilter.modulesIn,
                modulesOut: tilter.modulesOut,
                stateWhenCompleted: WaitToTilt()));
}

class WaitToTilt extends State<ModuleTilter> {
  @override
  String get name => 'WaitToTilt';

  @override
  void onStart(ModuleTilter tilter) {
    _verifyModuleGroup(tilter);
  }

  void _verifyModuleGroup(ModuleTilter tilter) {
    var moduleGroup = tilter.moduleGroupPlace.moduleGroup!;
    if (moduleGroup.modules.length > 1) {
      throw Exception('${tilter.name}: can only process one container');
    }
    if (moduleGroup.compartment is! CompartmentWithDoor) {
      throw Exception('${tilter.name}: can only unload containers with doors');
    }
    if (moduleGroup.direction.rotate(-90) != tilter.doorDirection) {
      throw Exception('${tilter.name}: In correct door direction of '
          '$ModuleGroup');
    }
  }

  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (tilter.birdsOut.linkedTo!.canReceiveBirds()) {
      return TiltForward();
    }
    return null;
  }
}

class TiltForward extends DurationState<ModuleTilter> {
  @override
  String get name => 'TiltForward';

  TiltForward()
      : super(
            durationFunction: (tilter) => tilter.tiltForwardDuration,
            nextStateFunction: (tilter) => TiltBack());

  @override
  void onCompleted(ModuleTilter tilter) {
    var moduleGroup = tilter.moduleGroupPlace.moduleGroup!;
    tilter.birdsOut.linkedTo!.transferBirds(moduleGroup.numberOfBirds);
    moduleGroup.unloadBirds();
  }
}

class TiltBack extends DurationState<ModuleTilter> {
  @override
  String get name => 'TiltBack';

  TiltBack()
      : super(
            durationFunction: (tilter) => tilter.tiltBackDuration,
            nextStateFunction: (tilter) => SimultaneousFeedOutFeedInModuleGroup(
                  modulesIn: tilter.modulesIn,
                  modulesOut: tilter.modulesOut,
                  stateWhenCompleted: WaitToTilt(),
                ));

  @override
  void onCompleted(ModuleTilter tilter) {
    super.onCompleted(tilter);
    tilter.onEndOfCycle();
  }
}
