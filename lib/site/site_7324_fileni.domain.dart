import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter_dump_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shackle_conveyor/shackle_conveyor.domain.dart';
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
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';

import 'site.dart';

class FileniSite extends Site {
  FileniSite()
    : super(
        meynLayoutNumber: 7324,
        organizationName: 'Fileni',
        city: 'Castelplanio',
        country: 'Italy',
        productDefinitions: FileniProductDefinitions(),
      );
}

/// Fileni chicken: ModuleGroup = 4 and 5 compartment module
/// Pollo Bio:                  26 birds/compartment @ 8000 birds/hour
/// Pollo RUSTICANELLO Pesante: 33 birds/compartment @ 6000 birds/hour
/// Pollo RUSTICANELLO :        52 birds/compartment @ 7000 birds/hour
/// Pollo PICCOLO:              54 birds/compartment @ 10000 birds/hour
class FileniProductDefinitions extends DelegatingList<ProductDefinition> {
  FileniProductDefinitions()
    : super([
        ProductDefinition(
          //2,82286 stacks per hour
          areaFactory: _areaFactory(),
          birdType: 'Pollo Bio',
          lineSpeedInShacklesPerHour: 8000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom: BrandBuilder().marel.gps.l5
                  .build()
                  .withBirdsPerCompartment(26),
              PositionWithinModuleGroup.secondBottom: BrandBuilder()
                  .marel
                  .gps
                  .l4
                  .build()
                  .withBirdsPerCompartment(26),
            }),
          ],
        ),
        ProductDefinition(
          // 1,3 stacks per hour
          areaFactory: _areaFactory(),
          birdType: 'Pollo RUSTICANELLO Pesante',
          lineSpeedInShacklesPerHour: 6000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom: BrandBuilder().marel.gps.l5
                  .build()
                  .withBirdsPerCompartment(33),
              PositionWithinModuleGroup.secondBottom: BrandBuilder()
                  .marel
                  .gps
                  .l4
                  .build()
                  .withBirdsPerCompartment(33),
            }),
          ],
        ),
        ProductDefinition(
          //0.6319997 stacks per hour
          areaFactory: _areaFactory(),
          birdType: 'Pollo RUSTICANELLO',
          lineSpeedInShacklesPerHour: 7000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom: BrandBuilder().marel.gps.l5
                  .build()
                  .withBirdsPerCompartment(52),
              PositionWithinModuleGroup.secondBottom: BrandBuilder()
                  .marel
                  .gps
                  .l4
                  .build()
                  .withBirdsPerCompartment(52),
            }),
          ],
        ),
        ProductDefinition(
          //0,8379
          areaFactory: _areaFactory(),
          birdType: 'Pollo PICCOLO',
          lineSpeedInShacklesPerHour: 10000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom: BrandBuilder().marel.gps.l5
                  .build()
                  .withBirdsPerCompartment(54),
              PositionWithinModuleGroup.secondBottom: BrandBuilder()
                  .marel
                  .gps
                  .l4
                  .build()
                  .withBirdsPerCompartment(54),
            }),
          ],
        ),
      ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
  _areaFactory() =>
      (ProductDefinition productDefinition) => [
        FileniLiveBirdHandlingArea(productDefinition),
      ];
}

class FileniLiveBirdHandlingArea extends LiveBirdHandlingArea {
  static const int levelsOfModulesForCasUnits = 1;
  static const int numberOfModuleStacksForCasUnits = 2;

  FileniLiveBirdHandlingArea(ProductDefinition productDefinition)
    : super(lineName: 'Chicken line', productDefinition: productDefinition);

  @override
  void createSystemsAndLinks() {
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.right,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mc1 = ModuleConveyor(area: this, lengthInMeters: 3.75);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
      ],
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
      ],
    );

    var cas5 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesForCasUnits,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var mc2 = ModuleConveyor(area: this, lengthInMeters: 3.5);

    var tilter = ModuleTilter(area: this, tiltDirection: Direction.clockWise);

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.counterClockWise,
    );

    var unloadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    // module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mrc2.modulesIns[0]);
    systems.link(mrc1.modulesOuts[2], cas5.modulesIn);
    systems.link(cas5.modulesOut, mrc1.modulesIns[2]);

    systems.link(mrc2.modulesOuts[1], cas4.modulesIn);
    systems.link(cas4.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);
    systems.link(mrc2.modulesOuts[3], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc2.modulesIns[3]);

    systems.link(mrc3.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[2], mc2.modulesIn);
    systems.link(mrc3.modulesOuts[3], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[3]);

    systems.link(mc2.modulesOut, tilter.modulesIn);
    systems.link(tilter.modulesOut, unloadingConveyor.modulesIn);
    systems.link(
      unloadingConveyor.modulesOut,
      unLoadingForkLiftTruck.modulesIn,
    );

    /// bird transport
    systems.link(tilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdsIn);

    systems.add(
      ModuleCasAllocation(area: this, allocationPlace: mc1.moduleGroupPlace),
    );

    systems.add(ModuleCasStart(area: this));
  }
}
