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

class DabeSite extends Site {
  DabeSite()
      : super(
          meynLayoutNumber: 7696,
          organizationName: 'Dabe',
          city: 'Beihen',
          country: 'Germany',
          productDefinitions: DabeProductDefinitions(),
        );
}

const dabeCasRecipe = CasRecipe([
  Duration(seconds: 40), //22%, Stage 1
  Duration(seconds: 40), //36%, Stage 2
  Duration(seconds: 40), //43%, Stage 3
  Duration(seconds: 165), //67%, Stage 4
  Duration(seconds: 0), //00%, Stage 5
], Duration(seconds: 10));

/// Dabe:                       ModuleGroup = 2x 6 compartment module
/// Turkey:                     6 birds/compartment @ 3600 birds/hour
class DabeProductDefinitions extends DelegatingList<ProductDefinition> {
  DabeProductDefinitions()
      : super([
          ProductDefinition(
              //83 containers per hour
              areaFactory: _areaFactory(),
              birdType: 'Turkey',
              lineSpeedInShacklesPerHour: 3600,
              lineShacklePitchInInches: 12,
              casRecipe: dabeCasRecipe,
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .marel
                      .gpsk
                      .build()
                      .withBirdsPerCompartment(6),
                  PositionWithinModuleGroup.secondBottom: BrandBuilder()
                      .marel
                      .gpsk
                      .build()
                      .withBirdsPerCompartment(6),
                })
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() => (ProductDefinition productDefinition) =>
          [DabeLiveBirdHandlingArea(productDefinition)];
}

class DabeLiveBirdHandlingArea extends LiveBirdHandlingArea {
  DabeLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Turkey line',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.right,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
            direction: const CompassDirection.south(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedOut: true),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
            direction: const CompassDirection.south(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedOut: true),
      ],
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.south(),
        ),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedOut: true),
      ],
    );

    var cas5 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      slideDoorLeft: false,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      slideDoorLeft: false,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var mc1 = ModuleConveyor(
      area: this,
      lengthInMeters: 3.5,
    );

    var tilter = ModuleTilter(
      area: this,
      tiltDirection: Direction.clockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(
      area: this,
      minBirdsOnDumpBeltBuffer:
          (productDefinition.averageProductsPerModuleGroup).round(),
      maxBirdsOnDumpBeltBuffer:
          (productDefinition.averageProductsPerModuleGroup * 2).round(),
    );

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.counterClockWise,
    );

    var unloadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

// module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas4.modulesIn);
    systems.link(
      cas4.modulesOut,
      mrc1.modulesIns[1],
    );
    systems.link(mrc1.modulesOuts[2], mrc2.modulesIns[0]);
    systems.link(mrc1.modulesOuts[3], cas5.modulesIn);
    systems.link(cas5.modulesOut, mrc1.modulesIns[3]);

    systems.link(mrc2.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);
    systems.link(mrc2.modulesOuts[3], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc2.modulesIns[3]);

    systems.link(mrc3.modulesOuts[1], mc1.modulesIn);
    systems.link(mrc3.modulesOuts[2], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[2]);

    systems.link(mc1.modulesOut, tilter.modulesIn);
    systems.link(tilter.modulesOut, unloadingConveyor.modulesIn);
    systems.link(
        unloadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// bird transport
    systems.link(tilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

    systems.add(ModuleCasAllocation(
      area: this,
      allocationPlace: loadingConveyor.moduleGroupPlace,
    ));

    systems.add(ModuleCasStart(area: this));
  }
}
