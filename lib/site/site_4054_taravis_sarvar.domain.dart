import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_loader/module_drawer_loader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_row_unloader/module_drawer_row_unloader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_allocation.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_start.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';

import 'site.dart';

class TaravisSite extends Site {
  TaravisSite()
    : super(
        meynLayoutNumber: 4054,
        organizationName: 'Taravis',
        city: 'Sárvár',
        country: 'Hungary',
        productDefinitions: ProductDefinitions(),
      );
}

final averageNormalBirdWeight = grams(2500);
final averageHeavyBirdWeight = grams(4250);

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  ProductDefinitions()
    : super([
        ProductDefinition(
          areaFactory: _areaFactory(),
          birdType: '2,5kg in winter @160cm2/kg',
          lineSpeedInShacklesPerHour: 8000,
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
                  .withLoadDensity(
                    LoadDensity.eec64_432(averageNormalBirdWeight, 100),
                    averageNormalBirdWeight,
                  ),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .meyn
                  .grandeDrawer
                  .m4
                  .c2
                  .l4
                  .gs
                  .build()
                  .withLoadDensity(
                    LoadDensity.eec64_432(averageNormalBirdWeight, 100),
                    averageNormalBirdWeight,
                  ),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: _areaFactory(),
          birdType: '2,5kg in summer @177,8cm2/kg',
          lineSpeedInShacklesPerHour: 8000,
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
                  .withLoadDensity(
                    LoadDensity.eec64_432(averageNormalBirdWeight, 90),
                    averageNormalBirdWeight,
                  ),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .meyn
                  .grandeDrawer
                  .m4
                  .c2
                  .l4
                  .gs
                  .build()
                  .withLoadDensity(
                    LoadDensity.eec64_432(averageNormalBirdWeight, 90),
                    averageNormalBirdWeight,
                  ),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: _areaFactory(),
          birdType: '4,25kg in winter @160cm2/kg',
          lineSpeedInShacklesPerHour: 8000,
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
                  .withLoadDensity(
                    LoadDensity.floorSpaceInCm2(
                      minCm2FloorSpacePerKgLiveWeight: 160,
                      loadingPercentage: 100,
                    ),
                    averageHeavyBirdWeight,
                  ),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .meyn
                  .grandeDrawer
                  .m4
                  .c2
                  .l4
                  .gs
                  .build()
                  .withLoadDensity(
                    LoadDensity.floorSpaceInCm2(
                      minCm2FloorSpacePerKgLiveWeight: 160,
                      loadingPercentage: 100,
                    ),
                    averageHeavyBirdWeight,
                  ),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: _areaFactory(),
          birdType: '4,25kg in summer @177,8cm2/kg',
          lineSpeedInShacklesPerHour: 8000,
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
                  .withLoadDensity(
                    LoadDensity.floorSpaceInCm2(
                      minCm2FloorSpacePerKgLiveWeight: 160,
                      loadingPercentage: 90,
                    ),
                    averageHeavyBirdWeight,
                  ),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .meyn
                  .grandeDrawer
                  .m4
                  .c2
                  .l4
                  .gs
                  .build()
                  .withLoadDensity(
                    LoadDensity.floorSpaceInCm2(
                      minCm2FloorSpacePerKgLiveWeight: 160,
                      loadingPercentage: 90,
                    ),
                    averageHeavyBirdWeight,
                  ),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: _areaFactory(),
          birdType: '4,25kg in winter @115cm2/kg',
          lineSpeedInShacklesPerHour: 8000,
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
                  .withLoadDensity(
                    LoadDensity.eec64_432(averageHeavyBirdWeight, 100),
                    averageHeavyBirdWeight,
                  ),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .meyn
                  .grandeDrawer
                  .m4
                  .c2
                  .l4
                  .gs
                  .build()
                  .withLoadDensity(
                    LoadDensity.eec64_432(averageHeavyBirdWeight, 100),
                    averageHeavyBirdWeight,
                  ),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: _areaFactory(),
          birdType: '4,25kg in summer @127,8cm2/kg',
          lineSpeedInShacklesPerHour: 8000,
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
                  .withLoadDensity(
                    LoadDensity.eec64_432(averageHeavyBirdWeight, 90),
                    averageHeavyBirdWeight,
                  ),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .meyn
                  .grandeDrawer
                  .m4
                  .c2
                  .l4
                  .gs
                  .build()
                  .withLoadDensity(
                    LoadDensity.eec64_432(averageHeavyBirdWeight, 90),
                    averageHeavyBirdWeight,
                  ),
            }),
          ],
        ),
      ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
  _areaFactory() =>
      (ProductDefinition productDefinition) => [
        TaravisLiveBirdHandlingArea(productDefinition),
      ];
}

class TaravisLiveBirdHandlingArea extends LiveBirdHandlingArea {
  static const int levelsOfModulesForCasUnits = 2;
  static const int numberOfModuleStacksForCasUnits = 1;

  TaravisLiveBirdHandlingArea(ProductDefinition productDefinition)
    : super(lineName: 'Chicken line', productDefinition: productDefinition);

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east().rotate(30);

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.right,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south().rotate(30)),
        TurnPosition(
          direction: const CompassDirection.east(),
          reverseFeedOut: true,
        ),
        TurnPosition(direction: const CompassDirection.north()),
      ],
    );

    var cas3 = ModuleCas(
      area: this,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: false,
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
          direction: const CompassDirection.east(),
          reverseFeedOut: true,
        ),
        TurnPosition(direction: const CompassDirection.north()),
      ],
    );

    var cas2 = ModuleCas(
      area: this,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: false,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
          direction: const CompassDirection.east(),
          reverseFeedOut: true,
        ),
        TurnPosition(direction: const CompassDirection.north()),
      ],
    );

    var cas1 = ModuleCas(
      area: this,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: false,
    );

    var mc2 = ModuleConveyor(area: this);

    var deStacker = ModuleDeStacker(area: this);

    var mc3 = ModuleConveyor(area: this);

    var unloader = ModuleDrawerRowUnloader(
      area: this,
      drawerOutDirection: Direction.clockWise,
    );

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
      lengthInMeters: 3.7,
    );

    var conveyor7 = DrawerTurningConveyor();

    var conveyor8 = DrawerConveyor90Degrees(
      direction: Direction.clockWise,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var conveyor9 = DrawerConveyorStraight(
      lengthInMeters: 3.1,
      metersPerSecond: drawerConveyorSpeedInMeterPerSecond,
    );

    var drawerLoaderLift = DrawerLoaderLift(area: this);

    var loader = ModuleDrawerLoader(
      area: this,
      drawersInDirection: Direction.clockWise,
    );

    var mc4 = ModuleConveyor(area: this);

    var mc5 = ModuleConveyor(area: this);

    var moduleWasher1 = ModuleWasherConveyor(area: this, lengthInMeters: 2.75);

    var moduleWasher2 = ModuleWasherConveyor(area: this, lengthInMeters: 2.75);

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(direction: const CompassDirection.west()),
      ],
    );

    var stacker = ModuleStacker(area: this);

    var moduleUnLoadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[2], mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);
    systems.link(mrc3.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[2], mc2.modulesIn);
    systems.link(mc2.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, unloader.modulesIn);
    systems.link(unloader.modulesOut, mc4.modulesIn);
    systems.link(unloader.drawersOut, receiver.drawersIn);
    systems.link(mc4.modulesOut, mc5.modulesIn);
    systems.link(mc5.modulesOut, moduleWasher1.modulesIn);
    systems.link(moduleWasher1.modulesOut, moduleWasher2.modulesIn);
    systems.link(moduleWasher2.modulesOut, loader.modulesIn);
    systems.link(loader.modulesOut, mrc4.modulesIns[0]);
    systems.link(mrc4.modulesOuts[1], stacker.modulesIn);
    systems.link(stacker.modulesOut, moduleUnLoadingConveyor.modulesIn);
    systems.link(
      moduleUnLoadingConveyor.modulesOut,
      unLoadingForkLiftTruck.modulesIn,
    );

    /// Drawers
    systems.link(unloader.drawersOut, receiver.drawersIn);
    systems.link(receiver.drawerOut, conveyor0.drawerIn);
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
    systems.link(drawerLoaderLift.drawersOut, loader.drawersIn);

    systems.add(ModuleCasStart(area: this));

    systems.add(
      ModuleCasAllocation(
        area: this,
        allocationPlace: loadingConveyor.moduleGroupPlace,
      ),
    );

    markers.add(Marker(unloader, unloader.shape.centerToDrawersOutLink));
    markers.add(
      Marker(unloader, unloader.shape.centerToLiftConveyorDrawerCenters[0]),
    );
    markers.add(
      Marker(unloader, unloader.shape.centerToLiftConveyorDrawerCenters[1]),
    );
    markers.add(
      Marker(
        receiver,
        receiver.shape.centerToReceivingConveyorDrawerCenters[0],
      ),
    );
    markers.add(
      Marker(
        receiver,
        receiver.shape.centerToReceivingConveyorDrawerCenters[1],
      ),
    );
    markers.add(
      Marker(
        receiver,
        receiver.shape.centerToCrossOverConveyorDrawerCenters[0],
      ),
    );
    markers.add(
      Marker(
        receiver,
        receiver.shape.centerToCrossOverConveyorDrawerCenters[1],
      ),
    );
    markers.add(
      Marker(receiver, receiver.shape.centerToFeedOutConveyorOutLink),
    );
  }
}
