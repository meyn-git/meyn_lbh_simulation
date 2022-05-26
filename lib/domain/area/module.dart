import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/util/title_builder.dart';

import 'life_bird_handling_area.dart';
import 'state_machine.dart';

/// A [ModuleGroup] can be one or 2 modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side
class ModuleGroup extends TimeProcessor {
  final Module firstModule;
  Module? secondModule;
  final ModuleType type;

  /// The direction (rotation) of the module group. This is the direction
  /// that the doors would be pointing towards (if it has any)
  CompassDirection direction;
  StateMachineCell destination;
  ModulePosition position;

  ModuleGroup({
    required this.type,
    required this.firstModule,
    this.secondModule,
    required this.direction,
    required this.destination,
    required this.position,
  });

  ModuleGroup copyWith(
          {ModuleType? type,
          Module? firstModule,
          Module? secondModule,
          CompassDirection? direction,
          StateMachineCell? destination,
          ModulePosition? position}) =>
      ModuleGroup(
          type: type ?? this.type,
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
  String toString() => TitleBuilder('ModuleGroup')
      .appendProperty('doorDirection', direction)
      .appendProperty('destination', destination.name)
      //.appendProperty('position', position) removed because its obvious
      .appendProperty('firstModule', firstModule)
      .appendProperty('secondModule', secondModule)
      .toString();

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

  ModuleContents get contents {
    if (sinceBirdsUnloaded != null) {
      return ModuleContents.noBirds;
    } else if (sinceEndStun != null) {
      return ModuleContents.stunnedBirds;
    } else if (sinceStartStun != null) {
      return ModuleContents.birdsBeingStunned;
    } else {
      return ModuleContents.awakeBirds;
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

enum ModuleContents { awakeBirds, birdsBeingStunned, stunnedBirds, noBirds }

/// A module location is either at a given position or traveling between 2 positions
class ModulePosition {
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
  String toString() {
    if (isMoving) {
      return TitleBuilder('ModulePosition')
          .appendProperty('source', source.name)
          .appendProperty('destination', destination.name)
          .appendProperty('remainingDuration', remainingDuration)
          .toString();
    } else {
      return TitleBuilder('ModulePosition')
          .appendProperty('at', source.name)
          .toString();
    }
  }

  transportingFrom(StateMachineCell stateMachineCell) =>
      source == stateMachineCell && destination != stateMachineCell;
}

class Module {
  final int sequenceNumber;
  int nrOfBirds;
  Duration? sinceLoadedOnSystem;
  Duration? sinceStartStun;
  Duration? sinceEndStun;
  Duration? sinceBirdsUnloaded;

  Module({
    required this.sequenceNumber,
    required this.nrOfBirds,
  });

  @override
  String toString() => TitleBuilder('Module')
      .appendProperty('sequenceNumber', sequenceNumber)
      .appendProperty('nrOfBirds', nrOfBirds)
      .appendProperty('sinceLoadedOnSystem', sinceLoadedOnSystem)
      .appendProperty('sinceStartStun', sinceStartStun)
      .appendProperty('sinceEndStun', sinceEndStun)
      .appendProperty('sinceBirdsUnloaded', sinceBirdsUnloaded)
      .toString();
}

class MeynEvoContainers extends ModuleType {
  MeynEvoContainers()
      : super(
          shape: ModuleShape.rectangularStacked,
          birdType: BirdType.chicken,
          compartmentType: CompartmentType.door,
          sizes: [
            ModuleSize(compartmentsPerLevel: 1, levels: 4),
            ModuleSize(compartmentsPerLevel: 1, levels: 5),
          ],
          //following durations are based on measurements at: 7113-Tyson Union city
          stackerInFeedDuration: const Duration(seconds: 14),
          conveyorTransportDuration: const Duration(seconds: 12),

          casTransportDuration: const Duration(seconds: 14),

          turnTableDegreesPerSecond: (90 / 6).round(),
        );
}

class MeynGrandeDrawerModule extends ModuleType {
  MeynGrandeDrawerModule()
      : super(
          shape: ModuleShape.rectangularStacked,
          birdType: BirdType.chicken,
          compartmentType: CompartmentType.drawer,
          sizes: [
            ModuleSize(
                compartmentsPerLevel: 2,
                levels: 4,
                maxWeightPerCompartment: kilo.grams(76),
                emptyWeight: kilo.grams(380)),
            ModuleSize(
                compartmentsPerLevel: 2,
                levels: 5,
                maxWeightPerCompartment: kilo.grams(76),
                emptyWeight: kilo.grams(430)),
          ],
          //following durations are based on measurements at: 7113-Tyson Union city
          stackerInFeedDuration: const Duration(seconds: 14),
          conveyorTransportDuration: const Duration(seconds: 12),
          casTransportDuration: const Duration(seconds: 14),
          turnTableDegreesPerSecond: (90 / 6).round(),
        );
}

class MeynMaxiLoadModule extends ModuleType {
  MeynMaxiLoadModule()
      : super(
          shape: ModuleShape.rectangularStacked,
          birdType: BirdType.chicken,
          compartmentType: CompartmentType.drawer,
          sizes: [
            ModuleSize(
                compartmentsPerLevel: 2,
                levels: 4,
                maxWeightPerCompartment: kilo.grams(85),
                emptyWeight: kilo.grams(393)),
            ModuleSize(
                compartmentsPerLevel: 2,
                levels: 5,
                maxWeightPerCompartment: kilo.grams(85),
                emptyWeight: kilo.grams(457)),
          ],
          //following durations are based on measurements at: 7113-Tyson Union city
          stackerInFeedDuration: const Duration(seconds: 14),
          conveyorTransportDuration: const Duration(seconds: 12),

          casTransportDuration: const Duration(seconds: 14),

          turnTableDegreesPerSecond: (90 / 6).round(),
        );
}

class MeynOmniTurkeyModule extends ModuleType {
  MeynOmniTurkeyModule()
      : super(
            shape: ModuleShape.rectangularStacked,
            birdType: BirdType.turkey,
            compartmentType: CompartmentType.door,
            sizes: [
              ModuleSize(
                compartmentsPerLevel: 1,
                levels: 3,
                maxWeightPerCompartment: kilo.grams(300),
              )
            ],
            //following durations are based on measurements at: 8052-Indrol Grodzisk
            conveyorTransportDuration: const Duration(seconds: 19),
            stackerInFeedDuration: const Duration(seconds: 19),
            casTransportDuration: const Duration(seconds: 19),
            turnTableDegreesPerSecond: (90 / 11.25).round());
}

class AngliaAutoFlowModule extends ModuleType {
  AngliaAutoFlowModule()
      : super(
          shape: ModuleShape.rectangularStacked,
          birdType: BirdType.chicken,
          compartmentType: CompartmentType.drawer,
          sizes: [
            ModuleSize(compartmentsPerLevel: 3, levels: 4),
            ModuleSize(compartmentsPerLevel: 3, levels: 5),
          ],
          //following durations are based on measurements at: 7113-Tyson Union city
          stackerInFeedDuration: const Duration(seconds: 14),
          conveyorTransportDuration: const Duration(seconds: 12),
          casTransportDuration: const Duration(seconds: 14),
          turnTableDegreesPerSecond: (90 / 6).round(),
        );
}

class StorkSquareModule extends ModuleType {
  StorkSquareModule()
      : super(
          shape: ModuleShape.squareSideBySide,
          birdType: BirdType.chicken,
          compartmentType: CompartmentType.door,
          sizes: [
            ModuleSize(compartmentsPerLevel: 1, levels: 4),
            ModuleSize(compartmentsPerLevel: 1, levels: 5),
          ],
          //following durations are based on measurements at: 7696-Dabe-Germanyk
          conveyorTransportDuration: const Duration(milliseconds: 13400),
          stackerInFeedDuration: const Duration(milliseconds: 18700),
          casTransportDuration: const Duration(milliseconds: 18700),
          turnTableDegreesPerSecond: (90 / 9).round(),
        );
}

class StorkRectangularGpModule extends ModuleType {
  StorkRectangularGpModule()
      : super(
          shape: ModuleShape.rectangularStacked,
          birdType: BirdType.chicken,
          compartmentType: CompartmentType.door,
          sizes: [ModuleSize(compartmentsPerLevel: 2, levels: 4)],

          //following durations are based on measurements at: 7113-Tyson Union city
          stackerInFeedDuration: const Duration(seconds: 14),
          conveyorTransportDuration: const Duration(seconds: 12),
          casTransportDuration: const Duration(seconds: 14),
          turnTableDegreesPerSecond: (90 / 6).round(),
        );
}

class ModuleType {
  final ModuleShape shape;
  final CompartmentType compartmentType;
  final BirdType birdType;
  final List<ModuleSize> sizes;

  /// [stackerInFeedDuration] is also used for [ModuleDeStacker]
  final Duration stackerInFeedDuration;
  final Duration conveyorTransportDuration;
  final Duration casTransportDuration;
  final int turnTableDegreesPerSecond;

  ModuleType({
    required this.shape,
    required this.birdType,
    required this.compartmentType,
    required this.sizes,
    required this.conveyorTransportDuration, //= const Duration(seconds: 12),
    required this.stackerInFeedDuration, //= const Duration(seconds: 14),
    required this.casTransportDuration, //= const Duration(seconds: 14),
    required this.turnTableDegreesPerSecond, //= 15,
  });

  String get name => '$shape-$compartmentType-$birdType';

  ModuleSize levels(int levels) =>
      sizes.where((size) => size.levels == levels).first;
}

class LoadDensity extends DerivedMeasurement<Area, Mass> {
  final Supplier standardOwner;
  final BirdType birdType;
  final LoadDensityType type;

  LoadDensity(
      {required this.standardOwner,
      required this.birdType,
      required this.type,

      /// The area for 1 kilo gram live weight at 100% loading
      required Area area})
      : super.divide(_calculateArea(area, type), grams(1000));

  double get squareMeterPerKgLiveWeight => as(Area.square(meters), kilo.grams);

  @override
  String toString() {
    return 'LoadDensity{standardOwner: $standardOwner, birdType: $birdType, type: $type, squareMeterPerKgLiveWeight: $squareMeterPerKgLiveWeight}';
  }

  static Area _calculateArea(Area area, LoadDensityType type) {
    var factor = 100 / type.percentage;
    var side = meters(area.as(meters, meters) * factor);
    return Area.of(side, meters(1));
  }
}

enum Supplier { meyn, marel, linco, baader }

class LoadDensityType {
  final String name;
  final int percentage;


  LoadDensityType.max()
      : name = 'Max',
        percentage = 100;

  LoadDensityType.summer({required this.percentage}) : name = 'Summer';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadDensityType &&
          runtimeType == other.runtimeType &&
          percentage == other.percentage &&
          name == other.name;

  @override
  int get hashCode => percentage.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'LoadDensityType{name: $name, percentage: $percentage}';
  }
}

class LoadDensities extends DelegatingList<LoadDensity> {
  static Area _createArea(double squareCentimeters) => Area.of(centi.meters(squareCentimeters), centi.meters(1) );

  LoadDensities()
      : super([
          LoadDensity(
              standardOwner: Supplier.meyn,
              birdType: BirdType.chicken,
              type: LoadDensityType.max(),
              area: _createArea(16)),
          LoadDensity(
              standardOwner: Supplier.meyn,
              birdType: BirdType.chicken,
              type: LoadDensityType.summer(percentage: 90),
              area: _createArea(16)),
          LoadDensity(
              standardOwner: Supplier.meyn,
              birdType: BirdType.turkey,
              type: LoadDensityType.max(),
              area: _createArea(10.5)),
          LoadDensity(
              standardOwner: Supplier.meyn,
              birdType: BirdType.chicken,
              type: LoadDensityType.summer(percentage: 90),
              area: _createArea(10.5)),
          LoadDensity(
              standardOwner: Supplier.marel,
              birdType: BirdType.chicken,
              type: LoadDensityType.max(),
              area: _createArea(17)),
          LoadDensity(
              standardOwner: Supplier.marel,
              birdType: BirdType.chicken,
              type: LoadDensityType.summer(percentage: 70),
              area: _createArea(17)),
        ]);

}

class ModuleSize {
  final int compartmentsPerLevel;
  final int levels;

  /// emptyWeight
  /// TODO change to Area liveBirdCompartmentArea
  /// TODO add method to calculate Mass maxCompartmentLoad using LoadDensity cm2/kg = (liveBirdCompartmentArea/ loadDensity *1000?):
  /// * Meyn Chicken Max	100%	160 cm2/kg live weight
  /// * Meyn Chicken Summer	90%	178 cm2/kg live weight
  /// * Meyn Turkey Max	100%	105 cm2/kg live weight
  /// * Meyn Turkey Summer	90%	117 cm2/kg live weight
  /// * Marel Chicken Max	100%	170 cm2/kg live weight
  /// * Marel Chicken Summer	70%	243 cm2/kg live weight
  /// TODO change birdsPerCompartment= ((maxCompartmentLoad(loadDensity)/averageBirdWeighHeaviestFlock).truncate)
  /// TODO remove capacityInWinter
  /// TODO remove capacityInSummer
  /// TODO change capacity (use birdsPerCompartment method)
  final Mass? emptyWeight;
  final Mass? maxWeightPerCompartment;

  ModuleSize({
    required this.compartmentsPerLevel,
    required this.levels,
    this.emptyWeight,
    this.maxWeightPerCompartment,
  });

  /// Calculates the [ModuleCapacity] when  <30ºC
  ModuleCapacity capacityInWinter(Mass maxBirdWeight) => ModuleCapacity(
      compartmentsPerLevel: compartmentsPerLevel,
      levels: levels,
      birdsPerCompartment: birdsPerCompartment(maxBirdWeight));

  /// Calculates the [ModuleCapacity] when  >30ºC (capacity is 90% of normal)
  ModuleCapacity capacityInSummer(Mass maxBirdWeight) => ModuleCapacity(
      compartmentsPerLevel: compartmentsPerLevel,
      levels: levels,
      birdsPerCompartment: birdsPerCompartment(maxBirdWeight) * 0.9.truncate());

  ModuleCapacity capacity({required int birdsPerCompartment}) => ModuleCapacity(
      compartmentsPerLevel: compartmentsPerLevel,
      levels: levels,
      birdsPerCompartment: birdsPerCompartment);

  int birdsPerCompartment(Mass maxBirdWeight) {
    if (maxWeightPerCompartment == null) {
      throw Exception(
          'Could not calculate the module capacity because the maxWeightPerCompartment is unknown for this ModuleType');
    }
    return (maxWeightPerCompartment!.as(grams) / maxBirdWeight.as(grams))
        .truncate();
  }
}

class ModuleCapacity {
  final int compartmentsPerLevel;
  final int birdsPerCompartment;
  final int levels;

  ModuleCapacity({
    required this.compartmentsPerLevel,
    required this.levels,
    required this.birdsPerCompartment,
  });

  int get numberOfBirds => compartments * birdsPerCompartment;

  int get compartments => compartmentsPerLevel * levels;

  @override
  String toString() =>
      '$levels${compartmentsPerLevel == 1 ? '' : 'x$compartmentsPerLevel'}x$birdsPerCompartment';
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

enum CompartmentType { door, drawer }

enum BirdType { chicken, turkey }
