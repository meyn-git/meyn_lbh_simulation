import 'package:meyn_lbh_simulation/domain/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/state_machine.dart';
import 'package:meyn_lbh_simulation/domain/unloading_fork_lift_truck.dart';

import 'bird_hanging_conveyor.dart';
import 'layout.dart';
import 'loading_fork_lift_truck.dart';
import 'module.dart';
import 'module_cas.dart';
import 'module_cas_allocation.dart';
import 'module_cas_start.dart';
import 'module_conveyor.dart';
import 'module_lift_position.dart';
import 'module_rotating_conveyor.dart';
import 'module_tilter.dart';

class FileniChickenLayout extends Layout {
  /// Fileni chicken: ModuleGroup = 4 and 5 compartment module
  /// Pollo Bio:                  26 birds/compartment @ 8000 birds/hour
  /// Pollo RUSTICANELLO Pesante: 33 birds/compartment @ 6000 birds/hour
  /// Pollo RUSTICANELLO :        52 birds/compartment @ 7000 birds/hour
  /// Pollo PICCOLO:              54 birds/compartment @ 10000 birds/hour

  static final birdsPerHour = 8000;
  static final birdsPerModule1 = 4 * 26;
  static final birdsPerModule2 = 5 * 26;
  static final casRecipe = CasRecipe.standardChickenRecipe();

  FileniChickenLayout() : super('7324-Fileni Castelplanio-Chicken-Italy') {
    _row1();
    _row2();
    _row3();
    _row4();
    _row5();
  }

  void _row1() {
    put(BirdHangingConveyor(
      layout: this,
      position: Position(3, 1),
      direction: CardinalDirection.east,
      shacklesPerHour: birdsPerHour,
    ));

    put(ModuleCas(
      layout: this,
      position: Position(5, 1),
      seqNr: 1,
      recipe: casRecipe,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      layout: this,
      position: Position(6, 1),
      seqNr: 3,
      recipe: casRecipe,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      layout: this,
      position: Position(7, 1),
      seqNr: 5,
      recipe: casRecipe,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.east,
    ));
  }

  void _row2() {
    put(UnLoadingForkLiftTruck(
      layout: this,
      position: Position(1, 2),
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleConveyor(
      layout: this,
      position: Position(2, 2),
      seqNr: 3,
      inFeedDirection: CardinalDirection.east,
    ));

    put(ModuleTilter(
      layout: this,
      position: Position(3, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.east,
      birdDirection: CardinalDirection.north,
      minBirdsOnDumpBeltBuffer: (birdsPerModule1 + birdsPerModule2 / 2).round(),
    ));


    /// mimicking a de-merging conveyor: 1 [ModuleGroup] => 2x [ModuleGroup] to tilter
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleDeStacker(
      layout: this,
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
    ));

    put(ModuleRotatingConveyor(
      layout: this,
      position: Position(5, 2),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      layout: this,
      position: Position(6, 2),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.north],
      oppositeOutFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      layout: this,
      position: Position(7, 2),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.north,
    ));
  }

  void _row3() {
    put(ModuleCas(
      layout: this,
      position: Position(5, 3),
      seqNr: 2,
      recipe: casRecipe,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    put(ModuleCas(
      layout: this,
      position: Position(6, 3),
      seqNr: 4,
      recipe: casRecipe,
      inAndOutFeedDirection: CardinalDirection.north,
      doorDirection: CardinalDirection.east,
    ));

    /// mimicking a merging conveyor: 2 x singe [ModuleGroup] from fork lift truck into 1
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    put(ModuleStacker(
      layout: this,
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
    ));
  }

  void _row4() {
    put(ModuleConveyor(
      layout: this,
      position: Position(7, 4),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));
  }

  void _row5() {
    put(LoadingForkLiftTruck(
        layout: this,
        position: Position(7, 5),
        outFeedDirection: CardinalDirection.north,
        createModuleGroup: () => ModuleGroup(
              type: ModuleType.square,
              destination:
                  this.cellForPosition(Position(7, 3)) as StateMachineCell,
              doorDirection: CardinalDirection.east.toCompassDirection(),
              position: ModulePosition.forCel(
                  this.cellForPosition(Position(7, 3)) as StateMachineCell),
              firstModule: Module(
                  sequenceNumber: ++moduleSequenceNumber,
                  nrOfBirds: birdsPerModule1),
              // secondModule: Module(
              //     sequenceNumber: ++moduleSequenceNumber,
              //     nrOfBirds: birdsPerModule2),
            )));

    put(ModuleCasAllocation(
      layout: this,
      position: Position(1, 5),
      positionToAllocate: Position(7, 3),
    ));

    put(ModuleCasStart(
      layout: this,
      position: Position(2, 5),
    ));
  }
}
