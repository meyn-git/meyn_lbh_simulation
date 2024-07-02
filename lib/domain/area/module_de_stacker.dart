// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_de_stacker.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_lift_position.dart';
import 'state_machine.dart';

class ModuleDeStacker extends StateMachine implements PhysicalSystem {
  final LiveBirdHandlingArea area;

  int nrOfModulesFeedingIn = 0;
  int currentHeightInCentiMeter;
  final Map<LiftPosition, int> heightsInCentiMeter;
  final int liftSpeedInCentiMeterPerSecond;
  final Duration inFeedDuration;
  final Duration outFeedDuration;
  final Duration supportsCloseDuration;
  final Duration supportsOpenDuration;
  late final ModuleDeStackerShape shape = ModuleDeStackerShape();

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  ModuleDeStacker({
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
      LiftPosition.supportTopModule: 150 + 150 + 30,
      LiftPosition.pickUpTopModule: 150 + 30
    },
  })  : inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.stackerInFeedDuration,
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        super(
          initialState: MoveLift(LiftPosition.inFeed, WaitToFeedIn()),
        );

  late ModuleGroupPlace moduleGroupOnConveyorPosition = ModuleGroupPlace(
    system: this,
    moduleGroups: area.moduleGroups,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter,
  );

  late ModuleGroupPlace moduleGroupOnSupportsPosition = ModuleGroupPlace(
    system: this,
    moduleGroups: area.moduleGroups,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToSupportsCenter,
  );

  late ModuleGroupInLink modulesIn = ModuleGroupInLink(
    position: moduleGroupOnConveyorPosition,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupInLink,
    directionToOtherLink: const CompassDirection.south(),
    inFeedDuration: inFeedDuration,
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    position: moduleGroupOnConveyorPosition,
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

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late String name = 'ModuleDeStacker$seqNr';

  @override
  SizeInMeters get sizeWhenFacingNorth => shape.size;
}

class MoveLift extends DurationState<ModuleDeStacker> {
  final LiftPosition goToPosition;

  MoveLift(this.goToPosition, State<ModuleDeStacker> nextState)
      : super(
            durationFunction: createDurationFunction(goToPosition),
            nextStateFunction: (deStacker) => nextState);

  static Duration Function(ModuleDeStacker) createDurationFunction(
      LiftPosition goToPosition) {
    return (deStacker) {
      var currentHeightInCentiMeter = deStacker.currentHeightInCentiMeter;
      var goToHeightInCentiMeter = deStacker.heightsInCentiMeter[goToPosition]!;
      var distanceInCentiMeter =
          (currentHeightInCentiMeter - goToHeightInCentiMeter).abs();
      Duration duration = Duration(
          milliseconds: (distanceInCentiMeter /
                  deStacker.liftSpeedInCentiMeterPerSecond *
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
  void onCompleted(ModuleDeStacker deStacker) {
    deStacker.currentHeightInCentiMeter =
        deStacker.heightsInCentiMeter[goToPosition]!;
  }

  @override
  String get name => 'MoveLift';
}

class WaitToFeedIn extends State<ModuleDeStacker>
    implements ModuleTransportStartedListener {
  bool transportStarted = false;

  @override
  String get name => 'WaitToFeedIn';

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
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

class FeedIn extends State<ModuleDeStacker>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedIn';

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (transportCompleted) {
      if (deStacker
              .moduleGroupOnConveyorPosition.moduleGroup!.numberOfModules ==
          1) {
        return MoveLift(LiftPosition.outFeed, WaitToFeedOut());
      } else {
        return MoveLift(LiftPosition.supportTopModule, CloseModuleSupports());
      }
    }
    return null;
  }

  @override
  void onModuleTransportCompleted() {
    transportCompleted = true;
  }
}

class CloseModuleSupports extends DurationState<ModuleDeStacker> {
  @override
  String get name => 'CloseModuleSupports';

  CloseModuleSupports()
      : super(
          durationFunction: (deStacker) => deStacker.supportsCloseDuration,
          nextStateFunction: (deStacker) =>
              MoveLift(LiftPosition.outFeed, WaitToFeedOut()),
        );

  @override
  void onCompleted(ModuleDeStacker deStacker) {
    var moduleGroupOnSupports =
        deStacker.moduleGroupOnConveyorPosition.moduleGroup!.split();
    deStacker.area.moduleGroups.add(moduleGroupOnSupports!);
    moduleGroupOnSupports.position =
        AtModuleGroupPlace(deStacker.moduleGroupOnSupportsPosition);
  }
}

class OpenModuleSupports extends DurationState<ModuleDeStacker> {
  @override
  String get name => 'OpenModuleSupports';

  OpenModuleSupports()
      : super(
          durationFunction: (deStacker) => deStacker.supportsOpenDuration,
          nextStateFunction: (deStacker) =>
              MoveLift(LiftPosition.outFeed, WaitToFeedOut()),
        );

  @override
  void onCompleted(ModuleDeStacker deStacker) {
    var moduleGroupOnSupports =
        deStacker.moduleGroupOnSupportsPosition.moduleGroup!;
    moduleGroupOnSupports.position =
        AtModuleGroupPlace(deStacker.moduleGroupOnConveyorPosition);
  }
}

class WaitToFeedOut extends State<ModuleDeStacker> {
  @override
  String get name => 'WaitToFeedOut';
  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (_neighborCanFeedIn(deStacker) &&
        !_moduleGroupAtDestination(deStacker)) {
      return FeedOut();
    }
    return null;
  }

  bool _moduleGroupAtDestination(ModuleDeStacker deStacker) =>
      deStacker.moduleGroupOnConveyorPosition.moduleGroup!.destination ==
      deStacker;

  bool _neighborCanFeedIn(ModuleDeStacker deStacker) =>
      deStacker.modulesOut.linkedTo!.canFeedIn();
}

class FeedOut extends State<ModuleDeStacker>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOut';

  @override
  void onStart(ModuleDeStacker deStacker) {
    var transportedModuleGroup =
        deStacker.moduleGroupOnConveyorPosition.moduleGroup!;
    transportedModuleGroup.position =
        BetweenModuleGroupPlaces.forModuleOutLink(deStacker.modulesOut);
  }

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (transportCompleted) {
      if (deStacker.moduleGroupOnSupportsPosition.moduleGroup == null) {
        return MoveLift(LiftPosition.inFeed, WaitToFeedIn());
      } else {
        return MoveLift(LiftPosition.pickUpTopModule, OpenModuleSupports());
      }
    }
    return null;
  }

  @override
  void onModuleTransportCompleted() {
    transportCompleted = true;
  }
}
