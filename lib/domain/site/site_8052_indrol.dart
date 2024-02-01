import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class IndrolSite extends Site {
  IndrolSite()
      : super(
          meynLayoutNumber: 8052,
          organizationName: 'Indrol',
          city: 'Grodzisk',
          country: 'Poland',
          productDefinitions: ProductDefinitions(),
        );
}

/// Modules:
/// - 1 CAS batch = 2 stacked modules
/// - 1 module = 3 levels
/// - 1 level = max 300 kg
///
///  Female turkeys:
///  - line speed: 3600 birds/hour
///  - live weight: min:8.500g, avr:10.000g, max 11.500g
///  - min birds: 300/11.5kg= 26 birds/level x 3 levels= 78 birds per module
///  - avr birds: 300/10kg=  30 birds/level x 3 levels= 90 birds per module
///  - max birds: 300/8.5kg= 35 birds/level x 3 levels= 105 birds per module
///
///  Male turkeys:
///  - line speed: 1800 birds/hour
///  - live weight: min:18.000g, avr:20.000g, max 23.000g
///  - min birds: 300/23kg= 13 birds/level x 3 levels= 39 birds per module
///  - avr birds: 300/20kg= 15 birds/level x 3 levels= 45 birds per module
///  - max birds: 300/18kg= 16 birds/level x 3 levels= 48 birds per module

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  static final ModuleCapacity femaleTurkeyMaxWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(11.5)));

  static final ModuleCapacity femaleTurkeyAverageWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(10.0)));
  static final ModuleCapacity femaleTurkeyMinWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(8.5)));

  static final ModuleCapacity maleTurkeyMaxWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(23)));
  static final ModuleCapacity maleTurkeyAverageWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(20)));
  static final ModuleCapacity maleTurkeyMinWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(18)));

  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Female Turkey min weight',
              lineSpeedInShacklesPerHour: 3600,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: femaleTurkeyMinWeightCapacity,
                  secondModule: femaleTurkeyMinWeightCapacity,
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Female Turkey avr weight',
              lineSpeedInShacklesPerHour: 3600,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: femaleTurkeyAverageWeightCapacity,
                  secondModule: femaleTurkeyAverageWeightCapacity,
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Female Turkey max weight',
              lineSpeedInShacklesPerHour: 3600,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: femaleTurkeyMaxWeightCapacity,
                  secondModule: femaleTurkeyMaxWeightCapacity,
                ),
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Male Turkey min weight',
              lineSpeedInShacklesPerHour: 1800,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: maleTurkeyMinWeightCapacity,
                  secondModule: maleTurkeyMinWeightCapacity,
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Male Turkey average weight',
              lineSpeedInShacklesPerHour: 1800,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: maleTurkeyAverageWeightCapacity,
                  secondModule: maleTurkeyAverageWeightCapacity,
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Male Turkey max weight',
              lineSpeedInShacklesPerHour: 1800,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: maleTurkeyMaxWeightCapacity,
                  secondModule: maleTurkeyMaxWeightCapacity,
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() =>
          (ProductDefinition productDefinition) => [Area(productDefinition)];

  static final Mass maxWeightPerCompartment = kilo.grams(150);

  static int _calculateBirdsPerCompartment(Mass birdMass) =>
      (maxWeightPerCompartment.as(grams) / birdMass.as(grams)).truncate();
}

class Area extends LiveBirdHandlingArea {
  Area(ProductDefinition productDefinition)
      : super(
          lineName: 'Line 1',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
    _row4();
  }

  void _row1() {
    put(ModuleCas(
      area: this,
      position: const Position(2, 1),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 1),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(BirdHangingConveyor(
      area: this,
      position: const Position(6, 1),
      direction: CardinalDirection.west,
    ));
  }

  void _row2() {
    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(1, 2),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.south,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(2, 2),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 2),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleDeStacker(
      area: this,
      position: const Position(4, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    //Gross weighing conveyor
    put(ModuleConveyor(
      area: this,
      position: const Position(5, 2),
      seqNr: 3,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(6, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
      birdDirection: CardinalDirection.north,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    //Tare weighing conveyor
    put(ModuleConveyor(
      area: this,
      position: const Position(7, 2),
      seqNr: 4,
      inFeedDirection: CardinalDirection.west,
    ));

    // Module conveyor
    put(ModuleConveyor(
      area: this,
      position: const Position(8, 2),
      seqNr: 5,
      inFeedDirection: CardinalDirection.west,
    ));

    // High pressure pre-washer
    put(ModuleConveyor(
      area: this,
      position: const Position(9, 2),
      seqNr: 6,
      inFeedDirection: CardinalDirection.west,
    ));

    //  Module conveyor
    put(ModuleConveyor(
      area: this,
      position: const Position(10, 2),
      seqNr: 7,
      inFeedDirection: CardinalDirection.west,
    ));

    // Active module washer
    put(ModuleConveyor(
      area: this,
      position: const Position(11, 2),
      seqNr: 8,
      inFeedDirection: CardinalDirection.west,
    ));

    // Disinfection unit
    put(ModuleConveyor(
      area: this,
      position: const Position(12, 2),
      seqNr: 9,
      inFeedDirection: CardinalDirection.west,
    ));

    //  Module conveyor
    put(ModuleConveyor(
      area: this,
      position: const Position(13, 2),
      seqNr: 10,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleStacker(
      area: this,
      position: const Position(14, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(15, 2),
      seqNr: 4,
      defaultPositionWhenIdle: CardinalDirection.east,
    ));
  }

  void _row3() {
    put(ModuleConveyor(
      area: this,
      position: const Position(1, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(15, 3),
      seqNr: 20,
      inFeedDirection: CardinalDirection.north,
    ));
  }

  void _row4() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(1, 4),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCasAllocation(
      area: this,
      position: const Position(8, 4),
      positionToAllocate: const Position(1, 2),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(9, 4),
    ));

    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(15, 4),
      inFeedDirection: CardinalDirection.north,
    ));
  }
}
