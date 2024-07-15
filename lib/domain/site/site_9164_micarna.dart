import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/site/site.dart';

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
          // ProductDefinition(
          //     areaFactory: _areaFactoryV1(),
          //     birdType: 'Chicken',
          //     lineSpeedInShacklesPerHour: 13500,
          //     casRecipe: const CasRecipe.standardChickenRecipe(),
          //     moduleSystem: ModuleSystem.meynGrandeDrawerContainers,
          //     moduleFamily: ModuleFamily.meynGrandeDrawerDoubleColumn,
          //     moduleGroupCapacities: [
          //       ModuleGroupCapacity(
          //         PositionWithinModuleGroup.firstBottom: MeynGrandeDrawerChicken4Level()
          //             .dimensions
          //             .capacityWithDensity(minLoadDensity, maxBirdWeight),
          //         PositionWithinModuleGroup.firstTop: MeynGrandeDrawerChicken4Level()
          //             .dimensions
          //             .capacityWithDensity(minLoadDensity, maxBirdWeight),
          //       )
          //     ]),
          // ProductDefinition(
          //     areaFactory: _areaFactoryV2(),
          //     birdType: 'Chicken',
          //     lineSpeedInShacklesPerHour: 13500,
          //     casRecipe: const CasRecipe.standardChickenRecipe(),
          //     moduleSystem: ModuleSystem.meynSingleColumnContainers,
          //     moduleFamily: ModuleFamily.meynGrandeDrawerSingleColumn,
          //     moduleGroupCapacities: [
          //       ModuleGroupCapacity(
          //         PositionWithinModuleGroup.firstBottom: MeynGrandeDrawerChicken5Level()
          //             .dimensions
          //             .capacityWithDensity(minLoadDensity, maxBirdWeight),
          //         PositionWithinModuleGroup.firstTop: MeynGrandeDrawerChicken4Level()
          //             .dimensions
          //             .capacityWithDensity(minLoadDensity, maxBirdWeight),
          //       )
          //     ]),
          ProductDefinition(
              areaFactory: _areaFactoryV2(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 13500,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynSingleColumnContainers,
              moduleFamily: ModuleFamily.meynGrandeDrawerSingleColumn,
              moduleGroupCapacities: [
                ModuleGroupCapacity({
                  PositionWithinModuleGroup.firstBottom:
                      MeynGrandeDrawerChicken5Level()
                          .dimensions
                          .capacityWithDensity(minLoadDensity, maxBirdWeight),
                  PositionWithinModuleGroup.firstTop:
                      MeynGrandeDrawerChicken4Level()
                          .dimensions
                          .capacityWithDensity(minLoadDensity, maxBirdWeight),
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
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.right,
    );

    var loadingConveyor = ModuleConveyor(
      area: this,
      lengthInMeters: 3.75,
    );

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
      turnPositions: [
        TurnPosition(
            direction: const CompassDirection.south(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
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
      lengthInMeters: 3.2,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(direction: const CompassDirection.west()),
      ],
    );

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
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
      slideDoorLeft: true,
    );

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      slideDoorLeft: false,
    );

    var mrc5 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
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
      slideDoorLeft: true,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      slideDoorLeft: false,
    );

    var mrc6 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
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
      slideDoorLeft: true,
    );

    var mc2 = ModuleConveyor(area: this);

    var deStacker = ModuleDeStacker(area: this);

    var mc3 = ModuleConveyor(area: this);

    var drawerUnloader = ModuleDrawerColumnUnloader(
      area: this,
      drawerOutDirection: Direction.clockWise,
    );

    var mc4 = ModuleConveyor(area: this);

    var mc5 = ModuleConveyor(area: this);

    var moduleWasher = ModuleConveyor(
      area: this,
      lengthInMeters: 5.5,
    );

    var moduleDrawerLoader = ModuleDrawerLoader(
      area: this,
      drawersFromLeft: false,
    );

    var stacker = ModuleStacker(area: this);

    var unloadingConveyor = ModuleConveyor(
      area: this,
      lengthInMeters: 3.75,
    );

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

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

    systems.link(mc2.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, drawerUnloader.modulesIn);
    systems.link(drawerUnloader.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, mc5.modulesIn);
    systems.link(mc5.modulesOut, moduleWasher.modulesIn);
    systems.link(moduleWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, unloadingConveyor.modulesIn);
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
        lengthInMeters: 5.5);

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
      1.40,
      1.80,
      2.20,
      2.40,
    ]));
  }
}
