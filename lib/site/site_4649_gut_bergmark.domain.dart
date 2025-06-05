import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_allocation.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_start.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_loader/module_drawer_loader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_column_unloader/module_drawer_column_unloader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';

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
  static final minLoadDensity = LoadDensity.eec64_432(
    maxBirdWeight,
    summerLoadPercentage,
  );

  GutBergmarkProductDefinitions()
    : super([
        ProductDefinition(
          //13500 b/h
          areaFactory: _areaFactory(),
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 15000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
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
            }),
          ],
        ),
      ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
  _areaFactory() =>
      (ProductDefinition productDefinition) => [
        GutBergmarkLiveBirdHandlingArea(productDefinition),
      ];
}

class GutBergmarkLiveBirdHandlingArea extends LiveBirdHandlingArea {
  final drawerConveyorSpeedInMeterPerSecond = 0.7;
  static const int levelsOfModulesForCasUnits = 2;
  static const int numberOfModuleStacksForCasUnits = 1;

  GutBergmarkLiveBirdHandlingArea(ProductDefinition productDefinition)
    : super(lineName: 'Line1', productDefinition: productDefinition);
  @override
  void createSystemsAndLinks() {
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
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
      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
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
      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
    );

    var cas3 = ModuleCas(
      area: this,
      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
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
      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
    );

    var cas1 = ModuleCas(
      area: this,
      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
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
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor2 = DrawerConveyorStraight(
      lengthInMeters: 3,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var hangingConveyor = DrawerHangingConveyor(
      productDefinition: productDefinition,
      hangers: 11, // TODO 11 hangers for 15000?
      metersPerSecondOfFirstConveyor: drawerConveyorSpeedInMeterPerSecond,
      allDrawers: drawers,
    );

    var conveyor3 = DrawerConveyorStraight(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
      lengthInMeters: 1,
    );

    var taraDrawerWeigher = DrawerWeighingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor4 = DrawerTurningConveyor();

    var soaker = DrawerSoakingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor5 = DrawerConveyorStraight(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
      lengthInMeters: 9.5,
    );

    var washer = DrawerWashingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor6 = DrawerConveyorStraight(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
      lengthInMeters: 3.6,
    );

    var conveyor7 = DrawerTurningConveyor();

    var conveyor8 = DrawerConveyor90Degrees(
      direction: Direction.counterClockWise,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor9 = DrawerConveyorStraight(
      lengthInMeters: 1.4,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var drawerLoaderLift = DrawerLoaderLift(area: this);
    var moduleDrawerLoader = ModuleDrawerLoader(
      area: this,
      drawersInDirection: Direction.counterClockWise,
    );

    var mc3 = ModuleConveyor(area: this);
    var mc4 = ModuleConveyor(area: this);
    var moduleWasher1 = ModuleWasherConveyor(area: this, lengthInMeters: 2.75);
    var moduleWasher2 = ModuleWasherConveyor(area: this, lengthInMeters: 2.75);
    var stacker = ModuleStacker(area: this);
    var unloadConveyor = ModuleUnLoadingConveyor(area: this);
    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.add(
      ModuleCasStart(
        area: this,
        transportTimeCorrections: {cas3: -12, cas4: -12, cas5: -24},
      ),
    );

    systems.add(
      ModuleCasAllocation(
        area: this,
        allocationPlace: loadingConveyor.moduleGroupPlace,
      ),
    );

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
    systems.link(mc4.modulesOut, moduleWasher1.modulesIn);
    systems.link(moduleWasher1.modulesOut, moduleWasher2.modulesIn);
    systems.link(moduleWasher2.modulesOut, moduleDrawerLoader.modulesIn);
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
