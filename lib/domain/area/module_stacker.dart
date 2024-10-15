// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/travel_speed.dart';
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
  double currentHeightInMeter;
  final Map<LiftPosition, double> heightsInMeters;
  final TravelSpeed liftSpeed;
  final Duration supportsCloseDuration;
  final Duration supportsOpenDuration;
  final Duration inFeedDuration;
  final Duration outFeedDuration;

  /// e.g. when [maxLevelsInTop] = 4 then it will feed out
  /// a 5 level module when there is no 4 level module in top
  int? maxLevelsInTop;
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  late final ModuleStackerShape shape = ModuleStackerShape();

  ModuleStacker({
    required this.area,
    this.supportsCloseDuration = const Duration(seconds: 3),
    this.supportsOpenDuration = const Duration(seconds: 3),
    Duration? inFeedDuration,
    Duration? outFeedDuration,
    this.maxLevelsInTop,
    this.currentHeightInMeter =
        DefaultLiftPositionHeights.inAndOutFeedHeightInMeters,
    TravelSpeed? liftSpeed,
    this.heightsInMeters = const DefaultLiftPositionHeights(),
  })  : inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.stackerInFeedDuration,
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        liftSpeed = liftSpeed ?? area.productDefinition.moduleSystem.liftSpeed,
        super(
          initialState: CheckIfEmpty(),
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
    canFeedIn: () =>
        SimultaneousFeedOutFeedInModuleGroup.canFeedIn(currentState),
  );

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: onConveyorPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupOutLink,
    directionToOtherLink: const CompassDirection.north(),
    outFeedDuration: outFeedDuration,
    durationUntilCanFeedOut: () => currentState is WaitToFeedOut
        ? Duration.zero
        : SimultaneousFeedOutFeedInModuleGroup.durationUntilCanFeedOut(
            currentState),
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

  late System nextSystem = modulesOut.linkedTo!.system;

  late System previousSystem = modulesIn.linkedTo!.system;

  State<ModuleStacker> createSimultaneousFeedOutFeedInModuleGroup() =>
      SimultaneousFeedOutFeedInModuleGroup<ModuleStacker>(
          modulesIn: modulesIn,
          modulesOut: modulesOut,
          stateWhenCompleted: DecideAfterModuleGroupFeedIn(),
          inFeedDelay: timeBetweenStacksForStopperToGoUpInBetween);

  final Duration timeBetweenStacksForStopperToGoUpInBetween =
      const Duration(seconds: 6);
}

class CheckIfEmpty extends DurationState<ModuleStacker> {
  CheckIfEmpty()
      : super(
            durationFunction: (stacker) => stacker.inFeedDuration * 1.5,
            nextStateFunction: (stacker) =>
                SimultaneousFeedOutFeedInModuleGroup(
                    modulesIn: stacker.modulesIn,
                    modulesOut: stacker.modulesOut,
                    stateWhenCompleted: MoveLift(LiftPosition.inFeed,
                        stacker.createSimultaneousFeedOutFeedInModuleGroup())));

  @override
  String get name => 'CheckIfEmpty';
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
      var currentHeightInMeters = stacker.currentHeightInMeter;
      var goToHeightInMeters = stacker.heightsInMeters[goToPosition]!;
      var distanceInMeters = (currentHeightInMeters - goToHeightInMeters).abs();
      var duration = stacker.liftSpeed.durationOfDistance(distanceInMeters);
      return duration;
    };
  }

  @override
  String toString() {
    return '$name to:${goToPosition.toString().replaceFirst('$LiftPosition.', '')} remaining:${remainingDuration.inSeconds}sec';
  }

  @override
  void onCompleted(ModuleStacker stacker) {
    stacker.currentHeightInMeter = stacker.heightsInMeters[goToPosition]!;
  }
}

class DecideAfterModuleGroupFeedIn extends State<ModuleStacker> {
  @override
  final String name = "DecideAfterModuleGroupFeedIn";

  @override
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (mustFeedOut(stacker)) {
      return stacker.createSimultaneousFeedOutFeedInModuleGroup();
    }
    if (hasNoModuleOnSupports(stacker)) {
      return MoveLift(
          LiftPosition.singleModuleAtSupports, CloseModuleSupports());
    } else {
      return MoveLift(LiftPosition.topModuleAtSupport, OpenModuleSupports());
    }
  }

  bool hasNoModuleOnSupports(ModuleStacker stacker) =>
      stacker.onSupportsPlace.moduleGroup == null;

  bool mustFeedOut(ModuleStacker stacker) {
    var modulesAreAlreadyStacked2 = modulesAreAlreadyStacked(stacker);
    var skipModuleBecauseItHasTooManyLevelsToBePlacedInTop2 =
        skipModuleBecauseItHasTooManyLevelsToBePlacedInTop(stacker);
    var moduleToBeStackedInNextStacker2 =
        moduleToBeStackedInNextStacker(stacker);

    return modulesAreAlreadyStacked2 ||
        skipModuleBecauseItHasTooManyLevelsToBePlacedInTop2 ||
        moduleToBeStackedInNextStacker2;
  }

  bool moduleToBeStackedInNextStacker(ModuleStacker stacker) {
    var moduleSequenceNumberModulo4 =
        stacker.onConveyorPlace.moduleGroup!.modules.first.sequenceNumber % 4;
    return stacker.nextSystem is ModuleStacker &&
        (moduleSequenceNumberModulo4 == 1 || moduleSequenceNumberModulo4 == 2);
  }

  modulesAreAlreadyStacked(ModuleStacker stacker) =>
      stacker.onConveyorPlace.moduleGroup!.isStacked;

  bool skipModuleBecauseItHasTooManyLevelsToBePlacedInTop(
      ModuleStacker stacker) {
    return (stacker.maxLevelsInTop != null &&
        stacker.onConveyorPlace.moduleGroup!.modules.first.variant.levels >
            stacker.maxLevelsInTop! &&
        hasNoModuleOnSupports(stacker));
  }
}

class CloseModuleSupports extends DurationState<ModuleStacker> {
  @override
  String get name => 'CloseModuleSupports';

  CloseModuleSupports()
      : super(
          durationFunction: (stacker) => stacker.supportsCloseDuration,
          nextStateFunction: (stacker) => MoveLift(LiftPosition.inFeed,
              stacker.createSimultaneousFeedOutFeedInModuleGroup()),
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
          nextStateFunction: (stacker) => MoveLift(LiftPosition.outFeed,
              stacker.createSimultaneousFeedOutFeedInModuleGroup()),
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
