// ignore_for_file: avoid_renaming_method_parameters

import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module_variant_builder.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.presentation.dart';
import 'package:user_command/user_command.dart';

import '../../area.domain.dart';
import '../../module/module.domain.dart';
import '../state_machine.domain.dart';
import '../vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';

enum ModuleDoor { rollDoorUp, slideDoorToLeft, slideDoorToRight }

class ModuleCas extends StateMachine implements LinkedSystem {
  final LiveBirdHandlingArea area;
  late SpeedProfile conveyorSpeedProfile;
  late CasRecipe recipe;
  final bool gasDuctsLeft;
  final ModuleDoor moduleDoor;
  final Duration closeDoorDuration;
  final Duration openDoorDuration;
  final int numberOfModuleStacks;
  final int levelsOfModules;
  Duration waitingForStartDuration = Duration.zero;
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  late final CompassDirection doorDirection = shape.gasDuctsDirection.opposite
      .rotate(area.layout.rotationOf(this).degrees);

  ModuleCas({
    required this.area,
    required this.moduleDoor,
    required this.gasDuctsLeft,
    required this.numberOfModuleStacks,
    required this.levelsOfModules,
    Duration? closeDoorDuration,
    Duration? openDoorDuration,
    SpeedProfile? conveyorSpeedProfile,
  }) : conveyorSpeedProfile =
           conveyorSpeedProfile ??
           area.productDefinition.speedProfiles.moduleConveyor,
       closeDoorDuration =
           closeDoorDuration ??
           (moduleDoor == ModuleDoor.rollDoorUp
               ? const Duration(seconds: 3)
               : const Duration(seconds: 6)),
       openDoorDuration =
           openDoorDuration ??
           (moduleDoor == ModuleDoor.rollDoorUp
               ? const Duration(seconds: 3)
               : const Duration(seconds: 6)),
       super(initialState: CheckIfEmpty()) {
    _verifyCasRecipeIsDefined();
    recipe = area.productDefinition.casRecipe!;
  }

  late final seqNr = area.systems.seqNrOf(this);

  bool get canFeedIn => currentState is WaitToFeedIn || currentState is FeedIn;

  bool get almostWaitingToFeedOut => durationUntilCanFeedOut != unknownDuration;

  bool get waitingToFeedOut => currentState is WaitToFeedOut;

  LinkedSystem get moduleGroupDestinationAfterStunning {
    var unLoadingForkLiftTruck = area.systems.linkedSystems.firstWhereOrNull(
      (system) => system is UnLoadingForkLiftTruck,
    );
    if (unLoadingForkLiftTruck == null) {
      throw Exception(
        'The $LiveBirdHandlingArea MUST have a $UnLoadingForkLiftTruck.',
      );
    }
    return unLoadingForkLiftTruck;
  }

  @override
  onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    if (currentState is WaitForStart) {
      waitingForStartDuration += jump;
    } else {
      waitingForStartDuration = Duration.zero;
    }
  }

  ///Called by [ModuleCasStart]
  void start() {
    if (currentState is WaitForStart) {
      (currentState as WaitForStart).start();
    } else {
      throw Exception(
        'Can not start $name, because it is in $currentState state and not in $WaitForStart state.',
      );
    }
  }

  void _verifyCasRecipeIsDefined() {
    if (area.productDefinition.casRecipe == null) {
      throw ArgumentError(
        '$LiveBirdHandlingArea error: You must specify the casRecipe in the layout when it contains one or more $ModuleCas',
      );
    }
  }

  late ModuleCasShape shape = ModuleCasShape(this);

  late ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupInOutLink,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () => canFeedIn,
  );

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupInOutLink,
    directionToOtherLink: const CompassDirection.south(),
    durationUntilCanFeedOut: () => durationUntilCanFeedOut,
  );

  Duration get durationUntilCanFeedOut {
    if (currentState is OpenSlideDoor) {
      return (currentState as OpenSlideDoor).remainingDuration;
    }
    if (currentState is ExhaustStage) {
      return (currentState as ExhaustStage).remainingDuration +
          openDoorDuration;
    }
    if (currentState is WaitToFeedOut || currentState is FeedOut) {
      return Duration.zero;
    }
    return unknownDuration;
  }

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
    modulesIn,
    modulesOut,
  ];

  @override
  late final String name = 'ModuleCas$seqNr';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToCabinCenter,
  );

  late final int numberOfModules = numberOfModuleStacks * levelsOfModules;
}

class CasRecipe {
  final List<CasRecipeStage> stages;
  final Duration exhaustDuration;

  const CasRecipe(this.stages, this.exhaustDuration);

  const CasRecipe.standardChickenRecipe()
    : this(const [
        CasRecipeStage(duration: Duration(seconds: 60), co2Percentage: 18),
        CasRecipeStage(duration: Duration(seconds: 60), co2Percentage: 28),
        CasRecipeStage(duration: Duration(seconds: 60), co2Percentage: 33),
        CasRecipeStage(duration: Duration(seconds: 60), co2Percentage: 38),
        CasRecipeStage(duration: Duration(seconds: 120), co2Percentage: 62),
      ], const Duration(seconds: 30));

  const CasRecipe.standardTurkeyRecipe()
    : this(const [
        CasRecipeStage(duration: Duration(seconds: 40), co2Percentage: 22),
        CasRecipeStage(duration: Duration(seconds: 40), co2Percentage: 34),
        CasRecipeStage(duration: Duration(seconds: 40), co2Percentage: 43),
        CasRecipeStage(duration: Duration(seconds: 120), co2Percentage: 67),
      ], const Duration(seconds: 30));

  const CasRecipe.turkeyRecipeAtIndrolAtInstallation()
    : this(const [
        CasRecipeStage(duration: Duration(seconds: 35), co2Percentage: 35),
        CasRecipeStage(duration: Duration(seconds: 35), co2Percentage: 43),
        CasRecipeStage(duration: Duration(seconds: 30), co2Percentage: 58),
        CasRecipeStage(duration: Duration(seconds: 110), co2Percentage: 72),
      ], const Duration(seconds: 30));

  //info from Maurizio on site @ 2024-09-18
  const CasRecipe.femaleTurkeyRecipeAtIndrol()
    : this(const [
        CasRecipeStage(duration: Duration(seconds: 35), co2Percentage: 32),
        CasRecipeStage(duration: Duration(seconds: 35), co2Percentage: 38),
        CasRecipeStage(duration: Duration(seconds: 30), co2Percentage: 43),
        CasRecipeStage(duration: Duration(seconds: 110), co2Percentage: 72),
      ], const Duration(seconds: 30));

  //info from Maurizio on site @ 2024-09-18
  const CasRecipe.maleTurkeyRecipeAtIndrol()
    : this(const [
        CasRecipeStage(duration: Duration(seconds: 30), co2Percentage: 32),
        CasRecipeStage(duration: Duration(seconds: 30), co2Percentage: 38),
        CasRecipeStage(duration: Duration(seconds: 70), co2Percentage: 43),
        CasRecipeStage(duration: Duration(seconds: 100), co2Percentage: 82),
      ], const Duration(seconds: 30));

  Duration totalDurationStunStages() =>
      stages.fold(Duration(), (sum, element) => sum + element.duration);

  Duration totalDurationStunStagesAndExhaust() =>
      totalDurationStunStages() + exhaustDuration;

  List<int> co2Percentages(int secondsFromStart, int durationInSeconds) {
    final result = <int>[];
    int end = secondsFromStart + durationInSeconds;
    int stageStart = 0;

    for (final stage in stages) {
      int stageEnd = stageStart + stage.duration.inSeconds;
      // If the stage overlaps with the requested interval
      if (stageEnd > secondsFromStart && stageStart < end) {
        // Determine the overlap range
        int overlapStart = stageStart < secondsFromStart
            ? secondsFromStart
            : stageStart;
        int overlapEnd = stageEnd > end ? end : stageEnd;
        int overlapDuration = overlapEnd - overlapStart;
        for (int i = 0; i < overlapDuration; i++) {
          result.add(stage.co2Percentage);
        }
      }
      stageStart = stageEnd;
      if (stageStart >= end) break;
    }
    return result;
  }
}

class CheckIfEmpty extends DurationState<ModuleCas> {
  CheckIfEmpty()
    : super(
        durationFunction: (cas) =>
            cas.conveyorSpeedProfile.durationOfDistance(cas.shape.yInMeters) *
            1.5,
        nextStateFunction: (cas) => WaitToFeedIn(),
      );

  @override
  String get name => 'CheckIfEmpty';
}

class WaitToFeedIn extends State<ModuleCas>
    implements ModuleTransportStartedListener {
  bool transportStarted = false;

  @override
  String get name => 'WaitToFeedIn';

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
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

class CasRecipeStage {
  final Duration duration;
  final int co2Percentage;

  const CasRecipeStage({required this.duration, required this.co2Percentage});
}

class FeedIn extends State<ModuleCas>
    implements ModuleTransportCompletedListener {
  bool completed = false;

  @override
  String get name => 'FeedIn';

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (completed) {
      return WaitForStart();
    }
    return null;
  }

  @override
  void onCompleted(ModuleCas cas) {
    _verifyDoorDirection(cas);
    _verifyLevelsOfModules(cas);
    _verifyStacksOfModules(cas);
  }

  void _verifyDoorDirection(ModuleCas cas) {
    var moduleGroup = cas.moduleGroupPlace.moduleGroup!;
    if (moduleGroup.compartment is CompartmentWithDoor &&
        moduleGroup.direction.rotate(-90) != cas.doorDirection) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${cas.name}');
    }
  }

  void _verifyLevelsOfModules(ModuleCas cas) {
    var moduleGroup = cas.moduleGroupPlace.moduleGroup!;
    if (moduleGroup.numberOfModuleLevels != cas.levelsOfModules) {
      throw Exception(
        '${cas.name} can only accept a moduleGroup with ${cas.levelsOfModules} '
        'levels of modules, but received ${moduleGroup.numberOfModuleLevels} module levels.',
      );
    }
  }

  void _verifyStacksOfModules(ModuleCas cas) {
    var moduleGroup = cas.moduleGroupPlace.moduleGroup!;
    if (moduleGroup.numberOfStacks != cas.numberOfModuleStacks) {
      throw Exception(
        '${cas.name} can only accept a moduleGroup with ${cas.numberOfModuleStacks} '
        'stacks of modules, but received ${moduleGroup.numberOfStacks} module levels.',
      );
    }
  }

  @override
  void onModuleTransportCompleted(_) {
    completed = true;
  }
}

class WaitForStart extends State<ModuleCas> {
  @override
  String get name => 'WaitForStart';

  bool _start = false;

  @override
  State<ModuleCas>? nextState(ModuleCas moduleCas) {
    if (_start) {
      _start = false;
      return CloseSlideDoor();
    }
    return null;
  }

  void start() {
    _start = true;
  }
}

class CloseSlideDoor extends DurationState<ModuleCas> {
  CloseSlideDoor()
    : super(
        durationFunction: (cas) => cas.closeDoorDuration,
        nextStateFunction: (cas) => StunStage(1),
      );

  @override
  String get name => 'CloseSlideDoor';
}

class StunStage extends DurationState<ModuleCas> {
  final int stageNumber;

  StunStage(this.stageNumber)
    : super(
        durationFunction: (cas) => findCasRecipeStage(cas).duration,
        nextStateFunction: (cas) => findNextStage(cas, stageNumber),
      );

  static State<ModuleCas> findNextStage(ModuleCas cas, int currentStageNumber) {
    if (currentStageNumber >= numberOfStages(cas)) {
      return ExhaustStage();
    } else {
      return StunStage(++currentStageNumber);
    }
  }

  static int numberOfStages(ModuleCas cas) => cas.recipe.stages.length;

  static CasRecipeStage findCasRecipeStage(ModuleCas cas) {
    var currentState = cas.currentState;
    if (currentState is StunStage) {
      var currentStageNumber = currentState.stageNumber;
      return cas.recipe.stages[currentStageNumber - 1];
    }
    throw Exception('Unknown StunStage duration');
  }

  @override
  String get name => 'StunStage$stageNumber';

  @override
  String toString() => '$name (remaining: ${remainingDuration.inSeconds}sec)';

  @override
  void onStart(ModuleCas cas) {
    super.onStart(cas);
    if (stageNumber == 1) {
      cas.moduleGroupPlace.moduleGroup!.startStunning();
    }
  }
}

class ExhaustStage extends DurationState<ModuleCas> {
  ExhaustStage()
    : super(
        durationFunction: (cas) => cas.recipe.exhaustDuration,
        nextStateFunction: (cas) => OpenSlideDoor(),
      );

  @override
  String get name => 'ExhaustStage';

  @override
  void onStart(ModuleCas cas) {
    super.onStart(cas);
    var destination = cas.moduleGroupDestinationAfterStunning;
    var moduleGroup = cas.moduleGroupPlace.moduleGroup!;
    moduleGroup.endStunning();
    moduleGroup.destination = destination;
  }
}

class OpenSlideDoor extends DurationState<ModuleCas> {
  OpenSlideDoor()
    : super(
        durationFunction: (cas) => cas.openDoorDuration,
        nextStateFunction: (cas) => WaitToFeedOut(),
      );

  @override
  String get name => 'OpenSlideDoor';
}

class WaitToFeedOut extends State<ModuleCas> {
  @override
  String get name => 'WaitToFeedOut';

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_neighborOkToFeedIn(cas)) {
      return FeedOut();
    }
    return null;
  }

  bool _neighborOkToFeedIn(ModuleCas cas) =>
      cas.modulesOut.linkedTo!.canFeedIn();
}

class FeedOut extends State<ModuleCas>
    implements ModuleTransportCompletedListener {
  bool completed = false;

  @override
  String get name => 'FeedOut';

  @override
  void onStart(ModuleCas cas) {
    cas.moduleGroupPlace.moduleGroup!.position =
        BetweenModuleGroupPlaces.forModuleOutLink(cas.modulesOut);
  }

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (completed) {
      return WaitToFeedIn();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    completed = true;
  }
}
