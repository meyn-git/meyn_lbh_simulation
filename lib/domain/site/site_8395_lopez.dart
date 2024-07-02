import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter_dump_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

import 'site.dart';

class LopezSite extends Site {
  LopezSite()
      : super(
          meynLayoutNumber: 8359,
          organizationName: 'Lopez',
          city: '',
          country: 'Spain',
          productDefinitions: ProductDefinitions(),
        );
}

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactory3CASUnits(),
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: 3300,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              moduleSystem: ModuleSystem.meynSingleColumnContainers,
              moduleFamily: ModuleFamily.marelGpSingleColumn,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  // bird weight min: 2,3 avr: 2,8 max 3kg
                  firstModule: ModuleCapacity(
                      levels: 4,
                      compartmentsPerLevel: 2,
                      birdsPerCompartment: 24),
                  secondModule: ModuleCapacity(
                      levels: 5,
                      compartmentsPerLevel: 2,
                      birdsPerCompartment: 24),
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory3CASUnits() => (ProductDefinition productDefinition) =>
          [AreaWith3CASUnits(productDefinition)];
}

class AreaWith3CASUnits extends LiveBirdHandlingArea {
  AreaWith3CASUnits(ProductDefinition productDefinition)
      : super(
          lineName: 'Chicken',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east();

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
            direction: const CompassDirection.west(), reverseFeedIn: true),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
      turnPositions: [
        TurnPosition(
          direction: const CompassDirection.west(),
        ),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
      turnPositions: [
        TurnPosition(
          direction: const CompassDirection.west(),
        ),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var tilter = ModuleTilter(
      area: this,
      tiltToLeft: true,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      toLeft: false,
    );

    var birdDetection = ModuleConveyor(area: this);

    var modulePreWasher = ModuleConveyor(
      area: this,
      lengthInMeters: 5.55,
    );

    var moduleMainWasher = ModuleConveyor(
      area: this,
      lengthInMeters: 5.55,
    );

    var unloadConveyor = ModuleConveyor(
      area: this,
      lengthInMeters: 3.75,
    );

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    /// Module Transport
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
    systems.link(mrc3.modulesOuts[2], tilter.modulesIn);
    systems.link(tilter.modulesOut, birdDetection.modulesIn);
    systems.link(birdDetection.modulesOut, modulePreWasher.modulesIn);
    systems.link(modulePreWasher.modulesOut, moduleMainWasher.modulesIn);
    systems.link(moduleMainWasher.modulesOut, unloadConveyor.modulesIn);
    systems.link(unloadConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// Bird transport
    systems.link(tilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

    systems.add(ModuleCasAllocation(
      area: this,
      allocationPlace: loadingConveyor.moduleGroupPlace,
    ));

    systems.add(ModuleCasStart(area: this));
  }
}
