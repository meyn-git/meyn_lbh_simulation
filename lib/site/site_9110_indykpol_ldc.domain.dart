import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter_dump_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_weigher/module_weighing_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shackle_conveyor/shackle_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
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

class IndykpolLdcSite extends Site {
  IndykpolLdcSite()
    : super(
        meynLayoutNumber: 9110,
        organizationName: 'Indykpol LDC',
        city: 'Olsztyn',
        country: 'Poland',
        productDefinitions: ProductDefinitions(),
      );
}

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  static const int schacklePitchInInch = 15;

  // *************** FE-MALES ******************
  static const femaleTurkeyMaxWeightInKiloGrams = 12;

  static final ModuleTemplate femaleTurkeyMaxWeightCapacity = BrandBuilder()
      .meyn
      .omnia
      .build()
      .withBirdsPerCompartment(
        _calculateBirdsPerCompartment(
          kilo.grams(femaleTurkeyMaxWeightInKiloGrams),
        ),
      );

  static int femaleLineSpeedInShacklesPerHour = 4000;

  // *************** MALES ******************
  static const maleTurkeyMaxWeightInKiloGrams = 22;

  static final ModuleTemplate maleTurkeyMaxWeightCapacity = BrandBuilder()
      .meyn
      .omnia
      .build()
      .withBirdsPerCompartment(
        _calculateBirdsPerCompartment(
          kilo.grams(maleTurkeyMaxWeightInKiloGrams),
        ),
      );

  static int maleLineSpeedInShacklesPerHour = 3300;

  ProductDefinitions()
    : super([
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            Area(productDefinition, SpeedType.asIs),
          ],
          birdType: 'Male Turkey $maleTurkeyMaxWeightInKiloGrams kg',
          lineSpeedInShacklesPerHour: maleLineSpeedInShacklesPerHour,
          lineShacklePitchInInches: schacklePitchInInch,
          casRecipe: const CasRecipe.standardTurkeyRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom:
                  maleTurkeyMaxWeightCapacity,
              PositionWithinModuleGroup.firstTop: maleTurkeyMaxWeightCapacity,
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            Area(productDefinition, SpeedType.asIs),
          ],
          birdType: 'Female Turkey $femaleTurkeyMaxWeightInKiloGrams kg',
          lineSpeedInShacklesPerHour: femaleLineSpeedInShacklesPerHour,
          lineShacklePitchInInches: schacklePitchInInch,
          casRecipe: const CasRecipe.standardTurkeyRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom:
                  femaleTurkeyMaxWeightCapacity,
              PositionWithinModuleGroup.firstTop: femaleTurkeyMaxWeightCapacity,
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            Area(productDefinition, SpeedType.toBe),
          ],
          birdType: 'Male Turkey $maleTurkeyMaxWeightInKiloGrams kg',
          lineSpeedInShacklesPerHour: maleLineSpeedInShacklesPerHour,
          lineShacklePitchInInches: schacklePitchInInch,
          casRecipe: const CasRecipe.standardTurkeyRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom:
                  maleTurkeyMaxWeightCapacity,
              PositionWithinModuleGroup.firstTop: maleTurkeyMaxWeightCapacity,
            }),
          ],
        ),
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            Area(productDefinition, SpeedType.toBe),
          ],
          birdType: 'Female Turkey $femaleTurkeyMaxWeightInKiloGrams kg',
          lineSpeedInShacklesPerHour: femaleLineSpeedInShacklesPerHour,
          lineShacklePitchInInches: schacklePitchInInch,
          casRecipe: const CasRecipe.standardTurkeyRecipe(),
          truckRows: [
            TruckRow({
              PositionWithinModuleGroup.firstBottom:
                  femaleTurkeyMaxWeightCapacity,
              PositionWithinModuleGroup.firstTop: femaleTurkeyMaxWeightCapacity,
            }),
          ],
        ),
      ]);

  static final Mass maxWeightPerCompartment = kilo.grams(150);

  static int _calculateBirdsPerCompartment(Mass birdMass) =>
      (maxWeightPerCompartment.as(grams) / birdMass.as(grams)).truncate();
}

enum SpeedType {
  asIs(
    name: 'Speed as is',
    turnSpeedProfile: TurnTableSpeedProfileForOmniaContainers(),
    moduleSpeedProfile: ConveyorWithoutStopperSpeedProfileForOmniaContainers(),
  ),
  toBe(
    name: 'Speed to be',
    turnSpeedProfile:
        TurnTableSpeedProfileForModulesWithMultipleCompartmentsPerLevel(),
    moduleSpeedProfile:
        ConveyorSpeedProfileForModulesWithMultipleCompartmentsPerLevel(),
  );

  final String name;
  final SpeedProfile turnSpeedProfile;
  final SpeedProfile moduleSpeedProfile;
  const SpeedType({
    required this.name,
    required this.turnSpeedProfile,
    required this.moduleSpeedProfile,
  });
}

class Area extends LiveBirdHandlingArea {
  static const int levelsOfModulesInCas = 2;
  static const int numberOfModuleStacksForCasUnits = 1;
  final SpeedType speed;
  Area(ProductDefinition productDefinition, this.speed)
    : super(lineName: speed.name, productDefinition: productDefinition);

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.south();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var loadingConveyor = ModuleLoadingConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var mc1 = ModuleConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var mc2 = ModuleConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.omnia,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(
          direction: const CompassDirection.east(),
          reverseFeedOut: true,
        ),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedIn: true,
        ),
        TurnPosition(
          direction: const CompassDirection.west(),
          reverseFeedIn: true,
        ),
      ],
      turnSpeedProfile: speed.turnSpeedProfile,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.omnia,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
      ],
      turnSpeedProfile: speed.turnSpeedProfile,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.omnia,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
      ],
      turnSpeedProfile: speed.turnSpeedProfile,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var cas5 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesInCas,
      moduleDoor: ModuleDoor.slideDoorToRight,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesInCas,
      moduleDoor: ModuleDoor.slideDoorToLeft,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesInCas,
      moduleDoor: ModuleDoor.slideDoorToLeft,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesInCas,
      moduleDoor: ModuleDoor.slideDoorToLeft,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesInCas,
      moduleDoor: ModuleDoor.slideDoorToRight,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var mc3 = ModuleConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var deStacker = ModuleDeStacker(
      area: this,
      conveyorSpeed: speed.moduleSpeedProfile,
    ); //TODO add Indroll parameters

    var grossWeigher = ModuleWeighingConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var tilter = ModuleTilter(
      //TODO add Indroll parameters
      area: this,
      tiltDirection: Direction.clockWise,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.counterClockWise,
    );

    var tareWeigher = ModuleWeighingConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var preWasher1 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.2,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var preWasher2 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.2,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var mc4 = ModuleConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var mainWasher1 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.4,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var mainWasher2 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.4,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var desInfection = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 3.4,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var mc5 = ModuleConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var stacker = ModuleStacker(
      area: this,
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.omnia,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(direction: const CompassDirection.north()),
      ],
      conveyorSpeedProfile: speed.moduleSpeedProfile,
    );

    var mc6 = ModuleConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var mc7 = ModuleConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var unloadingConveyor = ModuleUnLoadingConveyor(
      area: this,
      speedProfile: speed.moduleSpeedProfile,
    );

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    // module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mrc2.modulesIns[0]);
    systems.link(mrc1.modulesOuts[2], cas4.modulesIn);
    systems.link(cas4.modulesOut, mrc1.modulesIns[2]);
    systems.link(mrc1.modulesOuts[3], cas5.modulesIn);
    systems.link(cas5.modulesOut, mrc1.modulesIns[3]);

    systems.link(mrc2.modulesOuts[1], mrc3.modulesIns[0]);
    systems.link(mrc2.modulesOuts[2], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc2.modulesIns[2]);

    systems.link(mrc3.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[2], mc3.modulesIn);
    systems.link(mrc3.modulesOuts[3], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc3.modulesIns[3]);

    systems.link(mc3.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, grossWeigher.modulesIn);
    systems.link(grossWeigher.modulesOut, tilter.modulesIn);
    systems.link(tilter.modulesOut, tareWeigher.modulesIn);
    systems.link(tareWeigher.modulesOut, preWasher1.modulesIn);
    systems.link(preWasher1.modulesOut, preWasher2.modulesIn);
    systems.link(preWasher2.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, mainWasher1.modulesIn);
    systems.link(mainWasher1.modulesOut, mainWasher2.modulesIn);
    systems.link(mainWasher2.modulesOut, desInfection.modulesIn);
    systems.link(desInfection.modulesOut, mc5.modulesIn);
    systems.link(mc5.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, mrc4.modulesIns[0]);
    systems.link(mrc4.modulesOuts[1], mc6.modulesIn);
    systems.link(mc6.modulesOut, mc7.modulesIn);
    systems.link(mc7.modulesOut, unloadingConveyor.modulesIn);
    systems.link(
      unloadingConveyor.modulesOut,
      unLoadingForkLiftTruck.modulesIn,
    );

    /// bird transport
    systems.link(tilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdsIn);

    systems.add(
      ModuleCasAllocation(area: this, allocationPlace: mc2.moduleGroupPlace),
    );

    systems.add(ModuleCasStart(area: this));
  }
}
