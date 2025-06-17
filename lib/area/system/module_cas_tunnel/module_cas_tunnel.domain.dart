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
  final double internalCabinHeightInMeters = 1.7; //assumption
  late final double cabinVolumeInM3 =
      shape.size.xInMeters * shape.size.xInMeters * internalCabinHeightInMeters;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  Shape get shape;

  late final configuration = ModuleCasTunnelConfiguration(area);

  late final int sectionNumber = this is ModuleCasTunnelInFeedLift
      ? 0
      : (modulesIn.linkedTo!.system as ModuleCasTunnelSection).sectionNumber +
            1;

  ModuleCasTunnelSection({
    required this.area,
    SpeedProfile? conveyorSpeedProfile,
  }) : conveyorSpeedProfile =
           conveyorSpeedProfile ??
           area.productDefinition.speedProfiles.moduleConveyor,
       super(initialState: WaitToFeedIn(InitialCo2Value()));

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

  Duration get minimumCycleDuration;

  Duration get noneStunDurationPerCycle;

  Co2ConcentrationProvider get co2ConcentrationProvider =>
      (currentState as ModuleCasTunnelState).co2ConcentrationProvider;

  double get co2ConcentrationActual =>
      co2ConcentrationProvider.co2Concentration();

  double get co2ConcentrationSetPoint => configuration
      .sectionConfigurations[sectionNumber]
      .co2ConcentrationSetPoint;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    if (co2ConcentrationProvider is TimeProcessor) {
      (co2ConcentrationProvider as TimeProcessor).onUpdateToNextPointInTime(
        jump,
      );
    }
    if (co2ConcentrationProvider is InitialCo2Value) {
      (co2ConcentrationProvider as InitialCo2Value).init(this);
    }
  }

  @override
  ObjectDetails get objectDetails => super.objectDetails
      .appendProperty(
        'co2Actual',
        '${(co2ConcentrationActual * 100).toStringAsFixed(1)}% (${co2ConcentrationProvider.name})',
      )
      .appendProperty(
        'co2SetPoint',
        '${(co2ConcentrationSetPoint * 100).toStringAsFixed(1)}%',
      );
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
  late final String name = 'ModuleCasTunnelMiddleSection$seqNr';

  @override
  late final Map<Type, State<ModuleCasTunnelSection> Function()> nextState = {
    WaitToFeedIn: () =>
        FeedIn(FeedInToChamber(this, ModuleTransportFractionCompleted(this))),
    FeedIn: () =>
        WaitToStunBirds(ControlCo2(this, ControlCo2Mode.increaseOrDecrease)),
    WaitToStunBirds: () =>
        WaitToFeedOut(ControlCo2(this, ControlCo2Mode.increaseOrDecrease)),
    WaitToFeedOut: () =>
        FeedOut(FeedOutOfChamber(this, ModuleTransportFractionCompleted(this))),
    FeedOut: () => WaitToFeedIn(ControlCo2(this, ControlCo2Mode.increaseOnly)),
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

ModuleGroup _findModuleGroupBeingTransportedToOrFrom(
  ModuleCasTunnelSection section,
) => section.area.moduleGroups.firstWhere((m) {
  if (m.position is BetweenModuleGroupPlaces &&
      ((m.position as BetweenModuleGroupPlaces).destination.system == section ||
          (m.position as BetweenModuleGroupPlaces).source.system == section)) {
    return true;
  }
  if (m.position is AtModuleGroupPlace &&
      (m.position as AtModuleGroupPlace).place.system == section) {
    return true;
  }
  return false;
});

class ModuleTransportFractionCompleted implements FractionCompletedProvider {
  final ModuleGroup moduleGroup;

  ModuleTransportFractionCompleted(ModuleCasTunnelSection section)
    : moduleGroup = _findModuleGroupBeingTransportedToOrFrom(section);

  @override
  double fractionCompleted() => moduleGroup.position is BetweenModuleGroupPlaces
      ? (moduleGroup.position as BetweenModuleGroupPlaces).completedFraction
      : 1;
}

class DurationStateFractionCompleted implements FractionCompletedProvider {
  final ModuleCasTunnelSection section;

  DurationStateFractionCompleted(this.section);

  @override
  double fractionCompleted() {
    if (section.currentState is! DurationState) {
      return 0;
    }
    try {
      var completedFraction =
          (section.currentState as DurationState).completedFraction;
      return completedFraction;
    } catch (e) {
      return 0;
    }
  }
}

abstract class ModuleCasTunnelLift extends ModuleCasTunnelSection {
  final Direction moduleOutDirection;
  final Duration upDuration;
  final Duration downDuration;

  static const defaultUpOrDownDuration = Duration(seconds: 8);

  ModuleCasTunnelLift({
    required super.area,
    super.conveyorSpeedProfile,
    this.upDuration = defaultUpOrDownDuration,
    this.downDuration = defaultUpOrDownDuration,
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
  late final String name = 'ModuleCasTunnelInFeedLift$seqNr';

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
    WaitToFeedIn: () => FeedIn(ControlCo2(this, ControlCo2Mode.increaseOnly)),
    FeedIn: () =>
        WaitOnNextStartInterval(ControlCo2(this, ControlCo2Mode.increaseOnly)),
    WaitOnNextStartInterval: () =>
        Down(FeedInToChamber(this, DurationStateFractionCompleted(this))),
    Down: () =>
        WaitToStunBirds(ControlCo2(this, ControlCo2Mode.increaseOrDecrease)),
    WaitToStunBirds: () =>
        WaitToFeedOut(ControlCo2(this, ControlCo2Mode.increaseOrDecrease)),
    WaitToFeedOut: () =>
        FeedOut(FeedOutOfChamber(this, ModuleTransportFractionCompleted(this))),
    FeedOut: () => Up(ControlCo2(this, ControlCo2Mode.increaseOnly)),
    Up: () => WaitToFeedIn(ControlCo2(this, ControlCo2Mode.increaseOnly)),
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
  ObjectDetails get objectDetails => super.objectDetails
      .appendProperty('durationSinceLastStart', durationSinceLastStart)
      .appendObjectDetails(configuration.objectDetails);

  bool get isFirstModule => _isFirstModule;

  void onStartStun() {
    durationSinceLastStart = Duration.zero;
    _isFirstModule = false;
    var moduleGroup = moduleGroupPlace.moduleGroup!;
    moduleGroup.startStunning();
  }
}

class WaitOnNextStartInterval extends State<ModuleCasTunnelSection>
    implements ModuleCasTunnelState {
  @override
  final String name = 'WaitOnNextStartInterval';

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

  @override
  final Co2ConcentrationProvider co2ConcentrationProvider;

  WaitOnNextStartInterval(this.co2ConcentrationProvider);
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
  late final String name = 'ModuleCasTunnelOutFeedLift$seqNr';

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
    WaitToFeedIn: () =>
        FeedIn(FeedInToChamber(this, ModuleTransportFractionCompleted(this))),
    FeedIn: () =>
        WaitToStunBirds(ControlCo2(this, ControlCo2Mode.increaseOrDecrease)),
    WaitToStunBirds: () =>
        Up(FeedOutOfChamber(this, DurationStateFractionCompleted(this))),
    Up: () =>
        WaitToFeedOut(ControlCo2(this, ControlCo2Mode.increaseOrDecrease)),
    WaitToFeedOut: () =>
        FeedOut(ControlCo2(this, ControlCo2Mode.increaseOrDecrease)),
    FeedOut: () => Down(ControlCo2(this, ControlCo2Mode.increaseOrDecrease)),
    Down: () =>
        WaitToFeedIn(ControlCo2(this, ControlCo2Mode.increaseOrDecrease)),
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
  ObjectDetails get objectDetails => super.objectDetails
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
    implements ModuleTransportStartedListener, ModuleCasTunnelState {
  var transportStarted = false;

  @override
  final String name = 'WaitToFeedIn';

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

  @override
  final Co2ConcentrationProvider co2ConcentrationProvider;

  WaitToFeedIn(this.co2ConcentrationProvider);
}

class FeedIn extends State<ModuleCasTunnelSection>
    implements ModuleTransportCompletedListener, ModuleCasTunnelState {
  @override
  final String name = 'FeedIn';
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

  @override
  final Co2ConcentrationProvider co2ConcentrationProvider;

  FeedIn(this.co2ConcentrationProvider);
}

class WaitToFeedOut extends State<ModuleCasTunnelSection>
    implements ModuleCasTunnelState {
  @override
  final String name = 'WaitToFeedOut';

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

  @override
  final Co2ConcentrationProvider co2ConcentrationProvider;

  WaitToFeedOut(this.co2ConcentrationProvider);
}

class FeedOut extends State<ModuleCasTunnelSection>
    implements ModuleTransportCompletedListener, ModuleCasTunnelState {
  bool transportCompleted = false;

  @override
  final String name = 'FeedOut';

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

  @override
  final Co2ConcentrationProvider co2ConcentrationProvider;

  FeedOut(this.co2ConcentrationProvider);
}

class Up extends DurationState<ModuleCasTunnelSection>
    implements ModuleCasTunnelState {
  Up(this.co2ConcentrationProvider)
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
  final String name = 'Up';

  @override
  final Co2ConcentrationProvider co2ConcentrationProvider;
}

class Down extends DurationState<ModuleCasTunnelSection>
    implements ModuleCasTunnelState {
  Down(this.co2ConcentrationProvider)
    : super(
        durationFunction: (system) =>
            (system as ModuleCasTunnelLift).downDuration,
        nextStateFunction: (system) => system.nextState[Down]!(),
      );

  @override
  final String name = 'Down';

  @override
  final Co2ConcentrationProvider co2ConcentrationProvider;
}

class WaitToStunBirds extends DurationState<ModuleCasTunnelSection>
    implements ModuleCasTunnelState {
  WaitToStunBirds(this.co2ConcentrationProvider)
    : super(
        durationFunction: calculateRemainingStunDuration,
        nextStateFunction: (system) => system.nextState[WaitToStunBirds]!(),
      );

  @override
  final String name = 'WaitToStunBirds';

  static Duration calculateRemainingStunDuration(
    ModuleCasTunnelSection system,
  ) {
    var remainingDuration =
        system.configuration.durationPerSection - system.minimumCycleDuration;
    return remainingDuration < Duration.zero
        ? Duration.zero
        : remainingDuration;
  }

  @override
  final Co2ConcentrationProvider co2ConcentrationProvider;
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
      var co2Percentages = casRecipe.co2Concentrations(
        stunDurationSoFar.inSeconds,
        sectionStunDuration.inSeconds,
      );
      var co2Concentration = co2Percentages.isEmpty
          ? 0.0
          : co2Percentages.reduce((a, b) => a + b) / co2Percentages.length;
      sectionConfigs.add(
        ModuleCasTunnelSectionConfiguration(
          effectiveStunDuration: sectionStunDuration,
          co2ConcentrationSetPoint: co2Concentration,
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
  final String name = 'ModuleCasTunnelConfiguration';

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
  // 0=0%, 0.5=50%, 1=100%
  final double co2ConcentrationSetPoint;

  ModuleCasTunnelSectionConfiguration({
    required this.effectiveStunDuration,
    required this.co2ConcentrationSetPoint,
  });

  @override
  String toString() {
    return '(duration: ${effectiveStunDuration.inMinutes}:'
        '${(effectiveStunDuration.inSeconds % 60).toString().padLeft(2, '0')}'
        ', co2: ${(co2ConcentrationSetPoint * 100).toStringAsFixed(1)}%)';
  }
}

abstract class ModuleCasTunnelState {
  Co2ConcentrationProvider get co2ConcentrationProvider;
}

/// for all variables:
/// section1 = where module transport will start
/// section2 = where module transport will end
class Co2ConcentrationDuringTransport {
  late final double section1VolumeInM3;
  late final double section1Co2ConcentrationAtStart;
  late final double section1Co2ConcentrationAtEnd;

  late final double section2VolumeInM3;
  late final double section2Co2ConcentrationAtStart;
  late final double section2Co2ConcentrationAtEnd;

  late final double moduleGroupVolumeInM3;
  late final ModuleGroup moduleGroup;

  Co2ConcentrationDuringTransport.feedingIn(ModuleCasTunnelSection section) {
    var previousSystem = section.modulesIn.linkedTo!.system;
    if (previousSystem is ModuleCasTunnelSection) {
      section1VolumeInM3 = previousSystem.cabinVolumeInM3;
      section1Co2ConcentrationAtStart = previousSystem.co2ConcentrationActual;
    } else {
      section1VolumeInM3 = section.cabinVolumeInM3;
      section1Co2ConcentrationAtStart = 0;
    }

    section2VolumeInM3 = section.cabinVolumeInM3;
    section2Co2ConcentrationAtStart = section.co2ConcentrationActual;

    initRemainingFields(section);
  }

  Co2ConcentrationDuringTransport.feedingOut(ModuleCasTunnelSection section) {
    section1VolumeInM3 = section.cabinVolumeInM3;
    section1Co2ConcentrationAtStart = section.co2ConcentrationActual;

    var nextSystem = section.modulesOut.linkedTo!.system;
    if (nextSystem is ModuleCasTunnelSection) {
      section2VolumeInM3 = nextSystem.cabinVolumeInM3;
      section2Co2ConcentrationAtStart = nextSystem.co2ConcentrationActual;
    } else {
      section2VolumeInM3 = section.cabinVolumeInM3;
      section2Co2ConcentrationAtStart = 0;
    }

    initRemainingFields(section);
  }

  void initRemainingFields(ModuleCasTunnelSection section) {
    moduleGroup = _findModuleGroupBeingTransportedToOrFrom(section);

    var moduleGroupBirdVolume =
        moduleGroup.numberOfBirds *
        0.003; // lets assume 1 chicken = 3 kg = 3 liter
    if (moduleGroup.length != 1) {
      throw Exception('Only one module per group supported for now');
    }
    var module = moduleGroup.values.first;
    if (module.variant.family != 'Grande Drawer') {
      throw Exception('Only grande drawer supported for now');
    }
    var levels = module.variant.levels;
    var nrOfDrawers = module.variant.compartmentsPerLevel * levels;
    const double aytavDrawerWeightInKg = 18.7;
    var weightOfDrawersInKg = aytavDrawerWeightInKg * nrOfDrawers;
    var deadSpaceFactor =
        1.1; // assumption 10% dead space, e.g. inside profiles
    const densityStainlessSteelInKgPerM3 = 8000;
    var moduleGroupFrameVolume =
        (module.variant.weightWithoutBirdsInKiloGram! - weightOfDrawersInKg) /
        densityStainlessSteelInKgPerM3 *
        deadSpaceFactor;
    const double densityOfHdpeInKgPerM3 = 950;
    var moduleGroupDrawerVolume =
        weightOfDrawersInKg / densityOfHdpeInKgPerM3 * deadSpaceFactor;
    moduleGroupVolumeInM3 =
        moduleGroupBirdVolume +
        moduleGroupFrameVolume +
        moduleGroupDrawerVolume;

    // var section1VolumeCo2InM3 =
    //     section1VolumeInM3 * section1Co2ConcentrationAtStart;
    // var section2VolumeCo2InM3 =
    //     section2VolumeInM3 * section2Co2ConcentrationAtStart;

    var section1RemainingVolumeCo2InM3 =
        section1Co2ConcentrationAtStart *
        (section1VolumeInM3 - moduleGroupVolumeInM3);
    var section2RemainingVolumeCo2InM3 =
        section2Co2ConcentrationAtStart *
        (section2VolumeInM3 - moduleGroupVolumeInM3);
    var gasExchangeCo2Average =
        (moduleGroupVolumeInM3 * section1Co2ConcentrationAtStart +
            moduleGroupVolumeInM3 * section2Co2ConcentrationAtStart) /
        (2 * moduleGroupVolumeInM3);

    section1Co2ConcentrationAtEnd =
        (section1RemainingVolumeCo2InM3 +
            gasExchangeCo2Average * moduleGroupVolumeInM3) /
        section1VolumeInM3;
    section2Co2ConcentrationAtEnd =
        (section2RemainingVolumeCo2InM3 +
            gasExchangeCo2Average * moduleGroupVolumeInM3) /
        section2VolumeInM3;
  }

  double calculateSection1Co2Concentration(double fractionCompleted) =>
      ((section1Co2ConcentrationAtEnd - section1Co2ConcentrationAtStart) *
          fractionCompleted) +
      section1Co2ConcentrationAtStart;

  double calculateSection2Co2Concentration(double fractionCompleted) =>
      ((section2Co2ConcentrationAtEnd - section2Co2ConcentrationAtStart) *
          fractionCompleted) +
      section2Co2ConcentrationAtStart;

  //double get transportCompletedFraction => (moduleGroup.position as BetweenModuleGroupPlaces).completedFraction;

  // ModuleGroup _findModuleGroup(
  //   ModuleCasTunnelSection section,
  //   ModuleGroups moduleGroups,
  // ) {
  //   for (var moduleGroup in moduleGroups) {
  //     if (moduleGroup.position is BetweenModuleGroupPlaces &&
  //             (moduleGroup.position as BetweenModuleGroupPlaces)
  //                     .source
  //                     .system ==
  //                 section ||
  //         (moduleGroup.position as BetweenModuleGroupPlaces)
  //                 .destination
  //                 .system ==
  //             section) {
  //       return moduleGroup;
  //     }
  //     if (moduleGroup.position is AtModuleGroupPlace &&
  //         (moduleGroup.position as AtModuleGroupPlace).place.system ==
  //             section) {
  //       return moduleGroup;
  //     }
  //   }
  //   throw Exception(
  //     'Could not find Module Group going to or from ${section.name}',
  //   );
  // }
}

abstract class Co2ConcentrationProvider {
  String get name;

  double co2Concentration();
}

class FeedInToChamber implements Co2ConcentrationProvider {
  @override
  final String name = 'FeedIn';

  final Co2ConcentrationDuringTransport co2ConcentrationDuringTransport;
  final FractionCompletedProvider fractionCompletedProvider;

  FeedInToChamber(
    ModuleCasTunnelSection section,
    this.fractionCompletedProvider,
  ) : co2ConcentrationDuringTransport =
          Co2ConcentrationDuringTransport.feedingIn(section);

  @override
  double co2Concentration() =>
      co2ConcentrationDuringTransport.calculateSection2Co2Concentration(
        max(fractionCompletedProvider.fractionCompleted(), 0.01),
      );
}

abstract class FractionCompletedProvider {
  /// returns a value between 0 (start) and 1(completed)
  double fractionCompleted();
}

class FeedOutOfChamber implements Co2ConcentrationProvider {
  @override
  final String name = 'FeedOut';

  final Co2ConcentrationDuringTransport co2ConcentrationDuringTransport;
  final FractionCompletedProvider fractionCompletedProvider;

  FeedOutOfChamber(
    ModuleCasTunnelSection section,
    this.fractionCompletedProvider,
  ) : co2ConcentrationDuringTransport =
          Co2ConcentrationDuringTransport.feedingOut(section);

  @override
  double co2Concentration() =>
      co2ConcentrationDuringTransport.calculateSection1Co2Concentration(
        max(fractionCompletedProvider.fractionCompleted(), 0.01),
      );
}

class ControlCo2 implements Co2ConcentrationProvider, TimeProcessor {
  @override
  late final String name = 'ControlCO2${mode.name}';

  Duration _elapsed = Duration.zero;

  /// 0.001 = 0.1% per sec = 1% per 10 seconds
  final double co2FillSpeedInPercentPerSecond = 0.001;
  late final Duration _duration = Duration(
    microseconds: max(
      (_co2ConcentrationBegin - _co2ConcentrationEnd).abs() ~/
          (co2FillSpeedInPercentPerSecond / 1_000_000),
      1,
    ),
  );
  late final double _co2ConcentrationBegin;
  late final double _co2ConcentrationEnd;
  final ControlCo2Mode mode;

  ControlCo2(ModuleCasTunnelSection section, this.mode)
    : _co2ConcentrationBegin = section.co2ConcentrationActual,
      _co2ConcentrationEnd = section.co2ConcentrationSetPoint {
    assert(!section.co2ConcentrationActual.isNaN);
  }

  double get fractionCompleted =>
      _elapsed.inMicroseconds / _duration.inMicroseconds;

  @override
  double co2Concentration() =>
      _co2ConcentrationEnd < _co2ConcentrationBegin &&
          mode == ControlCo2Mode.increaseOnly
      ? _co2ConcentrationBegin
      : (_co2ConcentrationEnd - _co2ConcentrationBegin) * fractionCompleted +
            _co2ConcentrationBegin;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    _elapsed = _elapsed + jump;
    if (_elapsed > _duration) {
      _elapsed = _duration;
    }
  }
}

enum ControlCo2Mode {
  /// CO2 can only be increased by injecting CO2(almost 100%)
  increaseOnly,

  /// CO2 can be increased by injecting CO2(almost 100%)
  /// or decreased by injecting atmospheric air containing O2(21%) and N2(78%)
  increaseOrDecrease,
}

class InitialCo2Value implements Co2ConcentrationProvider {
  bool get isInitialized => _co2ConcentrationSetPoint != 0;

  @override
  double co2Concentration() => _co2ConcentrationSetPoint;

  @override
  String get name => 'Init';

  double _co2ConcentrationSetPoint = 0;

  void init(ModuleCasTunnelSection section) {
    _co2ConcentrationSetPoint = section.co2ConcentrationSetPoint;
  }
}
