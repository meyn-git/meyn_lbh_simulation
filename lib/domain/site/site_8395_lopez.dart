import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class LopezSite extends Site {
  LopezSite()
      : super(
          meynLayoutNumber: 8359,
          organizationName: 'Lopez',
          city: '',
          country: 'Spain',
          productDefinitions: ProductDefinitions(),
        );
}

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactory2CASUnits(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 3300,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.marelGpRectangular,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  // bird weight min: 2,3 avr: 2,8 max 3kg
                  firstModule: ModuleCapacity(
                      levels: 4,
                      compartmentsPerLevel: 2,
                      birdsPerCompartment: 24),
                  secondModule: ModuleCapacity(
                      levels: 5,
                      compartmentsPerLevel: 2,
                      birdsPerCompartment: 24),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory3CASUnits(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 3300,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.marelGpRectangular,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  // bird weight min: 2,3 avr: 2,8 max 3kg
                  firstModule: ModuleCapacity(
                      levels: 4,
                      compartmentsPerLevel: 2,
                      birdsPerCompartment: 24),
                  secondModule: ModuleCapacity(
                      levels: 5,
                      compartmentsPerLevel: 2,
                      birdsPerCompartment: 24),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory2CASUnits() => (ProductDefinition productDefinition) =>
          [AreaWith2CASUnits(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory3CASUnits() => (ProductDefinition productDefinition) =>
          [AreaWith3CASUnits(productDefinition)];
}

class AreaWith2CASUnits extends LiveBirdHandlingArea {
  AreaWith2CASUnits(ProductDefinition productDefinition)
      : super(
          lineName: 'With 2 CAS units',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
  }

  void _row1() {
    put(ModuleCas(
      area: this,
      position: const Position(3, 1),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 1),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(BirdHangingConveyor(
      area: this,
      position: const Position(5, 1),
      direction: CardinalDirection.west,
    ));
  }

  void _row2() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(1, 2),
      outFeedDirection: CardinalDirection.east,
      doorDirection: CardinalDirection.south,
      loadsSingeModule: true,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(2, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 2),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.west, CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(4, 2),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(5, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
      birdDirection: CardinalDirection.north,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    //Tare weighing conveyor
    put(ModuleConveyor(
      area: this,
      position: const Position(6, 2),
      seqNr: 2,
      inFeedDirection: CardinalDirection.west,
    ));

    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(7, 2),
      inFeedDirection: CardinalDirection.west,
    ));
  }

  void _row3() {
    put(ModuleCasAllocation(
      area: this,
      position: const Position(2, 3),
      positionToAllocate: const Position(2, 2),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(4, 3),
    ));
  }
}

class AreaWith3CASUnits extends LiveBirdHandlingArea {
  AreaWith3CASUnits(ProductDefinition productDefinition)
      : super(
          lineName: 'With 3 CAS units',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
  }

  void _row1() {
    put(ModuleCas(
      area: this,
      position: const Position(3, 1),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 1),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(5, 1),
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
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(1, 2),
      outFeedDirection: CardinalDirection.east,
      doorDirection: CardinalDirection.south,
      loadsSingeModule: true,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(2, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 2),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.west, CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(4, 2),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(5, 2),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.east,
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
      seqNr: 2,
      inFeedDirection: CardinalDirection.west,
    ));

    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(8, 2),
      inFeedDirection: CardinalDirection.west,
    ));
  }

  void _row3() {
    put(ModuleCasAllocation(
      area: this,
      position: const Position(2, 3),
      positionToAllocate: const Position(2, 2),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(4, 3),
    ));
  }
}
