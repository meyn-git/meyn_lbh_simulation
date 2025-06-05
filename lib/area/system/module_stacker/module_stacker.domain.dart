// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.presentation.dart';
import 'package:user_command/user_command.dart';

import '../../area.domain.dart';
import '../../module/module.domain.dart';
import '../lift_position.domain.dart';
import '../state_machine.domain.dart';

class ModuleStacker extends StateMachine implements LinkedSystem {
  final LiveBirdHandlingArea area;
  int nrOfModulesFeedingIn = 0;
  double liftHeightInMeters;
  final Map<LiftPosition, double> heightsInMeters;
  final SpeedProfile liftSpeedProfile;
  final SpeedProfile conveyorSpeedProfile;
  final Duration supportsCloseDuration;
  final Duration supportsOpenDuration;

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
    this.liftHeightInMeters =
        DefaultLiftPositionHeights.inAndOutFeedHeightInMeters,
    SpeedProfile? liftSpeedProfile,
    SpeedProfile? conveyorSpeedProfile,
    this.heightsInMeters = const DefaultLiftPositionHeights(),
  }) : conveyorSpeedProfile =
           conveyorSpeedProfile ??
           area.productDefinition.speedProfiles.moduleConveyor,
       liftSpeedProfile =
           liftSpeedProfile ?? area.productDefinition.speedProfiles.lift,
       super(initialState: CheckIfEmpty());

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
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () =>
        SimultaneousFeedOutFeedInModuleGroup.canFeedIn(currentState),
  );

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: onConveyorPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupOutLink,
    directionToOtherLink: const CompassDirection.north(),
    durationUntilCanFeedOut: () => currentState is WaitToFeedOut
        ? Duration.zero
        : SimultaneousFeedOutFeedInModuleGroup.durationUntilCanFeedOut(
            currentState,
          ),
  );

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
    modulesIn,
    modulesOut,
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
        inFeedDelay: timeBetweenStacksForStopperToGoUpInBetween,
      );

  final Duration timeBetweenStacksForStopperToGoUpInBetween = const Duration(
    seconds: 6,
  );
}

class CheckIfEmpty extends DurationState<ModuleStacker> {
  CheckIfEmpty()
    : super(
        durationFunction: (stacker) =>
            stacker.conveyorSpeedProfile.durationOfDistance(
              stacker.shape.yInMeters,
            ) *
            1.5,
        nextStateFunction: (stacker) => SimultaneousFeedOutFeedInModuleGroup(
          modulesIn: stacker.modulesIn,
          modulesOut: stacker.modulesOut,
          stateWhenCompleted: MoveLift(
            LiftPosition.inFeed,
            stacker.createSimultaneousFeedOutFeedInModuleGroup(),
          ),
        ),
      );

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
        nextStateFunction: (stacker) => nextState,
      );

  static Duration Function(ModuleStacker) createDurationFunction(
    LiftPosition goToPosition,
  ) {
    return (stacker) {
      var currentHeightInMeters = stacker.liftHeightInMeters;
      var goToHeightInMeters = stacker.heightsInMeters[goToPosition]!;
      var distanceInMeters = (currentHeightInMeters - goToHeightInMeters).abs();
      var duration = stacker.liftSpeedProfile.durationOfDistance(
        distanceInMeters,
      );
      return duration;
    };
  }

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty(
        'goToPosition',
        goToPosition.toString().replaceFirst('$LiftPosition.', ''),
      )
      .appendProperty('remaining', '${remainingDuration.inSeconds}sec');

  @override
  void onCompleted(ModuleStacker stacker) {
    stacker.liftHeightInMeters = stacker.heightsInMeters[goToPosition]!;
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
        LiftPosition.singleModuleAtSupports,
        CloseModuleSupports(),
      );
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
    var moduleToBeStackedInNextStacker2 = moduleToBeStackedInNextStacker(
      stacker,
    );

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
    ModuleStacker stacker,
  ) {
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
        nextStateFunction: (stacker) => MoveLift(
          LiftPosition.inFeed,
          stacker.createSimultaneousFeedOutFeedInModuleGroup(),
        ),
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
        nextStateFunction: (stacker) => MoveLift(
          LiftPosition.outFeed,
          stacker.createSimultaneousFeedOutFeedInModuleGroup(),
        ),
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
