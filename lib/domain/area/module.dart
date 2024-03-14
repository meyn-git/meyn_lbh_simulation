import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/machine.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';

import 'life_bird_handling_area.dart';
import 'state_machine.dart';

/// A [ModuleGroup] can be one or 2 modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side
class ModuleGroup extends TimeProcessor implements HasObjectDetails {
  final Module firstModule;
  Module? secondModule;
  final ModuleFamily moduleFamily;

  /// The direction (rotation) of the module group. This is the direction
  /// that the doors would be pointing towards (if it has any)
  CompassDirection direction;
  StateMachineCell destination;
  ModulePosition position;

  ModuleGroup({
    required this.moduleFamily,
    required this.firstModule,
    this.secondModule,
    required this.direction,
    required this.destination,
    required this.position,
  });

  ModuleGroup copyWith(
          {ModuleFamily? moduleFamily,
          Module? firstModule,
          Module? secondModule,
          CompassDirection? direction,
          StateMachineCell? destination,
          ModulePosition? position}) =>
      ModuleGroup(
          moduleFamily: moduleFamily ?? this.moduleFamily,
          firstModule: firstModule ?? this.firstModule,
          direction: direction ?? this.direction,
          destination: destination ?? this.destination,
          position: position ?? this.position);

  int get numberOfModules => 1 + ((secondModule == null) ? 0 : 1);

  int get numberOfBirds =>
      firstModule.nrOfBirds +
      ((secondModule == null) ? 0 : secondModule!.nrOfBirds);

  @override
  onUpdateToNextPointInTime(Duration jump) {
    position.processNextTimeFrame(this, jump);
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
  late String name = 'ModuleGroup';

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('doorDirection', direction)
      .appendProperty('destination', destination.name)
      .appendProperty('firstModule', firstModule)
      .appendProperty('secondModule', secondModule);

  @override
  String toString() => objectDetails.toString();

  Duration? get sinceLoadedOnSystem => firstModule.sinceLoadedOnSystem;

  set sinceLoadedOnSystem(Duration? duration) {
    firstModule.sinceLoadedOnSystem = duration;
    if (secondModule != null) {
      secondModule!.sinceLoadedOnSystem = duration;
    }
  }

  void loadedOnToSystem() {
    sinceLoadedOnSystem = Duration.zero;
  }

  Duration? get sinceStartStun => firstModule.sinceStartStun;

  set sinceStartStun(Duration? duration) {
    firstModule.sinceStartStun = duration;
    if (secondModule != null) {
      secondModule!.sinceStartStun = duration;
    }
  }

  void startStunning() {
    sinceStartStun = Duration.zero;
  }

  Duration? get sinceEndStun => firstModule.sinceEndStun;

  set sinceEndStun(Duration? duration) {
    firstModule.sinceEndStun = duration;
    if (secondModule != null) {
      secondModule!.sinceEndStun = duration;
    }
  }

  void endStunning() {
    sinceEndStun = Duration.zero;
  }

  Duration? get sinceBirdsUnloaded => firstModule.sinceBirdsUnloaded;

  set sinceBirdsUnloaded(Duration? duration) {
    firstModule.sinceBirdsUnloaded = duration;
    if (secondModule != null) {
      secondModule!.sinceBirdsUnloaded = duration;
    }
  }

  void unloadBirds() {
    sinceBirdsUnloaded = Duration.zero;
    firstModule.nrOfBirds = 0;
    if (secondModule != null) {
      secondModule!.nrOfBirds = 0;
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

  /// Splits the [ModuleGroup] int 2 different [ModuleGroup]s:
  /// - The [ModuleGroup.secondModule] is removed from the existing [ModuleGroup]
  /// - returns a new copied [ModuleGroup] where [ModuleGroup.firstModule]=[ModuleGroup.secondModule]
  ModuleGroup? split() {
    if (secondModule == null) {
      throw Exception(
          'You can not split a $ModuleGroup that contains only one module');
    }
    var newModuleGroup =
        copyWith(firstModule: secondModule, secondModule: null);
    secondModule = null;
    return newModuleGroup;
  }
}

enum BirdContents { awakeBirds, birdsBeingStunned, stunnedBirds, noBirds }

/// A module location is either at a given position or traveling between 2 positions
class ModulePosition implements HasObjectDetails {
  StateMachineCell source;
  StateMachineCell destination;
  late Duration duration;
  late Duration remainingDuration;

  ModulePosition.forCel(StateMachineCell cell)
      : source = cell,
        destination = cell,
        duration = Duration.zero,
        remainingDuration = Duration.zero;

  ModulePosition.betweenCells(
      {required this.source, required this.destination, Duration? duration}) {
    this.duration = duration ?? findLongestDuration(source, destination);
    remainingDuration = this.duration;
  }

  /// 0  =  0% of transportation is completed
  /// 0.5= 50% of transportation is completed
  /// 1  =100% of transportation is completed
  double get percentageCompleted => duration == Duration.zero
      ? 1
      : 1 - remainingDuration.inMilliseconds / duration.inMilliseconds;

  processNextTimeFrame(ModuleGroup moduleGroup, Duration jump) {
    if (remainingDuration > Duration.zero) {
      remainingDuration = remainingDuration - jump;
      if (remainingDuration <= Duration.zero) {
        source = destination;
      }
    } else {
      remainingDuration = Duration.zero;
    }
  }

  equals(StateMachineCell cell) =>
      source.position == cell.position &&
      destination.position == cell.position &&
      remainingDuration == Duration.zero;

  static Duration findLongestDuration(
    StateMachineCell source,
    StateMachineCell destination,
  ) {
    Duration outFeedDuration = source.outFeedDuration;
    Duration inFeedDuration = destination.inFeedDuration;
    return Duration(
        milliseconds:
            max(outFeedDuration.inMilliseconds, inFeedDuration.inMilliseconds));
  }

  bool get isMoving {
    return source != destination;
  }

  @override
  late String name = 'ModulePosition';

  @override
  ObjectDetails get objectDetails => isMoving
      ? ObjectDetails(name)
          .appendProperty('source', source.name)
          .appendProperty('destination', destination.name)
          .appendProperty('remainingDuration', remainingDuration)
      : ObjectDetails(name).appendProperty('at', source.name);

  @override
  String toString() => objectDetails.toString();

  transportingFrom(StateMachineCell stateMachineCell) =>
      source == stateMachineCell && destination != stateMachineCell;
}

class Module implements HasObjectDetails {
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
      turnTableDegreesPerSecond:
          5 // should be 10 but this resulted in 6 sec instead of 90 degrees in 9 seconds,
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

enum ModuleFamily {
  meynEvo(
    supplier: Supplier.meyn,
    compartmentType: CompartmentType.doorOnOneSide,
    shape: ModuleShape.rectangularStacked,
  ),
  meynGrandeDrawerDoubleColumn(
    supplier: Supplier.meyn,
    compartmentType: CompartmentType.drawerSlideInOutOnOneSide,
    shape: ModuleShape.rectangularStacked,
  ),
  meynGrandeDrawerSingleColumn(
    supplier: Supplier.meyn,
    compartmentType: CompartmentType.drawerSlideInOutOnOneSide,
    shape: ModuleShape.squareSideBySide,
  ),
  meynMaxiLoad(
    supplier: Supplier.meyn,
    compartmentType: CompartmentType.drawerSlideInOutOnOneSide,
    shape: ModuleShape.rectangularStacked,
  ),
  meynOmni(
    supplier: Supplier.meyn,
    compartmentType: CompartmentType.doorOnOneSide,
    shape: ModuleShape.rectangularStacked,
  ),
  angliaAutoFlow(
    supplier: Supplier.angliaAutoFlow,
    compartmentType: CompartmentType.drawerSlideInOutOnBothSides,
    shape: ModuleShape.rectangularStacked,
  ),
  marelGpDoubleColumn(
    supplier: Supplier.marel,
    compartmentType: CompartmentType.doorOnOneSide,
    shape: ModuleShape.squareSideBySide,
  ),
  marelGpSingleColumn(
    supplier: Supplier.marel,
    compartmentType: CompartmentType.doorOnOneSide,
    shape: ModuleShape.rectangularStacked,
  );

  const ModuleFamily({
    required this.supplier,
    required this.shape,
    required this.compartmentType,
  });

  final Supplier supplier;
  final ModuleShape shape;
  final CompartmentType compartmentType;
}

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

class MeynEvoChicken4Level extends ModuleType {
  MeynEvoChicken4Level()
      : super(
          moduleFamily: ModuleFamily.meynEvo,
          birdType: BirdType.chicken,
          dimensions: ModuleDimensions(
            lengthLongSide: meters(2.4),
            widthShortSide: meters(1.2),
            heightWithoutCam: meters(1.23),
            camHeight: meters(0.065),
            headHeight: meters(0.249),
            levels: 4,
            compartmentsPerLevel: 2,
            birdFloorSpacePerCompartment: Area.of(meters(1.311), meters(1)),
            emptyWeight: kilo.grams(340),
          ),
        );
}

class MeynEvoChicken5Level extends ModuleType {
  MeynEvoChicken5Level()
      : super(
          moduleFamily: ModuleFamily.meynEvo,
          birdType: BirdType.chicken,
          dimensions: ModuleDimensions(
            lengthLongSide: meters(2.4),
            widthShortSide: meters(1.2),
            heightWithoutCam: meters(1.483),
            camHeight: meters(0.065),
            headHeight: meters(0.249),
            levels: 5,
            compartmentsPerLevel: 2,
            birdFloorSpacePerCompartment: Area.of(meters(1.311), meters(1)),
            emptyWeight: kilo.grams(395),
          ),
        );
}

class GrandeDrawerModuleType extends ModuleType {
  static const double drawerOutSideLengthInMeters = 1.160;

  static const SizeInMeters size = SizeInMeters(
      widthInMeters: drawerOutSideLengthInMeters,
      heightInMeters: drawerOutSideLengthInMeters);

  GrandeDrawerModuleType({
    required super.moduleFamily,
    required super.birdType,
    required super.dimensions,
  });
}

class MeynGrandeDrawerChicken4Level extends GrandeDrawerModuleType {
  MeynGrandeDrawerChicken4Level()
      : super(
          moduleFamily: ModuleFamily.meynGrandeDrawerDoubleColumn,
          birdType: BirdType.chicken,
          dimensions: ModuleDimensions(
            lengthLongSide: meters(2.43),
            widthShortSide: meters(1.18),
            heightWithoutCam: meters(1.31),
            camHeight: meters(0.065),
            //TODO Unknown! Find out and change!
            headHeight: meters(0.255),
            levels: 4,
            compartmentsPerLevel: 2,
            birdFloorSpacePerCompartment: Area.of(meters(1.221), meters(1)),
            emptyWeight: kilo.grams(346),
          ),
        );
}

class MeynGrandeDrawerChicken5Level extends GrandeDrawerModuleType {
  MeynGrandeDrawerChicken5Level()
      : super(
          moduleFamily: ModuleFamily.meynGrandeDrawerDoubleColumn,
          birdType: BirdType.chicken,
          dimensions: ModuleDimensions(
            lengthLongSide: meters(2.43),
            widthShortSide: meters(1.18),
            heightWithoutCam: meters(1.59),
            camHeight: meters(0.065),
            //TODO Unknown! Find out and change!
            headHeight: meters(0.255),
            levels: 5,
            compartmentsPerLevel: 2,
            birdFloorSpacePerCompartment: Area.of(meters(1.221), meters(1)),
            emptyWeight: kilo.grams(404),
          ),
        );
}

class MeynOmniTurkey3Level extends ModuleType {
  /// maxWeight per floor =300kg (=150 per compartment)
  MeynOmniTurkey3Level()
      : super(
          moduleFamily: ModuleFamily.meynOmni,
          birdType: BirdType.turkey,
          dimensions: ModuleDimensions(
              lengthLongSide: meters(2.43),
              widthShortSide: meters(1.35),
              heightWithoutCam: meters(1.345),
              camHeight: meters(0.059),
              headHeight: meters(0.380),
              levels: 3,
              compartmentsPerLevel: 2,
              birdFloorSpacePerCompartment: Area.of(meters(2.1), meters(1)),
              //TODO verify. 2.1m2 seems small
              emptyWeight: kilo.grams(420)),
        );
}

class AngliaAutoFlowChickenSmall4Level extends ModuleType {
  AngliaAutoFlowChickenSmall4Level()
      : super(
          moduleFamily: ModuleFamily.angliaAutoFlow,
          birdType: BirdType.chicken,
          dimensions: ModuleDimensions(
              lengthLongSide: meters(2.438),
              widthShortSide: meters(1.165),
              heightWithoutCam: meters(1.152),
              camHeight: meters(0.1),
              headHeight: meters(0.22),
              levels: 4,
              compartmentsPerLevel: 3,
              birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
              emptyWeight: kilo.grams(330)),
        );
}

class AngliaAutoFlowChickenSmall5Level extends ModuleType {
  AngliaAutoFlowChickenSmall5Level()
      : super(
          moduleFamily: ModuleFamily.angliaAutoFlow,
          birdType: BirdType.chicken,
          dimensions: ModuleDimensions(
              lengthLongSide: meters(2.438),
              widthShortSide: meters(1.165),
              heightWithoutCam: meters(1.397),
              camHeight: meters(0.1),
              headHeight: meters(0.22),
              levels: 5,
              compartmentsPerLevel: 3,
              birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
              emptyWeight: kilo.grams(390)),
        );
}

class AngliaAutoFlowChickenLarge4Level extends ModuleType {
  AngliaAutoFlowChickenLarge4Level()
      : super(
          moduleFamily: ModuleFamily.angliaAutoFlow,
          birdType: BirdType.chicken,
          dimensions: ModuleDimensions(
              lengthLongSide: meters(2.438),
              widthShortSide: meters(1.165),
              heightWithoutCam: meters(1.292),
              camHeight: meters(0.1),
              headHeight: meters(0.255),
              levels: 4,
              compartmentsPerLevel: 3,
              birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
              emptyWeight: kilo.grams(350)),
        );
}

class AngliaAutoFlowChickenLarge5Level extends ModuleType {
  AngliaAutoFlowChickenLarge5Level()
      : super(
          moduleFamily: ModuleFamily.angliaAutoFlow,
          birdType: BirdType.chicken,
          dimensions: ModuleDimensions(
              lengthLongSide: meters(2.438),
              widthShortSide: meters(1.165),
              heightWithoutCam: meters(1.572),
              camHeight: meters(0.1),
              headHeight: meters(0.255),
              levels: 5,
              compartmentsPerLevel: 3,
              birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
              emptyWeight: kilo.grams(410)),
        );
}

class AngliaAutoFlowTurkey3Level extends ModuleType {
  AngliaAutoFlowTurkey3Level()
      : super(
          moduleFamily: ModuleFamily.angliaAutoFlow,
          birdType: BirdType.turkey,
          dimensions: ModuleDimensions(
              lengthLongSide: meters(2.438),
              widthShortSide: meters(1.165),
              heightWithoutCam: meters(1.292),
              camHeight: meters(0.1),
              headHeight: meters(0.355),
              levels: 3,
              compartmentsPerLevel: 3,
              birdFloorSpacePerCompartment: Area.of(meters(0.8), meters(1)),
              emptyWeight: kilo.grams(340)),
        );
}

class MarelGpSquareModule4Level extends ModuleType {
  MarelGpSquareModule4Level()
      : super(
            moduleFamily: ModuleFamily.marelGpDoubleColumn,
            birdType: BirdType.chicken,
            dimensions: ModuleDimensions(
              lengthLongSide: meters(1.420),
              widthShortSide: meters(1.20),
              heightWithoutCam: meters(1.260),
              camHeight: meters(0.1),
              levels: 4,
              compartmentsPerLevel: 1,
              birdFloorSpacePerCompartment: Area.of(meters(1.530), meters(1)),
              emptyWeight: kilo.grams(204),
            ));
}

class MarelGpSquareModule5Level extends ModuleType {
  MarelGpSquareModule5Level()
      : super(
            moduleFamily: ModuleFamily.marelGpDoubleColumn,
            birdType: BirdType.chicken,
            dimensions: ModuleDimensions(
              lengthLongSide: meters(1.420),
              widthShortSide: meters(1.20),
              heightWithoutCam: meters(1.540),
              camHeight: meters(0.1),
              levels: 5,
              compartmentsPerLevel: 1,
              birdFloorSpacePerCompartment: Area.of(meters(1.530), meters(1)),
              emptyWeight: kilo.grams(235),
            ));
}

class MarelGpSquareModule6LevelTurkey extends ModuleType {
  MarelGpSquareModule6LevelTurkey()
      : super(
            moduleFamily: ModuleFamily.marelGpDoubleColumn,
            birdType: BirdType.turkey,
            dimensions: ModuleDimensions(
              lengthLongSide: meters(1.420),
              widthShortSide: meters(1.210),
              heightWithoutCam: meters(2.560),
              camHeight: meters(0.1),
              levels: 6,
              compartmentsPerLevel: 1,
              birdFloorSpacePerCompartment: Area.of(meters(1.530), meters(1)),
              emptyWeight: kilo.grams(280), //TODO unknown
            ));
}

class MarelGpGalvanizedSteelRectangular4LevelChicken extends ModuleType {
  MarelGpGalvanizedSteelRectangular4LevelChicken()
      : super(
            moduleFamily: ModuleFamily.marelGpSingleColumn,
            birdType: BirdType.chicken,
            dimensions: ModuleDimensions(
              lengthLongSide: meters(2.430),
              widthShortSide: meters(1.20),
              heightWithoutCam: meters(1.260),
              camHeight: meters(0.1),
              levels: 4,
              compartmentsPerLevel: 2,
              birdFloorSpacePerCompartment: Area.of(meters(1.275), meters(1)),
              emptyWeight: kilo.grams(399),
            ));
}

class MarelGpStainlessSteelRectangular4LevelChicken extends ModuleType {
  MarelGpStainlessSteelRectangular4LevelChicken()
      : super(
            moduleFamily: ModuleFamily.marelGpSingleColumn,
            birdType: BirdType.chicken,
            dimensions: ModuleDimensions(
              lengthLongSide: meters(2.430),
              widthShortSide: meters(1.20),
              heightWithoutCam: meters(1.260),
              camHeight: meters(0.1),
              levels: 4,
              compartmentsPerLevel: 2,
              birdFloorSpacePerCompartment: Area.of(meters(1.275), meters(1)),
              emptyWeight: kilo.grams(385),
            ));
}

class MarelGpRectangular5LevelChicken extends ModuleType {
  MarelGpRectangular5LevelChicken()
      : super(
            moduleFamily: ModuleFamily.marelGpSingleColumn,
            birdType: BirdType.chicken,
            dimensions: ModuleDimensions(
              lengthLongSide: meters(2.430),
              widthShortSide: meters(1.20),
              heightWithoutCam: meters(1.365),
              camHeight: meters(0.1),
              levels: 4,
              compartmentsPerLevel: 2,
              birdFloorSpacePerCompartment: Area.of(meters(1.275), meters(1)),
              emptyWeight: kilo.grams(430),
            ));
}

class ModuleTypes extends DelegatingList<ModuleType> {
  ModuleTypes()
      : super([
          MeynEvoChicken4Level(),
          MeynEvoChicken5Level(),
          MeynGrandeDrawerChicken4Level(),
          MeynGrandeDrawerChicken5Level(),
          MeynOmniTurkey3Level(),
          AngliaAutoFlowChickenSmall4Level(),
          AngliaAutoFlowChickenSmall5Level(),
          AngliaAutoFlowChickenLarge4Level(),
          AngliaAutoFlowChickenLarge5Level(),
          MarelGpSquareModule4Level(),
          MarelGpSquareModule5Level(),
          MarelGpStainlessSteelRectangular4LevelChicken(),
          MarelGpGalvanizedSteelRectangular4LevelChicken(),
          MarelGpRectangular5LevelChicken(),
        ]);
}

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

enum Supplier { meyn, marel, baaderLinco, angliaAutoFlow }

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
    required this.emptyWeight,
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

class ModuleGroupCapacity {
  /// how often this Module Combination is loaded on to the system
  /// 1=100% of the time, 1/4=25% of the time
  final double occurrence;
  final ModuleCapacity firstModule;
  final ModuleCapacity? secondModule;

  ModuleGroupCapacity({
    this.occurrence = 1,
    required this.firstModule,
    this.secondModule,
  });

  int get numberOfBirds =>
      firstModule.numberOfBirds +
      (secondModule == null ? 0 : secondModule!.numberOfBirds);

  @override
  String toString() {
    if (secondModule == null) {
      return firstModule.toString();
    }
    if (firstModule.toString() == secondModule.toString()) {
      return '2x$firstModule';
    } else {
      return '$firstModule+$secondModule';
    }
  }
}

enum ModuleShape { squareSideBySide, rectangularStacked }

enum CompartmentType {
  doorOnOneSide(true),
  drawerSlideInOutOnBothSides(false),
  drawerSlideInOutOnOneSide(true);

  final bool birdsExitOnOneSide;
  bool get hasDoor => this == CompartmentType.doorOnOneSide;
  const CompartmentType(this.birdsExitOnOneSide);
}

enum BirdType { chicken, turkey }
