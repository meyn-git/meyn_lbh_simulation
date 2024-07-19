import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module/brand.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
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
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawerDoubleColumn,
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m4
                      .c2
                      .l4
                      .gs
                      .build()
                      .withLoadDensity(minLoadDensity, maxBirdWeight),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m4
                      .c2
                      .l5
                      .gs
                      .build()
                      .withLoadDensity(minLoadDensity, maxBirdWeight),
                })
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [GutBergmarkLiveBirdHandlingArea(productDefinition)];
}

class GutBergmarkLiveBirdHandlingArea extends LiveBirdHandlingArea {
  final drawerConveyorSpeedInMeterPerSecond = 0.7;

  GutBergmarkLiveBirdHandlingArea(ProductDefinition productDefinition)
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

    var loadingConveyor = ModuleConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var cas5 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: false,
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
          direction: const CompassDirection.west(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(
          direction: const CompassDirection.east(),
          reverseFeedOut: true,
        ),
      ],
    );

    var cas4 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: false,
    );

    var cas3 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: false,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
          direction: const CompassDirection.west(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(
          direction: const CompassDirection.east(),
          reverseFeedOut: true,
        ),
      ],
    );

    var cas2 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: false,
    );

    var cas1 = ModuleCas(
      area: this,
      slideDoorLeft: true,
      gasDuctsLeft: false,
    );

    var mc1 = ModuleConveyor(area: this);

    var deStacker = ModuleDeStacker(area: this);

    var mc2 = ModuleConveyor(area: this);

    var drawerUnloader = ModuleDrawerColumnUnloader(
      area: this,
      drawerOutDirection: Direction.counterClockWise,
    );

    var drawerUnloaderLift = DrawerUnloaderLift(area: this);

    var grossDrawerWeigher = DrawerWeighingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor1 = DrawerConveyor90Degrees(
        direction: Direction.counterClockWise,
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
        direction: Direction.counterClockWise,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor9 = DrawerConveyorStraight(
        lengthInMeters: 1.4,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var drawerLoaderLift = DrawerLoaderLift(area: this);
    var moduleDrawerLoader = ModuleDrawerLoader(
      area: this,
      drawersFromLeft: true,
    );

    var mc3 = ModuleConveyor(area: this);
    var mc4 = ModuleConveyor(area: this);
    var moduleWasher = ModuleConveyor(area: this, lengthInMeters: 5.5);
    var stacker = ModuleStacker(area: this);
    var unloadConveyor = ModuleConveyor(area: this);
    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.add(ModuleCasStart(area: this, startIntervalFractions: <double>[
      0.5,
      0.6,
      0.7,
      0.8,
      0.9,
      1,
      1,
      1,
      1.1,
      1.2,
      1.3,
    ], transportTimeCorrections: {
      cas3: -12,
      cas4: -12,
      cas5: -24,
    }));

    systems.add(ModuleCasAllocation(
      area: this,
      allocationPlace: loadingConveyor.moduleGroupPlace,
    ));

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas5.modulesIn);
    systems.link(cas5.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[2], mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[3], cas4.modulesIn);
    systems.link(cas4.modulesOut, mrc2.modulesIns[3]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);
    systems.link(mrc3.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[3], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc3.modulesIns[3]);
    systems.link(mrc3.modulesOuts[2], mc1.modulesIn);
    systems.link(mc1.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, drawerUnloader.modulesIn);
    systems.link(drawerUnloader.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, moduleWasher.modulesIn);
    systems.link(moduleWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, unloadConveyor.modulesIn);
    systems.link(unloadConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    // drawers
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
