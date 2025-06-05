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
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_loader/module_drawer_loader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_row_unloader/module_drawer_row_unloader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';

import 'site.dart';

class AbaliogluSite extends Site {
  AbaliogluSite()
    : super(
        meynLayoutNumber: 1203,
        organizationName: 'Abalioglu',
        city: 'Maksutuşağı	Kahramanmaraş',
        country: 'Turkey',
        productDefinitions: AbaliogluProductDefinitions(),
      );
}

class AbaliogluProductDefinitions extends DelegatingList<ProductDefinition> {
  static final maxBirdWeight = 2.kilo.grams;
  static const summerLoadPercentage = 90;
  static final minLoadDensity = LoadDensity.eec64_432(
    maxBirdWeight,
    summerLoadPercentage,
  );
  AbaliogluProductDefinitions()
    : super([
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            AreaWithRowUnloader(productDefinition),
          ],
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 12000,
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
                  .withLoadDensity(minLoadDensity, maxBirdWeight),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .meyn
                  .grandeDrawer
                  .m1
                  .c2
                  .l4
                  .gs
                  .build()
                  .withLoadDensity(minLoadDensity, maxBirdWeight),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            AreaWithRowUnloader(productDefinition),
          ],
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
}

class AreaWithRowUnloader extends LiveBirdHandlingArea {
  final drawerConveyorSpeedInMeterPerSecond = 0.7;

  AreaWithRowUnloader(ProductDefinition productDefinition)
    : super(lineName: 'Line1', productDefinition: productDefinition);
  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.west();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var mlc = ModuleLoadingConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(
          direction: const CompassDirection.east(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.south()),
      ],
    );

    var deStacker = ModuleDeStacker(area: this);

    var mc1 = ModuleConveyor(area: this);

    var drawerUnloader = ModuleDrawerRowUnloader(
      area: this,
      drawerOutDirection: Direction.clockWise,
    );

    var mc2 = ModuleConveyor(area: this);

    var mc3 = ModuleConveyor(area: this);
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
      drawersInDirection: Direction.clockWise,
    );

    var stacker = ModuleStacker(area: this);

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var muc = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    // systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    // systems.link(loadingConveyor.modulesOut, deStacker.modulesIn);
    systems.link(loadingForkLiftTruck.modulesOut, mlc.modulesIn);
    systems.link(mlc.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, drawerUnloader.modulesIn);
    systems.link(drawerUnloader.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, modulePreWasher.modulesIn);
    systems.link(modulePreWasher.modulesOut, moduleMainWasher.modulesIn);
    systems.link(moduleMainWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], muc.modulesIn);
    systems.link(muc.modulesOut, unLoadingForkLiftTruck.modulesIn);

    // drawers

    var drawerUnloaderLift = ModuleDrawerRowUnloaderReceiver(
      area: this,
      drawerOutDirection: Direction.counterClockWise,
      crossOverFeedOutMetersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor0 = DrawerConveyor90Degrees(
      direction: Direction.clockWise,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor1 = DrawerConveyor90Degrees(
      direction: Direction.clockWise,
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
      lengthInMeters: 4,
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
      direction: Direction.clockWise,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor9 = DrawerConveyorStraight(
      lengthInMeters: 2.9,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var drawerLoaderLift = DrawerLoaderLift(area: this);

    systems.link(drawerUnloader.drawersOut, drawerUnloaderLift.drawersIn);
    systems.link(drawerUnloaderLift.drawerOut, conveyor0.drawerIn);
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
  }
}
