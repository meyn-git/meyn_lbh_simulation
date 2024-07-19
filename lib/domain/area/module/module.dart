import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/gui/area/area.dart';
import 'package:meyn_lbh_simulation/gui/area/module.dart';

import '../life_bird_handling_area.dart';
import '../state_machine.dart';

/// A [ModuleGroup] can be one or 2 modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side
///
/// TODO deprecate this class and replace with new [ModulePosition] classes:
/// * After(Module)
/// * OnTopOf(Module)
///
/// e.g: 2 stacked modules
/// * module1.position=ModuleAtMachine()
/// * module2.position=OnTopOf(module1)
///
/// e.g: 2 x 1/2 modules
/// * module1.position=ModuleAtMachine()
/// * module2.position=After(module1)
///
/// e.g: 4 x 1/2 modules
/// * module1.position=ModuleAtMachine()
/// * module2.position=OnTopOf(module1)
/// * module3.position=After(module1)
/// * module4.position=OnTopOf(module2)
///
/// Or make ModuleGroup extend DelegatingList<Module>
class ModuleGroup extends DelegatingMap<PositionWithinModuleGroup, Module>
    implements TimeProcessor, Detailable {
  final ModuleFamily family;

  /// The direction (rotation) of the module group. This is the direction
  /// that the doors would be pointing towards (if it has any)
  CompassDirection direction;
  PhysicalSystem destination;
  PositionOnSystem position;

  late ModuleGroupShape shape;

  ModuleGroup({
    required Map<PositionWithinModuleGroup, Module> modules,
    required this.family,
    required this.direction,
    required this.destination,
    required this.position,
  }) : super(modules) {
    shape = ModuleGroupShape(this);
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
    shape = ModuleGroupShape(this);
    return remove;
  }

  @override
  late String name = 'ModuleGroup';

  late final compartmentSize = SizeInMeters(
      xInMeters: family.footprintSingleModule.xInMeters,
      yInMeters:
          family.footprintSingleModule.yInMeters / family.compartmentsPerLevel);

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('doorDirection', direction)
      .appendProperty('destination', destination.name);

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

  get stacks => keys.map((position) => position.stack).toSet().length;

  isBeingTransportedTo(PhysicalSystem system) =>
      position is BetweenModuleGroupPlaces &&
      (position as BetweenModuleGroupPlaces).destination.system == system;
}

enum PositionWithinModuleGroup {
  firstBottom(stack: 0, level: 0),
  firstTop(stack: 0, level: 1),
  secondBottom(stack: 1, level: 0),
  secondTop(stack: 1, level: 1),
  ;

  /// the stack number of a [Module] within a [ModuleGroup]
  /// * 0= first (leading stack)
  /// * 1= second stack (if any)
  final int stack;

  /// the level of a [Module] within a [ModuleGroup]
  /// * 0= bottom level
  /// * 1= stacked on bottom level (if any)
  final int level;
  const PositionWithinModuleGroup({required this.stack, required this.level});
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
  late String name = 'Module Transport';

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
        duration = Duration(
            milliseconds: max(moduleOutLink.outFeedDuration.inMilliseconds,
                moduleOutLink.linkedTo!.inFeedDuration.inMilliseconds)),
        moduleGroup = moduleOutLink.place.moduleGroup! {
    onModuleTransportStarted();
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
      moduleGroup.position = AtModuleGroupPlace(destination);
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

class Module implements Detailable {
  final int sequenceNumber;
  int nrOfBirds;
  int levels;
  Duration? sinceLoadedOnSystem;
  Duration? sinceStartStun;
  Duration? sinceEndStun;
  Duration? sinceBirdsUnloaded;

  Module({
    required this.sequenceNumber,
    required this.nrOfBirds,
    required this.levels,
  });

  @override
  late String name = 'Module';

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('sequenceNumber', sequenceNumber)
      .appendProperty('nrOfBirds', nrOfBirds)
      .appendProperty('sinceLoadedOnSystem', sinceLoadedOnSystem)
      .appendProperty('sinceStartStun', sinceStartStun)
      .appendProperty('sinceEndStun', sinceEndStun)
      .appendProperty('sinceBirdsUnloaded', sinceBirdsUnloaded);

  @override
  String toString() => objectDetails.toString();
}

enum ModuleBirdExitDirection { bothSides, left, right }

enum ModuleSystem {
  ///following durations are based on measurements at: 7113-Tyson Union city
  meynVdlRectangularContainers(
    stackerInFeedDuration: Duration(seconds: 14),
    deStackerInFeedDuration: Duration(seconds: 14),
    conveyorTransportDuration: Duration(seconds: 12),
    casTransportDuration: Duration(seconds: 14),
    turnTableDegreesPerSecond: 15
    // 90 degrees in 6 seconds
    ,
  ),

  /// Same as [meynVdlRectangularContainers]
  meynGrandeDrawerContainers(
    stackerInFeedDuration: Duration(seconds: 14),
    deStackerInFeedDuration: Duration(seconds: 14),
    conveyorTransportDuration: Duration(seconds: 12),
    casTransportDuration: Duration(seconds: 14),
    turnTableDegreesPerSecond: 15
    // 90 degrees in 6 seconds
    ,
  ),

  ///following durations are based on measurements at: 8052-Indrol Grodzisk
  meynOmni(
      conveyorTransportDuration: Duration(seconds: 19),
      stackerInFeedDuration: Duration(seconds: 19),
      deStackerInFeedDuration: Duration(seconds: 19),
      casTransportDuration: Duration(seconds: 19),
      turnTableDegreesPerSecond: 8
      // 90 degrees in 11.5 seconds
      ),

  ///following durations are based on measurements at: 7696-Dabe-Germanyk
  meynSingleColumnContainers(
      conveyorTransportDuration: Duration(milliseconds: 13400),
      stackerInFeedDuration: Duration(milliseconds: 18700),
      deStackerInFeedDuration: Duration(milliseconds: 18700),
      casTransportDuration: Duration(milliseconds: 18700),
      turnTableDegreesPerSecond: 10 // 90 degrees in 9 seconds,
      );

  const ModuleSystem(
      {required this.stackerInFeedDuration,
      required this.deStackerInFeedDuration,
      required this.conveyorTransportDuration,
      required this.casTransportDuration,
      required this.turnTableDegreesPerSecond});

  final Duration stackerInFeedDuration;
  final Duration deStackerInFeedDuration;
  final Duration conveyorTransportDuration;
  final Duration casTransportDuration;
  final int turnTableDegreesPerSecond;
}

@Deprecated('Use ModuleVariant instead')
enum ModuleFamily {
  meynEvo(
      supplier: Brand.meyn,
      compartmentType: CompartmentType.doorOnOneSide,
      compartmentsPerLevel: 2,
      footprintSingleModule: SizeInMeters(xInMeters: 1.2, yInMeters: 2.4)),
  meynGrandeDrawerDoubleColumn(
      supplier: Brand.meyn,
      compartmentType: CompartmentType.drawerSlideInOutOnOneSide,
      compartmentsPerLevel: 2,
      footprintSingleModule: SizeInMeters(xInMeters: 1.18, yInMeters: 2.43)),
  meynGrandeDrawerSingleColumn(
      supplier: Brand.meyn,
      compartmentType: CompartmentType.drawerSlideInOutOnOneSide,
      compartmentsPerLevel: 1,
      footprintSingleModule: SizeInMeters(xInMeters: 1.18, yInMeters: 1.23)),
  meynMaxiLoad(
      //TODO rename to meynMaxiLoadTwin
      supplier: Brand.meyn,
      compartmentType: CompartmentType.drawerSlideInOutOnOneSide,
      compartmentsPerLevel: 2,
      footprintSingleModule: SizeInMeters(xInMeters: 1.35, yInMeters: 2.43)),
  meynOmni(
      supplier: Brand.meyn,
      compartmentType: CompartmentType.doorOnOneSide,
      compartmentsPerLevel: 2,
      footprintSingleModule: SizeInMeters(xInMeters: 1.35, yInMeters: 2.43)),
  angliaAutoFlow(
      supplier: Brand.angliaAutoFlow,
      compartmentType: CompartmentType.drawerSlideInOutOnBothSides,
      compartmentsPerLevel: 3,
      footprintSingleModule: SizeInMeters(xInMeters: 1.165, yInMeters: 2.438)),
  marelGpDoubleColumn(
      supplier: Brand.marel,
      compartmentType: CompartmentType.doorOnOneSide,
      compartmentsPerLevel: 2,
      footprintSingleModule: SizeInMeters(xInMeters: 1.2, yInMeters: 2.43)),
  marelGpSingleColumn(
      supplier: Brand.marel,
      compartmentType: CompartmentType.doorOnOneSide,
      compartmentsPerLevel: 1,
      footprintSingleModule: SizeInMeters(xInMeters: 1.2, yInMeters: 1.42));

  const ModuleFamily({
    required this.supplier,
    required this.compartmentsPerLevel,
    required this.compartmentType,
    required this.footprintSingleModule,
  });

  final Brand supplier;
  final int compartmentsPerLevel;
  final CompartmentType compartmentType;
  final SizeInMeters footprintSingleModule;
}

@Deprecated('Use ModuleVariant instead')
class ModuleType {
  final ModuleFamily moduleFamily;
  final BirdType birdType;
  final ModuleDimensions dimensions;

  ModuleType({
    required this.moduleFamily,
    required this.birdType,
    required this.dimensions,
  });
}

// class MeynEvoChicken4Level extends ModuleType {
//   MeynEvoChicken4Level()
//       : super(
//           moduleFamily: ModuleFamily.meynEvo,
//           birdType: BirdType.chicken,
//           dimensions: ModuleDimensions(
//             lengthLongSide: meters(2.4),
//             widthShortSide: meters(1.2),
//             heightWithoutCam: meters(1.23),
//             camHeight: meters(0.065),
//             headHeight: meters(0.249),
//             levels: 4,
//             compartmentsPerLevel: 2,
//             birdFloorSpacePerCompartment: Area.of(meters(1.311), meters(1)),
//             emptyWeight: kilo.grams(340),
//           ),
//         );
// }

// class MeynEvoChicken5Level extends ModuleType {
//   MeynEvoChicken5Level()
//       : super(
//           moduleFamily: ModuleFamily.meynEvo,
//           birdType: BirdType.chicken,
//           dimensions: ModuleDimensions(
//             lengthLongSide: meters(2.4),
//             widthShortSide: meters(1.2),
//             heightWithoutCam: meters(1.483),
//             camHeight: meters(0.065),
//             headHeight: meters(0.249),
//             levels: 5,
//             compartmentsPerLevel: 2,
//             birdFloorSpacePerCompartment: Area.of(meters(1.311), meters(1)),
//             emptyWeight: kilo.grams(395),
//           ),
//         );
// }

// class GrandeDrawerModuleType extends ModuleType {
//   static const double drawerOutSideLengthInMeters = 1.160;

//   static const SizeInMeters size = SizeInMeters(
//       xInMeters: drawerOutSideLengthInMeters,
//       yInMeters: drawerOutSideLengthInMeters);

//   GrandeDrawerModuleType({
//     required super.moduleFamily,
//     required super.birdType,
//     required super.dimensions,
//   });
// }

// class MeynGrandeDrawerChicken2x4 extends GrandeDrawerModuleType {
//   MeynGrandeDrawerChicken2x4()
//       : super(
//           moduleFamily: ModuleFamily.meynGrandeDrawerDoubleColumn,
//           birdType: BirdType.chicken,
//           dimensions: ModuleDimensions(
//             lengthLongSide: meters(2.43),
//             widthShortSide: meters(1.18),
//             heightWithoutCam: meters(1.31),
//             camHeight: meters(0.065),
//             //TODO Unknown! Find out and change!
//             headHeight: meters(0.255),
//             levels: 4,
//             compartmentsPerLevel: 2,
//             birdFloorSpacePerCompartment: Area.of(meters(1.221), meters(1)),
//             emptyWeight: kilo.grams(346),
//           ),
//         );
// }

// class MeynGrandeDrawerChicken2x5 extends GrandeDrawerModuleType {
//   MeynGrandeDrawerChicken2x5()
//       : super(
//           moduleFamily: ModuleFamily.meynGrandeDrawerDoubleColumn,
//           birdType: BirdType.chicken,
//           dimensions: ModuleDimensions(
//             lengthLongSide: meters(2.43),
//             widthShortSide: meters(1.18),
//             heightWithoutCam: meters(1.59),
//             camHeight: meters(0.065),
//             //TODO Unknown! Find out and change!
//             headHeight: meters(0.255),
//             levels: 5,
//             compartmentsPerLevel: 2,
//             birdFloorSpacePerCompartment: Area.of(meters(1.221), meters(1)),
//             emptyWeight: kilo.grams(404),
//           ),
//         );
// }

// class MeynOmniTurkey2x3 extends ModuleType {
//   /// maxWeight per floor =300kg (=150 per compartment)
//   MeynOmniTurkey2x3()
//       : super(
//           moduleFamily: ModuleFamily.meynOmni,
//           birdType: BirdType.turkey,
//           dimensions: ModuleDimensions(
//               lengthLongSide: meters(2.43),
//               widthShortSide: meters(1.35),
//               heightWithoutCam: meters(1.345),
//               camHeight: meters(0.059),
//               headHeight: meters(0.380),
//               levels: 3,
//               compartmentsPerLevel: 2,
//               birdFloorSpacePerCompartment: Area.of(meters(2.1), meters(1)),
//               //TODO verify. 2.1m2 seems small
//               emptyWeight: kilo.grams(420)),
//         );
// }

// class AngliaAutoFlowChickenSmall3x4 extends ModuleType {
//   AngliaAutoFlowChickenSmall3x4()
//       : super(
//           moduleFamily: ModuleFamily.angliaAutoFlow,
//           birdType: BirdType.chicken,
//           dimensions: ModuleDimensions(
//               lengthLongSide: meters(2.438),
//               widthShortSide: meters(1.165),
//               heightWithoutCam: meters(1.152),
//               camHeight: meters(0.1),
//               headHeight: meters(0.22),
//               levels: 4,
//               compartmentsPerLevel: 3,
//               birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
//               emptyWeight: kilo.grams(330)),
//         );
// }

// class AngliaAutoFlowChickenSmall3x5 extends ModuleType {
//   AngliaAutoFlowChickenSmall3x5()
//       : super(
//           moduleFamily: ModuleFamily.angliaAutoFlow,
//           birdType: BirdType.chicken,
//           dimensions: ModuleDimensions(
//               lengthLongSide: meters(2.438),
//               widthShortSide: meters(1.165),
//               heightWithoutCam: meters(1.397),
//               camHeight: meters(0.1),
//               headHeight: meters(0.22),
//               levels: 5,
//               compartmentsPerLevel: 3,
//               birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
//               emptyWeight: kilo.grams(390)),
//         );
// }

// class AngliaAutoFlowChickenLarge3x4 extends ModuleType {
//   AngliaAutoFlowChickenLarge3x4()
//       : super(
//           moduleFamily: ModuleFamily.angliaAutoFlow,
//           birdType: BirdType.chicken,
//           dimensions: ModuleDimensions(
//               lengthLongSide: meters(2.438),
//               widthShortSide: meters(1.165),
//               heightWithoutCam: meters(1.292),
//               camHeight: meters(0.1),
//               headHeight: meters(0.255),
//               levels: 4,
//               compartmentsPerLevel: 3,
//               birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
//               emptyWeight: kilo.grams(350)),
//         );
// }

// class AngliaAutoFlowChickenLarge3x5 extends ModuleType {
//   AngliaAutoFlowChickenLarge3x5()
//       : super(
//           moduleFamily: ModuleFamily.angliaAutoFlow,
//           birdType: BirdType.chicken,
//           dimensions: ModuleDimensions(
//               lengthLongSide: meters(2.438),
//               widthShortSide: meters(1.165),
//               heightWithoutCam: meters(1.572),
//               camHeight: meters(0.1),
//               headHeight: meters(0.255),
//               levels: 5,
//               compartmentsPerLevel: 3,
//               birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
//               emptyWeight: kilo.grams(410)),
//         );
// }

// class AngliaAutoFlowTurkey3x3 extends ModuleType {
//   AngliaAutoFlowTurkey3x3()
//       : super(
//           moduleFamily: ModuleFamily.angliaAutoFlow,
//           birdType: BirdType.turkey,
//           dimensions: ModuleDimensions(
//               lengthLongSide: meters(2.438),
//               widthShortSide: meters(1.165),
//               heightWithoutCam: meters(1.292),
//               camHeight: meters(0.1),
//               headHeight: meters(0.355),
//               levels: 3,
//               compartmentsPerLevel: 3,
//               birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
//               emptyWeight: kilo.grams(340)),
//         );
// }

// class MarelGpS1x4Chicken extends ModuleType {
//   MarelGpS1x4Chicken()
//       : super(
//             moduleFamily: ModuleFamily.marelGpSingleColumn,
//             birdType: BirdType.chicken,
//             dimensions: ModuleDimensions(
//               lengthLongSide: meters(1.420),
//               widthShortSide: meters(1.20),
//               heightWithoutCam: meters(1.260),
//               camHeight: meters(0.1),
//               levels: 4,
//               compartmentsPerLevel: 1,
//               birdFloorSpacePerCompartment: Area.of(meters(1.530), meters(1)),
//               emptyWeight: kilo.grams(204),
//             ));
// }

// class MarelGpS1x5Chicken extends ModuleType {
//   MarelGpS1x5Chicken()
//       : super(
//             moduleFamily: ModuleFamily.marelGpSingleColumn,
//             birdType: BirdType.chicken,
//             dimensions: ModuleDimensions(
//               lengthLongSide: meters(1.420),
//               widthShortSide: meters(1.20),
//               heightWithoutCam: meters(1.540),
//               camHeight: meters(0.1),
//               levels: 5,
//               compartmentsPerLevel: 1,
//               birdFloorSpacePerCompartment: Area.of(meters(1.530), meters(1)),
//               emptyWeight: kilo.grams(235),
//             ));
// }

// class MarelGpS1x6Turkey extends ModuleType {
//   MarelGpS1x6Turkey()
//       : super(
//             moduleFamily: ModuleFamily.marelGpSingleColumn,
//             birdType: BirdType.turkey,
//             dimensions: ModuleDimensions(
//               lengthLongSide: meters(1.420),
//               widthShortSide: meters(1.210),
//               heightWithoutCam: meters(2.560),
//               camHeight: meters(0.1),
//               levels: 6,
//               compartmentsPerLevel: 1,
//               birdFloorSpacePerCompartment: Area.of(meters(1.530), meters(1)),
//               emptyWeight: kilo.grams(280), //TODO unknown
//             ));
// }

// class MarelGpGalvanizedSteel2x4Chicken extends ModuleType {
//   MarelGpGalvanizedSteel2x4Chicken()
//       : super(
//             moduleFamily: ModuleFamily.marelGpSingleColumn,
//             birdType: BirdType.chicken,
//             dimensions: ModuleDimensions(
//               lengthLongSide: meters(2.430),
//               widthShortSide: meters(1.20),
//               heightWithoutCam: meters(1.260),
//               camHeight: meters(0.1),
//               levels: 4,
//               compartmentsPerLevel: 2,
//               birdFloorSpacePerCompartment: Area.of(meters(1.275), meters(1)),
//               emptyWeight: kilo.grams(399),
//             ));
// }

// class MarelGpStainlessSteel2x4Chicken extends ModuleType {
//   MarelGpStainlessSteel2x4Chicken()
//       : super(
//             moduleFamily: ModuleFamily.marelGpSingleColumn,
//             birdType: BirdType.chicken,
//             dimensions: ModuleDimensions(
//               lengthLongSide: meters(2.430),
//               widthShortSide: meters(1.20),
//               heightWithoutCam: meters(1.260),
//               camHeight: meters(0.1),
//               levels: 4,
//               compartmentsPerLevel: 2,
//               birdFloorSpacePerCompartment: Area.of(meters(1.275), meters(1)),
//               emptyWeight: kilo.grams(385),
//             ));
// }

// class MarelGp2x4Chicken extends ModuleType {
//   MarelGp2x4Chicken.marelGp2x5Chicken()
//       : super(
//             moduleFamily: ModuleFamily.marelGpSingleColumn,
//             birdType: BirdType.chicken,
//             dimensions: ModuleDimensions(
//               lengthLongSide: meters(2.430),
//               widthShortSide: meters(1.20),
//               heightWithoutCam: meters(1.365),
//               camHeight: meters(0.1),
//               levels: 4,
//               compartmentsPerLevel: 2,
//               birdFloorSpacePerCompartment: Area.of(meters(1.275), meters(1)),
//               emptyWeight: kilo.grams(430),
//             ));
// }

// class ModuleTypes extends DelegatingList<ModuleType> {
//   ModuleTypes()
//       : super([
//           MeynEvoChicken4Level(),
//           MeynEvoChicken5Level(),
//           MeynGrandeDrawerChicken2x4(),
//           MeynGrandeDrawerChicken2x5(),
//           MeynOmniTurkey2x3(),
//           AngliaAutoFlowChickenSmall3x4(),
//           AngliaAutoFlowChickenSmall3x5(),
//           AngliaAutoFlowChickenLarge3x4(),
//           AngliaAutoFlowChickenLarge3x5(),
//           MarelGpS1x4Chicken(),
//           MarelGpS1x5Chicken(),
//           MarelGpStainlessSteel2x4Chicken(),
//           MarelGpGalvanizedSteel2x4Chicken(),
//           MarelGp2x4Chicken.marelGp2x5Chicken(),
//         ]);
// }

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

@Deprecated('Use ModuleVariant instead')
class ModuleDimensions {
  final Distance lengthLongSide;
  final Distance widthShortSide;
  final Distance heightWithoutCam;
  final Distance camHeight;
  final Distance? headHeight;

  final int compartmentsPerLevel;
  final int levels;
  final Area birdFloorSpacePerCompartment;
  final Mass emptyWeight;

  const ModuleDimensions({
    required this.lengthLongSide,
    required this.widthShortSide,
    required this.heightWithoutCam,
    required this.camHeight,
    this.headHeight,
    required this.levels,
    required this.compartmentsPerLevel,
    required this.birdFloorSpacePerCompartment,
    required this.emptyWeight, //TODO make emptyWeightStainlessSteel and emptyWeightGalvanized
  });

  Mass maxWeightPerCompartment(LoadDensity loadDensity) =>
      kilo.grams(birdFloorSpacePerCompartment.as(meters, meters) /
          loadDensity.squareMeterPerKgLiveWeight);

  int birdsPerCompartment({
    required LoadDensity loadDensity,
    required Mass averageBirdWeightOfHeaviestFlock,
  }) =>
      (maxWeightPerCompartment(loadDensity).as(grams) /
              averageBirdWeightOfHeaviestFlock.as(grams))
          .truncate();

  ModuleCapacity capacityWithDensity(
    LoadDensity loadDensity,
    Mass averageBirdWeight,
  ) =>
      ModuleCapacity(
          compartmentsPerLevel: compartmentsPerLevel,
          levels: levels,
          birdsPerCompartment: birdsPerCompartment(
              loadDensity: loadDensity,
              averageBirdWeightOfHeaviestFlock: averageBirdWeight));

  ModuleCapacity capacityWithBirdsPerCompartment(int birdsPerCompartment) =>
      ModuleCapacity(
          compartmentsPerLevel: compartmentsPerLevel,
          levels: levels,
          birdsPerCompartment: birdsPerCompartment);
}

class ModuleCapacity {
  final int compartmentsPerLevel;
  final int birdsPerCompartment;
  final int levels;

  ModuleCapacity({
    required this.compartmentsPerLevel,
    required this.levels,
    required this.birdsPerCompartment,
  }) {
    _verifyNumberOfBirds();
  }

  int get compartments => compartmentsPerLevel * levels;

  int get numberOfBirds => compartments * birdsPerCompartment;

  @override
  String toString() => '${levels}L'
      '${compartmentsPerLevel == 1 ? '' : 'x${compartmentsPerLevel}C'}'
      'x${birdsPerCompartment}B';

  void _verifyNumberOfBirds() {
    if (numberOfBirds < 1) {
      throw ArgumentError('Container must contain birds', 'numberOfBirds');
    }
  }
}

class TruckRow
    extends DelegatingMap<PositionWithinModuleGroup, ModuleCapacity> {
  /// how often this Module Combination is loaded on to the system
  /// 1=100% of the time, 0.25=25% of the time
  final double occurrence;

  TruckRow(
    super.moduleCapacities, {
    this.occurrence = 1,
  });

  Iterable<ModuleCapacity> get capacities => values;

  int get numberOfBirds =>
      capacities.map((capacity) => capacity.numberOfBirds).sum;

  @override
  String toString() {
    var strings = values.map((capacity) => capacity.toString()).toList();
    var result = StringBuffer();
    for (String string in strings.toSet()) {
      var count = strings.where((s) => s == string).length;
      if (result.length > 0) {
        result.write('+');
      }
      if (count > 1) {
        result.write('$count$string');
      } else {
        result.write(string);
      }
    }
    return result.toString();
  }
}

@Deprecated('Use Compartment instead')
enum CompartmentType {
  doorOnOneSide(true),
  drawerSlideInOutOnBothSides(false),
  drawerSlideInOutOnOneSide(true);

  final bool birdsExitOnOneSide;
  bool get hasDoor => this == CompartmentType.doorOnOneSide;
  const CompartmentType(this.birdsExitOnOneSide);
}

enum BirdType { chicken, turkey }

enum ModuleFrameMaterial { galvanizedSteel, stainlessSteel }
