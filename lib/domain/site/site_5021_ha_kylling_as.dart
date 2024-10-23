import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module/brand.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_row_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter_dump_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_washer.dart';
import 'package:meyn_lbh_simulation/domain/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class HaKyllingAsSite extends Site {
  HaKyllingAsSite()
      : super(
          meynLayoutNumber: 5021,
          organizationName: 'Hå Kylling AS',
          city: 'NÆRBØ',
          country: 'Norway',
          productDefinitions: ProductDefinitions(),
        );
}

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [AreaWithGrande(productDefinition)],
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 12500,
              lineShacklePitchInInches: 6,
              casRecipe: NksCasRecipe(),
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
                      .withBirdsPerCompartment(34),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m4
                      .c2
                      .l4
                      .gs
                      .build()
                      .withBirdsPerCompartment(34),
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [AreaWithGp(productDefinition)],
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 9300,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .marel
                      .gpl
                      .l4
                      .build()
                      .withBirdsPerCompartment(37),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .marel
                      .gpl
                      .l4
                      .build()
                      .withBirdsPerCompartment(37)
                })
              ]),
        ]);
}

/// 2024-08-07 According to Aize Land (Meyn sales person):
/// standaard Meyn gas receipt is 6 min -> 360 sec.
/// Volgens rapport van Wietse Leguijt is daar 32 sec van af gehaald in de laatste fase. Dat zou 328 sec total betekenen voor 1 cyclus.
class NksCasRecipe extends CasRecipe {
  NksCasRecipe()
      : super(const [
          Duration(seconds: 60), //18%
          Duration(seconds: 60), //28%
          Duration(seconds: 60), //33%
          Duration(seconds: 60), //38%
          Duration(seconds: 120 - 32) //67%
        ], const Duration(seconds: 30));
}

class AreaWithGp extends LiveBirdHandlingArea {
  AreaWithGp(ProductDefinition productDefinition)
      : super(
          lineName: 'GP Modules',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var loadingConveyor = ModuleConveyor(
      area: this,
      lengthInMeters: 3.75,
    );

    var mc1 = ModuleConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
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
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      slideDoorLeft: false,
    );

    var mc2 = ModuleConveyor(area: this);

    var deStacker = ModuleDeStacker(area: this);

    var mc3 = ModuleConveyor(area: this);

    var tilter = ModuleTilter(
      area: this,
      tiltDirection: Direction.counterClockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(
        area: this,
        minBirdsOnDumpBeltBuffer:
            productDefinition.truckRows.first.numberOfBirds,
        lengthInMeters: 3.2);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.clockWise,
    );

    var unloadingConveyor = ModuleConveyor(area: this, lengthInMeters: 3.75);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[3], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc1.modulesIns[3]);
    systems.link(mrc1.modulesOuts[2], mc2.modulesIn);
    systems.link(mc2.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, tilter.modulesIn);
    systems.link(tilter.modulesOut, unloadingConveyor.modulesIn);
    systems.link(
        unloadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    // bird conveyors
    systems.link(tilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

    systems.add(ModuleCasStart(area: this));
    systems.add(
        ModuleCasAllocation(area: this, allocationPlace: mc1.moduleGroupPlace));
  }
}

class AreaWithGrande extends LiveBirdHandlingArea {
  AreaWithGrande(ProductDefinition productDefinition)
      : super(
          lineName: 'Grande Drawer',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var loadingConveyor = ModuleConveyor(
      area: this,
      lengthInMeters: 3.75,
    );

    var mc1 = ModuleConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
        area: this,
        turnPositions: [
          TurnPosition(direction: const CompassDirection.south()),
          TurnPosition(
            direction: const CompassDirection.west(),
            reverseFeedIn: true,
          ),
          TurnPosition(direction: const CompassDirection.north()),
        ],
        diameter: ModuleRotatingConveyorDiameter.beforeModuleCas);

    var mrc2 = ModuleRotatingConveyor(
        area: this,
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
        diameter: ModuleRotatingConveyorDiameter.beforeModuleCas);

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      slideDoorLeft: false,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var mc2 = ModuleConveyor(area: this);

    var deStacker = ModuleDeStacker(area: this);

    var unloader = ModuleDrawerRowUnloader(
      area: this,
      drawerOutDirection: Direction.counterClockWise,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(direction: const CompassDirection.west())
      ],
    );

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(direction: const CompassDirection.north())
      ],
    );

    var mc4 = ModuleConveyor(area: this);

    var modulePreWasher =
        ModuleWasherConveyor(area: this, lengthInMeters: 5.5 / 2);

    var moduleMainWasher =
        ModuleWasherConveyor(area: this, lengthInMeters: 5.5 / 2);

    var mc5 = ModuleConveyor(area: this);
    var loader = ModuleDrawerLoader(
      area: this,
      drawersInDirection: Direction.counterClockWise,
    );

    var stacker = ModuleStacker(area: this);

    var mrc5 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(direction: const CompassDirection.east())
      ],
    );

    var unloadConveyor = ModuleConveyor(
      area: this,
      lengthInMeters: 3.75,
    );

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mc1.modulesIn);

    systems.link(mc1.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[2], mrc2.modulesIns[0]);

    systems.link(mrc2.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[3], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc2.modulesIns[3]);
    systems.link(mrc2.modulesOuts[2], mc2.modulesIn);
    systems.link(mc2.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, unloader.modulesIn);
    systems.link(unloader.modulesOut, mrc3.modulesIns[0]);
    systems.link(mrc3.modulesOuts[1], mrc4.modulesIns[0]);
    systems.link(mrc4.modulesOuts[1], mc4.modulesIn);
    systems.link(mc4.modulesOut, modulePreWasher.modulesIn);
    systems.link(modulePreWasher.modulesOut, moduleMainWasher.modulesIn);
    systems.link(moduleMainWasher.modulesOut, mc5.modulesIn);
    systems.link(mc5.modulesOut, loader.modulesIn);
    systems.link(loader.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, mrc5.modulesIns[0]);
    systems.link(mrc5.modulesOuts[1], unloadConveyor.modulesIn);
    systems.link(unloadConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// Drawers
    var drawerConveyorSpeedInMeterPerSecond = 0.7;
    var receiver = ModuleDrawerRowUnloaderReceiver(
      area: this,
      drawerOutDirection: Direction.counterClockWise,
      crossOverFeedOutMetersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor0 = DrawerConveyor90Degrees(
      direction: Direction.clockWise,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor1 = DrawerConveyor90Degrees(
        direction: Direction.counterClockWise,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var hangingConveyor = DrawerHangingConveyor(
        productDefinition: productDefinition,
        hangers: 11, // TODO 11 hangers for 15000?
        metersPerSecondOfFirstConveyor: drawerConveyorSpeedInMeterPerSecond,
        allDrawers: drawers);

    var conveyor2 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 1);

    var taraDrawerWeigher = DrawerWeighingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor3 = DrawerTurningConveyor();

    var conveyor4 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 11.8);

    var preWasher = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 2,
        systemProtrudesInMeters:
            (1.47 - DrawerConveyor.chainWidthInMeters) / 2);

    var soaker = DrawerSoakingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor5 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 0.2);

    var washer = DrawerWashingConveyor(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor6 = DrawerConveyorStraight(
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
        lengthInMeters: 3.7);

    var conveyor7 = DrawerTurningConveyor();

    var conveyor8 = DrawerConveyor90Degrees(
        direction: Direction.counterClockWise,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var conveyor9 = DrawerConveyorStraight(
        lengthInMeters: 0.1,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

    var drawerLoaderLift = DrawerLoaderLift(
      area: this,
    );

    systems.link(unloader.drawersOut, receiver.drawersIn);
    systems.link(receiver.drawerOut, conveyor0.drawerIn);
    systems.link(conveyor0.drawerOut, conveyor1.drawerIn);
    systems.link(conveyor1.drawerOut, hangingConveyor.drawerIn);
    systems.link(hangingConveyor.drawerOut, conveyor2.drawerIn);
    systems.link(conveyor2.drawerOut, taraDrawerWeigher.drawerIn);
    systems.link(taraDrawerWeigher.drawerOut, conveyor3.drawerIn);
    systems.link(conveyor3.drawerOut, conveyor4.drawerIn);
    systems.link(conveyor4.drawerOut, preWasher.drawerIn);
    systems.link(preWasher.drawerOut, soaker.drawerIn);
    systems.link(soaker.drawerOut, conveyor5.drawerIn);
    systems.link(conveyor5.drawerOut, washer.drawerIn);
    systems.link(washer.drawerOut, conveyor6.drawerIn);
    systems.link(conveyor6.drawerOut, conveyor7.drawerIn);
    systems.link(conveyor7.drawerOut, conveyor8.drawerIn);
    systems.link(conveyor8.drawerOut, conveyor9.drawerIn);
    systems.link(conveyor9.drawerOut, drawerLoaderLift.drawerIn);
    systems.link(drawerLoaderLift.drawersOut, loader.drawersIn);

    systems.add(ModuleCasStart(area: this, startIntervalFractions: <double>[
      0.7,
      0.8,
      0.9,
      1,
      1,
      1.25,
      1.5,
      1.75,
      2,
      2.25,
    ]));
    systems.add(
        ModuleCasAllocation(area: this, allocationPlace: mc1.moduleGroupPlace));
  }
}
