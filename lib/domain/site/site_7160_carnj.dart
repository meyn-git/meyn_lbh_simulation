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
          meynLayoutNumber: 7160,
          organizationName: 'Carnj Soc. Coop. Agricola (Fileni-Cingoli)',
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

//           ProductDefinition(
//               // 3.5 kg/bird average
//               // 9 levels * 25 birds = 225 birds / 2 cont = average 112 birds/cont
//               // 112 birds/cont * 2 cont * 7.5 CAS cycle/hour * 6 CAS units = 10080 birds/hour
//               // 10080 birds/hour / 112 birds/cont = 90 cont/hour
//               areaFactory: _areaFactory(),
//               birdType: 'Pollo Grosso',
//               lineSpeedInShacklesPerHour: 8000,
//               casRecipe: const CasRecipe.standardChickenRecipe(),
//               moduleSystem: ModuleSystem.meynVdlSquareContainers,
//               moduleFamily: ModuleFamily.marelGpSquare,
//               moduleGroupCapacities: [
//                 ModuleGroupCapacity(
//                   firstModule: MarelGpSquareModule4Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(25),
//                   secondModule: MarelGpSquareModule5Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(25),
//                 )
//               ]),
//           ProductDefinition(
//               // 2.6 kg/bird average
//               // 9 levels * 34 birds = 306 birds / 2 cont = average 153 birds/cont
//               // 153 birds/cont * 2 cont * 7.5 CAS cycle/hour * 5 CAS units = 11475 birds/hour
//               // 11000 birds/hour / 153 birds/cont = 72 cont/hour
//               areaFactory: _areaFactory(),
//               birdType: 'Pollo Medio',
//               lineSpeedInShacklesPerHour: 10000,
//               casRecipe: const CasRecipe.standardChickenRecipe(),
//               moduleSystem: ModuleSystem.meynVdlSquareContainers,
//               moduleFamily: ModuleFamily.marelGpSquare,
//               moduleGroupCapacities: [
//                 ModuleGroupCapacity(
//                   firstModule: MarelGpSquareModule4Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(34),
//                   secondModule: MarelGpSquareModule5Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(34),
//                 )
//               ]),

// // With buffer conveyor between tilter and turntable but lower feasible speed

//           ProductDefinition(
//               // 3.5 kg/bird average
//               // 9 levels * 25 birds = 225 birds / 2 cont = average 112 birds/cont
//               // 112 birds/cont * 2 cont * 7.5 CAS cycle/hour * 6 CAS units = 10080 birds/hour
//               // 10080 birds/hour / 112 birds/cont = 90 cont/hour
//               areaFactory: _areaWithExtraConveyorFactory(),
//               birdType: 'Pollo Grosso',
//               lineSpeedInShacklesPerHour: 8000,
//               casRecipe: const CasRecipe.standardChickenRecipe(),
//               moduleSystem: ModuleSystem.meynVdlSquareContainers,
//               moduleFamily: ModuleFamily.marelGpSquare,
//               moduleGroupCapacities: [
//                 ModuleGroupCapacity(
//                   firstModule: MarelGpSquareModule4Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(25),
//                   secondModule: MarelGpSquareModule5Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(25),
//                 )
//               ]),
//           ProductDefinition(
//               // 2.6 kg/bird average
//               // 9 levels * 34 birds = 306 birds / 2 cont = average 153 birds/cont
//               // 153 birds/cont * 2 cont * 7.5 CAS cycle/hour * 5 CAS units = 11475 birds/hour
//               // 11000 birds/hour / 153 birds/cont = 72 cont/hour
//               areaFactory: _areaWithExtraConveyorFactory(),
//               birdType: 'Pollo Medio',
//               lineSpeedInShacklesPerHour: 10000,
//               casRecipe: const CasRecipe.standardChickenRecipe(),
//               moduleSystem: ModuleSystem.meynVdlSquareContainers,
//               moduleFamily: ModuleFamily.marelGpSquare,
//               moduleGroupCapacities: [
//                 ModuleGroupCapacity(
//                   firstModule: MarelGpSquareModule4Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(34),
//                   secondModule: MarelGpSquareModule5Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(34),
//                 )
//               ]),

// // With buffer conveyor between tilter and turntable but with unfeasible requested speed

//           ProductDefinition(
//               // 3.5 kg/bird average
//               // 9 levels * 25 birds = 225 birds / 2 cont = average 112 birds/cont
//               // 112 birds/cont * 2 cont * 7.5 CAS cycle/hour * 6 CAS units = 10080 birds/hour
//               // 9000 birds/hour / 112 birds/cont = 81 cont/hour
//               areaFactory: _areaWithExtraConveyorFactory(),
//               birdType: 'Pollo Grosso',
//               lineSpeedInShacklesPerHour: 9000,
//               casRecipe: const CasRecipe.standardChickenRecipe(),
//               moduleSystem: ModuleSystem.meynVdlSquareContainers,
//               moduleFamily: ModuleFamily.marelGpSquare,
//               moduleGroupCapacities: [
//                 ModuleGroupCapacity(
//                   firstModule: MarelGpSquareModule4Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(25),
//                   secondModule: MarelGpSquareModule5Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(25),
//                 )
//               ]),
//           ProductDefinition(
//               // 2.6 kg/bird average
//               // 9 levels * 34 birds = 306 birds / 2 cont = average 153 birds/cont
//               // 153 birds/cont * 2 cont * 7.5 CAS cycle/hour * 5 CAS units = 11475 birds/hour
//               // 11000 birds/hour / 153 birds/cont = 72 cont/hour
//               areaFactory: _areaWithExtraConveyorFactory(),
//               birdType: 'Pollo Medio',
//               lineSpeedInShacklesPerHour: 11000,
//               casRecipe: const CasRecipe.standardChickenRecipe(),
//               moduleSystem: ModuleSystem.meynVdlSquareContainers,
//               moduleFamily: ModuleFamily.marelGpSquare,
//               moduleGroupCapacities: [
//                 ModuleGroupCapacity(
//                   firstModule: MarelGpSquareModule4Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(34),
//                   secondModule: MarelGpSquareModule5Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(34),
//                 )
//               ]),

// // With buffer conveyor between tilter and turntable , extra CAS unit but with unfeasible requested speed

//           ProductDefinition(
//               // 3.5 kg/bird average
//               // 9 levels * 25 birds = 225 birds / 2 cont = average 112 birds/cont
//               // 112 birds/cont * 2 cont * 7.5 CAS cycle/hour * 6 CAS units = 10080 birds/hour
//               // 9000 birds/hour / 112 birds/cont = 81 cont/hour
//               areaFactory: _areaWithExtraCasAndConveyorFactory(),
//               birdType: 'Pollo Grosso',
//               lineSpeedInShacklesPerHour: 9000,
//               casRecipe: const CasRecipe.standardChickenRecipe(),
//               moduleSystem: ModuleSystem.meynVdlSquareContainers,
//               moduleFamily: ModuleFamily.marelGpSquare,
//               moduleGroupCapacities: [
//                 ModuleGroupCapacity(
//                   firstModule: MarelGpSquareModule4Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(25),
//                   secondModule: MarelGpSquareModule5Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(25),
//                 )
//               ]),
//           ProductDefinition(
//               // 2.6 kg/bird average
//               // 9 levels * 34 birds = 306 birds / 2 cont = average 153 birds/cont
//               // 153 birds/cont * 2 cont * 7.5 CAS cycle/hour * 5 CAS units = 11475 birds/hour
//               // 11000 birds/hour / 153 birds/cont = 72 cont/hour
//               areaFactory: _areaWithExtraCasAndConveyorFactory(),
//               birdType: 'Pollo Medio',
//               lineSpeedInShacklesPerHour: 11000,
//               casRecipe: const CasRecipe.standardChickenRecipe(),
//               moduleSystem: ModuleSystem.meynVdlSquareContainers,
//               moduleFamily: ModuleFamily.marelGpSquare,
//               moduleGroupCapacities: [
//                 ModuleGroupCapacity(
//                   firstModule: MarelGpSquareModule4Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(34),
//                   secondModule: MarelGpSquareModule5Level()
//                       .dimensions
//                       .capacityWithBirdsPerCompartment(34),
//                 )
//               ]),

          ProductDefinition(
              // 3.5 kg/bird average
              // 9 levels * 25 birds = 225 birds / 2 cont = average 112 birds/cont
              // 112 birds/cont * 2 cont * 7.5 CAS cycle/hour * 6 CAS units = 10080 birds/hour
              // 9000 birds/hour / 112 birds/cont = 81 cont/hour
              areaFactory: _areaWithComparableToAvimeccFactory(),
              birdType: 'Pollo Grosso',
              lineSpeedInShacklesPerHour: 9000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem
                  .meynGrandeDrawerContainers, //Actually: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily
                  .meynGrandeDrawer, //Actually: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule:
                      MeynGrandeDrawerChicken4Level() // Actually 2x MarelGpSquareModule4Level() with 2x25 birds per level
                          .dimensions
                          .capacityWithBirdsPerCompartment(25),
                  secondModule:
                      MeynGrandeDrawerChicken5Level() // Actually 2x MarelGpSquareModule5Level() with 2x25 birds per level
                          .dimensions
                          .capacityWithBirdsPerCompartment(25),
                )
              ]),
          ProductDefinition(
              // 2.6 kg/bird average
              // 9 levels * 34 birds = 306 birds / 2 cont = average 153 birds/cont
              // 153 birds/cont * 2 cont * 7.5 CAS cycle/hour * 5 CAS units = 11475 birds/hour
              // 11000 birds/hour / 153 birds/cont = 72 cont/hour
              areaFactory: _areaWithComparableToAvimeccFactory(),
              birdType: 'Pollo Medio',
              lineSpeedInShacklesPerHour: 11000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem
                  .meynVdlRectangularContainers, //Actually: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily
                  .meynGrandeDrawer, //Actually: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule:
                      MeynGrandeDrawerChicken4Level() // Actually 2x MarelGpSquareModule4Level() with 2x34 birds per level
                          .dimensions
                          .capacityWithBirdsPerCompartment(34),
                  secondModule:
                      MeynGrandeDrawerChicken5Level() // Actually 2x MarelGpSquareModule5Level() with 2x34 birds per level
                          .dimensions
                          .capacityWithBirdsPerCompartment(34),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [CarnjLiveBirdHandlingArea(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaWithExtraConveyorFactory() =>
          (ProductDefinition productDefinition) =>
              [CarnjLiveBirdHandlingAreaWithExtraConveyor(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaWithExtraCasAndConveyorFactory() => (ProductDefinition
              productDefinition) =>
          [CarnjLiveBirdHandlingAreaWithExtraCasAndConveyor(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaWithComparableToAvimeccFactory() =>
          (ProductDefinition productDefinition) => [
                CarnjLiveBirdHandlingAreaComparableToAvimeccFactory(
                    productDefinition)
              ];
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
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
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

class CarnjLiveBirdHandlingAreaWithExtraCasAndConveyor
    extends LiveBirdHandlingArea {
  CarnjLiveBirdHandlingAreaWithExtraCasAndConveyor(
      ProductDefinition productDefinition)
      : super(
          lineName: 'With extra CAS and buffer for tilter',
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
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
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

    put(ModuleCas(
      area: this,
      position: const Position(7, 5),
      seqNr: 7,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));
  }
}

class CarnjLiveBirdHandlingAreaComparableToAvimeccFactory
    extends LiveBirdHandlingArea {
  CarnjLiveBirdHandlingAreaComparableToAvimeccFactory(
      ProductDefinition productDefinition)
      : super(
          lineName: '4 containers on a plate, comparable to 9018 Avimecc',
          productDefinition: productDefinition,
        ) {
    _row3();
    _row4();
    _row5();
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
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(6, 3),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
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
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(5, 4),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(6, 4),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(7, 4),
      seqNr: 2,
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(8, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.east,
    ));

    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(9, 4),
      outFeedDirection: CardinalDirection.west,
      doorDirection: CardinalDirection.south,
      loadsSingeModule: false,
    ));
  }

  void _row5() {
    put(ModuleCasAllocation(
      area: this,
      position: const Position(1, 5),
      positionToAllocate: const Position(7, 4),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(2, 5),
    ));
  }
}
