import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_column_unloader/module_drawer_column_unloader.domain.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_allocation.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_start.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_loader/module_drawer_loader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/truck/truck_route.domain.dart';
import 'package:meyn_lbh_simulation/site/site.dart';

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
  static final maxBirdWeight = 2.5.kilo.grams;
  static const summerLoadPercentage = 80;
  static final minLoadDensity =
      LoadDensity.eec64_432(maxBirdWeight, summerLoadPercentage);

  MicarnaProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactoryV2(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 13500,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m4
                      .c1
                      .l5
                      .gs
                      .build()
                      .withLoadDensity(minLoadDensity, maxBirdWeight),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m4
                      .c1
                      .l4
                      .gs
                      .build()
                      .withLoadDensity(minLoadDensity, maxBirdWeight),
                  PositionWithinModuleGroup.secondBottom: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m4
                      .c1
                      .l5
                      .gs
                      .build()
                      .withLoadDensity(minLoadDensity, maxBirdWeight),
                  PositionWithinModuleGroup.secondTop: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m4
                      .c1
                      .l4
                      .gs
                      .build()
                      .withLoadDensity(minLoadDensity, maxBirdWeight),
                })
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactoryV2() => (ProductDefinition productDefinition) =>
          [MicarnaLiveBirdHandlingArea(productDefinition)];
}

class MicarnaLiveBirdHandlingArea extends LiveBirdHandlingArea {
  double drawerConveyorSpeedInMeterPerSecond = 0.5;

  MicarnaLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Line1',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    var truckRoutes = TruckRoutes.forTrailerPuller(area: this);

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.right,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(
            direction: const CompassDirection.south(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(direction: const CompassDirection.north()),
      ],
    );

    var mc1 = ModuleConveyor(
      area: this,
      lengthInMeters: 4.2,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(direction: const CompassDirection.west()),
      ],
    );

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.west()),
      ],
    );

    var cas5 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var mrc5 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.west()),
      ],
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var mrc6 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
      ],
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var mc2 = ModuleConveyor(area: this);

    var deStacker1 = ModuleDeStacker(
      area: this,
    );

    var deStacker2 = ModuleDeStacker(
      area: this,
    );

    var mc3 = ModuleConveyor(
      area: this,
    );

    var drawerUnloader = ModuleDrawerColumnUnloader(
      area: this,
      drawerOutDirection: Direction.clockWise,
    );

    var mc4 = ModuleConveyor(area: this);

    var mc5 = ModuleConveyor(area: this);

    var mc6 = ModuleConveyor(area: this);

    var moduleWasher1 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 2.25,
    );

    var moduleWasher2 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 2.25,
    );

    var moduleDrawerLoader = ModuleDrawerLoader(
      area: this,
      drawersInDirection: Direction.clockWise,
    );

    var stacker1 = ModuleStacker(
      area: this,
      maxLevelsInTop: 4,
    );

    var stacker2 = ModuleStacker(
      area: this,
      maxLevelsInTop: 4,
    );

    var unloadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(truckRoutes.modulesOut, loadingForkLiftTruck.modulesIn);
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], mc1.modulesIn);
    systems.link(mc1.modulesOut, mrc3.modulesIns[0]);
    systems.link(mrc3.modulesOuts[1], mrc4.modulesIns[0]);

    systems.link(mrc4.modulesOuts[1], cas4.modulesIn);
    systems.link(cas4.modulesOut, mrc4.modulesIns[1]);
    systems.link(mrc4.modulesOuts[2], cas5.modulesIn);
    systems.link(cas5.modulesOut, mrc4.modulesIns[2]);
    systems.link(mrc4.modulesOuts[3], mrc5.modulesIns[0]);

    systems.link(mrc5.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc5.modulesIns[1]);
    systems.link(mrc5.modulesOuts[2], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc5.modulesIns[2]);
    systems.link(mrc5.modulesOuts[3], mrc6.modulesIns[0]);

    systems.link(mrc6.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc6.modulesIns[1]);
    systems.link(mrc6.modulesOuts[2], mc2.modulesIn);

    systems.link(mc2.modulesOut, deStacker1.modulesIn);
    systems.link(deStacker1.modulesOut, deStacker2.modulesIn);
    systems.link(deStacker2.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, drawerUnloader.modulesIn);
    systems.link(drawerUnloader.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, mc5.modulesIn);
    systems.link(mc5.modulesOut, mc6.modulesIn);
    systems.link(mc6.modulesOut, moduleWasher1.modulesIn);
    systems.link(moduleWasher1.modulesOut, moduleWasher2.modulesIn);
    systems.link(moduleWasher2.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, stacker1.modulesIn);
    systems.link(stacker1.modulesOut, stacker2.modulesIn);
    systems.link(stacker2.modulesOut, unloadingConveyor.modulesIn);
    systems.link(
        unloadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// drawer systems

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
        lengthInMeters: 7.8);

    var washer = DrawerWashingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor6 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 5.0);

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

    systems.add(ModuleCasAllocation(
      area: this,
      allocationPlace: mrc3.moduleGroupPlace,
    ));

    systems.add(ModuleCasStart(area: this, startIntervalFractions: <double>[
      0.5,
      0.5,
      0.6,
      0.6,
      0.7,
      0.7,
      0.8,
      0.8,
      0.9,
      0.9,
      1,
      1,
      1.10,
      1.10,
      1.20,
      1.20,
      1.30,
      1.30,
      1.40,
      1.40,
      1.50,
      1.50,
    ]));
  }
}
