import 'package:collection/collection.dart';
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
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class HaerlandSite extends Site {
  HaerlandSite()
      : super(
          meynLayoutNumber: 5246,
          organizationName: 'Nortura',
          city: 'Haerland',
          country: 'Norway',
          productDefinitions: HaerlandProductDefinitions(),
        );
}

class HaerlandProductDefinitions extends DelegatingList<ProductDefinition> {
  static int birdsPerCompartment = 34 * 2;

  HaerlandProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactoryTurkey(),
              birdType: 'Small Turkeys',
              lineSpeedInShacklesPerHour: 950,
              casRecipe: const CasRecipe.standardTurkeyRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.angliaAutoFlow,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: AngliaAutoFlowTurkey3Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(8),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactoryTurkey(),
              birdType: 'Big Turkeys',
              lineSpeedInShacklesPerHour: 800,
              casRecipe: const CasRecipe.standardTurkeyRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.angliaAutoFlow,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: AngliaAutoFlowTurkey3Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(3),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactoryTurkey(),
              birdType: 'Breeder Turkeys',
              lineSpeedInShacklesPerHour: 100,
              casRecipe: const CasRecipe.standardTurkeyRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.angliaAutoFlow,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: AngliaAutoFlowTurkey3Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(1),
                )
              ]),

          /// Lost chicken line to Marel Atlas
          ProductDefinition(
              areaFactory: _areaFactoryChicken(),
              birdType: 'Chickens',
              lineSpeedInShacklesPerHour: 12500,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.marelGpSingleColumn,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(birdsPerCompartment),
                  secondModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(birdsPerCompartment),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactoryChicken(),
              birdType: 'Chickens',
              lineSpeedInShacklesPerHour: 15000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.marelGpSingleColumn,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(birdsPerCompartment),
                  secondModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(birdsPerCompartment),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactoryChicken() => (ProductDefinition productDefinition) =>
          [HaerlandLiveBirdHandlingChickenArea(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactoryTurkey() => (ProductDefinition productDefinition) =>
          [HaerlandLiveBirdHandlingTurkeyArea(productDefinition)];
}

class HaerlandLiveBirdHandlingTurkeyArea extends LiveBirdHandlingArea {
  HaerlandLiveBirdHandlingTurkeyArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Turkey Line',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
    _row4();
    _row5();
    _row6();
  }

  void _row1() {
    put(ModuleCas(
      area: this,
      position: const Position(1, 2),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(2, 2),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 2),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(4, 2),
    ));
  }

  void _row2() {
    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(1, 3),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.north,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(2, 3),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 3),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));
  }

  void _row3() {
    put(ModuleConveyor(
      area: this,
      position: const Position(1, 4),
      seqNr: 2,
      inFeedDirection: CardinalDirection.south,
    ));

    put(ModuleCasAllocation(
      area: this,
      position: const Position(2, 4),
      positionToAllocate: const Position(1, 4),
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(3, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.north,
      birdDirection: CardinalDirection.east,
      minBirdsOnDumpBeltBuffer: (productDefinition
                  .averageProductsPerModuleGroup /
              2)
          .round(), //REDUCED buffer size to 4.5 drawers due to limited buffer space!!!!
    ));

    put(BirdHangingConveyor(
      area: this,
      position: const Position(4, 4),
      direction: CardinalDirection.north,
    ));
  }

  void _row4() {
    put(ModuleConveyor(
      area: this,
      position: const Position(1, 5),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 5),
      seqNr: 4,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.north,
    ));
  }

  void _row5() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(1, 6),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
      loadsSingeModule: false,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(3, 6),
      seqNr: 3,
      inFeedDirection: CardinalDirection.north,
    ));
  }

  void _row6() {
    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(3, 7),
      inFeedDirection: CardinalDirection.north,
    ));
  }
}

class HaerlandLiveBirdHandlingChickenArea extends LiveBirdHandlingArea {
  HaerlandLiveBirdHandlingChickenArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Chicken line',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
    _row4();
    _row5();
    _row6();
  }

  void _row1() {
    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(2, 1),
      inFeedDirection: CardinalDirection.south,
    ));
  }

  void _row2() {
    put(ModuleTilter(
      area: this,
      position: const Position(2, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
      birdDirection: CardinalDirection.east,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    put(BirdHangingConveyor(
      area: this,
      position: const Position(3, 2),
      direction: CardinalDirection.north,
    ));
  }

  void _row3() {
    put(ModuleConveyor(
      area: this,
      position: const Position(2, 3),
      inFeedDirection: CardinalDirection.south,
    ));
  }

  void _row4() {
    put(ModuleDeStacker(
      area: this,
      position: const Position(2, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 4),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 4),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(5, 4),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(6, 4),
      seqNr: 2,
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(7, 4),
      seqNr: 1,
      defaultPositionWhenIdle: CardinalDirection.north,
    ));
  }

  void _row5() {
    put(ModuleCas(
      area: this,
      position: const Position(1, 5),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.east,
      doorDirection: CardinalDirection.north,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(2, 5),
      seqNr: 7,
      oppositeInFeeds: [CardinalDirection.west],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 5),
      seqNr: 6,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(4, 5),
      seqNr: 5,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(5, 5),
      seqNr: 4,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(6, 5),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(7, 5),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));
  }

  void _row6() {
    put(ModuleCasAllocation(
      area: this,
      position: const Position(1, 6),
      positionToAllocate: const Position(6, 5),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(2, 6),
    ));

    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(7, 6),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));
  }
}
