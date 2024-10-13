// ignore_for_file: avoid_renaming_method_parameters

import 'dart:math';

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_de_stacker.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module/module.dart';
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
      LiftPosition.topModuleAtSupport: 150 + 150 + 30,
      LiftPosition.singleModuleAtSupports: 150 + 30
    },
  })  : inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.stackerInFeedDuration,
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        super(
          initialState: MoveLift(LiftPosition.inFeed, WaitToFeedIn()),
        );

  /// normaly used for rectangular containers (2 or more columns of compartments)
  late ModuleGroupPlace onConveyorPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter,
  );

  /// only used for the first (stacked) square container with 1 column of compartments
  late ModuleGroupPlace onConveyorFirstSingleColumnModulePlace =
      ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth:
        shape.centerToConveyorCenter.addY(-1),
  );

  /// only used for the second (stacked) square container with 1 column of compartments
  late ModuleGroupPlace onConveyorSecondSingleColumnModulePlace =
      ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter.addY(1),
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

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late String name = 'ModuleDeStacker$seqNr';

  @override
  SizeInMeters get sizeWhenFacingNorth => shape.size;

  late System nextSystem = modulesOut.linkedTo!.system;

  late System previousSystem = modulesIn.linkedTo!.system;
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
  void onModuleTransportStarted(_) {
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
      if (transportFirstStackToNextDestacker(deStacker)) {
        return WaitToFeedOutFirstStackAndTransportSecondStackToCenter();
      }
      if (deStacker.onConveyorPlace.moduleGroup!.numberOfModules == 1) {
        return MoveLift(LiftPosition.outFeed, WaitToFeedOut());
      } else {
        return MoveLift(LiftPosition.topModuleAtSupport, CloseModuleSupports());
      }
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }

  bool transportFirstStackToNextDestacker(deStacker) =>
      deStacker.nextSystem is ModuleDeStacker &&
      deStacker.onConveyorPlace.moduleGroup!.stackNumbers.length > 1;
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
    var moduleGroupOnConveyor = deStacker.onConveyorPlace.moduleGroup!;
    if (moduleGroupOnConveyor.numberOfStacks > 1) {
      throw Exception('$name can only de-stack a single stack at a time!');
    }
    Module module = moduleGroupOnConveyor[PositionWithinModuleGroup.firstTop]!;
    moduleGroupOnConveyor.remove(PositionWithinModuleGroup.firstTop);

    var moduleGroupOnSupports = ModuleGroup(
        modules: {PositionWithinModuleGroup.firstBottom: module},
        direction: moduleGroupOnConveyor.direction,
        destination: moduleGroupOnConveyor.destination,
        position: AtModuleGroupPlace(deStacker.onSupportsPlace));
    deStacker.area.moduleGroups.add(moduleGroupOnSupports);
    deStacker.onSupportsPlace.moduleGroup = moduleGroupOnSupports;
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
    var moduleGroup = deStacker.onSupportsPlace.moduleGroup!;
    moduleGroup.position = AtModuleGroupPlace(deStacker.onConveyorPlace);
    deStacker.onSupportsPlace.moduleGroup = null;
    deStacker.onConveyorPlace.moduleGroup = moduleGroup;
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
      deStacker.onConveyorPlace.moduleGroup!.destination == deStacker;

  bool _neighborCanFeedIn(ModuleDeStacker deStacker) =>
      deStacker.modulesOut.linkedTo!.canFeedIn();
}

class WaitToFeedOutFirstStackAndTransportSecondStackToCenter
    extends State<ModuleDeStacker> {
  @override
  String get name => 'WaitToFeedOutFirstStackAndTransportSecondStackToCenter';

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if ((deStacker.nextSystem as StateMachine).currentState is WaitToFeedIn) {
      return FeedOutFirstStackAndTransportSecondStackToCenter();
    }
    return null;
  }
}

class FeedOutFirstStackAndTransportSecondStackToCenter
    extends State<ModuleDeStacker> implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOutFirstStackAndTransportSecondStackToCenter';

  @override
  void onStart(ModuleDeStacker deStacker) {
    var duration = Duration(
        milliseconds: max(deStacker.modulesOut.outFeedDuration.inMilliseconds,
            deStacker.modulesOut.linkedTo!.inFeedDuration.inMilliseconds));

    var secondStack = createSecondStack(deStacker);
    deStacker.onConveyorSecondSingleColumnModulePlace.moduleGroup = secondStack;
    deStacker.area.moduleGroups.add(secondStack);
    secondStack.position = BetweenModuleGroupPlaces(
        source: deStacker.onConveyorSecondSingleColumnModulePlace,
        destination: deStacker.onConveyorPlace,
        duration: duration);

    var firstStack = createFirstStack(deStacker);
    deStacker.onConveyorFirstSingleColumnModulePlace.moduleGroup = firstStack;
    firstStack.position = BetweenModuleGroupPlaces(
        source: deStacker.onConveyorFirstSingleColumnModulePlace,
        destination: deStacker.modulesOut.linkedTo!.place,
        duration: duration);
  }

  ModuleGroup createFirstStack(ModuleDeStacker deStacker) {
    //reusing the module group, so [createSecondStack] needs to be created first!
    var moduleGroup = deStacker.onConveyorPlace.moduleGroup!;
    moduleGroup.remove(PositionWithinModuleGroup.secondBottom);
    moduleGroup.remove(PositionWithinModuleGroup.secondTop);
    moduleGroup.position =
        AtModuleGroupPlace(deStacker.onConveyorFirstSingleColumnModulePlace);
    return moduleGroup;
  }

  ModuleGroup createSecondStack(ModuleDeStacker deStacker) {
    var moduleGroup = deStacker.onConveyorPlace.moduleGroup!;
    var modulesOfSecondStack = <PositionWithinModuleGroup, Module>{
      PositionWithinModuleGroup.firstBottom:
          moduleGroup[PositionWithinModuleGroup.secondBottom]!,
      PositionWithinModuleGroup.firstTop:
          moduleGroup[PositionWithinModuleGroup.secondTop]!,
    };
    return ModuleGroup(
        destination: moduleGroup.destination,
        direction: moduleGroup.direction,
        modules: modulesOfSecondStack,
        position: AtModuleGroupPlace(
            deStacker.onConveyorSecondSingleColumnModulePlace));
  }

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (transportCompleted) {
      return MoveLift(LiftPosition.topModuleAtSupport, CloseModuleSupports());
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class FeedOut extends State<ModuleDeStacker>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOut';

  @override
  void onStart(ModuleDeStacker deStacker) {
    var transportedModuleGroup = deStacker.onConveyorPlace.moduleGroup!;
    transportedModuleGroup.position =
        BetweenModuleGroupPlaces.forModuleOutLink(deStacker.modulesOut);
  }

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (transportCompleted) {
      if (mustFeedIn(deStacker)) {
        return MoveLift(LiftPosition.inFeed, WaitToFeedIn());
      } else {
        return MoveLift(
            LiftPosition.singleModuleAtSupports, OpenModuleSupports());
      }
    }
    return null;
  }

  bool mustFeedIn(ModuleDeStacker deStacker) =>
      noModuleOnSupports(deStacker) ||
      transferModuleFormPreceedingDeStacker(deStacker);

  bool noModuleOnSupports(ModuleDeStacker deStacker) =>
      deStacker.onSupportsPlace.moduleGroup == null;

  bool transferModuleFormPreceedingDeStacker(ModuleDeStacker deStacker) {
    var previousSystem = deStacker.previousSystem;
    if (previousSystem is! ModuleDeStacker) {
      return false;
    }
    var previousDeStacker = previousSystem;
    var moduleGroupOnPreviousDestacker =
        previousDeStacker.onConveyorPlace.moduleGroup;
    return isOnlyOneModule(moduleGroupOnPreviousDestacker) &&
        isFirstModuleOfStack(moduleGroupOnPreviousDestacker);
  }

  bool isFirstModuleOfStack(ModuleGroup? moduleGroupOnPreviousDestacker) =>
      (moduleGroupOnPreviousDestacker!.modules.first.sequenceNumber - 1) % 2 ==
      0;

  bool isOnlyOneModule(ModuleGroup? moduleGroupOnPreviousDestacker) =>
      moduleGroupOnPreviousDestacker!.modules.length == 1;

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}
