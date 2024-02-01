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
import 'package:meyn_lbh_simulation/domain/area/module_lift_position.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class DabeSite extends Site {
  DabeSite()
      : super(
          meynLayoutNumber: 7696,
          organizationName: 'Dabe',
          city: 'Beihen',
          country: 'Germany',
          productDefinitions: DabeProductDefinitions(),
        );
}

const dabeCasRecipe = CasRecipe([
  Duration(seconds: 40), //22%, Stage 1
  Duration(seconds: 40), //36%, Stage 2
  Duration(seconds: 40), //43%, Stage 3
  Duration(seconds: 165), //67%, Stage 4
  Duration(seconds: 0), //00%, Stage 5
], Duration(seconds: 10));

/// Dabe:                       ModuleGroup = 2x 6 compartment module
/// Turkey:                     6 birds/compartment @ 3600 birds/hour
class DabeProductDefinitions extends DelegatingList<ProductDefinition> {
  DabeProductDefinitions()
      : super([
          ProductDefinition(
              //83 containers per hour
              areaFactory: _areaFactory(),
              birdType: 'Turkey',
              lineSpeedInShacklesPerHour: 3600,
              casRecipe: dabeCasRecipe,
              moduleSystem: ModuleSystem.meynVdlSquareContainers,
              moduleFamily: ModuleFamily.marelGpSquare,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MarelGpSquareModule6LevelTurkey()
                      .dimensions
                      .capacityWithBirdsPerCompartment(6),
                  secondModule: MarelGpSquareModule6LevelTurkey()
                      .dimensions
                      .capacityWithBirdsPerCompartment(6),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [DabeLiveBirdHandlingArea(productDefinition)];
}

class DabeLiveBirdHandlingArea extends LiveBirdHandlingArea {
  DabeLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Turkey line',
          productDefinition: productDefinition,
        ) {
    _row1(); // Cas 1, Cas 3, Cas 5
    _row2(); // TT 3, TT 2, TT 1, Infeed, Fork lift
    _row3(); // Buffer (Destacker), Cas 4, Cas 6, Cas Allocation
    _row4(); // Hanging, Tilter, Cas Start
    _row5(); // Outfeed
    _row6(); // Fork lift
  }

  void _row1() {
    // Cas 1, Cas 3, Cas 5
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
      seqNr: 3,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 1),
      seqNr: 5,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));
  }

  void _row2() {
    // TT 3, TT 2, TT 1, Infeed, Fork lift
    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(2, 2),
      seqNr: 10,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(3, 2),
      seqNr: 9,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      area: this,
      position: const Position(4, 2),
      seqNr: 8,
      oppositeInFeeds: [CardinalDirection.south],
      oppositeOutFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(5, 2),
      seqNr: 7,
      inFeedDirection: CardinalDirection.east,
    ));

    put(LoadingForkLiftTruck(
      area: this,
      position: const Position(6, 2),
      outFeedDirection: CardinalDirection.west,
      doorDirection: CardinalDirection.north,
      loadsSingeModule: false,
    ));
  }

  void _row3() {
    // Buffer (Destacker), Cas 4, Cas 6, Cas Allocation
    /// mimicking a de-merging conveyor: 1 [ModuleGroup] => 2x [ModuleGroup] to tilter
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleDeStacker(
      area: this,
      position: const Position(2, 3),
      seqNr: 11,
      inFeedDirection: CardinalDirection.north,
      heightsInCentiMeter: const {
        LiftPosition.inFeed: 0,
        LiftPosition.outFeed: 0,
        LiftPosition.pickUpTopModule: 0,
        LiftPosition.supportTopModule: 0,
      },
      supportsCloseDuration: Duration.zero,
      supportsOpenDuration: Duration.zero,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(3, 3),
      seqNr: 4,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      area: this,
      position: const Position(4, 3),
      seqNr: 6,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCasAllocation(
      area: this,
      position: const Position(5, 3),
      positionToAllocate: const Position(5, 2),
    ));
  }

  void _row4() {
    // Hanging, Tilter, Cas Start
    put(BirdHangingConveyor(
      area: this,
      position: const Position(1, 4),
      direction: CardinalDirection.south,
    ));

    put(ModuleTilter(
      area: this,
      position: const Position(2, 4),
      seqNr: 12,
      inFeedDirection: CardinalDirection.north,
      birdDirection: CardinalDirection.west,
      minBirdsOnDumpBeltBuffer:
          productDefinition.averageProductsPerModuleGroup.round(),
    ));

    put(ModuleCasStart(
      area: this,
      position: const Position(5, 4),
    ));
  }

  void _row5() {
    // Outfeed
    put(ModuleConveyor(
      area: this,
      position: const Position(2, 5),
      seqNr: 13,
      inFeedDirection: CardinalDirection.north,
    ));
  }

  void _row6() {
    // Fork lift
    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(2, 6),
      inFeedDirection: CardinalDirection.north,
    ));
  }
}
