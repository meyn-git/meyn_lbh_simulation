import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_lift_position.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor_single_out.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class CarnjSite extends Site {
  CarnjSite()
      : super(
          meynLayoutNumber: 7324,
          organizationName: 'Carnj Soc. Coop. Agricola',
          city: 'Jesi-Ancona',
          country: 'Italy',
          productDefinitions: CarnjProductDefinitions(),
        );
}

class CarnjProductDefinitions extends DelegatingList<ProductDefinition> {
  static int maxBirdPerHour = 8000,
      exceedingMaxBirdPerHour = maxBirdPerHour + 1000;

  CarnjProductDefinitions()
      : super([
// Without buffer conveyor between tilter and turntable

          ProductDefinition(
              // 3.5 kg/bird average
              // 9 levels * 25 birds = 225 birds / 2 cont = average 112 birds/cont
              // 112 birds/cont * 2 cont * 7.5 CAS cycle/hour * 6 CAS units = 10080 birds/hour
              // 10080 birds/hour / 112 birds/cont = 90 cont/hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo Grosso',
              lineSpeedInShacklesPerHour: maxBirdPerHour,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(25),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(25),
                )
              ]),
          ProductDefinition(
              // 1.65 kg/bird average
              // 9 levels * 54 birds = 486 birds / 2 cont = average 243 birds/cont
              // 243 birds/cont * 2 cont * 7.5 CAS cycle/hour * 3 CAS units = 10935 birds/hour
              // 10935 birds/hour / 243 birds/cont = 45 cont/hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo Piccolo',
              lineSpeedInShacklesPerHour: maxBirdPerHour,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(54),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(54),
                )
              ]),

// With buffer conveyor between tilter and turntable

          ProductDefinition(
              // 3.5 kg/bird average
              // 9 levels * 25 birds = 225 birds / 2 cont = average 112 birds/cont
              // 112 birds/cont * 2 cont * 7.5 CAS cycle/hour * 6 CAS units = 10080 birds/hour
              // 10080 birds/hour / 112 birds/cont = 90 cont/hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo Grosso',
              lineSpeedInShacklesPerHour: maxBirdPerHour,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(25),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(25),
                )
              ]),
          ProductDefinition(
              // 1.65 kg/bird average
              // 9 levels * 54 birds = 486 birds / 2 cont = average 243 birds/cont
              // 243 birds/cont * 2 cont * 7.5 CAS cycle/hour * 3 CAS units = 10935 birds/hour
              // 10935 birds/hour / 243 birds/cont = 45 cont/hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo Piccolo',
              lineSpeedInShacklesPerHour: maxBirdPerHour,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(54),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(54),
                )
              ]),

          ProductDefinition(
              // 3.5 kg/bird average
              // 9 levels * 25 birds = 225 birds / 2 cont = average 112 birds/cont
              // 112 birds/cont * 2 cont * 7.5 CAS cycle/hour * 6 CAS units = 10080 birds/hour
              // 10080 birds/hour / 112 birds/cont = 90 cont/hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo Grosso',
              lineSpeedInShacklesPerHour: exceedingMaxBirdPerHour,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(25),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(25),
                )
              ]),
          ProductDefinition(
              // 1.65 kg/bird average
              // 9 levels * 54 birds = 486 birds / 2 cont = average 243 birds/cont
              // 243 birds/cont * 2 cont * 7.5 CAS cycle/hour * 3 CAS units = 10935 birds/hour
              // 10935 birds/hour / 243 birds/cont = 45 cont/hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo Piccolo',
              lineSpeedInShacklesPerHour: exceedingMaxBirdPerHour,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(54),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(54),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [CarnjLiveBirdHandlingArea(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaWithExtraBufferFactory() => (ProductDefinition productDefinition) =>
          [CarnjLiveBirdHandlingAreaWithExtraConveyor(productDefinition)];
}

class CarnjLiveBirdHandlingArea extends LiveBirdHandlingArea {
  CarnjLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Without buffer for tilter',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
    _row4();
    _row5();
  }

  void _row1() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(7, 1),
      outFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
      loadsSingeModule: true,
    ));
  }

  void _row2() {
    put(ModuleConveyor(
      area: this,
      position: const Position(7, 2),
      inFeedDirection: CardinalDirection.north,
    ));
  }

  void _row3() {
    put(BirdHangingConveyor(
      area: this,
      position: const Position(3, 3),
      direction: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 3),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(5, 3),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(6, 3),
      seqNr: 5,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    /// mimicking a merging conveyor: 2 x singe [ModuleGroup] from fork lift truck into 1
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleStacker(
      area: this,
      position: const Position(7, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.north,
      heightsInCentiMeter: const {
        LiftPosition.inFeed: 0,
        LiftPosition.outFeed: 0,
        LiftPosition.pickUpTopModule: 0,
        LiftPosition.supportTopModule: 0,
      },
      supportsCloseDuration: Duration.zero,
      supportsOpenDuration: Duration.zero,
    ));
  }

  void _row4() {
    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(2, 4),
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(3, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.east,
      birdDirection: CardinalDirection.north,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    put(ModuleRotatingConveyorSingleOut(
      area: this,
      position: const Position(4, 4),
      seqNr: 4,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(5, 4),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(6, 4),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(7, 4),
      seqNr: 1,
      defaultPositionWhenIdle: CardinalDirection.south,
    ));
  }

  void _row5() {
    put(ModuleCasAllocation(
      area: this,
      position: const Position(1, 5),
      positionToAllocate: const Position(7, 3),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(2, 5),
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 5),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(5, 5),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(6, 5),
      seqNr: 6,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));
  }
}

class CarnjLiveBirdHandlingAreaWithExtraConveyor extends LiveBirdHandlingArea {
  CarnjLiveBirdHandlingAreaWithExtraConveyor(
      ProductDefinition productDefinition)
      : super(
          lineName: 'With buffer for tilter',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
    _row4();
    _row5();
  }

  void _row1() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(7, 1),
      outFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
      loadsSingeModule: true,
    ));
  }

  void _row2() {
    put(ModuleConveyor(
      area: this,
      position: const Position(7, 2),
      inFeedDirection: CardinalDirection.north,
    ));
  }

  void _row3() {
    put(BirdHangingConveyor(
      area: this,
      position: const Position(2, 3),
      direction: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 3),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(5, 3),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(6, 3),
      seqNr: 5,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    /// mimicking a merging conveyor: 2 x singe [ModuleGroup] from fork lift truck into 1
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleStacker(
      area: this,
      position: const Position(7, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.north,
      heightsInCentiMeter: const {
        LiftPosition.inFeed: 0,
        LiftPosition.outFeed: 0,
        LiftPosition.pickUpTopModule: 0,
        LiftPosition.supportTopModule: 0,
      },
      supportsCloseDuration: Duration.zero,
      supportsOpenDuration: Duration.zero,
    ));
  }

  void _row4() {
    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(1, 4),
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(2, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.east,
      birdDirection: CardinalDirection.north,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    /// mimicking a de-merging conveyor: 1 [ModuleGroup] => 2x [ModuleGroup] to tilter
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleDeStacker(
      area: this,
      position: const Position(3, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.east,
      heightsInCentiMeter: const {
        LiftPosition.inFeed: 0,
        LiftPosition.outFeed: 0,
        LiftPosition.pickUpTopModule: 0,
        LiftPosition.supportTopModule: 0,
      },
      supportsCloseDuration: Duration.zero,
      supportsOpenDuration: Duration.zero,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(4, 4),
      seqNr: 4,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(5, 4),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(6, 4),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(7, 4),
      seqNr: 1,
      defaultPositionWhenIdle: CardinalDirection.south,
    ));
  }

  void _row5() {
    put(ModuleCasAllocation(
      area: this,
      position: const Position(1, 5),
      positionToAllocate: const Position(7, 3),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(2, 5),
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 5),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(5, 5),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(6, 5),
      seqNr: 6,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));
  }
}
