import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/module/brand.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter_dump_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_lift_position.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

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
              moduleSystem: ModuleSystem.meynSingleColumnContainers,
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

    /// Hack: mimicking a merging conveyor: 2 x singe [ModuleGroup] from fork lift truck into 1
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    // var mc1 = ModuleStacker(
    //   area: this,
    //   heightsInCentiMeter: const {
    //     LiftPosition.inFeed: 0,
    //     LiftPosition.outFeed: 0,
    //     LiftPosition.pickUpTopModule: 0,
    //     LiftPosition.supportTopModule: 0,
    //   },
    //   supportsCloseDuration: Duration.zero,
    //   supportsOpenDuration: Duration.zero,
    // );

    var mc1 = ModuleConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.2,
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
      lengthInMeters: 3.2,
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
      slideDoorLeft: false,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      slideDoorLeft: false,
    );

    /// Hack: mimicking a de-merging conveyor: 1 [ModuleGroup] => 2x [ModuleGroup] to tilter
    /// heights are therefore all 0 and no [supportsCloseDuration] or [supportsOpenDuration]
    var mc2 = ModuleDeStacker(
      area: this,
      heightsInCentiMeter: const {
        LiftPosition.inFeed: 0,
        LiftPosition.outFeed: 0,
        LiftPosition.pickUpTopModule: 0,
        LiftPosition.supportTopModule: 0,
      },
      supportsCloseDuration: Duration.zero,
      supportsOpenDuration: Duration.zero,
    );

    var moduleTilter = ModuleTilter(
      area: this,
      tiltDirection: Direction.clockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.clockWise,
    );

    var mc3 = ModuleConveyor(area: this, lengthInMeters: 3);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    /// module transport
    systems.link(loadingForkLiftTruck.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[2], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc1.modulesIns[2]);
    systems.link(mrc1.modulesOuts[3], mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mc2.modulesIn);
    systems.link(mc2.modulesOut, moduleTilter.modulesIn);
    systems.link(moduleTilter.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// bird transport
    systems.link(moduleTilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

    systems.add(
        ModuleCasAllocation(area: this, allocationPlace: mc1.moduleGroupPlace));

    systems.add(ModuleCasStart(area: this));
  }
}
