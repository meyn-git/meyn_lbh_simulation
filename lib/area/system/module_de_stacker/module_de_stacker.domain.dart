// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/module/drawer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.presentation.dart';
import 'package:user_command/user_command.dart';

import '../../area.domain.dart';
import '../../module/module.domain.dart';
import '../lift_position.domain.dart';
import '../state_machine.domain.dart';

class ModuleDeStacker extends StateMachine implements LinkedSystem {
  final LiveBirdHandlingArea area;

  int nrOfModulesFeedingIn = 0;
  double currentHeightInMeter;
  final Map<LiftPosition, double> heightsInMeters;
  final SpeedProfile liftSpeed;
  final SpeedProfile conveyorSpeedProfile;
  final Duration supportsCloseDuration;
  final Duration supportsOpenDuration;
  late final ModuleDeStackerShape shape = ModuleDeStackerShape();

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  ModuleDeStacker({
    required this.area,
    this.supportsCloseDuration = const Duration(seconds: 3),
    this.supportsOpenDuration = const Duration(seconds: 3),
    SpeedProfile? conveyorSpeed,
    Duration? inFeedDuration,
    Duration? outFeedDuration,
    this.currentHeightInMeter =
        DefaultLiftPositionHeights.inAndOutFeedHeightInMeters,
    this.liftSpeed = const ElectricModuleLiftSpeedProfile(),
    this.heightsInMeters = const DefaultLiftPositionHeights(),
  }) : conveyorSpeedProfile =
           conveyorSpeed ?? area.productDefinition.speedProfiles.moduleConveyor,
       super(initialState: CheckIfEmpty());

  /// normally used for rectangular containers (2 or more columns of compartments)
  late ModuleGroupPlace onConveyorPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter,
  );

  /// only used for the first (stacked) square container with 1 column of compartments
  late ModuleGroupPlace onConveyorFirstSingleColumnModulePlace =
      ModuleGroupPlace(
        system: this,
        offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter
            .addY(-(DrawerVariant.lengthInMeters + 0.1) / 2),
      );

  /// only used for the second (stacked) square container with 1 column of compartments
  late ModuleGroupPlace onConveyorSecondSingleColumnModulePlace =
      ModuleGroupPlace(
        system: this,
        offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter
            .addY((DrawerVariant.lengthInMeters + 0.1) / 2),
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
    durationUntilCanFeedOut: () => (currentState is WaitToFeedOut)
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

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late String name = 'ModuleDeStacker$seqNr';

  @override
  SizeInMeters get sizeWhenFacingNorth => shape.size;

  late System nextSystem = modulesOut.linkedTo!.system;

  late System previousSystem = modulesIn.linkedTo!.system;

  State<ModuleDeStacker> createSimultaneousFeedOutFeedInModuleGroup() =>
      SimultaneousFeedOutFeedInModuleGroup<ModuleDeStacker>(
        modulesIn: modulesIn,
        modulesOut: modulesOut,
        stateWhenCompleted: DecideAfterSimultaneousFeedOutFeedIn(),
        inFeedDelay: timeBetweenStacksForStopperToGoUpInBetween,
      );

  final Duration timeBetweenStacksForStopperToGoUpInBetween = const Duration(
    seconds: 6,
  );
}

class CheckIfEmpty extends DurationState<ModuleDeStacker> {
  CheckIfEmpty()
    : super(
        durationFunction: (deStacker) => deStacker.conveyorSpeedProfile
            .durationOfDistance(deStacker.shape.yInMeters * 1.5),
        nextStateFunction: (deStacker) => MoveLift(
          LiftPosition.inFeed,
          deStacker.createSimultaneousFeedOutFeedInModuleGroup(),
        ),
      );

  @override
  String get name => 'CheckIfEmpty';
}

class MoveLift extends DurationState<ModuleDeStacker>
    implements DetailProvider {
  final LiftPosition goToPosition;

  MoveLift(this.goToPosition, State<ModuleDeStacker> nextState)
    : super(
        durationFunction: createDurationFunction(goToPosition),
        nextStateFunction: (deStacker) => nextState,
      );

  static Duration Function(ModuleDeStacker) createDurationFunction(
    LiftPosition goToPosition,
  ) {
    return (deStacker) {
      var currentHeightInMeter = deStacker.currentHeightInMeter;
      var goToHeightInMeter = deStacker.heightsInMeters[goToPosition]!;
      var distanceInMeter = (currentHeightInMeter - goToHeightInMeter).abs();
      var duration = deStacker.liftSpeed.durationOfDistance(distanceInMeter);
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
  void onCompleted(ModuleDeStacker deStacker) {
    deStacker.currentHeightInMeter = deStacker.heightsInMeters[goToPosition]!;
  }

  @override
  String get name => 'MoveLift';
}

class DecideAfterSimultaneousFeedOutFeedIn extends State<ModuleDeStacker> {
  @override
  String get name => 'DecideAfterSimultaneousFeedOutFeedIn';

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (feedFirstStackToNextDeStackerAndSecondStackToCenter(deStacker)) {
      return WaitToFeedOutFirstStackAndTransportSecondStackToCenter();
    }
    if (feedOutBottomModule(deStacker)) {
      return WaitToFeedOut();
    }
    if (simultaneousFeedOutFeedIn(deStacker)) {
      return deStacker.createSimultaneousFeedOutFeedInModuleGroup();
    }

    if (putTopModuleOnSupports(deStacker)) {
      return MoveLift(LiftPosition.topModuleAtSupport, CloseModuleSupports());
    }

    return null;
  }

  bool putTopModuleOnSupports(ModuleDeStacker deStacker) =>
      deStacker.onSupportsPlace.moduleGroup == null;

  bool feedOutBottomModule(ModuleDeStacker deStacker) =>
      ((deStacker.previousSystem is ModuleDeStacker &&
              deStacker.onSupportsPlace.moduleGroup != null) ||
          deStacker.previousSystem is! ModuleDeStacker) &&
      deStacker.onConveyorPlace.moduleGroup!.numberOfModules == 1;

  bool simultaneousFeedOutFeedIn(ModuleDeStacker deStacker) =>
      deStacker.onConveyorPlace.moduleGroup!.numberOfModules == 1;

  bool feedFirstStackToNextDeStackerAndSecondStackToCenter(
    ModuleDeStacker deStacker,
  ) =>
      deStacker.nextSystem is ModuleDeStacker &&
      deStacker.onConveyorPlace.moduleGroup!.stackNumbers.length > 1;

  bool getModuleFromSupports(ModuleDeStacker deStacker) =>
      deStacker.onSupportsPlace.moduleGroup != null;
}

class CloseModuleSupports extends DurationState<ModuleDeStacker> {
  @override
  String get name => 'CloseModuleSupports';

  CloseModuleSupports()
    : super(
        durationFunction: (deStacker) => deStacker.supportsCloseDuration,
        nextStateFunction: (deStacker) => MoveLift(
          LiftPosition.outFeed,
          deStacker.previousSystem is! ModuleDeStacker ||
                  deStacker.nextSystem is ModuleDeStacker
              ? WaitToFeedOut()
              : deStacker.createSimultaneousFeedOutFeedInModuleGroup(),
        ),
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
      position: AtModuleGroupPlace(deStacker.onSupportsPlace),
    );
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
        nextStateFunction: (deStacker) => MoveLift(
          LiftPosition.outFeed,
          deStacker.createSimultaneousFeedOutFeedInModuleGroup(),
        ),
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

class FeedOut extends State<ModuleDeStacker>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOut';

  @override
  void onStart(ModuleDeStacker deStacker) {
    var transportedModuleGroup = deStacker.onConveyorPlace.moduleGroup!;
    transportedModuleGroup.position = BetweenModuleGroupPlaces.forModuleOutLink(
      deStacker.modulesOut,
    );
  }

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (transportCompleted) {
      return MoveLift(
        LiftPosition.singleModuleAtSupports,
        OpenModuleSupports(),
      );
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class WaitToFeedOutFirstStackAndTransportSecondStackToCenter
    extends State<ModuleDeStacker> {
  @override
  String get name => 'WaitToFeedOutFirstStackAndTransportSecondStackToCenter';

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (SimultaneousFeedOutFeedInModuleGroup.canFeedIn(
      (deStacker.nextSystem as StateMachine).currentState,
    )) {
      return FeedOutFirstStackAndTransportSecondStackToCenter();
    }
    return null;
  }
}

class FeedOutFirstStackAndTransportSecondStackToCenter
    extends State<ModuleDeStacker>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOutFirstStackAndTransportSecondStackToCenter';

  @override
  void onStart(ModuleDeStacker deStacker) {
    var destinationFirstStack = deStacker.modulesOut.linkedTo!;
    var duration = destinationFirstStack.transportDuration(
      destinationFirstStack,
    );

    var secondStack = createSecondStack(deStacker);
    deStacker.onConveyorSecondSingleColumnModulePlace.moduleGroup = secondStack;
    deStacker.area.moduleGroups.add(secondStack);
    secondStack.position = BetweenModuleGroupPlaces(
      source: deStacker.onConveyorSecondSingleColumnModulePlace,
      destination: deStacker.onConveyorPlace,
      duration: duration,
    );

    var firstStack = createFirstStack(deStacker);
    deStacker.onConveyorFirstSingleColumnModulePlace.moduleGroup = firstStack;
    firstStack.position = BetweenModuleGroupPlaces(
      source: deStacker.onConveyorFirstSingleColumnModulePlace,
      destination: deStacker.modulesOut.linkedTo!.place,
      duration: duration,
    );
  }

  ModuleGroup createFirstStack(ModuleDeStacker deStacker) {
    //reusing the module group, so [createSecondStack] needs to be created first!
    var moduleGroup = deStacker.onConveyorPlace.moduleGroup!;
    moduleGroup.remove(PositionWithinModuleGroup.secondBottom);
    moduleGroup.remove(PositionWithinModuleGroup.secondTop);
    moduleGroup.position = AtModuleGroupPlace(
      deStacker.onConveyorFirstSingleColumnModulePlace,
    );
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
        deStacker.onConveyorSecondSingleColumnModulePlace,
      ),
    );
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
