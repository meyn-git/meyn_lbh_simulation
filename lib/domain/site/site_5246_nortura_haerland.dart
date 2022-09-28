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
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class HaerlandSite extends Site {
  HaerlandSite()
      : super(
          meynLayoutNumber: 5246,
          organizationName: 'Haerland',
          city: 'Haerland',
          country: 'Norway',
          productDefinitions: HaerlandProductDefinitions(),
        );
}

class HaerlandProductDefinitions extends DelegatingList<ProductDefinition> {
  HaerlandProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Chickens',
              lineSpeedInShacklesPerHour: 12500,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.marelGpRectangular,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(64),
                  secondModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(64),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Chickens',
              lineSpeedInShacklesPerHour: 15000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.marelGpRectangular,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(64),
                  secondModule: MarelGpSquareModule4Level()
                      .dimensions
                      .capacityWithBirdsPerCompartment(64),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [HaerlandLiveBirdHandlingArea(productDefinition)];
}

class HaerlandLiveBirdHandlingArea extends LiveBirdHandlingArea {
  HaerlandLiveBirdHandlingArea(ProductDefinition productDefinition)
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
      direction: CardinalDirection.west,
    ));
  }

  void _row2() {
    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(1, 2),
      seqNr: 5,
      defaultPositionWhenIdle: CardinalDirection.north,
    ));

    put(ModuleDeStacker(
      area: this,
      position: const Position(2, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(3, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
      birdDirection: CardinalDirection.north,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(4, 2),
      seqNr: 3,
      inFeedDirection: CardinalDirection.west,
    ));

    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(5, 2),
      inFeedDirection: CardinalDirection.west,
    ));
  }

  void _row3() {
    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(1, 3),
      seqNr: 4,
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(2, 3),
      seqNr: 3,
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 3),
      seqNr: 2,

      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(4, 3),
      seqNr: 1,

      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(5, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.east,
    ));

    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(6, 3),
      outFeedDirection: CardinalDirection.west,
      doorDirection: CardinalDirection.north,
    ));
  }

  void _row4() {
    put(ModuleCas(
      area: this,
      position: const Position(1, 4),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(2, 4),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 4),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 4),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));
  }

  void _row5() {
    put(ModuleCasAllocation(
      area: this,
      position: const Position(1, 5),
      positionToAllocate: const Position(5, 3),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(2, 5),
    ));
  }
}
