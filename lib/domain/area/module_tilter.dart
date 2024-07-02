// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_tilter.dart';
import 'package:user_command/user_command.dart';

import 'object_details.dart';
import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

class ModuleTilter extends StateMachine implements PhysicalSystem {
  final LiveBirdHandlingArea area;
  final bool tiltToLeft;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];
  late final shape = ModuleTilterShape(this);

  final Duration checkIfEmptyDuration;
  final Duration tiltForwardDuration;
  final Duration tiltBackDuration;
  final Duration inFeedDuration;
  final Duration outFeedDuration;

  late final CompassDirection doorDirection = (tiltToLeft
          ? const CompassDirection.west()
          : const CompassDirection.east())
      .rotate(area.layout.rotationOf(this).degrees);

  ModuleTilter({
    required this.area,
    required this.tiltToLeft,
    this.checkIfEmptyDuration = const Duration(seconds: 18),
    Duration? inFeedDuration,
    this.tiltForwardDuration = const Duration(seconds: 9),
    this.tiltBackDuration = const Duration(seconds: 5),
    Duration? outFeedDuration,
  })  : inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
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
      .appendProperty('moduleGroup', moduleGroupPosition.moduleGroup);

  @override
  late String name = 'ModuleTilter$seqNr';

  late final moduleGroupPosition = ModuleGroupPlace(
      system: this,
      moduleGroups: area.moduleGroups,
      offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter);

  late final modulesIn = ModuleGroupInLink(
      position: moduleGroupPosition,
      offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupInLink,
      directionToOtherLink: const CompassDirection.south(),
      inFeedDuration: inFeedDuration,
      canFeedIn: () => currentState is WaitToFeedIn);

  late final modulesOut = ModuleGroupOutLink(
      position: moduleGroupPosition,
      offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupOutLink,
      directionToOtherLink: const CompassDirection.north(),
      outFeedDuration: outFeedDuration,
      durationUntilCanFeedOut: () =>
          currentState is WaitToFeedOut ? Duration.zero : unknownDuration);

  late final birdsOut = BirdsOutLink(
    system: this,
    offsetFromCenterWhenFacingNorth: shape.centerToBirdsOutLink,
    directionToOtherLink:
        tiltToLeft ? CompassDirection.west() : CompassDirection.east(),
  );

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn,
    modulesOut,
    birdsOut,
  ];

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;
}

class CheckIfEmpty extends DurationState<ModuleTilter> {
  @override
  String get name => 'CheckIfEmpty';

  CheckIfEmpty()
      : super(
            durationFunction: (tilter) => tilter.checkIfEmptyDuration,
            nextStateFunction: (tilter) => WaitToFeedIn());
}

class WaitToFeedIn extends State<ModuleTilter>
    implements ModuleTransportStartedListener {
  bool transportStarted = false;

  @override
  String get name => 'WaitToFeedIn';

  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (transportStarted) {
      return FeedIn();
    }
    return null;
  }

  @override
  void onModuleTransportStarted() {
    transportStarted = true;
  }
}

class FeedIn extends State<ModuleTilter>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedIn';

  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (transportCompleted) {
      return WaitToTilt();
    }
    return null;
  }

  @override
  void onCompleted(ModuleTilter tilter) {
    _verifyModule(tilter);
  }

  void _verifyModule(ModuleTilter tilter) {
    var moduleGroup = tilter.moduleGroupPosition.moduleGroup!;
    // TODO add later. The tilter was missuesed because as a drawer inloader. Fix when we have one.
    // if (moduleGroup.moduleFamily.compartmentType!=CompartmentType.doorOnOneSide) {
    //   throw ('In correct container type of the $ModuleGroup that was fed in to ${tilter.name}');
    // }
    if (moduleGroup.moduleFamily.compartmentType.hasDoor &&
        moduleGroup.direction.rotate(-90) != tilter.doorDirection) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${tilter.name}');
    }
  }

  @override
  void onModuleTransportCompleted() {
    transportCompleted = true;
  }
}

class WaitToTilt extends State<ModuleTilter> {
  @override
  String get name => 'WaitToTilt';

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
    var moduleGroup = tilter.moduleGroupPosition.moduleGroup!;
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
            nextStateFunction: (tilter) => WaitToFeedOut());
}

class WaitToFeedOut extends State<ModuleTilter> {
  @override
  String get name => 'WaitToFeedOut';

  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_neighborCanFeedIn(tilter) && !_moduleGroupAtDestination(tilter)) {
      return FeedOut();
    }
    return null;
  }

  bool _moduleGroupAtDestination(ModuleTilter tilter) =>
      tilter.moduleGroupPosition.moduleGroup!.destination == tilter;

  _neighborCanFeedIn(ModuleTilter tilter) =>
      tilter.modulesOut.linkedTo!.canFeedIn();
}

class FeedOut extends State<ModuleTilter>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOut';

  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleTilter tilter) {
    transportedModuleGroup = tilter.moduleGroupPosition.moduleGroup!;
    transportedModuleGroup!.position =
        BetweenModuleGroupPlaces.forModuleOutLink(tilter.modulesOut);
  }

  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (transportCompleted) {
      return WaitToFeedIn();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted() {
    transportCompleted = true;
  }
}
