import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
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
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';

import 'site.dart';

class IndrolSite extends Site {
  IndrolSite()
      : super(
          meynLayoutNumber: 8052,
          organizationName: 'Indrol',
          city: 'Grodzisk',
          country: 'Poland',
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
  static final ModuleTemplate femaleTurkeyMaxWeightCapacity = BrandBuilder()
      .meyn
      .omnia
      .build()
      .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(11.5)));

  static final ModuleTemplate femaleTurkeyAverageWeightCapacity = BrandBuilder()
      .meyn
      .omnia
      .build()
      .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(10.0)));
  static final ModuleTemplate femaleTurkeyMinWeightCapacity = BrandBuilder()
      .meyn
      .omnia
      .build()
      .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(8.5)));

  static final ModuleTemplate maleTurkeyMaxWeightCapacity = BrandBuilder()
      .meyn
      .omnia
      .build()
      .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(23)));
  static final ModuleTemplate maleTurkeyAverageWeightCapacity = BrandBuilder()
      .meyn
      .omnia
      .build()
      .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(20)));
  static final ModuleTemplate maleTurkeyMinWeightCapacity = BrandBuilder()
      .meyn
      .omnia
      .build()
      .withBirdsPerCompartment(_calculateBirdsPerCompartment(kilo.grams(18)));

  /// Info from Maurizio @ Indrol on 2024-09-18
  static final ModuleTemplate maleTurkeyGivenCapacity =
      BrandBuilder().meyn.omnia.build().withBirdsPerCompartment(36 ~/ 6);

  /// Info from Maurizio @ Indrol on 2024-09-18
  static final ModuleTemplate femaleTurkeyGivenCapacity =
      BrandBuilder().meyn.omnia.build().withBirdsPerCompartment(80 ~/ 6);

  /// Info from Maurizio @ Indrol on 2024-09-18
  static int newLineSpeedInShacklesPerHour = 4200;

  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.asIs)],
              birdType: 'Female Turkey min weight',
              lineSpeedInShacklesPerHour: 3600,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrolAtInstallation(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      femaleTurkeyMinWeightCapacity,
                  PositionWithinModuleGroup.firstTop:
                      femaleTurkeyMinWeightCapacity,
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.asIs)],
              birdType: 'Female Turkey avr weight',
              lineSpeedInShacklesPerHour: 3600,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrolAtInstallation(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      femaleTurkeyAverageWeightCapacity,
                  PositionWithinModuleGroup.firstTop:
                      femaleTurkeyAverageWeightCapacity,
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.asIs)],
              birdType: 'Female Turkey max weight',
              lineSpeedInShacklesPerHour: 3600,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrolAtInstallation(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      femaleTurkeyMaxWeightCapacity,
                  PositionWithinModuleGroup.firstTop:
                      femaleTurkeyMaxWeightCapacity,
                }),
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.asIs)],
              birdType: 'Male Turkey min weight',
              lineSpeedInShacklesPerHour: 1800,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrolAtInstallation(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      maleTurkeyMinWeightCapacity,
                  PositionWithinModuleGroup.firstTop:
                      maleTurkeyMinWeightCapacity,
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.asIs)],
              birdType: 'Male Turkey average weight',
              lineSpeedInShacklesPerHour: 1800,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrolAtInstallation(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      maleTurkeyAverageWeightCapacity,
                  PositionWithinModuleGroup.firstTop:
                      maleTurkeyAverageWeightCapacity,
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.asIs)],
              birdType: 'Male Turkey average weight',
              lineSpeedInShacklesPerHour: 1800,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrolAtInstallation(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      maleTurkeyAverageWeightCapacity,
                  PositionWithinModuleGroup.firstTop:
                      maleTurkeyAverageWeightCapacity,
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.cas3NextToCas2)],
              birdType: 'Female Turkey average weight',
              lineSpeedInShacklesPerHour: newLineSpeedInShacklesPerHour,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.femaleTurkeyRecipeAtIndrol(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      femaleTurkeyGivenCapacity,
                  PositionWithinModuleGroup.firstTop: femaleTurkeyGivenCapacity,
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.cas3NextToCas2)],
              birdType: 'Male Turkey average weight',
              lineSpeedInShacklesPerHour: newLineSpeedInShacklesPerHour ~/ 2,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.maleTurkeyRecipeAtIndrol(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      maleTurkeyGivenCapacity,
                  PositionWithinModuleGroup.firstTop: maleTurkeyGivenCapacity,
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.cas3OppositeOfCas2)],
              birdType: 'Female Turkey average weight',
              lineSpeedInShacklesPerHour: newLineSpeedInShacklesPerHour,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.femaleTurkeyRecipeAtIndrol(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      femaleTurkeyGivenCapacity,
                  PositionWithinModuleGroup.firstTop: femaleTurkeyGivenCapacity,
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.cas3OppositeOfCas2)],
              birdType: 'Male Turkey average weight',
              lineSpeedInShacklesPerHour: newLineSpeedInShacklesPerHour ~/ 2,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.maleTurkeyRecipeAtIndrol(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom:
                      maleTurkeyGivenCapacity,
                  PositionWithinModuleGroup.firstTop: maleTurkeyGivenCapacity,
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.cas3OppositeOfCas1)],
              birdType: 'Female Turkey max 12kg',
              lineSpeedInShacklesPerHour: 4000,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.femaleTurkeyRecipeAtIndrol(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .meyn
                      .omnia
                      .build()
                      .withBirdsPerCompartment(
                          _calculateBirdsPerCompartment(kilo.grams(12))),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .omnia
                      .build()
                      .withBirdsPerCompartment(
                          _calculateBirdsPerCompartment(kilo.grams(12))),
                })
              ]),
          ProductDefinition(
              areaFactory: (ProductDefinition productDefinition) =>
                  [Area(productDefinition, Layout.cas3OppositeOfCas1)],
              birdType: 'Male Turkey max 22kg',
              lineSpeedInShacklesPerHour:
                  3300, //TODO verify with Marcin. Was expecting 50% of female speed
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.maleTurkeyRecipeAtIndrol(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .meyn
                      .omnia
                      .build()
                      .withBirdsPerCompartment(
                          _calculateBirdsPerCompartment(kilo.grams(22))),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .meyn
                      .omnia
                      .build()
                      .withBirdsPerCompartment(
                          _calculateBirdsPerCompartment(kilo.grams(22))),
                })
              ]),
        ]);

  static final Mass maxWeightPerCompartment = kilo.grams(150);

  static int _calculateBirdsPerCompartment(Mass birdMass) =>
      (maxWeightPerCompartment.as(grams) / birdMass.as(grams)).truncate();
}

enum Layout {
  asIs,
  cas3NextToCas2,
  cas3OppositeOfCas2,
  cas3OppositeOfCas1,
}

class Area extends LiveBirdHandlingArea {
  final Layout layout2;
  Area(ProductDefinition productDefinition, this.layout2)
      : super(
          lineName: layout2.toString(),
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
      diameter: ModuleRotatingConveyorDiameter.omnia,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
            direction: const CompassDirection.east(), reverseFeedOut: true),
        if (layout2 == Layout.cas3NextToCas2)
          TurnPosition(
              direction: const CompassDirection.north(), reverseFeedIn: true),
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
        if (layout2 == Layout.cas3OppositeOfCas2)
          TurnPosition(
              direction: const CompassDirection.south(), reverseFeedOut: true),
      ],
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.omnia,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.east()),
        if (layout2 == Layout.cas3OppositeOfCas1)
          TurnPosition(
              direction: const CompassDirection.south(), reverseFeedOut: true),
      ],
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      moduleDoor: layout2 != Layout.cas3NextToCas2
          ? ModuleDoor.slideDoorToLeft
          : ModuleDoor.slideDoorToRight,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.slideDoorToRight,
    );

    var deStacker = ModuleDeStacker(area: this); //TODO add Indroll parameters

    var grossWeigher = ModuleConveyor(area: this);

    var tilter = ModuleTilter(
      //TODO add Indroll parameters
      area: this,
      tiltDirection: Direction.counterClockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.clockWise,
    );

    var tareWeigher = ModuleConveyor(area: this);

    var mc1 = ModuleConveyor(area: this);

    var preWasher = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.2,
    );

    var mc2 = ModuleConveyor(area: this);

    var mainWasher1 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.4,
    );

    var mc2b = ModuleConveyor(area: this);

    var mainWasher2 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.4,
    );

    var desInfection = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.4,
    );

    var mc3 = ModuleConveyor(
      area: this,
    );

    var stacker = ModuleStacker(area: this);

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.omnia,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(direction: const CompassDirection.south()),
      ],
    );

    var unloadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

// module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mrc2.modulesIns[0]);
    if (layout2 == Layout.cas3NextToCas2) {
      systems.link(mrc1.modulesOuts[2], cas3.modulesIn);
      systems.link(cas3.modulesOut, mrc1.modulesIns[2]);
    }

    systems.link(mrc2.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);

    if (layout2 == Layout.cas3OppositeOfCas2) {
      systems.link(mrc2.modulesOuts[3], cas3.modulesIn);
      systems.link(cas3.modulesOut, mrc2.modulesIns[3]);
    }
    systems.link(mrc3.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[1]);
    if (layout2 == Layout.cas3OppositeOfCas1) {
      systems.link(mrc3.modulesOuts[3], cas3.modulesIn);
      systems.link(cas3.modulesOut, mrc3.modulesIns[3]);
    }
    systems.link(mrc3.modulesOuts[2], deStacker.modulesIn);
    systems.link(deStacker.modulesOut, grossWeigher.modulesIn);
    systems.link(grossWeigher.modulesOut, tilter.modulesIn);
    systems.link(tilter.modulesOut, tareWeigher.modulesIn);
    systems.link(tareWeigher.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, preWasher.modulesIn);
    systems.link(preWasher.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, mainWasher1.modulesIn);
    if (layout2 == Layout.asIs) {
      systems.link(mainWasher1.modulesOut, desInfection.modulesIn);
    } else {
      systems.link(mainWasher1.modulesOut, mc2b.modulesIn);
      systems.link(mc2b.modulesOut, mainWasher2.modulesIn);
      systems.link(mainWasher2.modulesOut, desInfection.modulesIn);
    }
    systems.link(desInfection.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, mrc4.modulesIns[0]);
    systems.link(mrc4.modulesOuts[1], unloadingConveyor.modulesIn);
    systems.link(
        unloadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// bird transport
    systems.link(tilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

    systems.add(ModuleCasAllocation(
      area: this,
      allocationPlace: layout2 == Layout.cas3NextToCas2
          ? loadingConveyor.moduleGroupPlace
          : mrc1.moduleGroupPlace,
    ));

    systems.add(ModuleCasStart(
      area: this,
      startIntervalFractions: <double>[
        0,
        0.2,
        0.4,
        0.6,
        0.8,
        1,
        1,
        1.25,
        1.5,
        2,
      ],
      //  transportTimeCorrections: {
      //   cas1: ModuleSystem.meynOmnia.casTransportDuration.inSeconds,
      //   cas2: 0,
      //   cas3: layout2 == Layout.cas3NextToCas2
      //       ? -ModuleSystem.meynOmnia.casTransportDuration.inSeconds
      //       : layout2 == Layout.cas3OppositeOfCas1
      //           ? ModuleSystem.meynOmnia.casTransportDuration.inSeconds
      //           : 0
      // },
    ));
  }
}
