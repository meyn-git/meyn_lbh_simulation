import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_row_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter_dump_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class SystemTestSite extends Site {
  SystemTestSite()
      : super(
          meynLayoutNumber: 0000,
          organizationName: 'MachineTest',
          city: 'Assendelft',
          country: 'Nederland',
          productDefinitions: SystemProductDefinitions(),
        );
}

class SystemProductDefinitions extends DelegatingList<ProductDefinition> {
  static final maxBirdWeight = 2.9.kilo.grams;
  static const summerLoadPercentage = 90;
  static final loadDensityHeaviestFlock =
      LoadDensity.eec64_432(maxBirdWeight, summerLoadPercentage);

  SystemProductDefinitions()
      : super([
          ProductDefinition(
              //13500 b/h
              areaFactory: _grandeRowUnloaderAreaFactory(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 15000,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawerDoubleColumn,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          loadDensityHeaviestFlock, maxBirdWeight),
                  secondModule: MeynGrandeDrawerChicken5Level()
                      .dimensions
                      .capacityWithDensity(
                          loadDensityHeaviestFlock, maxBirdWeight),
                )
              ]),
          ProductDefinition(
              //13500 b/h
              areaFactory: _grandeColumnUnloaderAreaFactory(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 15000,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawerDoubleColumn,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynGrandeDrawerChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          loadDensityHeaviestFlock, maxBirdWeight),
                  secondModule: MeynGrandeDrawerChicken5Level()
                      .dimensions
                      .capacityWithDensity(
                          loadDensityHeaviestFlock, maxBirdWeight),
                )
              ]),
          ProductDefinition(
              //13500 b/h
              areaFactory: _evoAreaFactory(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 15000,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlRectangularContainers,
              moduleFamily: ModuleFamily.meynEvo,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: MeynEvoChicken4Level()
                      .dimensions
                      .capacityWithDensity(
                          loadDensityHeaviestFlock, maxBirdWeight),
                  secondModule: MeynEvoChicken5Level()
                      .dimensions
                      .capacityWithDensity(
                          loadDensityHeaviestFlock, maxBirdWeight),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _evoAreaFactory() =>
          (ProductDefinition productDefinition) => [EvoArea(productDefinition)];
  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _grandeColumnUnloaderAreaFactory() =>
          (ProductDefinition productDefinition) =>
              [GrandeColumnUnloaderArea(productDefinition)];
  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _grandeRowUnloaderAreaFactory() =>
          (ProductDefinition productDefinition) =>
              [GrandeRowUnloaderArea(productDefinition)];
}

class GrandeRowUnloaderArea extends LiveBirdHandlingArea {
  final drawerConveyorSpeedInMeterPerSecond = 0.7;

  GrandeRowUnloaderArea(ProductDefinition productDefinition)
      : super(
          lineName: 'GrandeRowUnloader',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
      loadsSingleModule: true,
    );

    var moduleLoadingConveyor = ModuleConveyor(area: this);

    var moduleConveyor2 = ModuleConveyor(area: this, lengthInMeters: 5);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 2.75,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(direction: const CompassDirection(45))
      ],
    );
    // systems.add(mrc1);

    var mcr2Mcr1 = TurnPosition(direction: const CompassDirection.south());
    var mrc2 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
      // defaultFeedInTurnPosition: mcr2Mcr1,
      turnPositions: [
        mcr2Mcr1,
        TurnPosition(
            direction: const CompassDirection(-45), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection(45))
      ],
    );
    // systems.add(mrc2);

    var cas1 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: true,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
            direction: const CompassDirection(270), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection(0))
      ],
    );

    var cas2 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: true,
    );

    // var casStart = ModuleCasStart(area: this);
    // systems.add(casStart);

    // var casAllocation = ModuleCasAllocation(
    //     area: this, systemPositionToAllocate: mrc1.moduleGroupPosition);
    // systems.add(casAllocation);

    var deStacker = ModuleDeStacker(area: this);

    var moduleConveyor3 = ModuleConveyor(area: this);

    var unloader = ModuleDrawerRowUnloader(area: this, drawersToLeft: true);

    var receiver = ModuleDrawerRowUnloaderReceiver(
        area: this,
        drawersToLeft: true,
        crossOverFeedOutMetersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    systems.link(unloader.drawersOut, receiver.drawersIn);

    var conveyor0 = DrawerConveyor90Degrees(
      clockwise: true,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );
    systems.link(receiver.drawerOut, conveyor0.drawerIn);

    var conveyor1 = DrawerConveyor90Degrees(
        clockwise: false, metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor0.drawerOut, conveyor1.drawerIn);

    var conveyor2 = DrawerConveyorStraight(
        lengthInMeters: 3,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor1.drawerOut, conveyor2.drawerIn);

    var hangingConveyor = DrawerHangingConveyor(
        productDefinition: productDefinition,
        hangers: 11, // TODO 11 hangers for 15000?
        metersPerSecondOfFirstConveyor: drawerConveyorSpeedInMeterPerSecond,
        allDrawers: drawers);
    systems.link(conveyor2.drawerOut, hangingConveyor.drawerIn);

    var conveyor3 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 1);
    systems.link(hangingConveyor.drawerOut, conveyor3.drawerIn);

    var taraDrawerWeigher = DrawerWeighingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor3.drawerOut, taraDrawerWeigher.drawerIn);

    var conveyor4 = DrawerTurningConveyor();
    systems.link(taraDrawerWeigher.drawerOut, conveyor4.drawerIn);

    var soaker = DrawerSoakingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor4.drawerOut, soaker.drawerIn);

    var conveyor5 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 9.5);
    systems.link(soaker.drawerOut, conveyor5.drawerIn);

    var washer = DrawerWashingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor5.drawerOut, washer.drawerIn);

    var conveyor6 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 7);
    systems.link(washer.drawerOut, conveyor6.drawerIn);

    var conveyor7 = DrawerTurningConveyor();
    systems.link(conveyor6.drawerOut, conveyor7.drawerIn);

    var conveyor8 = DrawerConveyor90Degrees(
        clockwise: false, metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor7.drawerOut, conveyor8.drawerIn);

    var conveyor9 = DrawerConveyorStraight(
        lengthInMeters: 3.1,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor8.drawerOut, conveyor9.drawerIn);

    var drawerLoaderLift = DrawerLoaderLift(
      area: this,
    );
    systems.link(conveyor9.drawerOut, drawerLoaderLift.drawerIn);

    var moduleDrawerLoader =
        ModuleDrawerLoader(area: this, drawersFromLeft: true);
    systems.link(drawerLoaderLift.drawersOut, moduleDrawerLoader.drawersIn);

    var moduleConveyor4 = ModuleConveyor(area: this, lengthInMeters: 3.9);

    var moduleWasher = ModuleConveyor(area: this, lengthInMeters: 6);

    var stacker = ModuleStacker(area: this);

    var moduleUnLoadingConveyor = ModuleConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(
        loadingForkLiftTruck.modulesOut, moduleLoadingConveyor.modulesIn);
    // systems.link(moduleConveyor1.modulesOut, moduleConveyor2.modulesIn);
    // systems.link(moduleConveyor2.modulesOut, mrc1.modulesInLinks[0]);
    // systems.link(mrc1.modulesOutLinks[1], mrc2.modulesInLinks[0]);
    // systems.link(mrc2.modulesOutLinks[1], cas1.modulesInLink);
    // systems.link(cas1.modulesOutLink, mrc2.modulesInLinks[1]);
    // systems.link(mrc2.modulesOutLinks[2], mrc3.modulesInLinks[0]);
    // systems.link(mrc3.modulesOutLinks[1], cas2.modulesInLink);
    // systems.link(cas2.modulesOutLink, mrc3.modulesInLinks[1]);
    // systems.link(mrc3.modulesOutLinks[2], deStacker.modulesIn);
    //systems.link(moduleLoadingConveyor.modulesOut, deStacker.modulesIn);
    //systems.link(deStacker.modulesOut, moduleConveyor3.modulesIn);
    //systems.link(moduleConveyor3.modulesOut, drawerUnloader.modulesIn);
    systems.link(moduleLoadingConveyor.modulesOut, unloader.modulesIn);
    systems.link(unloader.modulesOut, moduleConveyor4.modulesIn);
    systems.link(moduleConveyor4.modulesOut, moduleWasher.modulesIn);
    systems.link(moduleWasher.modulesOut, stacker.modulesIn);
    systems.link(moduleWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, moduleUnLoadingConveyor.modulesIn);
    systems.link(
        moduleUnLoadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// Drawers
    systems.link(unloader.drawersOut, receiver.drawersIn);
    systems.link(receiver.drawerOut, conveyor0.drawerIn);
    systems.link(conveyor0.drawerOut, conveyor1.drawerIn);
    systems.link(conveyor1.drawerOut, conveyor2.drawerIn);
    systems.link(conveyor2.drawerOut, hangingConveyor.drawerIn);
    systems.link(hangingConveyor.drawerOut, conveyor3.drawerIn);
    systems.link(conveyor3.drawerOut, taraDrawerWeigher.drawerIn);
    systems.link(taraDrawerWeigher.drawerOut, conveyor4.drawerIn);
    systems.link(conveyor4.drawerOut, soaker.drawerIn);
    systems.link(soaker.drawerOut, conveyor5.drawerIn);
    systems.link(conveyor5.drawerOut, washer.drawerIn);
    systems.link(washer.drawerOut, conveyor6.drawerIn);
    systems.link(conveyor6.drawerOut, conveyor7.drawerIn);
    systems.link(conveyor7.drawerOut, conveyor8.drawerIn);
    systems.link(conveyor8.drawerOut, conveyor9.drawerIn);
    systems.link(conveyor9.drawerOut, drawerLoaderLift.drawerIn);
    systems.link(drawerLoaderLift.drawersOut, moduleDrawerLoader.drawersIn);

    markers.add(Marker(unloader, unloader.shape.centerToConveyorCenter));

    markers.add(Marker(unloader, unloader.shape.centerToDrawersOutLink));
    markers.add(
        Marker(unloader, unloader.shape.centerToLiftConveyorDrawerCenters[0]));
    markers.add(
        Marker(unloader, unloader.shape.centerToLiftConveyorDrawerCenters[1]));
    markers.add(Marker(
        receiver, receiver.shape.centerToReceivingConveyorDrawerCenters[0]));
    markers.add(Marker(
        receiver, receiver.shape.centerToReceivingConveyorDrawerCenters[1]));
    markers.add(Marker(
        receiver, receiver.shape.centerToCrossOverConveyorDrawerCenters[0]));
    markers.add(Marker(
        receiver, receiver.shape.centerToCrossOverConveyorDrawerCenters[1]));
    markers
        .add(Marker(receiver, receiver.shape.centerToFeedOutConveyorOutLink));
  }
}

class GrandeColumnUnloaderArea extends LiveBirdHandlingArea {
  final drawerConveyorSpeedInMeterPerSecond = 0.7;

  GrandeColumnUnloaderArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Line1',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var moduleLoadingConveyor = ModuleConveyor(area: this);

    var moduleConveyor2 = ModuleConveyor(area: this, lengthInMeters: 5);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 2.75,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(direction: const CompassDirection(45))
      ],
    );
    // systems.add(mrc1);

    var mcr2Mcr1 = TurnPosition(direction: const CompassDirection.south());
    var mrc2 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
      // defaultFeedInTurnPosition: mcr2Mcr1,
      turnPositions: [
        mcr2Mcr1,
        TurnPosition(
            direction: const CompassDirection(-45), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection(45))
      ],
    );
    // systems.add(mrc2);

    var cas1 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: true,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
            direction: const CompassDirection(270), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection(0))
      ],
    );

    var cas2 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: true,
    );

    // var casStart = ModuleCasStart(area: this);
    // systems.add(casStart);

    // var casAllocation = ModuleCasAllocation(
    //     area: this, systemPositionToAllocate: mrc1.moduleGroupPosition);
    // systems.add(casAllocation);

    var deStacker = ModuleDeStacker(area: this);

    var moduleConveyor3 = ModuleConveyor(area: this);

    var drawerUnloader =
        ModuleDrawerColumnUnloader(area: this, drawersToLeft: true);

    var drawerUnloaderLift = DrawerUnloaderLift(area: this);

    systems.link(drawerUnloader.drawersOut, drawerUnloaderLift.drawersIn);

    var grossDrawerWeigher = DrawerWeighingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );
    systems.link(drawerUnloaderLift.drawerOut, grossDrawerWeigher.drawerIn);

    var conveyor1 = DrawerConveyor90Degrees(
        clockwise: false, metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(grossDrawerWeigher.drawerOut, conveyor1.drawerIn);

    var conveyor2 = DrawerConveyorStraight(
        lengthInMeters: 3,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor1.drawerOut, conveyor2.drawerIn);

    var hangingConveyor = DrawerHangingConveyor(
        productDefinition: productDefinition,
        hangers: 11, // TODO 11 hangers for 15000?
        metersPerSecondOfFirstConveyor: drawerConveyorSpeedInMeterPerSecond,
        allDrawers: drawers);
    systems.link(conveyor2.drawerOut, hangingConveyor.drawerIn);

    var conveyor3 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 1);
    systems.link(hangingConveyor.drawerOut, conveyor3.drawerIn);

    var taraDrawerWeigher = DrawerWeighingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor3.drawerOut, taraDrawerWeigher.drawerIn);

    var conveyor4 = DrawerTurningConveyor();
    systems.link(taraDrawerWeigher.drawerOut, conveyor4.drawerIn);

    var soaker = DrawerSoakingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor4.drawerOut, soaker.drawerIn);

    var conveyor5 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 9.5);
    systems.link(soaker.drawerOut, conveyor5.drawerIn);

    var washer = DrawerWashingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor5.drawerOut, washer.drawerIn);

    var conveyor6 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 2.5);
    systems.link(washer.drawerOut, conveyor6.drawerIn);

    var conveyor7 = DrawerTurningConveyor();
    systems.link(conveyor6.drawerOut, conveyor7.drawerIn);

    var conveyor8 = DrawerConveyor90Degrees(
        clockwise: false, metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor7.drawerOut, conveyor8.drawerIn);

    var conveyor9 = DrawerConveyorStraight(
        lengthInMeters: 1.4,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);
    systems.link(conveyor8.drawerOut, conveyor9.drawerIn);

    var drawerLoaderLift = DrawerLoaderLift(
      area: this,
    );
    systems.link(conveyor9.drawerOut, drawerLoaderLift.drawerIn);

    var moduleDrawerLoader =
        ModuleDrawerLoader(area: this, drawersFromLeft: true);
    systems.link(drawerLoaderLift.drawersOut, moduleDrawerLoader.drawersIn);

    var moduleConveyor4 = ModuleConveyor(area: this, lengthInMeters: 3.9);

    var moduleWasher = ModuleConveyor(area: this, lengthInMeters: 6);

    var stacker = ModuleStacker(area: this);

    var moduleUnLoadingConveyor = ModuleConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(
        loadingForkLiftTruck.modulesOut, moduleLoadingConveyor.modulesIn);
    // systems.link(moduleConveyor1.modulesOut, moduleConveyor2.modulesIn);
    // systems.link(moduleConveyor2.modulesOut, mrc1.modulesInLinks[0]);
    // systems.link(mrc1.modulesOutLinks[1], mrc2.modulesInLinks[0]);
    // systems.link(mrc2.modulesOutLinks[1], cas1.modulesInLink);
    // systems.link(cas1.modulesOutLink, mrc2.modulesInLinks[1]);
    // systems.link(mrc2.modulesOutLinks[2], mrc3.modulesInLinks[0]);
    // systems.link(mrc3.modulesOutLinks[1], cas2.modulesInLink);
    // systems.link(cas2.modulesOutLink, mrc3.modulesInLinks[1]);
    // systems.link(mrc3.modulesOutLinks[2], deStacker.modulesIn);
    systems.link(moduleLoadingConveyor.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, moduleConveyor3.modulesIn);
    systems.link(moduleConveyor3.modulesOut, drawerUnloader.modulesIn);
    systems.link(drawerUnloader.drawersOut, drawerUnloaderLift.drawersIn);

    /// Drawers
    systems.link(drawerUnloader.drawersOut, drawerUnloaderLift.drawersIn);
    systems.link(drawerUnloaderLift.drawerOut, grossDrawerWeigher.drawerIn);
    systems.link(grossDrawerWeigher.drawerOut, conveyor1.drawerIn);
    systems.link(conveyor1.drawerOut, conveyor2.drawerIn);
    systems.link(conveyor2.drawerOut, hangingConveyor.drawerIn);
    systems.link(hangingConveyor.drawerOut, conveyor3.drawerIn);
    systems.link(conveyor3.drawerOut, taraDrawerWeigher.drawerIn);
    systems.link(taraDrawerWeigher.drawerOut, conveyor4.drawerIn);
    systems.link(conveyor4.drawerOut, soaker.drawerIn);
    systems.link(soaker.drawerOut, conveyor5.drawerIn);
    systems.link(conveyor5.drawerOut, washer.drawerIn);
    systems.link(washer.drawerOut, conveyor6.drawerIn);
    systems.link(conveyor6.drawerOut, conveyor7.drawerIn);
    systems.link(conveyor7.drawerOut, conveyor8.drawerIn);
    systems.link(conveyor8.drawerOut, conveyor9.drawerIn);
    systems.link(conveyor9.drawerOut, drawerLoaderLift.drawerIn);
    systems.link(drawerLoaderLift.drawersOut, moduleDrawerLoader.drawersIn);

    systems.link(drawerUnloader.modulesOut, moduleConveyor4.modulesIn);
    systems.link(moduleConveyor4.modulesOut, moduleWasher.modulesIn);
    systems.link(moduleWasher.modulesOut, stacker.modulesIn);
    systems.link(moduleWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, moduleUnLoadingConveyor.modulesIn);
    systems.link(
        moduleUnLoadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    markers.add(
        Marker(drawerUnloader, drawerUnloader.shape.centerToConveyorCenter));

    for (var pos in drawerUnloaderLift.shape.centerLiftToDrawerCenterInLift) {
      markers.add(Marker(drawerUnloaderLift, pos));
    }
  }
}

class EvoArea extends LiveBirdHandlingArea {
  final drawerConveyorSpeedInMeterPerSecond = 0.7;

  EvoArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Line1',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var moduleConveyor1 = ModuleConveyor(area: this);

    var moduleConveyor2 = ModuleConveyor(area: this, lengthInMeters: 5);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 2.75,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(direction: const CompassDirection(45))
      ],
    );
    // systems.add(mrc1);

    var mcr2Mcr1 = TurnPosition(direction: const CompassDirection.south());
    var mrc2 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
      // defaultFeedInTurnPosition: mcr2Mcr1,
      turnPositions: [
        mcr2Mcr1,
        TurnPosition(
            direction: const CompassDirection(-45), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection(45))
      ],
    );
    // systems.add(mrc2);

    var cas1 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: false,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
            direction: const CompassDirection(270), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection(0))
      ],
    );

    var cas2 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: false,
    );

    var casStart = ModuleCasStart(area: this);
    systems.add(casStart);

    var casAllocation =
        ModuleCasAllocation(area: this, allocationPlace: mrc1.moduleGroupPlace);
    systems.add(casAllocation);

    var deStacker = ModuleDeStacker(area: this);

    var moduleConveyor3 = ModuleConveyor(area: this);

    var tilter = ModuleTilter(area: this, tiltToLeft: true);

    var dumpBelt = ModuleTilterDumpConveyor(
        area: this,
        minBirdsOnDumpBeltBuffer:
            productDefinition.averageProductsPerModuleGroup.round(),
        lengthInMeters: 3);

    var shackleConveyor = ShackleConveyor(area: this, toLeft: false);

    var moduleConveyor4 = ModuleConveyor(area: this);

    var stacker = ModuleStacker(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, moduleConveyor1.modulesIn);
    systems.link(moduleConveyor1.modulesOut, moduleConveyor2.modulesIn);
    systems.link(moduleConveyor2.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);
    systems.link(mrc3.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[2], deStacker.modulesIn);
    systems.link(deStacker.modulesOut, moduleConveyor3.modulesIn);
    systems.link(moduleConveyor3.modulesOut, tilter.modulesIn);
    systems.link(tilter.modulesOut, moduleConveyor4.modulesIn);
    systems.link(tilter.birdsOut, dumpBelt.birdsIn);
    systems.link(dumpBelt.birdOut, shackleConveyor.birdIn);
    systems.link(moduleConveyor4.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, unLoadingForkLiftTruck.modulesIn);
  }
}
