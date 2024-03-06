import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
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

class MicarnaSite extends Site {
  MicarnaSite()
      : super(
          meynLayoutNumber: 9164,
          organizationName: 'Micarna',
          city: 'Courtepin',
          country: 'Switzerland',
          productDefinitions: MicarnaProductDefinitions(),
        );
}

class MicarnaProductDefinitions extends DelegatingList<ProductDefinition> {
  static final maxBirdWeight = 2.5.kilo.grams;
  static const summerLoadPercentage = 80;
  static final minLoadDensity =
      LoadDensity.eec64_432(maxBirdWeight, summerLoadPercentage);

  MicarnaProductDefinitions()
      : super([
          // ProductDefinition(
          //     areaFactory: _areaFactoryV1(),
          //     birdType: 'Chicken',
          //     lineSpeedInShacklesPerHour: 13500,
          //     casRecipe: const CasRecipe.standardChickenRecipe(),
          //     moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
          //     moduleFamily: ModuleFamily.meynGrandeDrawerDoubleColumn,
          //     moduleGroupCapacities: [
          //       ModuleGroupCapacity(
          //         firstModule: MeynGrandeDrawerChicken4Level()
          //             .dimensions
          //             .capacityWithDensity(minLoadDensity, maxBirdWeight),
          //         secondModule: MeynGrandeDrawerChicken4Level()
          //             .dimensions
          //             .capacityWithDensity(minLoadDensity, maxBirdWeight),
          //       )
          //     ]),
          // ProductDefinition(
          //     areaFactory: _areaFactoryV2(),
          //     birdType: 'Chicken',
          //     lineSpeedInShacklesPerHour: 13500,
          //     casRecipe: const CasRecipe.standardChickenRecipe(),
          //     moduleSystem: ModuleSystem.meynSingleColumnContainers,
          //     moduleFamily: ModuleFamily.meynGrandeDrawerSingleColumn,
          //     moduleGroupCapacities: [
          //       ModuleGroupCapacity(
          //         firstModule: MeynGrandeDrawerChicken5Level()
          //             .dimensions
          //             .capacityWithDensity(minLoadDensity, maxBirdWeight),
          //         secondModule: MeynGrandeDrawerChicken4Level()
          //             .dimensions
          //             .capacityWithDensity(minLoadDensity, maxBirdWeight),
          //       )
          //     ]),
          ProductDefinition(
              areaFactory: _areaFactoryV2(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 13500,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynSingleColumnContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawerSingleColumn,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken5Level()
                      .dimensions
                      .capacityWithDensity(minLoadDensity, maxBirdWeight),
                  secondModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(minLoadDensity, maxBirdWeight),
                )
              ]),
        ]);

  // static List<LiveBirdHandlingArea> Function(ProductDefinition)
  //     _areaFactoryV1() => (ProductDefinition productDefinition) =>
  //         [MicarnaLiveBirdHandlingAreaV1(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactoryV2() => (ProductDefinition productDefinition) =>
          [MicarnaLiveBirdHandlingAreaV2(productDefinition)];
}

// class MicarnaLiveBirdHandlingAreaV1 extends LiveBirdHandlingArea {
//   MicarnaLiveBirdHandlingAreaV1(ProductDefinition productDefinition)
//       : super(
//           lineName: 'Line1',
//           productDefinition: productDefinition,
//         ) {
//     _row1();
//     _row2();
//     _row3();
//     _row4();
//     _row5();
//   }

//   void _row1() {
//     put(ModuleCas(
//       area: this,
//       position: const Position(5, 1),
//       seqNr: 1,
//       inAndOutFeedDirection: CardinalDirection.south,
//       doorDirection: CardinalDirection.west,
//     ));

//     put(ModuleCas(
//       area: this,
//       position: const Position(6, 1),
//       seqNr: 2,
//       inAndOutFeedDirection: CardinalDirection.south,
//       doorDirection: CardinalDirection.west,
//     ));

//     put(ModuleCas(
//       area: this,
//       position: const Position(7, 1),
//       seqNr: 3,
//       inAndOutFeedDirection: CardinalDirection.south,
//       doorDirection: CardinalDirection.west,
//     ));

//     put(ModuleCas(
//       area: this,
//       position: const Position(8, 1),
//       seqNr: 4,
//       inAndOutFeedDirection: CardinalDirection.south,
//       doorDirection: CardinalDirection.west,
//     ));

//     put(ModuleCas(
//       area: this,
//       position: const Position(9, 1),
//       seqNr: 5,
//       inAndOutFeedDirection: CardinalDirection.south,
//       doorDirection: CardinalDirection.west,
//     ));
//   }

//   void _row2() {
//     put(ModuleRotatingConveyor(
//       area: this,
//       position: const Position(2, 2),
//       seqNr: 8,
//       defaultPositionWhenIdle: CardinalDirection.west,
//     ));

//     put(ModuleDeStacker(
//       area: this,
//       position: const Position(3, 2),
//       seqNr: 1,
//       inFeedDirection: CardinalDirection.east,
//     ));

//     put(ModuleConveyor(
//       area: this,
//       position: const Position(4, 2),
//       seqNr: 6,
//       inFeedDirection: CardinalDirection.east,
//     ));

//     put(ModuleRotatingConveyor(
//       area: this,
//       position: const Position(5, 2),
//       seqNr: 7,
//       oppositeInFeeds: [CardinalDirection.north],
//       oppositeOutFeeds: [CardinalDirection.south],
//       defaultPositionWhenIdle: CardinalDirection.west,
//     ));

//     put(ModuleRotatingConveyor(
//       area: this,
//       position: const Position(6, 2),
//       seqNr: 6,
//       oppositeInFeeds: [CardinalDirection.north],
//       oppositeOutFeeds: [CardinalDirection.south],
//       defaultPositionWhenIdle: CardinalDirection.west,
//     ));

//     put(ModuleRotatingConveyor(
//       area: this,
//       position: const Position(7, 2),
//       seqNr: 5,
//       oppositeInFeeds: [CardinalDirection.north],
//       oppositeOutFeeds: [CardinalDirection.south],
//       defaultPositionWhenIdle: CardinalDirection.west,
//     ));

//     put(ModuleRotatingConveyor(
//       area: this,
//       position: const Position(8, 2),
//       seqNr: 4,
//       oppositeInFeeds: [CardinalDirection.north],
//       oppositeOutFeeds: [CardinalDirection.south],
//       defaultPositionWhenIdle: CardinalDirection.west,
//     ));

//     put(ModuleRotatingConveyor(
//       area: this,
//       position: const Position(9, 2),
//       seqNr: 3,
//       oppositeInFeeds: [CardinalDirection.north],
//       oppositeOutFeeds: [CardinalDirection.south, CardinalDirection.west],
//       defaultPositionWhenIdle: CardinalDirection.north,
//     ));
//   }

//   void _row3() {
//     put(BirdHangingConveyor(
//       area: this,
//       position: const Position(1, 3),
//       direction: CardinalDirection.north,
//     ));

//     put(ModuleTilter(
//       area: this,
//       position: const Position(2, 3),
//       seqNr: 1,
//       inFeedDirection: CardinalDirection.north,
//       birdDirection: CardinalDirection.west,
//       minBirdsOnDumpBeltBuffer:
//           productDefinition.averageProductsPerModuleGroup.round(),
//     ));

//     put(ModuleRotatingConveyor(
//       area: this,
//       position: const Position(4, 3),
//       seqNr: 1,
//       oppositeInFeeds: [CardinalDirection.north],
//       oppositeOutFeeds: [CardinalDirection.south],
//       defaultPositionWhenIdle: CardinalDirection.north,
//     ));

//     put(ModuleConveyor(
//       area: this,
//       position: const Position(5, 3),
//       seqNr: 2,
//       inFeedDirection: CardinalDirection.west,
//     ));

//     put(ModuleConveyor(
//       area: this,
//       position: const Position(6, 3),
//       seqNr: 3,
//       inFeedDirection: CardinalDirection.west,
//     ));

//     put(ModuleConveyor(
//       area: this,
//       position: const Position(7, 3),
//       seqNr: 4,
//       inFeedDirection: CardinalDirection.west,
//     ));

//     put(ModuleConveyor(
//       area: this,
//       position: const Position(8, 3),
//       seqNr: 5,
//       inFeedDirection: CardinalDirection.west,
//     ));

//     put(ModuleRotatingConveyor(
//       area: this,
//       position: const Position(9, 3),
//       seqNr: 2,
//       oppositeInFeeds: [CardinalDirection.north],
//       oppositeOutFeeds: [CardinalDirection.south],
//       defaultPositionWhenIdle: CardinalDirection.east,
//     ));
//   }

//   void _row4() {
//     put(UnLoadingForkLiftTruck(
//       area: this,
//       position: const Position(2, 4),
//       inFeedDirection: CardinalDirection.north,
//     ));

//     put(ModuleConveyor(
//       area: this,
//       position: const Position(4, 4),
//       seqNr: 1,
//       inFeedDirection: CardinalDirection.south,
//     ));
//   }

//   void _row5() {
//     put(LoadingForkLiftTruck(
//       area: this,
//       position: const Position(4, 5),
//       outFeedDirection: CardinalDirection.north,
//       doorDirection: CardinalDirection.west,
//       loadsSingeModule: false,
//     ));

//     put(ModuleCasAllocation(
//       area: this,
//       position: const Position(5, 5),
//       positionToAllocate: const Position(9, 3),
//     ));

//     put(ModuleCasStart(
//         area: this,
//         position: const Position(6, 5),
//         startIntervalFractions: <double>[
//           0.5,
//           0.6,
//           0.7,
//           0.8,
//           1,
//           1,
//           1.25,
//           1.5,
//           1.75,
//           2,
//           2.25,
//         ]));
//   }
// }

class MicarnaLiveBirdHandlingAreaV2 extends LiveBirdHandlingArea {
  MicarnaLiveBirdHandlingAreaV2(ProductDefinition productDefinition)
      : super(
          lineName: 'Line1',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
    _row4();
    _row5();
    _row6();
    _row7();
  }

  void _row1() {
    put(ModuleCas(
      area: this,
      position: const Position(2, 1),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

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
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));
  }

  void _row2() {
    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(2, 2),
      seqNr: 6,
      defaultPositionWhenIdle: CardinalDirection.west,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 2),
      seqNr: 5,
      defaultPositionWhenIdle: CardinalDirection.west,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(4, 2),
      seqNr: 4,
      defaultPositionWhenIdle: CardinalDirection.west,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(5, 2),
      seqNr: 3,
      defaultPositionWhenIdle: CardinalDirection.north,
    ));
  }

  void _row3() {
    put(ModuleConveyor(
      area: this,
      position: const Position(2, 3),
      seqNr: 3,
      inFeedDirection: CardinalDirection.north,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 3),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 3),
      seqNr: 5,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleConveyor(
        area: this,
        position: const Position(5, 3),
        seqNr: 2,
        inFeedDirection: CardinalDirection.south));
  }

  void _row4() {
    put(ModuleDeStacker(
      area: this,
      position: const Position(2, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.north,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(4, 4),
      seqNr: 1,
      defaultPositionWhenIdle: CardinalDirection.north,
    ));

    put(ModuleRotatingConveyor(
        area: this,
        position: const Position(5, 4),
        seqNr: 2,
        defaultPositionWhenIdle: CardinalDirection.west,
        oppositeInFeeds: [CardinalDirection.west]));
  }

  void _row5() {
    put(ModuleConveyor(
        area: this,
        position: const Position(2, 5),
        seqNr: 4,
        inFeedDirection: CardinalDirection.north));

    put(ModuleConveyor(
        area: this,
        position: const Position(4, 5),
        seqNr: 1,
        inFeedDirection: CardinalDirection.south));
  }

  void _row6() {
    put(BirdHangingConveyor(
      area: this,
      position: const Position(1, 6),
      direction: CardinalDirection.north,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(2, 6),
      seqNr: 1,
      inFeedDirection: CardinalDirection.north,
      birdDirection: CardinalDirection.west,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(4, 6),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
      loadsSingeModule: false,
    ));
  }

  void _row7() {
    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(2, 7),
      inFeedDirection: CardinalDirection.north,
    ));

    put(ModuleCasAllocation(
      area: this,
      position: const Position(4, 7),
      positionToAllocate: const Position(5, 2),
    ));

    put(ModuleCasStart(
        area: this,
        position: const Position(6, 5),
        startIntervalFractions: <double>[
          0.5,
          0.5,
          0.6,
          0.6,
          0.7,
          0.7,
          0.8,
          0.8,
          0.9,
          0.9,
          1,
          1,
          1.40,
          1.80,
          2.20,
          2.40,
        ]));
  }
}
