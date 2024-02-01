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

class DobrimexSite extends Site {
  DobrimexSite()
      : super(
          meynLayoutNumber: 5674,
          organizationName: 'Drobrimex',
          city: 'Szczecin',
          country: 'Poland',
          productDefinitions: DobrimexProductDefinitions(),
        );
}

class DobrimexProductDefinitions extends DelegatingList<ProductDefinition> {
  DobrimexProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactory(DobrimexAreaType.sixCasUnits),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 15000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlRectangularContainers,
              moduleFamily: ModuleFamily.angliaAutoFlow,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                  secondModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(DobrimexAreaType.fiveCasUnits),
              birdType: 'Chicken',

              /// Running a too high line speed so we can determine the actual
              /// hanged birds/hour, by monitoring the [ShackleLine].
              lineSpeedInShacklesPerHour: 16500,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlRectangularContainers,
              moduleFamily: ModuleFamily.angliaAutoFlow,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                  secondModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(DobrimexAreaType.fiveCasUnits),
              birdType: 'Chicken',

              /// Runs 14200 b/h theoretically (see previous product definition),
              /// Assuming we need 10% margin = 14200 *0.9=12780 b/h
              lineSpeedInShacklesPerHour: 12780,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlRectangularContainers,
              moduleFamily: ModuleFamily.angliaAutoFlow,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                  secondModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(DobrimexAreaType.sixCasUnits),
              birdType: 'Chicken',

              /// Running a too high line speed so we can determine the actual
              /// hanged birds/hour, by monitoring the [ShackleLine].
              lineSpeedInShacklesPerHour: 19800,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlRectangularContainers,
              moduleFamily: ModuleFamily.angliaAutoFlow,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                  secondModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(DobrimexAreaType.sixCasUnits),
              birdType: 'Chicken',

              /// Runs 17100 b/h theoretically (see previous product definition),
              /// Assuming we need 10% margin = 17100 *0.9=15390 b/h
              lineSpeedInShacklesPerHour: 15390,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlRectangularContainers,
              moduleFamily: ModuleFamily.angliaAutoFlow,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                  secondModule: AngliaAutoFlowChickenSmall4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(15),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition) _areaFactory(
          DobrimexAreaType areaType) =>
      (ProductDefinition productDefinition) =>
          [DobrimexLiveBirdHandlingArea(productDefinition, areaType)];
}

enum DobrimexAreaType { fiveCasUnits, sixCasUnits }

class DobrimexLiveBirdHandlingArea extends LiveBirdHandlingArea {
  DobrimexLiveBirdHandlingArea(
      ProductDefinition productDefinition, DobrimexAreaType areaType)
      : super(
          lineName: 'Line 1',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2(areaType);
    _row3();
    _row4();
  }

  void _row1() {
    put(ModuleCas(
      area: this,
      position: const Position(2, 1),
      seqNr: 5,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 1),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 1),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));
  }

  void _row2(DobrimexAreaType areaType) {
    if (areaType == DobrimexAreaType.sixCasUnits) {
      put(ModuleCas(
        area: this,
        position: const Position(1, 2),
        seqNr: 6,
        inAndOutFeedDirection: CardinalDirection.east,
        doorDirection: CardinalDirection.south,
      ));
    }

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(2, 2),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south, CardinalDirection.west],
      defaultPositionWhenIdle: CardinalDirection.north,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 2),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(4, 2),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleDeStacker(
      area: this,
      position: const Position(5, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    //Gross weighing conveyor
    put(ModuleConveyor(
      area: this,
      position: const Position(6, 2),
      seqNr: 2,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(7, 2),
      seqNr: 4,
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));
  }

  void _row3() {
    put(ModuleConveyor(
      area: this,
      position: const Position(2, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 3),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 3),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(7, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.north,
      birdDirection: CardinalDirection.east,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    put(BirdHangingConveyor(
      area: this,
      position: const Position(8, 3),
      direction: CardinalDirection.north,
    ));
  }

  void _row4() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(2, 4),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCasAllocation(
        area: this,
        position: const Position(3, 4),
        positionToAllocate: const Position(2, 3)));

    put(ModuleCasStart(
      area: this,
      position: const Position(4, 4),
    ));

    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(7, 4),
      inFeedDirection: CardinalDirection.north,
    ));
  }
}
