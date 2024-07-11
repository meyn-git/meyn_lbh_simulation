import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
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
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';

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
  static final ModuleCapacity femaleTurkeyMaxWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(11.5)));

  static final ModuleCapacity femaleTurkeyAverageWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(10.0)));
  static final ModuleCapacity femaleTurkeyMinWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(8.5)));

  static final ModuleCapacity maleTurkeyMaxWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(23)));
  static final ModuleCapacity maleTurkeyAverageWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(20)));
  static final ModuleCapacity maleTurkeyMinWeightCapacity =
      MeynOmniTurkey3Level().dimensions.capacityWithBirdsPerCompartment(
          _calculateBirdsPerCompartment(kilo.grams(18)));

  ProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Female Turkey min weight',
              lineSpeedInShacklesPerHour: 3600,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: femaleTurkeyMinWeightCapacity,
                  secondModule: femaleTurkeyMinWeightCapacity,
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Female Turkey avr weight',
              lineSpeedInShacklesPerHour: 3600,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: femaleTurkeyAverageWeightCapacity,
                  secondModule: femaleTurkeyAverageWeightCapacity,
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Female Turkey max weight',
              lineSpeedInShacklesPerHour: 3600,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: femaleTurkeyMaxWeightCapacity,
                  secondModule: femaleTurkeyMaxWeightCapacity,
                ),
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Male Turkey min weight',
              lineSpeedInShacklesPerHour: 1800,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: maleTurkeyMinWeightCapacity,
                  secondModule: maleTurkeyMinWeightCapacity,
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Male Turkey average weight',
              lineSpeedInShacklesPerHour: 1800,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: maleTurkeyAverageWeightCapacity,
                  secondModule: maleTurkeyAverageWeightCapacity,
                )
              ]),
          ProductDefinition(
              areaFactory: _areaFactory(),
              birdType: 'Male Turkey max weight',
              lineSpeedInShacklesPerHour: 1800,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.turkeyRecipeAtIndrol(),
              moduleSystem: ModuleSystem.meynOmni,
              moduleFamily: ModuleFamily.meynOmni,
              moduleGroupCapacities: [
                ModuleGroupCapacity(
                  firstModule: maleTurkeyMaxWeightCapacity,
                  secondModule: maleTurkeyMaxWeightCapacity,
                )
              ]),
        ]);

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactory() =>
          (ProductDefinition productDefinition) => [Area(productDefinition)];

  static final Mass maxWeightPerCompartment = kilo.grams(150);

  static int _calculateBirdsPerCompartment(Mass birdMass) =>
      (maxWeightPerCompartment.as(grams) / birdMass.as(grams)).truncate();
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

    var loadingConveyor = ModuleConveyor(
      area: this,
      lengthInMeters: 3,
    );

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.5,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.south()),
        TurnPosition(
            direction: const CompassDirection.east(), reverseFeedOut: true),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.5,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.5,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
            direction: const CompassDirection.north(), reverseFeedIn: true),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: false,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: false,
    );

    var deStacker = ModuleDeStacker(area: this);

    var grossWeigher = ModuleConveyor(area: this);

    var tilter = ModuleTilter(
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

    var preWasher = ModuleConveyor(
      area: this,
      lengthInMeters: 3.2,
    );

    var mc2 = ModuleConveyor(area: this);

    var mainWasher = ModuleConveyor(
      area: this,
      lengthInMeters: 3.4,
    );

    var desInfection = ModuleConveyor(
      area: this,
      lengthInMeters: 3.4,
    );

    var mc3 = ModuleConveyor(
      area: this,
    );

    var stacker = ModuleStacker(area: this);

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      lengthInMeters: 3.5,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(direction: const CompassDirection.south()),
      ],
    );

    var unloadingConveyor = ModuleConveyor(
      area: this,
      lengthInMeters: 3,
    );

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

// module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);
    systems.link(mrc3.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[2], deStacker.modulesIn);
    systems.link(deStacker.modulesOut, grossWeigher.modulesIn);
    systems.link(grossWeigher.modulesOut, tilter.modulesIn);
    systems.link(tilter.modulesOut, tareWeigher.modulesIn);
    systems.link(tareWeigher.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, preWasher.modulesIn);
    systems.link(preWasher.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, mainWasher.modulesIn);
    systems.link(mainWasher.modulesOut, desInfection.modulesIn);
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
      allocationPlace: mrc1.moduleGroupPlace,
    ));

    systems.add(ModuleCasStart(area: this));
  }
}
