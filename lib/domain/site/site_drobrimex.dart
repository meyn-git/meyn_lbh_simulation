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
              areaFactory: _areaFactory(),
              birdType: 'Chicken',
              loadFactor: LoadFactor.average,
              lineSpeedInShacklesPerHour: 15000,
              moduleType: AngliaAutoFlowModule(),
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                    firstModule: ModuleCapacity(
                      numberOfCompartments: 4,
                      numberOfBirdsPerCompartment: 45,
                    ),
                    secondModule: ModuleCapacity(
                      numberOfCompartments: 5,
                      numberOfBirdsPerCompartment: 45,
                    ))
              ])
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [DobrimexLiveBirdHandlingArea(productDefinition)];
}

class DobrimexLiveBirdHandlingArea extends LiveBirdHandlingArea {
  DobrimexLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Line 1',
          productDefinition: productDefinition,
          casRecipe: const CasRecipe.standardChickenRecipe(),
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

  void _row2() {
    put(ModuleCas(
      area: this,
      position: const Position(1, 2),
      seqNr: 6,
      inAndOutFeedDirection: CardinalDirection.east,
      doorDirection: CardinalDirection.south,
    ));

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
