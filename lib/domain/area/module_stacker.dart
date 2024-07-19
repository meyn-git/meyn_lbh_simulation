// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_stacker.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module/module.dart';
import 'module_lift_position.dart';
import 'state_machine.dart';

class ModuleStacker extends StateMachine implements PhysicalSystem {
  final LiveBirdHandlingArea area;
  int nrOfModulesFeedingIn = 0;
  int currentHeightInCentiMeter;
  final Map<LiftPosition, int> heightsInCentiMeter;
  final int liftSpeedInCentiMeterPerSecond;
  final Duration supportsCloseDuration;
  final Duration supportsOpenDuration;
  final Duration inFeedDuration;
  final Duration outFeedDuration;
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  late final ModuleStackerShape shape = ModuleStackerShape();

  ModuleStacker({
    required this.area,
    this.supportsCloseDuration = const Duration(seconds: 3),
    this.supportsOpenDuration = const Duration(seconds: 3),
    Duration? inFeedDuration,
    Duration? outFeedDuration,
    this.currentHeightInCentiMeter = 150,
    this.liftSpeedInCentiMeterPerSecond = 30,
    this.heightsInCentiMeter = const {
      LiftPosition.inFeed: 150,
      LiftPosition.outFeed: 150,
      LiftPosition.pickUpTopModule: 150 + 150,
      LiftPosition.supportTopModule: 150 + 150 + 20,
    },
  })  : inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.stackerInFeedDuration,
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        super(
          initialState: MoveLift(LiftPosition.inFeed, WaitToFeedIn()),
        );

  late ModuleGroupPlace onConveyorPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter,
  );

  late ModuleGroupPlace onSupportsPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToSupportsCenter,
  );

  late ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: onConveyorPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupInLink,
    directionToOtherLink: const CompassDirection.south(),
    inFeedDuration: inFeedDuration,
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: onConveyorPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupOutLink,
    directionToOtherLink: const CompassDirection.north(),
    outFeedDuration: outFeedDuration,
    durationUntilCanFeedOut: () =>
        currentState is WaitToFeedOut ? Duration.zero : unknownDuration,
  );

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn,
    modulesOut
  ];

  @override
  late final String name = 'ModuleStacker$seqNr';

  late final seqNr = area.systems.seqNrOf(this);

  @override
  late final SizeInMeters sizeWhenFacingNorth = shape.size;
}

class MoveLift extends DurationState<ModuleStacker> {
  @override
  String get name => 'MoveLift';

  final LiftPosition goToPosition;

  MoveLift(this.goToPosition, State<ModuleStacker> nextState)
      : super(
            durationFunction: createDurationFunction(goToPosition),
            nextStateFunction: (stacker) => nextState);

  static Duration Function(ModuleStacker) createDurationFunction(
      LiftPosition goToPosition) {
    return (stacker) {
      var currentHeightInCentiMeter = stacker.currentHeightInCentiMeter;
      var goToHeightInCentiMeter = stacker.heightsInCentiMeter[goToPosition]!;
      var distanceInCentiMeter =
          (currentHeightInCentiMeter - goToHeightInCentiMeter).abs();
      Duration duration = Duration(
          milliseconds: (distanceInCentiMeter /
                  stacker.liftSpeedInCentiMeterPerSecond *
                  1000)
              .round());
      return duration;
    };
  }

  @override
  String toString() {
    return '$name to:${goToPosition.toString().replaceFirst('$LiftPosition.', '')} remaining:${remainingDuration.inSeconds}sec';
  }

  @override
  void onCompleted(ModuleStacker stacker) {
    stacker.currentHeightInCentiMeter =
        stacker.heightsInCentiMeter[goToPosition]!;
  }
}

class WaitToFeedIn extends State<ModuleStacker>
    implements ModuleTransportStartedListener {
  bool transportStarted = false;

  @override
  String get name => 'WaitToFeedIn';

  @override
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (transportStarted) {
      return FeedIn();
    }
    return null;
  }

  @override
  void onModuleTransportStarted(_) {
    transportStarted = true;
  }
}

class FeedIn extends State<ModuleStacker>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedIn';

  @override
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (transportCompleted) {
      if (stacker.onSupportsPlace.moduleGroup == null) {
        return MoveLift(LiftPosition.supportTopModule, CloseModuleSupports());
      } else {
        return MoveLift(LiftPosition.pickUpTopModule, OpenModuleSupports());
      }
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class CloseModuleSupports extends DurationState<ModuleStacker> {
  @override
  String get name => 'CloseModuleSupports';

  CloseModuleSupports()
      : super(
          durationFunction: (stacker) => stacker.supportsCloseDuration,
          nextStateFunction: (stacker) =>
              MoveLift(LiftPosition.inFeed, WaitToFeedIn()),
        );

  @override
  void onCompleted(ModuleStacker stacker) {
    var moduleGroup = stacker.onConveyorPlace.moduleGroup!;
    moduleGroup.position = AtModuleGroupPlace(stacker.onSupportsPlace);
    stacker.onConveyorPlace.moduleGroup = null;
    stacker.onSupportsPlace.moduleGroup = moduleGroup;
  }
}

class OpenModuleSupports extends DurationState<ModuleStacker> {
  @override
  String get name => 'OpenModuleSupports';

  OpenModuleSupports()
      : super(
          durationFunction: (stacker) => stacker.supportsOpenDuration,
          nextStateFunction: (stacker) =>
              MoveLift(LiftPosition.outFeed, WaitToFeedOut()),
        );

  @override
  void onCompleted(ModuleStacker stacker) {
    _mergeModuleGroup(stacker);
  }

  void _mergeModuleGroup(ModuleStacker stacker) {
    var moduleGroupOnConveyor = stacker.onConveyorPlace.moduleGroup!;
    var moduleGroupOnSupports = stacker.onSupportsPlace.moduleGroup!;
    moduleGroupOnConveyor[PositionWithinModuleGroup.firstTop] =
        moduleGroupOnSupports.modules.first;
    stacker.area.moduleGroups.remove(moduleGroupOnSupports);
    stacker.onSupportsPlace.moduleGroup = null;
  }
}

class WaitToFeedOut extends State<ModuleStacker> {
  @override
  String get name => 'WaitToFeedOut';

  @override
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (_neighborCanFeedIn(stacker) && !_moduleGroupAtDestination(stacker)) {
      return FeedOut();
    }
    return null;
  }

  bool _moduleGroupAtDestination(ModuleStacker stacker) =>
      stacker.onConveyorPlace.moduleGroup!.destination == stacker;

  bool _neighborCanFeedIn(ModuleStacker stacker) =>
      stacker.modulesOut.linkedTo!.canFeedIn();
}

class FeedOut extends State<ModuleStacker>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOut';

  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleStacker stacker) {
    var transportedModuleGroup = stacker.onConveyorPlace.moduleGroup!;
    transportedModuleGroup.position =
        BetweenModuleGroupPlaces.forModuleOutLink(stacker.modulesOut);
  }

  @override
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (transportCompleted) {
      return MoveLift(LiftPosition.inFeed, WaitToFeedIn());
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}
