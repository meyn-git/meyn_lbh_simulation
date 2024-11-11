import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/system/vehicle/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/domain/area/module/brand.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_washer.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/system/vehicle/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';

import 'site.dart';

class KeskinogluSite extends Site {
  KeskinogluSite()
      : super(
          meynLayoutNumber:
              0000, //old plant is 8117 this is a new greenfield and has no layout number yet.
          organizationName: 'Keskinoglu',
          city:
              '?', //old plant is 8117 this is a new greenfield and address is unknown fot now.
          country: 'Turkey',
          productDefinitions: KeskinogluProductDefinitions(),
        );
}

class KeskinogluProductDefinitions extends DelegatingList<ProductDefinition> {
  static const int shacklesPerHour = 15000;
  static final maxBirdWeight = 3.kilo.grams;
  static const summerLoadPercentage = 90;
  static final loadDensity =
      LoadDensity.eec64_432(maxBirdWeight, summerLoadPercentage);

  KeskinogluProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [AreaWithColumnUnloader(productDefinition)],
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: shacklesPerHour,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m1
                      .c2
                      .l4
                      .gs
                      .build()
                      .withLoadDensity(loadDensity, maxBirdWeight),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m1
                      .c2
                      .l4
                      .gs
                      .build()
                      .withLoadDensity(loadDensity, maxBirdWeight),
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [AreaWithColumnUnloader(productDefinition)],
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: shacklesPerHour,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m1
                      .c2
                      .l4
                      .gs
                      .build()
                      .withLoadDensity(loadDensity, maxBirdWeight),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m1
                      .c2
                      .l5
                      .gs
                      .build()
                      .withLoadDensity(loadDensity, maxBirdWeight),
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [AreaWithColumnUnloader(productDefinition)],
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: shacklesPerHour,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m1
                      .c2
                      .l5
                      .gs
                      .build()
                      .withLoadDensity(loadDensity, maxBirdWeight),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m1
                      .c2
                      .l5
                      .gs
                      .build()
                      .withLoadDensity(loadDensity, maxBirdWeight),
                })
              ]),
        ]);
}

class AreaWithColumnUnloader extends LiveBirdHandlingArea {
  final drawerConveyorSpeedInMeterPerSecond = 0.7;

  AreaWithColumnUnloader(ProductDefinition productDefinition)
      : super(
          lineName: 'With Column Unloader',
          productDefinition: productDefinition,
        );
  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.west();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var loadingConveyor = ModuleLoadingConveyor(
      area: this,
    );

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(
            direction: const CompassDirection.south(), reverseFeedOut: true),
      ],
    );

    var mc1 = ModuleConveyor(area: this);
    var mc2 = ModuleConveyor(area: this);

    var deStacker = ModuleDeStacker(area: this);

    var mc3 = ModuleConveyor(area: this);

    var drawerUnloader = ModuleDrawerColumnUnloader(
      area: this,
      drawerOutDirection: Direction.clockWise,
    );

    var mc4 = ModuleConveyor(area: this);
    var mc5 = ModuleConveyor(area: this);
    var modulePreWasher =
        ModuleWasherConveyor(area: this, lengthInMeters: 5.5 / 2);

    var moduleMainWasher =
        ModuleWasherConveyor(area: this, lengthInMeters: 5.5 / 2);
    var moduleDrawerLoader = ModuleDrawerLoader(
      area: this,
      drawersInDirection: Direction.clockWise,
    );

    var stacker = ModuleStacker(area: this);

    var mc6 = ModuleConveyor(area: this);
    var mc7 = ModuleConveyor(area: this);

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var unloadingConveyor = ModuleConveyor(area: this, lengthInMeters: 3.75);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mc1.modulesIn);
    systems.link(mc1.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, drawerUnloader.modulesIn);
    systems.link(drawerUnloader.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, mc5.modulesIn);
    systems.link(mc5.modulesOut, modulePreWasher.modulesIn);
    systems.link(modulePreWasher.modulesOut, moduleMainWasher.modulesIn);
    systems.link(moduleMainWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, mc6.modulesIn);
    systems.link(mc6.modulesOut, mc7.modulesIn);
    systems.link(mc7.modulesOut, mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], unloadingConveyor.modulesIn);
    systems.link(
        unloadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    // drawers

    var drawerUnloaderLift = DrawerUnloaderLift(area: this);

    var grossDrawerWeigher = DrawerWeighingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor1 = DrawerConveyor90Degrees(
        direction: Direction.clockWise,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor2 = DrawerConveyorStraight(
        lengthInMeters: 3,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var hangingConveyor = DrawerHangingConveyor(
        productDefinition: productDefinition,
        hangers: 11, // TODO 11 hangers for 15000?
        metersPerSecondOfFirstConveyor: drawerConveyorSpeedInMeterPerSecond,
        allDrawers: drawers);

    var conveyor3 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 1);

    var taraDrawerWeigher = DrawerWeighingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor4 = DrawerTurningConveyor();

    var soaker = DrawerSoakingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor5 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 9.5);

    var washer = DrawerWashingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor6 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 3.6);

    var conveyor7 = DrawerTurningConveyor();

    var conveyor8 = DrawerConveyor90Degrees(
        direction: Direction.clockWise,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor9 = DrawerConveyorStraight(
        lengthInMeters: 1.4,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var drawerLoaderLift = DrawerLoaderLift(area: this);

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
  }
}
