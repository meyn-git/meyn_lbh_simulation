import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module/brand.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_buffer_lane.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_column_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_row_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_washer.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';

import 'site.dart';

class SenpelicSite extends Site {
  SenpelicSite()
      : super(
          meynLayoutNumber: 1112,
          organizationName: 'Senpilic Gida San.Tic A.S.',
          city: 'Kavak/Samsun',
          country: 'Turkey',
          productDefinitions: SenpelicProductDefinitions(),
        );
}

class SenpelicProductDefinitions extends DelegatingList<ProductDefinition> {
  static final maxBirdWeight = 2.8.kilo.grams;
  static const summerLoadPercentage = 90;
  static final minLoadDensity =
      LoadDensity.eec64_432(maxBirdWeight, summerLoadPercentage);

  SenpelicProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [AreaWithRowUnloader(productDefinition)],
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 9000,
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
                      .withBirdsPerCompartment(22),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m1
                      .c2
                      .l4
                      .gs
                      .build()
                      .withBirdsPerCompartment(22),
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [AreaWithColumnUnloader(productDefinition)],
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
                      .withBirdsPerCompartment(22),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .grandeDrawer
                      .m4
                      .c2
                      .l4
                      .gs
                      .build()
                      .withBirdsPerCompartment(22),
                })
              ]),
        ]);
}

class AreaWithRowUnloader extends LiveBirdHandlingArea {
  final drawerConveyorSpeedInMeterPerSecond = 0.7;

  AreaWithRowUnloader(ProductDefinition productDefinition)
      : super(
          lineName: 'With Row Unloader',
          productDefinition: productDefinition,
        );
  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.west();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var bufferIn1 = ModuleBufferAngleTransferInFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );
    var bufferIn2 = ModuleBufferConveyor(area: this);
    var bufferIn3 = ModuleBufferConveyor(area: this);
    var bufferIn4 = ModuleBufferConveyor(area: this);
    var bufferIn5 = ModuleBufferConveyor(area: this);
    var bufferIn6 = ModuleBufferAngleTransferOutFeed(
      area: this,
      moduleOutDirection: Direction.counterClockWise,
    );

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3,
      turnPositions: [
        TurnPosition(
            direction: const CompassDirection.east(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.south()),
      ],
    );

    var deStacker = ModuleDeStacker(area: this);

    var mc1 = ModuleConveyor(area: this);

    var mc2 = ModuleConveyor(area: this);

    var drawerUnloader = ModuleDrawerRowUnloader(
      area: this,
      drawerOutDirection: Direction.clockWise,
    );

    var mc3 = ModuleConveyor(area: this);

    var mc4 = ModuleConveyor(area: this);
    var modulePreWasher =
        ModuleWasherConveyor(area: this, lengthInMeters: 5.5 / 2);

    var moduleMainWasher =
        ModuleWasherConveyor(area: this, lengthInMeters: 5.5 / 2);
    var moduleDrawerLoader = ModuleDrawerLoader(
      area: this,
      drawersInDirection: Direction.clockWise,
    );
    var mrc2 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var stacker = ModuleStacker(area: this);

    var bufferOut1 = ModuleBufferAngleTransferInFeed(
      area: this,
      moduleOutDirection: Direction.counterClockWise,
    );
    var bufferOut2 = ModuleBufferConveyor(area: this);
    var bufferOut3 = ModuleBufferConveyor(area: this);
    var bufferOut4 = ModuleBufferConveyor(area: this);
    var bufferOut5 = ModuleBufferConveyor(area: this);
    var bufferOut6 = ModuleBufferAngleTransferOutFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    // systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    // systems.link(loadingConveyor.modulesOut, deStacker.modulesIn);
    systems.link(loadingForkLiftTruck.modulesOut, bufferIn1.modulesIn);
    systems.link(bufferIn1.modulesOut, bufferIn2.modulesIn);
    systems.link(bufferIn2.modulesOut, bufferIn3.modulesIn);
    systems.link(bufferIn3.modulesOut, bufferIn4.modulesIn);
    systems.link(bufferIn4.modulesOut, bufferIn5.modulesIn);
    systems.link(bufferIn5.modulesOut, bufferIn6.modulesIn);
    systems.link(bufferIn6.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mc1.modulesIn);
    systems.link(mc1.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, drawerUnloader.modulesIn);
    systems.link(drawerUnloader.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, modulePreWasher.modulesIn);
    systems.link(modulePreWasher.modulesOut, moduleMainWasher.modulesIn);
    systems.link(moduleMainWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], stacker.modulesIn);
    systems.link(stacker.modulesOut, bufferOut1.modulesIn);
    systems.link(bufferOut1.modulesOut, bufferOut2.modulesIn);
    systems.link(bufferOut2.modulesOut, bufferOut3.modulesIn);
    systems.link(bufferOut3.modulesOut, bufferOut4.modulesIn);
    systems.link(bufferOut4.modulesOut, bufferOut5.modulesIn);
    systems.link(bufferOut5.modulesOut, bufferOut6.modulesIn);
    systems.link(bufferOut6.modulesOut, unLoadingForkLiftTruck.modulesIn);

    // drawers

    var drawerUnloaderLift = ModuleDrawerRowUnloaderReceiver(
      area: this,
      drawerOutDirection: Direction.counterClockWise,
      crossOverFeedOutMetersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor0 = DrawerConveyor90Degrees(
        direction: Direction.clockWise,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

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
        lengthInMeters: 4);

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
        lengthInMeters: 2.9,
        metersPerSecond: drawerConveyorSpeedInMeterPerSecond);

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

    var bufferIn1 = ModuleBufferAngleTransferInFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );
    var bufferIn2 = ModuleBufferConveyor(area: this);
    var bufferIn3 = ModuleBufferConveyor(area: this);
    var bufferIn4 = ModuleBufferConveyor(area: this);
    var bufferIn5 = ModuleBufferConveyor(area: this);
    var bufferIn6 = ModuleBufferAngleTransferOutFeed(
      area: this,
      moduleOutDirection: Direction.counterClockWise,
    );

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3,
      turnPositions: [
        TurnPosition(
            direction: const CompassDirection.east(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.south()),
      ],
    );

    var deStacker =
        ModuleDeStacker(area: this, liftSpeedInCentiMeterPerSecond: 40 //TODO!!
            );

    var mc1 = ModuleConveyor(area: this);

    var mc2 = ModuleConveyor(area: this);

    var drawerUnloader = ModuleDrawerColumnUnloader(
      area: this,
      drawerOutDirection: Direction.clockWise,
    );

    var mc3 = ModuleConveyor(area: this);
    var mc4 = ModuleConveyor(area: this);
    var modulePreWasher =
        ModuleWasherConveyor(area: this, lengthInMeters: 5.5 / 2);

    var moduleMainWasher =
        ModuleWasherConveyor(area: this, lengthInMeters: 5.5 / 2);
    var moduleDrawerLoader = ModuleDrawerLoader(
      area: this,
      drawersInDirection: Direction.clockWise,
    );
    var mrc2 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var stacker = ModuleStacker(area: this);

    var bufferOut1 = ModuleBufferAngleTransferInFeed(
      area: this,
      moduleOutDirection: Direction.counterClockWise,
    );
    var bufferOut2 = ModuleBufferConveyor(area: this);
    var bufferOut3 = ModuleBufferConveyor(area: this);
    var bufferOut4 = ModuleBufferConveyor(area: this);
    var bufferOut5 = ModuleBufferConveyor(area: this);
    var bufferOut6 = ModuleBufferAngleTransferOutFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, bufferIn1.modulesIn);
    systems.link(bufferIn1.modulesOut, bufferIn2.modulesIn);
    systems.link(bufferIn2.modulesOut, bufferIn3.modulesIn);
    systems.link(bufferIn3.modulesOut, bufferIn4.modulesIn);
    systems.link(bufferIn4.modulesOut, bufferIn5.modulesIn);
    systems.link(bufferIn5.modulesOut, bufferIn6.modulesIn);
    systems.link(bufferIn6.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mc1.modulesIn);
    systems.link(mc1.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, drawerUnloader.modulesIn);
    systems.link(drawerUnloader.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, modulePreWasher.modulesIn);
    systems.link(modulePreWasher.modulesOut, moduleMainWasher.modulesIn);
    systems.link(moduleMainWasher.modulesOut, moduleDrawerLoader.modulesIn);
    systems.link(moduleDrawerLoader.modulesOut, mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], stacker.modulesIn);
    systems.link(stacker.modulesOut, bufferOut1.modulesIn);
    systems.link(bufferOut1.modulesOut, bufferOut2.modulesIn);
    systems.link(bufferOut2.modulesOut, bufferOut3.modulesIn);
    systems.link(bufferOut3.modulesOut, bufferOut4.modulesIn);
    systems.link(bufferOut4.modulesOut, bufferOut5.modulesIn);
    systems.link(bufferOut5.modulesOut, bufferOut6.modulesIn);
    systems.link(bufferOut6.modulesOut, unLoadingForkLiftTruck.modulesIn);

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
