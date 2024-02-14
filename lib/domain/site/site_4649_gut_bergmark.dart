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
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';

import 'site.dart';

class GutBergmarkSite extends Site {
  GutBergmarkSite()
      : super(
          meynLayoutNumber: 4649,
          organizationName: 'Gut Bergmark',
          city: '',
          country: 'Germany',
          productDefinitions: GutBergmarkProductDefinitions(),
        );
}

class GutBergmarkProductDefinitions extends DelegatingList<ProductDefinition> {
  static final maxBirdWeight = 2.8.kilo.grams;
  static const summerLoadPercentage = 90;
  static final minLoadDensity =
      LoadDensity.eec64_432(maxBirdWeight, summerLoadPercentage);

  GutBergmarkProductDefinitions()
      : super([
          ProductDefinition(
              //13500 b/h
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
          [GutBergmarkLiveBirdHandlingArea(productDefinition)];
}

class GutBergmarkLiveBirdHandlingArea extends LiveBirdHandlingArea {
  late ModuleDrawerUnloader drawerUnloader = ModuleDrawerUnloader(
    area: this,
    position: const Position(7, 3),
    seqNr: 1,
    inFeedDirection: CardinalDirection.west,
    drawersToLeft: true,
  );

  final drawerConveyorSpeedInMeterPerSecond = 0.7;

  GutBergmarkLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Line1',
          productDefinition: productDefinition,
        ) {
    _addMachines();
    _row2();
    _row3();
    _row4();
    _row5();
  }

  void _addMachines() {
    var drawerUnloaderLift = DrawerUnloaderLift(
      area: this,
      maxDrawersPerHour: 650,
    );
    machines.add(drawerUnloaderLift);
    machines.link(drawerUnloader.drawersOut, drawerUnloaderLift.drawersIn);

    var grossDrawerWeigher = DrawerWeighingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );
    machines.add(grossDrawerWeigher);
    machines.link(drawerUnloaderLift.drawerOut, grossDrawerWeigher.drawerIn);

    var conveyor1 = DrawerConveyor90Degrees(
        clockwise: false, metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    machines.add(conveyor1);
    machines.link(grossDrawerWeigher.drawerOut, conveyor1.drawerIn);

    var conveyor2 = DrawerConveyorStraight(
        lengthInMeters: 3,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    machines.add(conveyor2);
    machines.link(conveyor1.drawerOut, conveyor2.drawerIn);

    var hangingConveyor = DrawerHangingConveyor(
        hangers: 11, // TODO 11 hangers for 15000?
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    machines.add(hangingConveyor);
    machines.link(conveyor2.drawerOut, hangingConveyor.drawerIn);

    var conveyor3 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 1);
    machines.add(conveyor3);
    machines.link(hangingConveyor.drawerOut, conveyor3.drawerIn);

    var taraDrawerWeigher = DrawerWeighingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    machines.add(taraDrawerWeigher);
    machines.link(conveyor3.drawerOut, taraDrawerWeigher.drawerIn);

    var conveyor4 = DrawerTurningConveyor();
    machines.add(conveyor4);
    machines.link(taraDrawerWeigher.drawerOut, conveyor4.drawerIn);

    var soaker = DrawerSoakingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    machines.add(soaker);
    machines.link(conveyor4.drawerOut, soaker.drawerIn);

    var conveyor5 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 8);
    machines.add(conveyor5);
    machines.link(soaker.drawerOut, conveyor5.drawerIn);

    var washer = DrawerWashingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    machines.add(washer);
    machines.link(conveyor5.drawerOut, washer.drawerIn);

    var conveyor6 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 2.5);
    machines.add(conveyor6);
    machines.link(washer.drawerOut, conveyor6.drawerIn);

    var conveyor7 = DrawerTurningConveyor();
    machines.add(conveyor7);
    machines.link(conveyor6.drawerOut, conveyor7.drawerIn);

    var conveyor8 = DrawerConveyor90Degrees(
        clockwise: false, metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    machines.add(conveyor8);
    machines.link(conveyor7.drawerOut, conveyor8.drawerIn);

    var conveyor9 = DrawerConveyorStraight(
        lengthInMeters: 1.5,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    machines.add(conveyor9);
    machines.link(conveyor8.drawerOut, conveyor9.drawerIn);

    var drawerLoaderLift = DrawerLoaderLift(
      area: this,
      maxDrawersPerHour: 650,
    );
    machines.add(drawerLoaderLift);
    machines.link(conveyor9.drawerOut, drawerLoaderLift.drawerIn);
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

    put(BirdHangingConveyor(
      area: this,
      position: const Position(7, 2),
      direction: CardinalDirection.west,
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

    put(ModuleConveyor(
      area: this,
      position: const Position(6, 3),
      seqNr: 3,
      inFeedDirection: CardinalDirection.west,
    ));

    put(drawerUnloader);

    put(ModuleConveyor(
      area: this,
      position: const Position(8, 3),
      seqNr: 4,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(9, 3),
      seqNr: 5,
      inFeedDirection: CardinalDirection.west,
    ));

//washer
    put(ModuleConveyor(
      area: this,
      position: const Position(10, 3),
      seqNr: 6,
      inFeedDirection: CardinalDirection.west,
    ));

//reloader
    put(ModuleConveyor(
      area: this,
      position: const Position(11, 3),
      seqNr: 7,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleStacker(
      area: this,
      position: const Position(12, 3),
      seqNr: 1,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleConveyor(
      area: this,
      position: const Position(13, 3),
      seqNr: 8,
      inFeedDirection: CardinalDirection.west,
    ));

    put(UnLoadingForkLiftTruck(
      area: this,
      position: const Position(14, 3),
      inFeedDirection: CardinalDirection.west,
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
