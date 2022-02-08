import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/site.dart';
import 'package:meyn_lbh_simulation/domain/unloading_fork_lift_truck.dart';

import 'bird_hanging_conveyor.dart';
import 'life_bird_handling_area.dart';
import 'loading_fork_lift_truck.dart';
import 'module.dart';
import 'module_cas.dart';
import 'module_cas_allocation.dart';
import 'module_cas_start.dart';
import 'module_conveyor.dart';
import 'module_lift_position.dart';
import 'module_rotating_conveyor.dart';
import 'module_tilter.dart';

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
          ProductDefinition(//2,82286 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo Bio',
              lineSpeedInShacklesPerHour: 8000,
              loadFactor: LoadFactor.average,
              moduleCombinations: [
                ModuleCombination(
                  firstModuleType: StorkSquare4LayerChickenModule(),
                  firstModuleNumberOfBirds: 4 * 26,
                  secondModuleType: AngliaAutoFlow5LayerChickenModule(),
                  secondModuleNumberOfBirds: 5 * 26,
                )
              ]),
          ProductDefinition(// 1,3 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo RUSTICANELLO Pesante',
              lineSpeedInShacklesPerHour: 6000,
              loadFactor: LoadFactor.average,
              moduleCombinations: [
                ModuleCombination(
                  firstModuleType: StorkSquare4LayerChickenModule(),
                  firstModuleNumberOfBirds: 4 * 33,
                  secondModuleType: AngliaAutoFlow5LayerChickenModule(),
                  secondModuleNumberOfBirds: 5 * 33,
                )
              ]),
          ProductDefinition(//0.6319997 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Pollo RUSTICANELLO',
              lineSpeedInShacklesPerHour: 7000,
              loadFactor: LoadFactor.average,
              moduleCombinations: [
                ModuleCombination(
                  firstModuleType: StorkSquare4LayerChickenModule(),
                  firstModuleNumberOfBirds: 4 * 52,
                  secondModuleType: AngliaAutoFlow5LayerChickenModule(),
                  secondModuleNumberOfBirds: 5 * 52,
                )
              ]),
          ProductDefinition(//0,8379
              areaFactory: _areaFactory(),
              birdType: 'Pollo PICCOLO',
              lineSpeedInShacklesPerHour: 10000,
              loadFactor: LoadFactor.average,
              moduleCombinations: [
                ModuleCombination(
                  firstModuleType: StorkSquare4LayerChickenModule(),
                  firstModuleNumberOfBirds: 4 * 54,
                  secondModuleType: AngliaAutoFlow5LayerChickenModule(),
                  secondModuleNumberOfBirds: 5 * 54,
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [FileniLiveBirdHandlingArea(productDefinition)];
}

class FileniLiveBirdHandlingArea extends LiveBirdHandlingArea {

  static final conveyorTransportDuration = //TODO move to ModuleType
      Duration(milliseconds: 13400); // Based on measurements @ Dabe
  static final turnTableDegreesPerSecond = //TODO move to ModuleType
      10; //Based on measurements @ Dabe
  static final casTransportDuration = //TODO move to ModuleType
      Duration(milliseconds: 18700); // Based on measurements @ Dabe

  FileniLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Chicken Line',
          productDefinition: productDefinition,
          casRecipe: CasRecipe.standardChickenRecipe(),
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
      position: Position(3, 1),
      direction: CardinalDirection.east,
    ));

    put(ModuleCas(
      area: this,
      position: Position(5, 1),
      seqNr: 1,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
      inFeedDuration: casTransportDuration,
      outFeedDuration: casTransportDuration,
    ));

    put(ModuleCas(
      area: this,
      position: Position(6, 1),
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
      inFeedDuration: casTransportDuration,
      outFeedDuration: casTransportDuration,
    ));

    put(ModuleCas(
      area: this,
      position: Position(7, 1),
      seqNr: 5,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
      inFeedDuration: casTransportDuration,
      outFeedDuration: casTransportDuration,
    ));
  }

  void _row2() {
    put(UnLoadingForkLiftTruck(
      area: this,
      position: Position(1, 2),
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleConveyor(
      area: this,
      position: Position(2, 2),
      seqNr: 3,
      inFeedDirection: CardinalDirection.east,
      inFeedDuration: conveyorTransportDuration,
      outFeedDuration: conveyorTransportDuration,
    ));

    put(ModuleTilter(
      area: this,
      position: Position(3, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.east,
      birdDirection: CardinalDirection.north,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
      inFeedDuration: conveyorTransportDuration,
      outFeedDuration: conveyorTransportDuration,
    ));

    /// mimicking a de-merging conveyor: 1 [ModuleGroup] => 2x [ModuleGroup] to tilter
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleDeStacker(
      area: this,
      position: Position(4, 2),
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
      inFeedDuration: conveyorTransportDuration,
      outFeedDuration: conveyorTransportDuration,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: Position(5, 2),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.west,
      inFeedDuration: conveyorTransportDuration,
      outFeedDuration: conveyorTransportDuration,
      degreesPerSecond: turnTableDegreesPerSecond,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: Position(6, 2),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.west,
      inFeedDuration: conveyorTransportDuration,
      outFeedDuration: conveyorTransportDuration,
      degreesPerSecond: turnTableDegreesPerSecond,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: Position(7, 2),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.north,
      inFeedDuration: conveyorTransportDuration,
      outFeedDuration: conveyorTransportDuration,
      degreesPerSecond: turnTableDegreesPerSecond,
    ));
  }

  void _row3() {
    put(ModuleCas(
      area: this,
      position: Position(5, 3),
      seqNr: 2,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
      inFeedDuration: casTransportDuration,
      outFeedDuration: casTransportDuration,
    ));

    put(ModuleCas(
      area: this,
      position: Position(6, 3),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
      inFeedDuration: casTransportDuration,
      outFeedDuration: casTransportDuration,
    ));

    /// mimicking a merging conveyor: 2 x singe [ModuleGroup] from fork lift truck into 1
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleStacker(
      area: this,
      position: Position(7, 3),
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
      inFeedDuration: conveyorTransportDuration,
      outFeedDuration: conveyorTransportDuration,
    ));
  }

  void _row4() {
    put(ModuleConveyor(
      area: this,
      position: Position(7, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
      inFeedDuration: conveyorTransportDuration,
      outFeedDuration: conveyorTransportDuration,
    ));
  }

  void _row5() {
    put(LoadingForkLiftTruck(
      area: this,
      position: Position(7, 5),
      outFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
      loadsSingeModule: true,
    ));

    put(ModuleCasAllocation(
      area: this,
      position: Position(1, 5),
      positionToAllocate: Position(7, 3),
    ));

    put(ModuleCasStart(
      area: this,
      position: Position(2, 5),
    ));
  }
}
