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
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';

import 'site.dart';

class LonkiSite extends Site {
  LonkiSite()
    : super(
        meynLayoutNumber: 5768,
        organizationName: 'Lonki',
        city: 'Fanipol',
        country: 'Belgium',
        productDefinitions: LonkiProductDefinitions(),
      );
}

class LonkiProductDefinitions extends DelegatingList<ProductDefinition> {
  static final maxBirdWeight = 3.kilo.grams;
  static const summerLoadPercentage = 90;
  static final minLoadDensity = LoadDensity.eec64_432(
    maxBirdWeight,
    summerLoadPercentage,
  );
  LonkiProductDefinitions()
    : super([
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            AreaWithRowUnloader(productDefinition),
          ],
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 6000,
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
                  .l5
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

    var deStacker = ModuleDeStacker(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(
          direction: const CompassDirection.east(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.west()),
      ],
    );

    var drawerUnloader = ModuleDrawerRowUnloader(
      area: this,
      drawerOutDirection: Direction.clockWise,
    );

    var mc1 = ModuleConveyor(area: this);
    var mrc2 = ModuleRotatingConveyor(
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

    var mc2 = ModuleConveyor(area: this);

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

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

    var muc = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, mlc.modulesIn);
    systems.link(mlc.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], drawerUnloader.modulesIn);
    systems.link(drawerUnloader.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], mc2.modulesIn);
    systems.link(mc2.modulesOut, mrc3.modulesIns[0]);
    systems.link(mrc3.modulesOuts[1], modulePreWasher.modulesIn);
    systems.link(modulePreWasher.modulesOut, moduleMainWasher.modulesIn);
    systems.link(moduleMainWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, muc.modulesIn);
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

    // var taraDrawerWeigher = DrawerWeighingConveyor(
    //   metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    // );

    var conveyor4 = DrawerTurningConveyor();

    var soaker = DrawerSoakingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor5 = DrawerConveyorStraight(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
      lengthInMeters: 4,
    );

    var conveyor5_1 = DrawerConveyor90Degrees(
      direction: Direction.counterClockWise,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor5_2 = DrawerConveyorStraight(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
      lengthInMeters: 13,
    );

    var conveyor5_3 = DrawerConveyor90Degrees(
      direction: Direction.counterClockWise,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var washer = DrawerWashingConveyor(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor6 = DrawerConveyorStraight(
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
      lengthInMeters: 4.2,
    );

    var conveyor7 = DrawerTurningConveyor();

    var conveyor8 = DrawerConveyor90Degrees(
      direction: Direction.clockWise,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var drawerLoaderLift = DrawerLoaderLift(area: this);

    systems.link(drawerUnloader.drawersOut, drawerUnloaderLift.drawersIn);
    systems.link(drawerUnloaderLift.drawerOut, conveyor0.drawerIn);
    systems.link(conveyor0.drawerOut, conveyor1.drawerIn);
    systems.link(conveyor1.drawerOut, conveyor2.drawerIn);
    systems.link(conveyor2.drawerOut, hangingConveyor.drawerIn);
    systems.link(hangingConveyor.drawerOut, conveyor3.drawerIn);
    systems.link(conveyor3.drawerOut, conveyor4.drawerIn);
    systems.link(conveyor4.drawerOut, soaker.drawerIn);
    systems.link(soaker.drawerOut, conveyor5.drawerIn);
    systems.link(conveyor5.drawerOut, conveyor5_1.drawerIn);
    systems.link(conveyor5_1.drawerOut, conveyor5_2.drawerIn);
    systems.link(conveyor5_2.drawerOut, conveyor5_3.drawerIn);
    systems.link(conveyor5_3.drawerOut, washer.drawerIn);
    systems.link(washer.drawerOut, conveyor6.drawerIn);
    systems.link(conveyor6.drawerOut, conveyor7.drawerIn);
    systems.link(conveyor7.drawerOut, conveyor8.drawerIn);
    systems.link(conveyor8.drawerOut, drawerLoaderLift.drawerIn);
    systems.link(drawerLoaderLift.drawersOut, moduleDrawerLoader.drawersIn);
  }
}
