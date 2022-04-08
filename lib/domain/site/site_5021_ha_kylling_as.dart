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

class HaKyllingAsSite extends Site {
  HaKyllingAsSite()
      : super(
          meynLayoutNumber: 5021,
          organizationName: 'Hå Kylling AS',
          city: 'NÆRBØ',
          country: 'Norway',
          productDefinitions: ProductDefinitions(),
        );
}

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition)],
              birdType: 'Chicken',

              /// To measure max birds/hour at [ShackleLine]
              lineSpeedInShacklesPerHour: 20000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkRectangularGpModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkRectangularGpModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 37),
                  secondModule: StorkRectangularGpModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 37),
                )
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition)],
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 9300,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleType: StorkRectangularGpModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: StorkRectangularGpModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 37),
                  secondModule: StorkRectangularGpModule()
                      .levels(4)
                      .capacity(birdsPerCompartment: 37),
                )
              ]),
        ]);
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
    _row5();
    _row6();
    _row7();
    _row8();
    _row9();
  }

  void _row1() {
    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(2, 1),
      inFeedDirection: CardinalDirection.south,
    ));
  }

  void _row2() {
    put(BirdHangingConveyor(
      area: this,
      position: const Position(1, 2),
      direction: CardinalDirection.north,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(2, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
      birdDirection: CardinalDirection.west,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));
  }

  void _row3() {
    //Gross weighing conveyor
    put(ModuleConveyor(
      area: this,
      position: const Position(2, 3),
      seqNr: 4,
      inFeedDirection: CardinalDirection.south,
      inFeedDuration: const Duration(seconds: 20),
    ));
  }

  void _row4() {
    put(ModuleDeStacker(
      area: this,
      position: const Position(2, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));
  }

  void _row5() {
    put(ModuleConveyor(
      area: this,
      position: const Position(2, 5),
      seqNr: 3,
      inFeedDirection: CardinalDirection.south,
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(3, 5),
    ));
  }

  void _row6() {
    put(ModuleCas(
      area: this,
      position: const Position(1, 6),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.east,
      doorDirection: CardinalDirection.south,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(2, 6),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.west],
      oppositeOutFeeds: [CardinalDirection.east],
      defaultPositionWhenIdle: CardinalDirection.north,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 6),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.west,
      doorDirection: CardinalDirection.south,
    ));
  }

  void _row7() {
    put(ModuleConveyor(
      area: this,
      position: const Position(2, 7),
      seqNr: 2,
      inFeedDirection: CardinalDirection.south,
    ));

    put(ModuleCasAllocation(
        area: this,
        position: const Position(3, 7),
        positionToAllocate: const Position(2, 7)));
  }

  void _row8() {
    put(ModuleConveyor(
      area: this,
      position: const Position(2, 8),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));
  }

  void _row9() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(2, 9),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));
  }
}
