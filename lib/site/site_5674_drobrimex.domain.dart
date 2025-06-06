import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_row_unloader/module_drawer_row_unloader.domain.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
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
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';

import 'site.dart';

class DobrimexSite extends Site {
  DobrimexSite()
    : super(
        meynLayoutNumber: 5674,
        organizationName: 'Drobrimex',
        city: 'Szczecin',
        country: 'Poland',
        productDefinitions: DobrimexProductDefinitions(),
      );
}

class DobrimexProductDefinitions extends DelegatingList<ProductDefinition> {
  DobrimexProductDefinitions()
    : super([
        ProductDefinition(
          areaFactory: _areaFactory(DobrimexAreaType.sixCasUnits),
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 15000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: _areaFactory(DobrimexAreaType.fiveCasUnits),
          birdType: 'Chicken',

          /// Running a too high line speed so we can determine the actual
          /// hanged birds/hour, by monitoring the [ShackleLine].
          lineSpeedInShacklesPerHour: 16500,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: _areaFactory(DobrimexAreaType.fiveCasUnits),
          birdType: 'Chicken',

          /// Runs 14200 b/h theoretically (see previous product definition),
          /// Assuming we need 10% margin = 14200 *0.9=12780 b/h
          lineSpeedInShacklesPerHour: 12780,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: _areaFactory(DobrimexAreaType.sixCasUnits),
          birdType: 'Chicken',

          /// Running a too high line speed so we can determine the actual
          /// hanged birds/hour, by monitoring the [ShackleLine].
          lineSpeedInShacklesPerHour: 19800,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: _areaFactory(DobrimexAreaType.sixCasUnits),
          birdType: 'Chicken',

          /// Runs 17100 b/h theoretically (see previous product definition),
          /// Assuming we need 10% margin = 17100 *0.9=15390 b/h
          lineSpeedInShacklesPerHour: 15390,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
              PositionWithinModuleGroup.firstTop: BrandBuilder()
                  .angliaAutoFlow
                  .chicken
                  .smallBirds
                  .l4
                  .build()
                  .withBirdsPerCompartment(15),
            }),
          ],
        ),
      ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition) _areaFactory(
    DobrimexAreaType areaType,
  ) =>
      (ProductDefinition productDefinition) => [
        DobrimexLiveBirdHandlingArea(productDefinition, areaType),
      ];
}

enum DobrimexAreaType { fiveCasUnits, sixCasUnits }

/// See "\\meyn.nl\project\acaddrwg\5674 Drobimex - Heintz - Poland\2021\02 - Meyn drawings\Sales\5674s138z00i1.dwg"
/// See https://meyn-git.github.io/meyn_lbh_simulation_web/
class DobrimexLiveBirdHandlingArea extends LiveBirdHandlingArea {
  final DobrimexAreaType areaType;

  DobrimexLiveBirdHandlingArea(
    ProductDefinition productDefinition,
    this.areaType,
  ) : super(lineName: 'Line 1', productDefinition: productDefinition);

  static const drawerSpeedInMetersPerSecond = 0.5;

  static const int levelsOfModulesForCasUnits = 2;
  static const int numberOfModuleStacksForCasUnits = 1;

  @override
  void createSystemsAndLinks() {
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.bothSides,
    );
    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
          direction: const CompassDirection.west(),
          reverseFeedOut: true,
        ),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
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
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
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
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
      ],
    );

    ModuleCas? cas6;
    if (areaType == DobrimexAreaType.sixCasUnits) {
      cas6 = ModuleCas(
        area: this,
        gasDuctsLeft: true,
        numberOfModuleStacks: numberOfModuleStacksForCasUnits,
        levelsOfModules: levelsOfModulesForCasUnits,
        moduleDoor: ModuleDoor.slideDoorToLeft,
      );
    }

    var cas5 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var deStacker = ModuleDeStacker(area: this);

    var mc1 = ModuleConveyor(area: this);

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.short,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(direction: const CompassDirection.south()),
      ],
    );

    var mc2 = ModuleConveyor(area: this);

    var mc3 = ModuleConveyor(area: this);

    /// Drawer line 1
    var unloader1 = ModuleDrawerRowUnloader(
      area: this,
      drawerOutDirection: Direction.counterClockWise,
    );

    var receiver1 = ModuleDrawerRowUnloaderReceiver(
      area: this,
      drawerOutDirection: Direction.counterClockWise,
      crossOverFeedOutMetersPerSecond: drawerSpeedInMetersPerSecond,
    );

    var dc1a = DrawerConveyor90Degrees(
      direction: Direction.clockWise,
      metersPerSecond: drawerSpeedInMetersPerSecond,
    );

    var dc1b = DrawerConveyorStraight(
      lengthInMeters: 3,
      metersPerSecond: drawerSpeedInMetersPerSecond,
    );

    var hangingConveyor1 = DrawerHangingConveyor(
      allDrawers: drawers,
      hangers: 11,
      metersPerSecondOfFirstConveyor: drawerSpeedInMetersPerSecond,
      productDefinition: productDefinition,
    );

    var dc1c = DrawerRemover(
      area: this,
      metersPerSecond: drawerSpeedInMetersPerSecond,
    );

    /// Drawer line 2
    var unloader2 = ModuleDrawerRowUnloader(
      area: this,
      drawerOutDirection: Direction.counterClockWise,
    );

    var receiver2 = ModuleDrawerRowUnloaderReceiver(
      area: this,
      drawerOutDirection: Direction.clockWise,
      crossOverFeedOutMetersPerSecond: drawerSpeedInMetersPerSecond,
    );

    var dc2a = DrawerConveyor90Degrees(
      direction: Direction.counterClockWise,
      metersPerSecond: drawerSpeedInMetersPerSecond,
    );

    var dc2b = DrawerConveyorStraight(
      lengthInMeters: 3,
      metersPerSecond: drawerSpeedInMetersPerSecond,
    );

    var hangingConveyor2 = DrawerHangingConveyor(
      allDrawers: drawers,
      hangers: 11,
      metersPerSecondOfFirstConveyor: drawerSpeedInMetersPerSecond,
      productDefinition: productDefinition,
    );

    var dc2c = DrawerRemover(
      area: this,
      metersPerSecond: drawerSpeedInMetersPerSecond,
    );

    var unloadConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    if (areaType == DobrimexAreaType.sixCasUnits) {
      systems.link(mrc1.modulesOuts[1], cas6!.modulesIn);
      systems.link(cas6.modulesOut, mrc1.modulesIns[1]);
    }
    systems.link(mrc1.modulesOuts[2], cas5.modulesIn);
    systems.link(cas5.modulesOut, mrc1.modulesIns[2]);
    systems.link(mrc1.modulesOuts[3], mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[3], cas4.modulesIn);
    systems.link(cas4.modulesOut, mrc2.modulesIns[3]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);
    systems.link(mrc3.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[3], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc3.modulesIns[3]);
    systems.link(mrc3.modulesOuts[2], deStacker.modulesIn);
    systems.link(deStacker.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, mrc4.modulesIns[0]);
    systems.link(mrc4.modulesOuts[1], mc2.modulesIn);
    systems.link(mc2.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, unloader1.modulesIn);
    systems.link(unloader1.modulesOut, unloader2.modulesIn);
    systems.link(unloader2.modulesOut, unloadConveyor.modulesIn);
    systems.link(unloadConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    // drawers line 1
    systems.link(unloader1.drawersOut, receiver1.drawersIn);
    systems.link(receiver1.drawerOut, dc1a.drawerIn);
    systems.link(dc1a.drawerOut, dc1b.drawerIn);
    systems.link(dc1b.drawerOut, hangingConveyor1.drawerIn);
    systems.link(hangingConveyor1.drawerOut, dc1c.drawerIn);

    // drawers line 2
    systems.link(unloader2.drawersOut, receiver2.drawersIn);
    systems.link(receiver2.drawerOut, dc2a.drawerIn);
    systems.link(dc2a.drawerOut, dc2b.drawerIn);
    systems.link(dc2b.drawerOut, hangingConveyor2.drawerIn);
    systems.link(hangingConveyor2.drawerOut, dc2c.drawerIn);

    systems.add(
      ModuleCasAllocation(
        area: this,
        allocationPlace: loadingConveyor.moduleGroupPlace,
      ),
    );

    systems.add(ModuleCasStart(area: this));
  }
}
