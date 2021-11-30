import 'package:meyn_lbh_simulation/domain/layout.dart';
import 'package:meyn_lbh_simulation/domain/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/state_machine.dart';
import 'package:meyn_lbh_simulation/domain/unloading_fork_lift_truck.dart';

import 'bird_hanging_conveyor.dart';
import 'loading_fork_lift_truck.dart';
import 'module.dart';
import 'module_cas.dart';
import 'module_cas_allocation.dart';
import 'module_cas_start.dart';
import 'module_conveyor.dart';
import 'module_rotating_conveyor.dart';
import 'module_tilter.dart';

class IndrolLayout extends Layout {
  /// Modules:
  /// - 1 CAS batch = 2 stacked modules
  /// - 1 module = 3 levels
  /// - 1 level = max 300 kg
  ///
  ///  Female turkeys:
  ///  - line speed: 3600 birds/hour
  ///  - live weight: min:8.500g, avr:10.000g, max 11.500g
  ///  - min birds: 300/11.5kg= 26 birds/level x 3 levels= 78 birds per module
  ///  - max birds: 300/8.5kg= 35 birds/level x 3 levels= 105 birds per module
  ///
  ///  Male turkeys:
  ///  - line speed: 1800 birds/hour
  ///  - live weight: min:18.000g, avr:20.000g, max 23.000g
  ///  - min birds: 300/23kg= 13 birds/level x 3 levels= 39 birds per module
  ///  - max birds: 300/18kg= 16 birds/level x 3 levels= 48 birds per module

  static final birdsPerHour=1800;
  static final birdsPerModule=3*15;
  static final casRecipe=CasRecipe.standardTurkeyRecipe();

  IndrolLayout() : super('8052-Indrol-Grodzisk-Poland') {
    _row1();
    _row2();
    _row3();
    _row4();
  }

  void _row1() {
    put(ModuleCas(
      layout: this,
      position: Position(2, 1),
      seqNr: 2,
      recipe: casRecipe,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(ModuleCas(
      layout: this,
      position: Position(3, 1),
      seqNr: 1,
      recipe: casRecipe,
      inAndOutFeedDirection: CardinalDirection.south,
      doorDirection: CardinalDirection.west,
    ));

    put(BirdHangingConveyor(
        layout: this,
        position: Position(6, 1),
        direction: CardinalDirection.west,
        shacklesPerHour: birdsPerHour));
  }

  void _row2() {
    put(ModuleRotatingConveyor(
      layout: this,
      position: Position(1, 2),
      seqNr: 1,
      oppositeInFeeds: [CardinalDirection.south],
      defaultPositionWhenIdle: CardinalDirection.south,
    ));

    put(ModuleRotatingConveyor(
      layout: this,
      position: Position(2, 2),
      seqNr: 2,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleRotatingConveyor(
      layout: this,
      position: Position(3, 2),
      seqNr: 3,
      oppositeInFeeds: [CardinalDirection.north],
      defaultPositionWhenIdle: CardinalDirection.east,
    ));

    put(ModuleDeStacker(
      layout: this,
      position: Position(4, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    //Gross weighing conveyor
    put(ModuleConveyor(
      layout: this,
      position: Position(5, 2),
      seqNr: 3,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleTilter(
      layout: this,
      position: Position(6, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
      birdDirection: CardinalDirection.north,
      minBirdsOnDumpBeltBuffer: 2 * birdsPerModule,
    ));


    //Tare weighing conveyor
    put(ModuleConveyor(
      layout: this,
      position: Position(7, 2),
      seqNr: 4,
      inFeedDirection: CardinalDirection.west,
    ));

    // Module conveyor
    put(ModuleConveyor(
      layout: this,
      position: Position(8, 2),
      seqNr: 5,
      inFeedDirection: CardinalDirection.west,
    ));

    // High pressure pre-washer
    put(ModuleConveyor(
      layout: this,
      position: Position(9, 2),
      seqNr: 6,
      inFeedDirection: CardinalDirection.west,
    ));

    //  Module conveyor
    put(ModuleConveyor(
      layout: this,
      position: Position(10, 2),
      seqNr: 7,
      inFeedDirection: CardinalDirection.west,
    ));

    // Active module washer
    put(ModuleConveyor(
      layout: this,
      position: Position(11, 2),
      seqNr: 8,
      inFeedDirection: CardinalDirection.west,
    ));

    // Disinfection unit
    put(ModuleConveyor(
      layout: this,
      position: Position(12, 2),
      seqNr: 9,
      inFeedDirection: CardinalDirection.west,
    ));

    //  Module conveyor
    put(ModuleConveyor(
      layout: this,
      position: Position(13, 2),
      seqNr: 10,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleStacker(
      layout: this,
      position: Position(14, 2),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      layout: this,
      position: Position(15, 2),
      seqNr: 4,
      defaultPositionWhenIdle: CardinalDirection.east,
    ));
  }

  void _row3() {
    put(ModuleConveyor(
      layout: this,
      position: Position(1, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.south,
    ));

    put(ModuleConveyor(
      layout: this,
      position: Position(15, 3),
      seqNr: 20,
      inFeedDirection: CardinalDirection.north,
    ));
  }

  void _row4() {
    put(LoadingForkLiftTruck(
        layout: this,
        position: Position(1, 4),
        outFeedDirection: CardinalDirection.north,
        createModuleGroup: () => ModuleGroup(
              type: ModuleType.rectangular,
              destination:
                  this.cellForPosition(Position(1, 2)) as StateMachineCell,
              doorDirection: CardinalDirection.east.toCompassDirection(),
              position: ModulePosition.forCel(
                  this.cellForPosition(Position(1, 3)) as StateMachineCell),
              firstModule: Module(
                  sequenceNumber: ++moduleSequenceNumber, nrOfBirds: birdsPerModule),
              secondModule: Module(
                  sequenceNumber: ++moduleSequenceNumber, nrOfBirds: birdsPerModule),
            )));

    put(ModuleCasAllocation(
      layout: this,
      position: Position(8, 4),
      positionToAllocate: Position(1, 2),
    ));

    put(ModuleCasStart(
      layout: this,
      position: Position(9, 4),
    ));

    put(UnLoadingForkLiftTruck(
      layout: this,
      position: Position(15, 4),
      inFeedDirection: CardinalDirection.north,
    ));
  }
}
