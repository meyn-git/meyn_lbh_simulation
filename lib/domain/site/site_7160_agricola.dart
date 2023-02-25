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

class AgricolaSite extends Site {
  AgricolaSite()
      : super(
          meynLayoutNumber: 7324,
          organizationName: 'CARNJ Soc. Coop. Agricola',
          city: 'Jesi-Ancona',
          country: 'Italy',
          productDefinitions: AgricolaProductDefinitions(),
        );
}

/// Fileni chicken: ModuleGroup = 4 and 5 compartment module
/// Pollo Bio:                  26 birds/compartment @ 8000 birds/hour
/// Pollo RUSTICANELLO Pesante: 33 birds/compartment @ 6000 birds/hour
/// Pollo RUSTICANELLO :        52 birds/compartment @ 7000 birds/hour
/// Pollo PICCOLO:              54 birds/compartment @ 10000 birds/hour
class AgricolaProductDefinitions extends DelegatingList<ProductDefinition> {
  AgricolaProductDefinitions()
      : super([
// Without buffer conveyor between tilter and turntable

          ProductDefinition(
              //2,82286 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo Bio',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(26),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(26),
                )
              ]),
          ProductDefinition(
              // 1,3 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo RUSTICANELLO Pesante',
              lineSpeedInShacklesPerHour: 6000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(33),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(33),
                )
              ]),
          ProductDefinition(
              //0.6319997 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo RUSTICANELLO',
              lineSpeedInShacklesPerHour: 7000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(52),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(52),
                )
              ]),
          ProductDefinition(
              //0,8379
              areaFactory: _areaFactory(),
              birdType: 'Pollo PICCOLO',
              lineSpeedInShacklesPerHour: 10000,
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
              //2,82286 stacks per hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo Bio',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(26),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(26),
                )
              ]),
          ProductDefinition(
              // 1,3 stacks per hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo RUSTICANELLO Pesante',
              lineSpeedInShacklesPerHour: 6000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(33),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(33),
                )
              ]),
          ProductDefinition(
              //0.6319997 stacks per hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo RUSTICANELLO',
              lineSpeedInShacklesPerHour: 7000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(52),
                  secondModule: MarelGpSquareModule5Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(52),
                )
              ]),
          ProductDefinition(
              //0,8379
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo PICCOLO',
              lineSpeedInShacklesPerHour: 10000,
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
          [AgricolaLiveBirdHandlingArea(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaWithExtraBufferFactory() => (ProductDefinition productDefinition) =>
          [AgricolaLiveBirdHandlingAreaWithExtraConveyor(productDefinition)];
}

class AgricolaLiveBirdHandlingArea extends LiveBirdHandlingArea {
  AgricolaLiveBirdHandlingArea(ProductDefinition productDefinition)
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

class AgricolaLiveBirdHandlingAreaWithExtraConveyor
    extends LiveBirdHandlingArea {
  AgricolaLiveBirdHandlingAreaWithExtraConveyor(
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
