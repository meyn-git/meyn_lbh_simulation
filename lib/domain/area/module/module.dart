import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module_variant_builder.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/gui/area/area.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module.dart';
import 'package:user_command/user_command.dart';

import '../life_bird_handling_area.dart';
import '../state_machine.dart';

/// A [ModuleGroup] can be one or more modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side or 2 stacks of modules

class ModuleGroup extends DelegatingMap<PositionWithinModuleGroup, Module>
    implements TimeProcessor, Detailable, ModuleVariantBase, Commandable {
  @override
  late final BirdType birdType = modules.first.variant.birdType;

  @override
  late final Brand brand = modules.first.variant.brand;

  @override
  late final Compartment compartment = modules.first.variant.compartment;

  @override
  late final int compartmentsPerLevel =
      modules.first.variant.compartmentsPerLevel;

  @override
  late final String family = modules.first.variant.family;

  @override
  late final SizeInMeters moduleGroundSurface =
      modules.first.variant.moduleGroundSurface;

  @override
  late final compartmentGroundSurface = SizeInMeters(
      xInMeters: moduleGroundSurface.xInMeters,
      yInMeters: moduleGroundSurface.yInMeters / compartmentsPerLevel);

  @override
  late final ModuleVersion? version = modules.first.variant.version;

  /// The direction (rotation) of the module group. This is the direction
  /// that the doors would be pointing towards (if it has any)
  CompassDirection direction;
  PhysicalSystem destination;
  PositionOnSystem position;

  late ModuleGroupShape shape;

  ModuleGroup({
    required Map<PositionWithinModuleGroup, Module> modules,
    required this.direction,
    required this.destination,
    required this.position,
  }) : super(modules) {
    _refresh();
  }

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  // this method needs to be called when modules are added or removed
  void _refresh() {
    validateNotEmpty();
    validateIfModulesAreOfTheSameBase();
    shape = ModuleGroupShape(this);
  }

  void validateNotEmpty() {
    if (isEmpty) {
      throw Exception('A ModuleGroup may never be empty');
    }
  }

  void validateIfModulesAreOfTheSameBase() {
    for (var module in modules) {
      if (!module.variant.hasShameBaseAs(this)) {
        throw Exception('Modules must have the same variant base');
      }
    }
  }

  int get numberOfModules => keys.length;

  @override
  onUpdateToNextPointInTime(Duration jump) {
    if (position is TimeProcessor) {
      (position as TimeProcessor).onUpdateToNextPointInTime(jump);
    }
    if (sinceLoadedOnSystem != null) {
      sinceLoadedOnSystem = sinceLoadedOnSystem! + jump;
    }
    if (sinceStartStun != null) {
      sinceStartStun = sinceStartStun! + jump;
    }
    if (sinceEndStun != null) {
      sinceEndStun = sinceEndStun! + jump;
    }
    if (sinceBirdsUnloaded != null) {
      sinceBirdsUnloaded = sinceBirdsUnloaded! + jump;
    }
  }

  @override
  Module? remove(Object? key) {
    var remove = super.remove(key);
    _refresh();
    return remove;
  }

  @override
  late String name = 'ModuleGroup';

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      //.appendProperty('doorDirection', direction)
      .appendProperty('destination', destination.name)
      .appendProperty('modules', modules);
  @override
  String toString() => objectDetails.toString();

  Iterable<Module> get modules => values;

  Duration? get sinceLoadedOnSystem => modules.firstOrNull?.sinceLoadedOnSystem;

  set sinceLoadedOnSystem(Duration? duration) {
    for (var module in modules) {
      module.sinceLoadedOnSystem = duration;
    }
  }

  void loadedOnToSystem() {
    sinceLoadedOnSystem = Duration.zero;
  }

  Duration? get sinceStartStun => modules.firstOrNull?.sinceStartStun;

  set sinceStartStun(Duration? duration) {
    for (var module in modules) {
      module.sinceStartStun = duration;
    }
  }

  void startStunning() {
    sinceStartStun = Duration.zero;
  }

  Duration? get sinceEndStun => modules.firstOrNull?.sinceEndStun;

  set sinceEndStun(Duration? duration) {
    for (var module in modules) {
      module.sinceEndStun = duration;
    }
  }

  void endStunning() {
    sinceEndStun = Duration.zero;
  }

  Duration? get sinceBirdsUnloaded => modules.firstOrNull?.sinceBirdsUnloaded;

  set sinceBirdsUnloaded(Duration? duration) {
    for (var module in modules) {
      module.sinceBirdsUnloaded = duration;
    }
  }

  int get numberOfBirds => values.map((module) => module.nrOfBirds).sum;

  void unloadBirds() {
    sinceBirdsUnloaded = Duration.zero;
    for (var module in modules) {
      module.nrOfBirds = 0;
    }
  }

  BirdContents get contents {
    if (sinceBirdsUnloaded != null) {
      return BirdContents.noBirds;
    } else if (sinceEndStun != null) {
      return BirdContents.stunnedBirds;
    } else if (sinceStartStun != null) {
      return BirdContents.birdsBeingStunned;
    } else {
      return BirdContents.awakeBirds;
    }
  }

  Iterable<PositionWithinModuleGroup> get positions => keys;

  Iterable<int> get stackNumbers =>
      keys.map((position) => position.stackNumber).toSet();

  int get numberOfStacks => stackNumbers.length;

  Map<PositionWithinModuleGroup, Module> stack(int stackNumber) => {
        for (var position in positions
            .where((position) => position.stackNumber == stackNumber))
          position: this[position]!
      };

  List<Map<PositionWithinModuleGroup, Module>> get stacks =>
      [for (var stackNumber in stackNumbers) stack(stackNumber)];

  bool get isStacked =>
      keys.contains(PositionWithinModuleGroup.firstBottom) &&
          keys.contains(PositionWithinModuleGroup.firstTop) ||
      keys.contains(PositionWithinModuleGroup.secondBottom) &&
          keys.contains(PositionWithinModuleGroup.secondTop);

  isBeingTransportedTo(PhysicalSystem system) =>
      position is BetweenModuleGroupPlaces &&
      (position as BetweenModuleGroupPlaces).destination.system == system;
}

enum PositionWithinModuleGroup {
  firstBottom(stackNumber: 0, level: 0),
  firstTop(stackNumber: 0, level: 1),
  secondBottom(stackNumber: 1, level: 0),
  secondTop(stackNumber: 1, level: 1),
  ;

  /// the stack number of a [Module] within a [ModuleGroup]
  /// * 0= first (leading stack)
  /// * 1= second stack (if any)
  final int stackNumber;

  /// the level of a [Module] within a [ModuleGroup]
  /// * 0= bottom level
  /// * 1= stacked on bottom level (if any)
  final int level;
  const PositionWithinModuleGroup(
      {required this.stackNumber, required this.level});
}

enum BirdContents { awakeBirds, birdsBeingStunned, stunnedBirds, noBirds }

abstract class PositionOnSystem {
  /// topLeft of [AreaPanel] to the center of a thing on a [PhysicalSystem]
  OffsetInMeters center(SystemLayout layout);
}

class AtModuleGroupPlace implements PositionOnSystem, Detailable {
  final ModuleGroupPlace place;
  OffsetInMeters? _center;

  @override
  final String name = 'Module Position';

  AtModuleGroupPlace(this.place);

  @override
  ObjectDetails get objectDetails =>
      ObjectDetails(name)..appendProperty('position', place);

  @override
  OffsetInMeters center(SystemLayout layout) {
    _center = _center ?? _calculateCenter(layout);
    return _center!;
  }

  OffsetInMeters _calculateCenter(SystemLayout layout) {
    var system = place.system;
    var offset = place.offsetFromCenterWhenSystemFacingNorth;
    var positionOnSystem = layout.positionOnSystem(system, offset);
    return positionOnSystem;
  }
}

class BetweenModuleGroupPlaces
    implements PositionOnSystem, TimeProcessor, Detailable {
  late ModuleGroup moduleGroup;
  final ModuleGroupPlace source;
  final ModuleGroupPlace destination;
  final Duration duration;
  OffsetInMeters? startPosition;
  OffsetInMeters? travelPath;
  Duration elapsed = Duration.zero;

  @override
  late String name = 'BetweenModuleGroupPlaces';

  late final ModuleGroup transportedModuleGroup;

  BetweenModuleGroupPlaces({
    required this.source,
    required this.destination,
    required this.duration,
  }) : moduleGroup = source.moduleGroup! {
    onModuleTransportStarted();
  }

  BetweenModuleGroupPlaces.forModuleOutLink(ModuleGroupOutLink moduleOutLink)
      : source = moduleOutLink.place,
        destination = moduleOutLink.linkedTo!.place,
        duration = hasSpeedProfile(moduleOutLink)
            ? calculateDuration(moduleOutLink)
            : Duration(
                milliseconds: max(moduleOutLink.feedOutDuration.inMilliseconds,
                    moduleOutLink.linkedTo!.feedInDuration.inMilliseconds)),
        moduleGroup = moduleOutLink.place.moduleGroup! {
    onModuleTransportStarted();
  }

  static Duration calculateDuration(
      ModuleGroupOutLink<PhysicalSystem> moduleOutLink) {
    var source = moduleOutLink;
    var destination = moduleOutLink.linkedTo!;
    var lengthInMeters =
        source.distanceToFeedOutInMeters + destination.distanceToFeedInInMeters;
    var duration = destination.speedProfile!.durationOfDistance(lengthInMeters);
    print('${source.system.name}-${destination.system.name}: '
        '${feedOutDistanceInMeters(moduleOutLink)} + '
        '${nextConveyorFeedInDistanceInMeters(moduleOutLink)} ='
        ' $lengthInMeters m = ${(duration.inMilliseconds / 1000)} s');

    return duration;
  }

  static double feedOutDistanceInMeters(
      ModuleGroupOutLink<PhysicalSystem> moduleOutLink) {
    var linkOffset = moduleOutLink.offsetFromCenterWhenFacingNorth;
    var modulePlaceOffset =
        moduleOutLink.place.offsetFromCenterWhenSystemFacingNorth;
    var lengthInMeters = (modulePlaceOffset - linkOffset).lengthInMeters.abs();
    return lengthInMeters;
  }

  static double nextConveyorFeedInDistanceInMeters(
      ModuleGroupOutLink<PhysicalSystem> moduleOutLink) {
    var linkOffset = moduleOutLink.linkedTo!.offsetFromCenterWhenFacingNorth;
    var modulePlaceOffset =
        moduleOutLink.linkedTo!.place.offsetFromCenterWhenSystemFacingNorth;
    var lengthInMeters = (modulePlaceOffset - linkOffset).lengthInMeters.abs();
    return lengthInMeters;
  }

  void onModuleTransportStarted() {
    transportedModuleGroup = source.moduleGroup!;
    source.moduleGroup = null;
    _callOnModuleTransportStarted(source);
    _callOnModuleTransportStarted(destination);
  }

  void _callOnModuleTransportStarted(ModuleGroupPlace position) {
    var system = position.system;
    if (system is StateMachine) {
      var stateMachine = system as StateMachine;
      if (stateMachine.currentState is ModuleTransportStartedListener) {
        var listener =
            stateMachine.currentState as ModuleTransportStartedListener;
        listener.onModuleTransportStarted(this);
      }
    }
  }

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    elapsed += jump;
    if (elapsed > duration) {
      elapsed = duration;
      onModuleTransportCompleted();
    }
  }

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
    ..appendProperty('source', source.system.name)
    ..appendProperty('destination', destination.system.name);

  @override
  OffsetInMeters center(SystemLayout layout) {
    startPosition ??= _startPosition(layout);
    travelPath ??= _travelPath(layout);
    return startPosition! + travelPath! * completedFraction;
  }

  double get completedFraction =>
      elapsed.inMicroseconds / duration.inMicroseconds;

  OffsetInMeters _startPosition(SystemLayout layout) =>
      _moduleCenterPosition(layout, source);

  OffsetInMeters _endPosition(SystemLayout layout) =>
      _moduleCenterPosition(layout, destination);

  OffsetInMeters _moduleCenterPosition(
      SystemLayout layout, ModuleGroupPlace position) {
    var system = position.system;
    var offset = position.offsetFromCenterWhenSystemFacingNorth;
    return layout.positionOnSystem(system, offset);
  }

  OffsetInMeters _travelPath(SystemLayout layout) =>
      _endPosition(layout) - startPosition!;

  void onModuleTransportCompleted() {
    _callOnModuleTransportCompleted(source.system);
    _callOnModuleTransportCompleted(destination.system);
    transportedModuleGroup.position = AtModuleGroupPlace(destination);
    destination.moduleGroup = transportedModuleGroup;
  }

  void _callOnModuleTransportCompleted(PhysicalSystem system) {
    if (system is StateMachine) {
      var stateMachine = system as StateMachine;
      if (stateMachine.currentState is ModuleTransportCompletedListener) {
        var listener =
            stateMachine.currentState as ModuleTransportCompletedListener;
        listener.onModuleTransportCompleted(this);
      }
    }
  }

  static hasSpeedProfile(ModuleGroupOutLink<PhysicalSystem> moduleOutLink) =>
      moduleOutLink.linkedTo!.speedProfile != null;
}

abstract class ModuleTransportCompletedListener {
  /// Will be called by [BetweenModuleGroupPlaces]
  void onModuleTransportCompleted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces);
}

abstract class ModuleTransportStartedListener {
  /// Will be called by [BetweenModuleGroupPlaces]
  void onModuleTransportStarted(
      BetweenModuleGroupPlaces betweenModuleGroupPlaces);
}

class Module implements Detailable, Commandable {
  final ModuleVariant variant;
  final int sequenceNumber;
  int nrOfBirds;
  Duration? sinceLoadedOnSystem;
  Duration? sinceStartStun;
  Duration? sinceEndStun;
  Duration? sinceBirdsUnloaded;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  Module({
    required this.variant,
    required this.sequenceNumber,
    required this.nrOfBirds,
  });

  @override
  late String name = 'Module';

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('sequenceNumber', sequenceNumber)
      .appendProperty('levels', variant.levels)
      .appendProperty('nrOfBirds', nrOfBirds)
      .appendProperty('sinceLoadedOnSystem', sinceLoadedOnSystem)
      .appendProperty('sinceStartStun', sinceStartStun)
      .appendProperty('sinceEndStun', sinceEndStun)
      .appendProperty('sinceBirdsUnloaded', sinceBirdsUnloaded);

  @override
  String toString() => objectDetails.toString();
}

enum ModuleBirdExitDirection { bothSides, left, right }

class LoadDensity extends DerivedMeasurement<Area, Mass> {
  LoadDensity({
    required Area minFloorSpacePerKgLiveWeight,

    /// max=100%, in summer the loading density is normally 70-90%
    required int loadingPercentage,
  }) : super.divide(
            _calculateArea(minFloorSpacePerKgLiveWeight, loadingPercentage),
            grams(1000));

  LoadDensity.floorSpaceInCm2({
    required double minCm2FloorSpacePerKgLiveWeight,

    /// max=100%, in summer the loading density is normally 70-90%
    required int loadingPercentage,
  }) : super.divide(
            _calculateArea(
                _areaFromSquareCentimeters(minCm2FloorSpacePerKgLiveWeight),
                loadingPercentage),
            grams(1000));

  /// legal density according to European regulation EEC64.32
  factory LoadDensity.eec64_432(Mass averageBirdWeight, int loadingPercentage) {
    if (averageBirdWeight <= grams(1600)) {
      return LoadDensity.floorSpaceInCm2(
          loadingPercentage: loadingPercentage,
          minCm2FloorSpacePerKgLiveWeight: 180);
    } else if (averageBirdWeight <= grams(3000)) {
      return LoadDensity.floorSpaceInCm2(
          loadingPercentage: loadingPercentage,
          minCm2FloorSpacePerKgLiveWeight: 160);
    } else if (averageBirdWeight <= grams(5000)) {
      return LoadDensity.floorSpaceInCm2(
          loadingPercentage: loadingPercentage,
          minCm2FloorSpacePerKgLiveWeight: 115);
    } else {}
    return LoadDensity.floorSpaceInCm2(
        loadingPercentage: loadingPercentage,
        minCm2FloorSpacePerKgLiveWeight: 150);
  }

  static Area _areaFromSquareCentimeters(double squareCentimeters) =>
      Area.of(centi.meters(squareCentimeters), centi.meters(1));

  double get squareMeterPerKgLiveWeight => as(Area.square(meters), kilo.grams);

  @override
  String toString() {
    return 'LoadDensity{squareMeterPerKgLiveWeight: $squareMeterPerKgLiveWeight}';
  }

  static Area _calculateArea(Area area, int loadingPercentage) {
    var factor = 100 / loadingPercentage;
    var side = meters(area.as(meters, meters) * factor);
    return Area.of(side, meters(1));
  }
}

enum Brand {
  meyn,
  marel,
  baaderLinco,
  angliaAutoFlow,
}

class ModuleTemplate {
  final ModuleVariant variant;
  final int birdsPerCompartment;

  ModuleTemplate({required this.variant, required this.birdsPerCompartment}) {
    _verifyNumberOfBirds();
  }

  int get compartments => variant.compartmentsPerLevel * variant.levels;

  int get numberOfBirds => compartments * birdsPerCompartment;

  @override
  String toString() => '${variant.levels}L'
      '${variant.compartmentsPerLevel == 1 ? '' : 'x${variant.compartmentsPerLevel}C'}'
      'x${birdsPerCompartment}B';

  void _verifyNumberOfBirds() {
    if (birdsPerCompartment < 1) {
      throw ArgumentError(
          'A ModuleTemplate must contain birds', 'numberOfBirds');
    }
  }
}

class TruckRow
    extends DelegatingMap<PositionWithinModuleGroup, ModuleTemplate> {
  /// how often this Module Combination is loaded on to the system
  /// 1=100% of the time, 0.25=25% of the time
  final double occurrence;

  late final SizeInMeters footprintOnSystem = _calculateFootprint();

  TruckRow(
    super.moduleCapacities, {
    this.occurrence = 1,
  });

  Iterable<PositionWithinModuleGroup> get positions => keys;

  Iterable<ModuleTemplate> get templates => values;

  int get numberOfBirds =>
      templates.map((template) => template.numberOfBirds).sum;

  @override
  String toString() {
    var strings = templates.map((template) => template.toString()).toList();
    var result = StringBuffer();
    for (String string in strings.toSet()) {
      var count = strings.where((s) => s == string).length;
      if (result.length > 0) {
        result.write('+');
      }
      if (count > 1) {
        result.write('${count}x$string');
      } else {
        result.write(string);
      }
    }
    return result.toString();
  }

  SizeInMeters _calculateFootprint() {
    var positions = keys;
    var numberOfStacks =
        positions.map((position) => position.stackNumber).toSet().length;
    var moduleFootprint = templates.first.variant.moduleGroundSurface;
    var width = moduleFootprint.xInMeters;
    var length = numberOfStacks * moduleFootprint.yInMeters +
        (numberOfStacks - 1) * ModuleGroupShape.offsetBetweenStacks;
    return SizeInMeters(xInMeters: width, yInMeters: length);
  }

  void validateIsNotEmpty() {
    if (isEmpty) {
      throw ArgumentError('May not be empty');
    }
  }
}

enum BirdType { chicken, turkey }

enum ModuleFrameMaterial { galvanizedSteel, stainlessSteel }
