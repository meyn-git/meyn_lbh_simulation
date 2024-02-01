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
import 'package:meyn_lbh_simulation/domain/area/module_lift_position.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class TaravisSite extends Site {
  TaravisSite()
      : super(
          meynLayoutNumber: 4054,
          organizationName: 'Taravis',
          city: 'Sárvár',
          country: 'Hungary',
          productDefinitions: ProductDefinitions(),
        );
}

final averageNormalBirdWeight = grams(2500);
final averageHeavyBirdWeight = grams(4250);

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: '2,5kg in winter @160cm2/kg',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawer,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.eec64_432(averageNormalBirdWeight, 100),
                          averageNormalBirdWeight),
                  secondModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.eec64_432(averageNormalBirdWeight, 100),
                          averageNormalBirdWeight),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: '2,5kg in summer @177,8cm2/kg',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawer,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.eec64_432(averageNormalBirdWeight, 90),
                          averageNormalBirdWeight),
                  secondModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.eec64_432(averageNormalBirdWeight, 90),
                          averageNormalBirdWeight),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: '4,25kg in winter @160cm2/kg',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawer,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.floorSpaceInCm2(
                              minCm2FloorSpacePerKgLiveWeight: 160,
                              loadingPercentage: 100),
                          averageHeavyBirdWeight),
                  secondModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.floorSpaceInCm2(
                              minCm2FloorSpacePerKgLiveWeight: 160,
                              loadingPercentage: 100),
                          averageHeavyBirdWeight),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: '4,25kg in summer @177,8cm2/kg',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawer,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.floorSpaceInCm2(
                              minCm2FloorSpacePerKgLiveWeight: 160,
                              loadingPercentage: 90),
                          averageHeavyBirdWeight),
                  secondModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.floorSpaceInCm2(
                              minCm2FloorSpacePerKgLiveWeight: 160,
                              loadingPercentage: 90),
                          averageHeavyBirdWeight),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: '4,25kg in winter @115cm2/kg',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawer,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.eec64_432(averageHeavyBirdWeight, 100),
                          averageHeavyBirdWeight),
                  secondModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.eec64_432(averageHeavyBirdWeight, 100),
                          averageHeavyBirdWeight),
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: '4,25kg in summer @127,8cm2/kg',
              lineSpeedInShacklesPerHour: 8000,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawer,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.eec64_432(averageHeavyBirdWeight, 90),
                          averageHeavyBirdWeight),
                  secondModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          LoadDensity.eec64_432(averageHeavyBirdWeight, 90),
                          averageHeavyBirdWeight),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [TaravisLiveBirdHandlingArea(productDefinition)];
}

class TaravisLiveBirdHandlingArea extends LiveBirdHandlingArea {
  TaravisLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Chicken line',
          productDefinition: productDefinition,
        ) {
    _row1();
    _row2();
    _row3();
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
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(7, 1),
      seqNr: 3,
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

    put(ModuleConveyor(
      area: this,
      position: const Position(8, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.east,
    ));

    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(9, 2),
      outFeedDirection: CardinalDirection.west,
      doorDirection: CardinalDirection.north,
    ));
  }

  void _row3() {
    put(ModuleCasStart(
      area: this,
      position: const Position(6, 3),
    ));

    put(ModuleCasAllocation(
      area: this,
      position: const Position(8, 3),
      positionToAllocate: const Position(8, 2),
    ));
  }
}
