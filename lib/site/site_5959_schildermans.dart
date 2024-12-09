import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_buffer_lane/module_buffer_lane.domain.dart';
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
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';

import 'site.dart';

class SchildermansSite extends Site {
  SchildermansSite()
      : super(
          meynLayoutNumber: 5959,
          organizationName: 'Schildermans',
          city: 'Bree',
          country: 'Belgium',
          productDefinitions: ProductDefinitions(),
        );
}

///
/// See "\\meyn.nl\project\acaddrwg\8052 Indrol - Grodzisk - Poland\2024\02 - Meyn drawings\Sales\8052DB03A0001.dwg"
///
/// Modules:
/// - 1 CAS batch = 2 stacked modules
/// - 1 module = 3 levels
/// - 1 level = max 300 kg
///
///  Female turkeys:
///  - line speed: 3600 birds/hour
///  - live weight: min:8.500g, avr:10.000g, max 11.500g
///  - min birds: 300/11.5kg= 26 birds/level x 3 levels= 78 birds per module
///  - avr birds: 300/10kg=  30 birds/level x 3 levels= 90 birds per module
///  - max birds: 300/8.5kg= 35 birds/level x 3 levels= 105 birds per module
///
///  Male turkeys:
///  - line speed: 1800 birds/hour
///  - live weight: min:18.000g, avr:20.000g, max 23.000g
///  - min birds: 300/23kg= 13 birds/level x 3 levels= 39 birds per module
///  - avr birds: 300/20kg= 15 birds/level x 3 levels= 45 birds per module
///  - max birds: 300/18kg= 16 birds/level x 3 levels= 48 birds per module

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  // static final ModuleTemplate femaleTurkeyMaxWeightCapacity = BrandBuilder()
  //     .meyn
  //     .omnia
  //     .build()
  //     .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(11.5)));

  // static final ModuleTemplate femaleTurkeyAverageWeightCapacity = BrandBuilder()
  //     .meyn
  //     .omnia
  //     .build()
  //     .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(10.0)));
  // static final ModuleTemplate femaleTurkeyMinWeightCapacity = BrandBuilder()
  //     .meyn
  //     .omnia
  //     .build()
  //     .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(8.5)));

  // static final ModuleTemplate maleTurkeyMaxWeightCapacity = BrandBuilder()
  //     .meyn
  //     .omnia
  //     .build()
  //     .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(23)));
  // static final ModuleTemplate maleTurkeyAverageWeightCapacity = BrandBuilder()
  //     .meyn
  //     .omnia
  //     .build()
  //     .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(20)));
  // static final ModuleTemplate maleTurkeyMinWeightCapacity = BrandBuilder()
  //     .meyn
  //     .omnia
  //     .build()
  //     .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(18)));

  // /// Info from Maurizio @ Indrol on 2024-09-18
  // static final ModuleTemplate maleTurkeyGivenCapacity =
  //     BrandBuilder().meyn.omnia.build().withBirdsPerCompartment(36 ~/ 6);

  // /// Info from Maurizio @ Indrol on 2024-09-18
  // static final ModuleTemplate femaleTurkeyGivenCapacity =
  //     BrandBuilder().meyn.omnia.build().withBirdsPerCompartment(80 ~/ 6);

  static int lineSpeed = 9000;

  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition)],
              birdType: 'Chicken',
              lineSpeedInShacklesPerHour: lineSpeed,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .marel
                      .gpl
                      .l5
                      .build()
                      .withBirdsPerCompartment(25),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .marel
                      .gpl
                      .l4
                      .build()
                      .withBirdsPerCompartment(25),
                })
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
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.right,
    );

    var loadingConveyor = ModuleLoadingConveyor(
      area: this,
    );

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(direction: const CompassDirection.south()),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(
            direction: const CompassDirection.east(), reverseFeedOut: true),
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
            direction: const CompassDirection.west(), reverseFeedIn: true),
      ],
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(
            direction: const CompassDirection.east(), reverseFeedOut: true),
        TurnPosition(direction: const CompassDirection.west()),
      ],
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

    var deStacker = ModuleDeStacker(area: this); //TODO add Indroll parameters

    var grossWeigher = ModuleConveyor(area: this);

    var tilter = ModuleTilter(
      //TODO add Indroll parameters
      area: this,
      tiltDirection: Direction.clockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.counterClockWise,
    );

    var tareWeigher = ModuleConveyor(area: this);

    var mc1 = ModuleConveyor(area: this);

    var preWasher = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.8,
    );

    var moduleWasher1 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.8,
    );

    var moduleWasher2 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.8,
    );

    var moduleWasher3 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.8,
    );

    var buffer1_1 = ModuleBufferAngleTransferInFeed(
      area: this,
      moduleOutDirection: Direction.counterClockWise,
    );
    var buffer1_2 = ModuleBufferConveyor(area: this);
    var buffer1_3 = ModuleBufferAngleTransferOutFeed(
      area: this,
      moduleOutDirection: Direction.counterClockWise,
    );

    var stacker = ModuleStacker(area: this);

    var unloadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

// module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mrc2.modulesIns[0]);

    systems.link(mrc2.modulesOuts[1], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);
    systems.link(mrc2.modulesOuts[3], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc2.modulesIns[3]);

    systems.link(mrc3.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[2], grossWeigher.modulesIn);
    systems.link(grossWeigher.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, tilter.modulesIn);
    systems.link(tilter.modulesOut, tareWeigher.modulesIn);
    systems.link(tareWeigher.modulesOut, preWasher.modulesIn);
    systems.link(preWasher.modulesOut, buffer1_1.modulesIn);
    systems.link(buffer1_1.modulesOut, buffer1_2.modulesIn);
    systems.link(buffer1_2.modulesOut, buffer1_3.modulesIn);
    systems.link(buffer1_3.modulesOut, moduleWasher1.modulesIn);
    systems.link(moduleWasher1.modulesOut, moduleWasher2.modulesIn);
    systems.link(moduleWasher2.modulesOut, moduleWasher3.modulesIn);
    systems.link(moduleWasher3.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, unloadingConveyor.modulesIn);
    systems.link(
        unloadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// bird transport
    systems.link(tilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

    systems.add(ModuleCasAllocation(
        area: this, allocationPlace: mrc1.moduleGroupPlace));

    systems.add(ModuleCasStart(
      area: this,
    ));
  }
}
