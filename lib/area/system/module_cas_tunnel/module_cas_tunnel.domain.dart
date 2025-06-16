// ignore_for_file: avoid_renaming_method_parameters

import 'dart:math';

import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:user_command/user_command.dart';

abstract class ModuleCasTunnelSection extends StateMachine
    implements LinkedSystem {
  final LiveBirdHandlingArea area;
  final SpeedProfile conveyorSpeedProfile;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  Shape get shape;

  ModuleCasTunnelSection({
    required this.area,
    SpeedProfile? conveyorSpeedProfile,
  }) : conveyorSpeedProfile =
           conveyorSpeedProfile ??
           area.productDefinition.speedProfiles.moduleConveyor,
       super(initialState: WaitToFeedIn());

  ModuleGroupInLink get modulesIn;

  ModuleGroupOutLink get modulesOut;

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
    modulesIn,
    modulesOut,
  ];

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late final ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: OffsetInMeters.zero,
  );

  Map<Type, State<ModuleCasTunnelSection> Function()> get nextState;

  late final configuration = ModuleCasTunnelConfiguration(area);

  Duration get minimumCycleDuration;

  Duration get noneStunDurationPerCycle;
}

class ModuleCasTunnelMiddleSection extends ModuleCasTunnelSection {
  @override
  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.bottomCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  @override
  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.topCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.north(),
    durationUntilCanFeedOut: () =>
        currentState is WaitToFeedOut ? Duration.zero : unknownDuration,
  );

  @override
  String get name => 'ModuleBufferConveyor$seqNr';

  @override
  final Map<Type, State<ModuleCasTunnelSection> Function()> nextState = {
    WaitToFeedIn: () => FeedIn(),
    FeedIn: () => WaitToStunBirds(),
    WaitToStunBirds: () => WaitToFeedOut(),
    WaitToFeedOut: () => FeedOut(),
    FeedOut: () => WaitToFeedIn(),
  };

  ModuleCasTunnelMiddleSection({
    required super.area,
    super.conveyorSpeedProfile,
  });

  @override
  late final Shape shape = Box(
    xInMeters:
        area.productDefinition.truckRows.first.footprintOnSystem.yInMeters +
        0.3,
    yInMeters:
        area.productDefinition.truckRows.first.footprintOnSystem.xInMeters +
        0.3,
  );

  late final Duration feedInDuration = modulesIn.transportDuration(modulesIn);

  late final Duration feedOutDuration = modulesOut.linkedTo!.transportDuration(
    modulesOut.linkedTo!,
  );

  @override
  late final Duration minimumCycleDuration = feedInDuration + feedOutDuration;

  @override
  late final Duration noneStunDurationPerCycle =
      (feedInDuration + feedOutDuration) * 0.5;
}

abstract class ModuleCasTunnelLift extends ModuleCasTunnelSection {
  final Direction moduleOutDirection;
  final Duration upDuration;
  final Duration downDuration;

  static const defaultUpOrDownDuration = Duration(seconds: 8);

  ModuleCasTunnelLift({
    required super.area,
    super.conveyorSpeedProfile,
    this.upDuration = const Duration(seconds: 4),
    this.downDuration = const Duration(seconds: 4),
    required this.moduleOutDirection,
  });
}

class ModuleCasTunnelInFeedLift extends ModuleCasTunnelLift {
  Duration durationSinceLastStart = Duration.zero;
  @override
  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.bottomCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  @override
  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth:
        (moduleOutDirection == Direction.counterClockWise
            ? shape.centerLeft
            : shape.centerRight) -
        shape.centerCenter,
    directionToOtherLink: moduleOutDirection == Direction.counterClockWise
        ? const CompassDirection.west()
        : const CompassDirection.east(),
    durationUntilCanFeedOut: () =>
        currentState is WaitToFeedOut ? Duration.zero : unknownDuration,
  );

  @override
  String get name => 'ModuleCasTunnelInFeedLift$seqNr';

  @override
  late final Shape shape = Box(
    xInMeters:
        area.productDefinition.truckRows.first.footprintOnSystem.xInMeters +
        0.3,
    yInMeters:
        area.productDefinition.truckRows.first.footprintOnSystem.yInMeters +
        0.3,
  );

  @override
  late final Map<Type, State<ModuleCasTunnelSection> Function()> nextState = {
    WaitToFeedIn: () => FeedIn(),
    FeedIn: () => WaitOnNextStartInterval(),
    WaitOnNextStartInterval: () => Down(),
    Down: () => WaitToStunBirds(),
    WaitToStunBirds: () => WaitToFeedOut(),
    WaitToFeedOut: () => FeedOut(),
    FeedOut: () => Up(),
    Up: () => WaitToFeedIn(),
  };

  ModuleCasTunnelInFeedLift({
    required super.area,
    super.conveyorSpeedProfile,
    super.upDuration = ModuleCasTunnelLift.defaultUpOrDownDuration,
    super.downDuration = ModuleCasTunnelLift.defaultUpOrDownDuration,
    required super.moduleOutDirection,
  });

  late final Duration feedInDuration = modulesIn.transportDuration(modulesIn);

  late final Duration feedOutDuration = modulesOut.linkedTo!.transportDuration(
    modulesOut.linkedTo!,
  );

  @override
  late final Duration minimumCycleDuration =
      feedInDuration + downDuration + feedOutDuration + upDuration;

  @override
  late final Duration noneStunDurationPerCycle =
      feedInDuration + feedOutDuration * 0.5 + upDuration;

  bool _isFirstModule = true;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    durationSinceLastStart += jump;
    super.onUpdateToNextPointInTime(jump);
  }

  @override
  ObjectDetails get objectDetails => super.objectDetails.appendProperty(
    'durationSinceLastStart',
    durationSinceLastStart,
  );

  bool get isFirstModule => _isFirstModule;

  void onStartStun() {
    durationSinceLastStart = Duration.zero;
    _isFirstModule = false;
    var moduleGroup = moduleGroupPlace.moduleGroup!;
    moduleGroup.startStunning();
  }
}

class WaitOnNextStartInterval extends State<ModuleCasTunnelSection> {
  @override
  String get name => 'WaitOnNextStartInterval';

  @override
  State<ModuleCasTunnelSection>? nextState(ModuleCasTunnelSection section) {
    var inFeedLift = section as ModuleCasTunnelInFeedLift;
    if (inFeedLift.isFirstModule ||
        inFeedLift.durationSinceLastStart >
            inFeedLift.configuration.startInterval) {
      inFeedLift.onStartStun();
      return inFeedLift.nextState[WaitOnNextStartInterval]!();
    }
    return null;
  }
}

class ModuleCasTunnelOutFeedLift extends ModuleCasTunnelLift {
  Duration? stunDurationOfLastModule;
  Duration? cycleDuration;
  Durations cycleDurations = Durations(maxSize: 8);

  @override
  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.bottomCenter - shape.centerCenter,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  @override
  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth:
        (moduleOutDirection == Direction.counterClockWise
            ? shape.centerLeft
            : shape.centerRight) -
        shape.centerCenter,
    directionToOtherLink: moduleOutDirection == Direction.counterClockWise
        ? const CompassDirection.west()
        : const CompassDirection.east(),
    durationUntilCanFeedOut: () =>
        currentState is WaitToFeedOut ? Duration.zero : unknownDuration,
  );

  @override
  String get name => 'ModuleCasTunnelOutFeedLift$seqNr';

  @override
  late final Shape shape = Box(
    xInMeters:
        area.productDefinition.truckRows.first.footprintOnSystem.yInMeters +
        0.3,
    yInMeters:
        area.productDefinition.truckRows.first.footprintOnSystem.xInMeters +
        0.3,
  );

  @override
  late final Map<Type, State<ModuleCasTunnelSection> Function()> nextState = {
    WaitToFeedIn: () => FeedIn(),
    FeedIn: () => WaitToStunBirds(),
    WaitToStunBirds: () => Up(),
    Up: () => WaitToFeedOut(),
    WaitToFeedOut: () => FeedOut(),
    FeedOut: () => Down(),
    Down: () => WaitToFeedIn(),
  };

  ModuleCasTunnelOutFeedLift({
    required super.area,
    super.conveyorSpeedProfile,
    super.upDuration = ModuleCasTunnelLift.defaultUpOrDownDuration,
    super.downDuration = ModuleCasTunnelLift.defaultUpOrDownDuration,
    required super.moduleOutDirection,
  });

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (cycleDuration != null) {
      cycleDuration = cycleDuration! + jump;
    }

    super.onUpdateToNextPointInTime(jump);
  }

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendObjectDetails(configuration.objectDetails)
      .appendProperty('stunDurationOfLastModule', stunDurationOfLastModule)
      .appendProperty(
        'module speed',
        '${cycleDurations.averagePerHour.toStringAsFixed(1)} modules/hour',
      );

  late final Duration feedInDuration = modulesIn.transportDuration(modulesIn);

  late final Duration feedOutDuration = modulesOut.linkedTo!.transportDuration(
    modulesOut.linkedTo!,
  );

  @override
  late final Duration minimumCycleDuration =
      feedInDuration + upDuration + feedOutDuration + downDuration;

  @override
  late final Duration noneStunDurationPerCycle =
      feedInDuration * 0.5 + upDuration + feedOutDuration + downDuration;

  void onEndStun() {
    var moduleGroup = moduleGroupPlace.moduleGroup!;
    moduleGroup.endStunning();
    stunDurationOfLastModule = moduleGroup.sinceStartStun;
    if (cycleDuration != null) {
      cycleDurations.add(cycleDuration);
    }
    cycleDuration = Duration.zero;
  }
}

class WaitToFeedIn extends State<ModuleCasTunnelSection>
    implements ModuleTransportStartedListener {
  var transportStarted = false;

  @override
  String get name => 'WaitToFeedIn';

  @override
  State<ModuleCasTunnelSection>? nextState(ModuleCasTunnelSection system) {
    if (transportStarted) {
      return system.nextState[WaitToFeedIn]!();
    }
    return null;
  }

  @override
  void onModuleTransportStarted(_) {
    transportStarted = true;
  }
}

class FeedIn extends State<ModuleCasTunnelSection>
    implements ModuleTransportCompletedListener {
  @override
  String get name => 'FeedIn';
  bool transportCompleted = false;

  @override
  State<ModuleCasTunnelSection>? nextState(ModuleCasTunnelSection system) {
    if (transportCompleted) {
      return system.nextState[FeedIn]!();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class WaitToFeedOut extends State<ModuleCasTunnelSection> {
  @override
  String get name => 'WaitToFeedOut';

  @override
  State<ModuleCasTunnelSection>? nextState(ModuleCasTunnelSection system) {
    if (neighborCanFeedIn(system) && !_moduleGroupAtDestination(system)) {
      return system.nextState[WaitToFeedOut]!();
    }
    return null;
  }

  bool neighborCanFeedIn(ModuleCasTunnelSection conveyor) =>
      conveyor.modulesOut.linkedTo!.canFeedIn();

  bool _moduleGroupAtDestination(ModuleCasTunnelSection conveyor) =>
      conveyor.moduleGroupPlace.moduleGroup!.destination == conveyor;
}

class FeedOut extends State<ModuleCasTunnelSection>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOut';

  @override
  void onStart(ModuleCasTunnelSection system) {
    var transportedModuleGroup = system.moduleGroupPlace.moduleGroup!;
    transportedModuleGroup.position = BetweenModuleGroupPlaces.forModuleOutLink(
      system.modulesOut,
    );
  }

  @override
  State<ModuleCasTunnelSection>? nextState(ModuleCasTunnelSection system) {
    if (transportCompleted) {
      return system.nextState[FeedOut]!();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class Up extends DurationState<ModuleCasTunnelSection> {
  Up()
    : super(
        durationFunction: (system) =>
            (system as ModuleCasTunnelLift).upDuration,
        nextStateFunction: (system) => system.nextState[Up]!(),
      );

  @override
  void onStart(ModuleCasTunnelSection section) {
    if (section is ModuleCasTunnelOutFeedLift) {
      section.onEndStun();
    }
  }

  @override
  String get name => 'Up';
}

class Down extends DurationState<ModuleCasTunnelSection> {
  Down()
    : super(
        durationFunction: (system) =>
            (system as ModuleCasTunnelLift).downDuration,
        nextStateFunction: (system) => system.nextState[Down]!(),
      );

  @override
  String get name => 'Down';
}

class WaitToStunBirds extends DurationState<ModuleCasTunnelSection> {
  WaitToStunBirds()
    : super(
        durationFunction: calculateRemainingStunDuration,
        nextStateFunction: (system) => system.nextState[WaitToStunBirds]!(),
      );

  @override
  String get name => 'WaitToStunBirds';

  static Duration calculateRemainingStunDuration(
    ModuleCasTunnelSection system,
  ) {
    var remainingDuration =
        system.configuration.durationPerSection - system.minimumCycleDuration;
    return remainingDuration < Duration.zero
        ? Duration.zero
        : remainingDuration;
  }
}

class ModuleCasTunnelConfiguration implements DetailProvider {
  final LiveBirdHandlingArea area;
  late final CasRecipe casRecipe = area.productDefinition.casRecipe!;
  late final Duration totalStunDuration = casRecipe.totalDurationStunStages();

  /// Each tunnel will need some over capacity, so when the line speed increases
  /// you do not need to add extra tunnel segments
  ///
  /// e.g. when line speed is 10.000 b/h and it will later bu upgraded to 12.000 b/h
  /// than this is 12.000 / 10.000= 20 % over capacity needed = 0.2
  static const double overCapacityFactor = 0.2;

  /// The tunnel needs to be able to catch up after a problem.
  /// We therefor normally add 10% on top of the [overCapacityFactor]
  /// 10% =0.1
  static const double catchUpFactor = 0.1;

  /// the amount of additional capacity needed
  /// normally this is 100% [overCapacityFactor] + [catchUpFactor]
  ///
  /// e.g. additionalCapacityFactor = 1 + 0.2 + 0.1 = 1.3, so 30% extra capacity
  static const double additionalCapacityFactor =
      1 + overCapacityFactor + catchUpFactor;

  late final double modulesPerHour =
      area.productDefinition.lineSpeedInShacklesPerHour /
      area.productDefinition.averageNumberOfBirdsPerModule;
  late final Duration startInterval = Duration(hours: 1) * (1 / modulesPerHour);

  late final Duration noneEffectiveStunningTimeOfTunnel = tunnelSections().fold(
    Duration.zero,
    (sum, item) => sum + item.noneStunDurationPerCycle,
  );

  Iterable<ModuleCasTunnelSection> tunnelSections() {
    var sections = area.systems.whereType<ModuleCasTunnelSection>();
    if (sections.whereType<ModuleCasTunnelInFeedLift>().length > 1) {
      throw Exception('Expected only one ModuleCasTunnelInFeedLift');
    }
    return sections;
  }

  late final Duration maxTotalTunnelDuration =
      (totalStunDuration * additionalCapacityFactor) +
      noneEffectiveStunningTimeOfTunnel;

  late final int numberOfSections = max(
    3,
    (maxTotalTunnelDuration.inMicroseconds / startInterval.inMicroseconds)
        .ceil(),
  );

  late final Duration maxDurationPerSection =
      maxTotalTunnelDuration * (1 / numberOfSections);

  late final Duration totalTunnelDuration =
      totalStunDuration + noneEffectiveStunningTimeOfTunnel;

  late final Duration durationPerSection =
      totalTunnelDuration * (1 / numberOfSections);

  late final List<ModuleCasTunnelSectionConfiguration> sectionConfigurations =
      _createSectionConfigurations();

  List<ModuleCasTunnelSectionConfiguration> _createSectionConfigurations() {
    var stunDurationSoFar = Duration.zero;
    var sectionConfigs = <ModuleCasTunnelSectionConfiguration>[];
    for (var section in tunnelSections()) {
      var sectionStunDuration =
          durationPerSection - section.noneStunDurationPerCycle;
      var co2Percentages = casRecipe.co2Percentages(
        stunDurationSoFar.inSeconds,
        sectionStunDuration.inSeconds,
      );
      var co2Concentration = co2Percentages.isEmpty
          ? 0.0
          : co2Percentages.reduce((a, b) => a + b) / co2Percentages.length;
      sectionConfigs.add(
        ModuleCasTunnelSectionConfiguration(
          effectiveStunDuration: sectionStunDuration,
          co2Concentration: co2Concentration,
        ),
      );
      stunDurationSoFar = stunDurationSoFar + sectionStunDuration;
    }
    return sectionConfigs;
  }

  ModuleCasTunnelConfiguration(this.area) {
    validateSpeed();
    validateNumberOfSections();
  }

  @override
  String get name => 'ModuleCasTunnelConfiguration';

  @override
  late final ObjectDetails objectDetails = ObjectDetails(name)
      .appendProperty('totalStunDuration', totalStunDuration)
      .appendProperty(
        'noneEffectiveStunningTimeOfTunnel',
        noneEffectiveStunningTimeOfTunnel,
      )
      .appendProperty('overCapacityFactor', overCapacityFactor)
      .appendProperty('numberOfSections', numberOfSections)
      .appendProperty('modulesPerHour', modulesPerHour)
      .appendProperty('startInterval', startInterval)
      .appendProperty('durationPerSection', durationPerSection)
      .appendProperty('sectionConfigurations', sectionConfigurations);

  void validateSpeed() {
    var sections = tunnelSections();
    var slowestSection = sections.fold(
      sections.first,
      (longest, item) =>
          longest.minimumCycleDuration > item.minimumCycleDuration
          ? longest
          : item,
    );
    //FIXME OutFeedLift has negative duration > 90.9 modules/hour
    var slowestSectionModulesPerHour =
        3600000 / slowestSection.minimumCycleDuration.inMilliseconds;
    if (modulesPerHour > slowestSectionModulesPerHour) {
      throw Exception(
        'You need to run ${modulesPerHour.toStringAsFixed(1)} modules/hour'
        ', but ${slowestSection.name} can only run '
        '${slowestSectionModulesPerHour.toStringAsFixed(1)} modules/hour',
      );
    }
  }

  void validateNumberOfSections() {
    var numberOfSectionsInArea = tunnelSections().length;
    if (numberOfSections != numberOfSectionsInArea) {
      throw Exception(
        'Your area must have $numberOfSections ModuleCasTunnelSections',
      );
    }
  }
}

class ModuleCasTunnelSectionConfiguration {
  final Duration effectiveStunDuration;
  final double co2Concentration;

  ModuleCasTunnelSectionConfiguration({
    required this.effectiveStunDuration,
    required this.co2Concentration,
  });

  @override
  String toString() {
    return '(duration: ${effectiveStunDuration.inMinutes}:${(effectiveStunDuration.inSeconds % 60).toString().padLeft(2, '0')}, co2: ${co2Concentration.toStringAsFixed(2)}%)';
  }
}
