import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter_dump_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
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
                  [Area(productDefinition)],
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 9300,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynVdlRectangularContainers,
              moduleFamily: ModuleFamily.marelGpSingleColumn,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                    firstModule: MarelGpStainlessSteel2x4Chicken()
                        .dimensions
                        .capacityWithBirdsPerCompartment(37),
                    secondModule: MarelGpStainlessSteel2x4Chicken()
                        .dimensions
                        .capacityWithBirdsPerCompartment(37))
              ]),
        ]);
}

class Area extends LiveBirdHandlingArea {
  Area(ProductDefinition productDefinition)
      : super(
          lineName: 'Line 1',
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
        lengthInMeters: 3.2);

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
      tiltToLeft: true,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(
        area: this,
        minBirdsOnDumpBeltBuffer:
            productDefinition.moduleGroupCapacities.first.numberOfBirds,
        lengthInMeters: 3.2);

    var shackleConveyor = ShackleConveyor(
      area: this,
      toLeft: false,
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
