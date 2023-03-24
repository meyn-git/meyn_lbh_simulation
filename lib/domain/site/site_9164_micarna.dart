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
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_lift_position.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
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
  
  static final maxBirdWeight=2.5.kilo.grams;
  static const summerLoadPercentage=90;
  static final  minLoadDensity=LoadDensity.eec64_432(maxBirdWeight, summerLoadPercentage);
  
  MicarnaProductDefinitions()
      : super([
          ProductDefinition(
              //13500 b/h
              areaFactory: _areaFactory(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 13500,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawer,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(minLoadDensity, maxBirdWeight),
                  secondModule: MeynGrandeDrawerChicken5Level()
                      .dimensions
                      .capacityWithDensity(minLoadDensity, maxBirdWeight),
                )
              ]),
       
          ProductDefinition(
              //15000 b/h
              areaFactory: _areaFactory(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 15000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawer,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(minLoadDensity, maxBirdWeight),
                  secondModule: MeynGrandeDrawerChicken5Level()
                      .dimensions
                      .capacityWithDensity(minLoadDensity, maxBirdWeight),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [MicarnaLiveBirdHandlingArea(productDefinition)];
}


class MicarnaLiveBirdHandlingArea extends LiveBirdHandlingArea {
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

  MicarnaLiveBirdHandlingArea(ProductDefinition productDefinition)
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
  put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(6, 1),
      inFeedDirection: CardinalDirection.south,
    ));


  }

  void _row2() {
  
     put(ModuleCas(
      area: this,
      position: const Position(1, 2),
      seqNr: 5,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(2, 2),
      seqNr: 3,
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

 put(ModuleTilter(
      area: this,
      position: const Position(6, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
      birdDirection: CardinalDirection.east,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    put(BirdHangingConveyor(
      area: this,
      position: const Position(7, 2),
      direction: CardinalDirection.north,
    ));

 
  }

  void _row3() {

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

    put(ModuleConveyor(
      area: this,
      position: const Position(4, 3),
      seqNr: 2,
      inFeedDirection: CardinalDirection.west,
    ));

   
    put(ModuleDeStacker(
      area: this,
      position: const Position(5, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(6, 3),
      seqNr: 4,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

  }

  void _row4() {
    put(ModuleConveyor(
      area: this,
      position: const Position(1, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(2, 4),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 4),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

  }


  void _row5() {
    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(1, 5),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
      loadsSingeModule: false,
    ));

    put(ModuleCasAllocation(
      area: this,
      position: const Position(4, 5),
      positionToAllocate: const Position(1, 4),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(5, 5),
    ));
  }
}
