import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';
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
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/site/site.dart';

class BorgmeierSite extends Site {
  BorgmeierSite()
    : super(
        meynLayoutNumber: 8199,
        organizationName: 'Borgmeier',
        city: 'Lohne',
        country: 'Germany',
        productDefinitions: BorgmeierProductDefinitions(),
      );
}

class BorgmeierProductDefinitions extends DelegatingList<ProductDefinition> {
  static final maxBirdWeight = 2.9.kilo.grams;
  static const summerLoadPercentage = 90;
  static final loadDensityHeaviestFlock = LoadDensity.eec64_432(
    maxBirdWeight,
    summerLoadPercentage,
  );

  BorgmeierProductDefinitions()
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
                  .withLoadDensity(loadDensityHeaviestFlock, maxBirdWeight),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .meyn
                  .grandeDrawer
                  .m4
                  .c2
                  .l5
                  .gs
                  .build()
                  .withLoadDensity(loadDensityHeaviestFlock, maxBirdWeight),
            }),
          ],
        ),
        ProductDefinition(
          //13500 b/h
          areaFactory: _areaFactory(),
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 16500,
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
                  .withLoadDensity(loadDensityHeaviestFlock, maxBirdWeight),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .meyn
                  .grandeDrawer
                  .m4
                  .c2
                  .l5
                  .gs
                  .build()
                  .withLoadDensity(loadDensityHeaviestFlock, maxBirdWeight),
            }),
          ],
        ),
      ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
  _areaFactory() =>
      (ProductDefinition productDefinition) => [
        Simultaneously(productDefinition),
      ];
}

/// See "\\meyn.nl\project\acaddrwg\8199 Borgmeier - Germany\2024\02 - Meyn drawings\Sales\8199s123z00g1.dwg"
class Simultaneously extends LiveBirdHandlingArea {
  /// Module systems

  final drawerConveyorSpeedInMeterPerSecond = 0.7;

  static const int levelsOfModulesForCasUnits = 2;
  static const int numberOfModuleStacksForCasUnits = 1;

  Simultaneously(ProductDefinition productDefinition)
    : super(lineName: 'Line1', productDefinition: productDefinition);

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.right,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mc1 = ModuleConveyor(area: this);

    var mc2 = ModuleConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(
          direction: const CompassDirection.west(),
          reverseFeedIn: true,
        ),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var cas6 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas5 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var mc3 = ModuleConveyor(area: this);

    var deStacker = ModuleDeStacker(area: this);

    var drawerUnloader = ModuleDrawerColumnUnloader(
      area: this,
      drawerOutDirection: Direction.counterClockWise,
    );

    var mc4 = ModuleConveyor(area: this);

    var mc5 = ModuleConveyor(area: this);

    var modulePreWasher = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 5.5 / 2,
    );

    var moduleMainWasher = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 5.5 / 2,
    );

    var moduleDrawerLoader = ModuleDrawerLoader(
      area: this,
      drawersInDirection: Direction.counterClockWise,
    );

    var stacker = ModuleStacker(area: this);

    var unloadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.add(
      ModuleCasAllocation(area: this, allocationPlace: mc2.moduleGroupPlace),
    );

    systems.add(
      ModuleCasStart(
        area: this,
        transportTimeCorrections: {cas1: 12, cas2: 12, cas5: -12, cas6: -12},
      ),
    );

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas6.modulesIn);
    systems.link(cas6.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[2], cas5.modulesIn);
    systems.link(cas5.modulesOut, mrc1.modulesIns[2]);
    systems.link(mrc1.modulesOuts[3], mrc2.modulesIns[0]);

    systems.link(mrc2.modulesOuts[1], cas4.modulesIn);
    systems.link(cas4.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc2.modulesIns[2]);
    systems.link(mrc2.modulesOuts[3], mrc3.modulesIns[0]);

    systems.link(mrc3.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[2], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[2]);
    systems.link(mrc3.modulesOuts[3], mc3.modulesIn);
    systems.link(mc3.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, drawerUnloader.modulesIn);
    systems.link(drawerUnloader.modulesOut, mc5.modulesIn);
    systems.link(mc5.modulesOut, modulePreWasher.modulesIn);
    systems.link(modulePreWasher.modulesOut, moduleMainWasher.modulesIn);
    systems.link(moduleMainWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, unloadingConveyor.modulesIn);
    systems.link(
      unloadingConveyor.modulesOut,
      unLoadingForkLiftTruck.modulesIn,
    );

    /// drawer systems

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
      lengthInMeters: 7.8,
    );

    var washer = DrawerWashingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor6 = DrawerConveyorStraight(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
      lengthInMeters: 2.5,
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

  ///Capacity can not be reached because unloader can not feed out, because transport trough module washer takes too long

  ///TODO: ModuleConveyors to feed out and feed in simultaneously

  ///TODO: Module washer to be 2 module conveyors that feed out and feed in simultaniously with force feed out when modulesIn.linkToOther.canFeedOut
}
