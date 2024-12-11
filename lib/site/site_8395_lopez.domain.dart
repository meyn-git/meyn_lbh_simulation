import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter_dump_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
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
              truckRows: [
                TruckRow(
                    // bird weight min: 2,3 avr: 2,8 max 3kg
                    {
                      PositionWithinModuleGroup.firstBottom: BrandBuilder()
                          .marel
                          .gps
                          .l4
                          .build()
                          .withBirdsPerCompartment(24),
                      PositionWithinModuleGroup.secondBottom: BrandBuilder()
                          .marel
                          .gps
                          .l5
                          .build()
                          .withBirdsPerCompartment(24),
                    })
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

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
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
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
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
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
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

    var mc0 = ModuleConveyor(area: this);

    var tilter = ModuleTilter(
      area: this,
      tiltDirection: Direction.counterClockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.clockWise,
    );

    var birdDetection = ModuleConveyor(area: this);

    var modulePreWasher = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 5.55,
    );

    var moduleMainWasher = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 5.55,
    );

    var unloadConveyor = ModuleUnLoadingConveyor(area: this);

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
    systems.link(mrc3.modulesOuts[2], mc0.modulesIn);
    systems.link(mc0.modulesOut, tilter.modulesIn);
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
