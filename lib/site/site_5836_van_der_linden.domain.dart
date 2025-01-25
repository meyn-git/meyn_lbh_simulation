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

class VanDerLindenSite extends Site {
  VanDerLindenSite()
      : super(
          meynLayoutNumber: 5836,
          organizationName: 'VanDerLinden',
          city: 'Panningen',
          country: 'Nederland',
          productDefinitions: VanDerLindenProductDefinitions(),
        );
}

class VanDerLindenProductDefinitions extends DelegatingList<ProductDefinition> {
  VanDerLindenProductDefinitions()
      : super([
          ProductDefinition(
              //2,82286 stacks per hour
              areaFactory: _areaFactory(),
              birdType: 'Kuikens',
              lineSpeedInShacklesPerHour: 7000,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                /// according to:  \\meyn.nl\project\acaddrwg\5836 Van der Linden - The Netherlands\2021\02 - Meyn drawings\Sales\5836s102z00b1-Model.pdf
                /// min = 192 per container (190)
                /// mac = 252 per container
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .marel
                      .gps
                      .l5
                      .build()
                      .withBirdsPerCompartment((190 / 5).round()),
                  PositionWithinModuleGroup.secondBottom: BrandBuilder()
                      .marel
                      .gps
                      .l5
                      .build()
                      .withBirdsPerCompartment((190 / 5).round()),
                })
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [VanDerLindenLiveBirdHandlingArea(productDefinition)];
}

/// See \\meyn.nl\project\acaddrwg\5836 Van der Linden - The Netherlands\2021\02 - Meyn drawings\Sales\5836s102z00b1-Model.pdf
/// See: https://meyn-git.github.io/meyn_lbh_simulation_web/
class VanDerLindenLiveBirdHandlingArea extends LiveBirdHandlingArea {
  VanDerLindenLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Chicken line',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.right,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
            direction: const CompassDirection.west(), reverseFeedIn: true),
        TurnPosition(
            direction: const CompassDirection.east(), reverseFeedOut: true),
        TurnPosition(direction: const CompassDirection.north()),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
            direction: const CompassDirection.west(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.north()),
      ],
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var mc2 = ModuleConveyor(area: this, lengthInMeters: 3.5);

    var moduleTilter = ModuleTilter(
      area: this,
      tiltDirection: Direction.clockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.clockWise,
    );

    var unloadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    /// module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[2], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc1.modulesIns[2]);
    systems.link(mrc1.modulesOuts[3], mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mc2.modulesIn);
    systems.link(mc2.modulesOut, moduleTilter.modulesIn);
    systems.link(moduleTilter.modulesOut, unloadingConveyor.modulesIn);
    systems.link(
        unloadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// bird transport
    systems.link(moduleTilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

    systems.add(ModuleCasAllocation(
        area: this, allocationPlace: loadingConveyor.moduleGroupPlace));

    systems.add(ModuleCasStart(area: this));
  }
}
