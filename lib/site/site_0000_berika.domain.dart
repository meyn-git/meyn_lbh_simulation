import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_buffer_lane/module_buffer_lane.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter_dump_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shackle_conveyor/shackle_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
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

class BerikaSite extends Site {
  BerikaSite()
      : super(
          meynLayoutNumber: 0000,
          organizationName: 'Berika',
          city: '?',
          country: 'Norway',
          productDefinitions: ProductDefinitions(),
        );
}

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.stunSingle)],
              birdType: '208 chickens/module',
              lineSpeedInShacklesPerHour: birdsPerHour,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .marel
                      .gpl
                      .l4
                      .build()
                      .withBirdsPerCompartment(26),
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.stunSingle)],
              birdType: '240 chickens/module',
              lineSpeedInShacklesPerHour: birdsPerHour,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .marel
                      .gpl
                      .l4
                      .build()
                      .withBirdsPerCompartment(30), //26
                }),
              ]),
          // ProductDefinition(
          //     areaFactory: (ProductDefinition productDefinition) =>
          //         [Area(productDefinition, Layout.stunStacked)],
          //     birdType: '208 chickens/module',
          //     lineSpeedInShacklesPerHour: birdsPerHour,
          //     lineShacklePitchInInches: 6,
          //     casRecipe: const CasRecipe.standardChickenRecipe(),
          //     truckRows: [
          //       TruckRow({
          //         PositionWithinModuleGroup.firstBottom: BrandBuilder()
          //             .marel
          //             .gpl
          //             .l4
          //             .build()
          //             .withBirdsPerCompartment(26),
          //         PositionWithinModuleGroup.firstTop: BrandBuilder()
          //             .marel
          //             .gpl
          //             .l4
          //             .build()
          //             .withBirdsPerCompartment(26),
          //       })
          //     ]),
          // ProductDefinition(
          //     areaFactory: (ProductDefinition productDefinition) =>
          //         [Area(productDefinition, Layout.stunStacked)],
          //     birdType: '240 chickens/module',
          //     lineSpeedInShacklesPerHour: birdsPerHour,
          //     lineShacklePitchInInches: 6,
          //     casRecipe: const CasRecipe.standardChickenRecipe(),
          //     truckRows: [
          //       TruckRow({
          //         PositionWithinModuleGroup.firstBottom: BrandBuilder()
          //             .marel
          //             .gpl
          //             .l4
          //             .build()
          //             .withBirdsPerCompartment(30),
          //         PositionWithinModuleGroup.firstTop: BrandBuilder()
          //             .marel
          //             .gpl
          //             .l4
          //             .build()
          //             .withBirdsPerCompartment(30),
          //       }),
          //     ]),
        ]);

  static int get birdsPerHour => 5000;
}

enum Layout {
  stunSingle('Stun Single Containers'),
  stunStacked('Stun Stacked Containers');

  final String name;
  const Layout(this.name);
}

class Area extends LiveBirdHandlingArea {
  final Layout layoutType;
  Area(ProductDefinition productDefinition, this.layoutType)
      : super(
          lineName: layoutType.name,
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east();
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var loadingConveyor = ModuleLoadingConveyor(
      area: this,
    );

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.omnia,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedIn: true),
        TurnPosition(
            direction: const CompassDirection.east(), reverseFeedIn: true),
        if (layoutType == Layout.stunSingle)
          TurnPosition(
              direction: const CompassDirection.south(), reverseFeedOut: true),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.omnia,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.east()),
        if (layoutType == Layout.stunSingle)
          TurnPosition(
              direction: const CompassDirection.south(), reverseFeedOut: true),
      ],
    );

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      moduleDoor: ModuleDoor.slideDoorToLeft,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var mc1 = ModuleConveyor(area: this);

    var destacker = ModuleDeStacker(area: this);

    var tilter = ModuleTilter(
      area: this,
      tiltDirection: Direction.counterClockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(
        area: this,
        minBirdsOnDumpBeltBuffer: (208 * 0.5).round(),
        maxBirdsOnDumpBeltBuffer: (208 * 1.5).round());

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.clockWise,
    );

    var mc2 = ModuleConveyor(area: this);

    var mc3 = ModuleConveyor(area: this);

    var bufferOut1_1 = ModuleBufferAngleTransferInFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );
    var bufferOut1_2 = ModuleBufferConveyor(area: this);
    var bufferOut1_3 = ModuleBufferConveyor(area: this);
    var bufferOut1_4 = ModuleBufferConveyor(area: this);
    var bufferOut1_5 = ModuleBufferAngleTransferOutFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );

    var mainWasher1 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.4,
    );

    var mainWasher2 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.4,
    );

    var mc4 = ModuleConveyor(area: this);

    var bufferOut2_1 = ModuleBufferAngleTransferInFeed(
      area: this,
      moduleOutDirection: Direction.counterClockWise,
    );
    var bufferOut2_2 = ModuleBufferConveyor(area: this);
    var bufferOut2_3 = ModuleBufferConveyor(area: this);
    var bufferOut2_4 = ModuleBufferConveyor(area: this);
    var bufferOut2_5 = ModuleBufferAngleTransferOutFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(
      area: this,
      //    stackModules: true,
    );

// module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[2], mrc2.modulesIns[0]);
    if (layoutType == Layout.stunSingle) {
      systems.link(mrc1.modulesOuts[3], cas4.modulesIn);
      systems.link(cas4.modulesOut, mrc1.modulesIns[3]);
    }

    systems.link(mrc2.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc2.modulesIns[1]);
    if (layoutType == Layout.stunSingle) {
      systems.link(mrc2.modulesOuts[3], cas2.modulesIn);
      systems.link(cas2.modulesOut, mrc2.modulesIns[3]);
    }
    if (layoutType == Layout.stunSingle) {
      systems.link(mrc2.modulesOuts[2], mc1.modulesIn);
      systems.link(mc1.modulesOut, tilter.modulesIn);
    } else {
      systems.link(mrc2.modulesOuts[2], destacker.modulesIn);
      systems.link(destacker.modulesOut, tilter.modulesIn);
    }
    systems.link(tilter.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, bufferOut1_1.modulesIn);
    systems.link(bufferOut1_1.modulesOut, bufferOut1_2.modulesIn);
    systems.link(bufferOut1_2.modulesOut, bufferOut1_3.modulesIn);
    systems.link(bufferOut1_3.modulesOut, bufferOut1_4.modulesIn);
    systems.link(bufferOut1_4.modulesOut, bufferOut1_5.modulesIn);

    systems.link(bufferOut1_5.modulesOut, mainWasher1.modulesIn);
    systems.link(mainWasher1.modulesOut, mainWasher2.modulesIn);
    systems.link(mainWasher2.modulesOut, mc4.modulesIn);

    systems.link(mc4.modulesOut, bufferOut2_1.modulesIn);
    systems.link(bufferOut2_1.modulesOut, bufferOut2_2.modulesIn);
    systems.link(bufferOut2_2.modulesOut, bufferOut2_3.modulesIn);
    systems.link(bufferOut2_3.modulesOut, bufferOut2_4.modulesIn);
    systems.link(bufferOut2_4.modulesOut, bufferOut2_5.modulesIn);

    systems.link(bufferOut2_5.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// bird transport
    systems.link(tilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

    systems.add(ModuleCasAllocation(
      area: this,
      allocationPlace: loadingConveyor.moduleGroupPlace,
    ));

    systems.add(ModuleCasStart(
      area: this,
      startIntervalFractions: <double>[
        0.8,
        1,
        1.33,
        1.66,
        2,
        2.33,
      ],
    ));
  }
}
