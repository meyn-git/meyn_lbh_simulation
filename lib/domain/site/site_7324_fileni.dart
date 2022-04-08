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
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class FileniSite extends Site {
  FileniSite()
      : super(
          meynLayoutNumber: 7324,
          organizationName: 'Fileni',
          city: 'Castelplanio',
          country: 'Italy',
          productDefinitions: FileniProductDefinitions(),
        );
}

/// Fileni chicken: ModuleGroup = 4 and 5 compartment module
/// Pollo Bio:                  26 birds/compartment @ 8000 birds/hour
/// Pollo RUSTICANELLO Pesante: 33 birds/compartment @ 6000 birds/hour
/// Pollo RUSTICANELLO :        52 birds/compartment @ 7000 birds/hour
/// Pollo PICCOLO:              54 birds/compartment @ 10000 birds/hour
class FileniProductDefinitions extends DelegatingList<ProductDefinition> {
  FileniProductDefinitions()
      : super([
          ProductDefinition(
              //2,82286 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo Bio',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkSquareModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkSquareModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 26),
                  secondModule: StorkSquareModule()
                      .levels(5)
                      .capacity(birdsPerCompartment: 26),
                )
              ]),
          ProductDefinition(
              // 1,3 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo RUSTICANELLO Pesante',
              lineSpeedInShacklesPerHour: 6000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkSquareModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkSquareModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 33),
                  secondModule: StorkSquareModule()
                      .levels(5)
                      .capacity(birdsPerCompartment: 33),
                )
              ]),
          ProductDefinition(
              //0.6319997 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo RUSTICANELLO',
              lineSpeedInShacklesPerHour: 7000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkSquareModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkSquareModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 52),
                  secondModule: StorkSquareModule()
                      .levels(5)
                      .capacity(birdsPerCompartment: 52),
                )
              ]),
          ProductDefinition(
              //0,8379
              areaFactory: _areaFactory(),
              birdType: 'Pollo PICCOLO',
              lineSpeedInShacklesPerHour: 10000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkSquareModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkSquareModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 54),
                  secondModule: StorkSquareModule()
                      .levels(5)
                      .capacity(birdsPerCompartment: 54),
                )
              ]),
          ProductDefinition(
              //2,82286 stacks per hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo Bio',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkSquareModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkSquareModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 26),
                  secondModule: StorkSquareModule()
                      .levels(5)
                      .capacity(birdsPerCompartment: 26),
                )
              ]),
          ProductDefinition(
              // 1,3 stacks per hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo RUSTICANELLO Pesante',
              lineSpeedInShacklesPerHour: 6000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkSquareModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkSquareModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 33),
                  secondModule: StorkSquareModule()
                      .levels(5)
                      .capacity(birdsPerCompartment: 33),
                )
              ]),
          ProductDefinition(
              //0.6319997 stacks per hour
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo RUSTICANELLO',
              lineSpeedInShacklesPerHour: 7000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkSquareModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkSquareModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 52),
                  secondModule: StorkSquareModule()
                      .levels(5)
                      .capacity(birdsPerCompartment: 52),
                )
              ]),
          ProductDefinition(
              //0,8379
              areaFactory: _areaWithExtraBufferFactory(),
              birdType: 'Pollo PICCOLO',
              lineSpeedInShacklesPerHour: 10000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkSquareModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkSquareModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 54),
                  secondModule: StorkSquareModule()
                      .levels(5)
                      .capacity(birdsPerCompartment: 54),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [FileniLiveBirdHandlingArea(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaWithExtraBufferFactory() => (ProductDefinition productDefinition) =>
          [FileniLiveBirdHandlingAreaWithExtraBuffer(productDefinition)];
}

class FileniLiveBirdHandlingArea extends LiveBirdHandlingArea {
  FileniLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Chicken line',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
    _row4();
    _row5();
  }

  void _row1() {
    put(BirdHangingConveyor(
      area: this,
      position: const Position(3, 1),
      direction: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(5, 1),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(6, 1),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(7, 1),
      seqNr: 5,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));
  }

  void _row2() {
    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(1, 2),
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(2, 2),
      seqNr: 3,
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(3, 2),
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
      position: const Position(4, 2),
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
      position: const Position(5, 2),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(6, 2),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(7, 2),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.north,
    ));
  }

  void _row3() {
    put(ModuleCas(
      area: this,
      position: const Position(5, 3),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(6, 3),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    /// mimicking a merging conveyor: 2 x singe [ModuleGroup] from fork lift truck into 1
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleStacker(
      area: this,
      position: const Position(7, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
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
    put(ModuleConveyor(
      area: this,
      position: const Position(7, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));
  }

  void _row5() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(7, 5),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
      loadsSingeModule: true,
    ));

    put(ModuleCasAllocation(
      area: this,
      position: const Position(1, 5),
      positionToAllocate: const Position(7, 3),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(2, 5),
    ));
  }
}

class FileniLiveBirdHandlingAreaWithExtraBuffer extends LiveBirdHandlingArea {
  // static final birdsPerHour = 8000;
  // static final birdsPerModule1 = ((4 + 5) / 2 * 26).round();
  // static final birdsPerModule2 = ((4 + 5) / 2 * 26).round();
  //
  // static const conveyorTransportDuration =
  //     Duration(milliseconds: 13400); // Based on measurements @ Dabe
  // static const turnTableDegreesPerSecond =
  //     10; //Based on measurements @ Dabe: 90 degrees in 9 seconds
  // static const casTransportDuration =
  //     Duration(milliseconds: 18700); // Based on measurements @ Dabe

  FileniLiveBirdHandlingAreaWithExtraBuffer(ProductDefinition productDefinition)
      : super(
          lineName: 'Chicken line with extra buffer',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
    _row4();
    _row5();
  }

  void _row1() {
    put(BirdHangingConveyor(
      area: this,
      position: const Position(5, 1),
      direction: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(9, 1),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(10, 1),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(11, 1),
      seqNr: 5,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));
  }

  void _row2() {
    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(3, 2),
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(4, 2),
      seqNr: 5,
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(5, 2),
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
      position: const Position(6, 2),
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

    put(ModuleConveyor(
      area: this,
      seqNr: 13,
      position: const Position(7, 2),
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleConveyor(
      area: this,
      seqNr: 14,
      position: const Position(8, 2),
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(9, 2),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(10, 2),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(11, 2),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.north,
    ));
  }

  void _row3() {
    put(ModuleCas(
      area: this,
      position: const Position(9, 3),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(10, 3),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    /// mimicking a merging conveyor: 2 x singe [ModuleGroup] from fork lift truck into 1
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleStacker(
      area: this,
      position: const Position(11, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
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
    put(ModuleConveyor(
      area: this,
      position: const Position(11, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));
  }

  void _row5() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(11, 5),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
      loadsSingeModule: true,
    ));

    put(ModuleCasAllocation(
      area: this,
      position: const Position(3, 5),
      positionToAllocate: const Position(11, 3),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(5, 5),
    ));
  }
}
