import 'package:flutter_test/flutter_test.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_allocation.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_start.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';
import 'package:shouldly/shouldly.dart';

void main() {
  group('$WaitingModuleCorrection', () {
    group('.default constructor', () {
      var fractionPerModule = 0.15;
      var setPointNumberOfWaitingModules = 3;
      var correction = WaitingModuleCorrection(
        baseFraction: 1 - (setPointNumberOfWaitingModules * fractionPerModule),
        fractionPerModule: fractionPerModule,
      );
      test(
        'correction.calculateFraction(0).should.be(correction.baseFraction)',
        () {
          correction.calculateFraction(0).should.be(correction.baseFraction);
        },
      );
      test('correction.calculateFraction(3).should.be(1)', () {
        correction.calculateFraction(3).should.be(1);
      });
      test(
        'correction.calculateFraction(6).should.be(6*correction.fractionPerModule+ correction.baseFraction)',
        () {
          correction
              .calculateFraction(6)
              .should
              .be(6 * correction.fractionPerModule + correction.baseFraction);
        },
      );
      test(
        'correction.calculateFraction(10).should.be(10*correction.fractionPerModule+ correction.baseFraction)',
        () {
          correction
              .calculateFraction(9.9)
              .should
              .be(9.9 * correction.fractionPerModule + correction.baseFraction);
        },
      );
    });
  });
}

class LiveBirdHandlingAreaFake extends LiveBirdHandlingArea {
  static const int numberOfModuleStacksForCasUnits = 1;
  static const int numberOfModuleLevelsForCasUnits = 2;

  LiveBirdHandlingAreaFake(ProductDefinition productDefinition)
    : super(
        lineName: '$LiveBirdHandlingAreaFake',
        productDefinition: productDefinition,
      );

  @override
  void createSystemsAndLinks() {
    var mlc = ModuleLoadingConveyor(area: this);
    var mrc1 = ModuleRotatingConveyor(
      area: this,
      turnPositions: [
        TurnPosition(direction: CompassDirection.west()),
        TurnPosition(direction: CompassDirection.north()),
        TurnPosition(direction: CompassDirection.east()),
      ],
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );
    var mrc2 = ModuleRotatingConveyor(
      area: this,
      turnPositions: [
        TurnPosition(direction: CompassDirection.west()),
        TurnPosition(direction: CompassDirection.north()),
        TurnPosition(direction: CompassDirection.east()),
      ],
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );
    var cas1 = ModuleCas(
      area: this,

      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: numberOfModuleLevelsForCasUnits,
    );
    var cas2 = ModuleCas(
      area: this,

      moduleDoor: ModuleDoor.slideDoorToLeft,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: 2,
    );

    var muc = ModuleUnLoadingConveyor(area: this);
    systems.link(mlc.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[2], mrc2.modulesIns[2]);

    systems.link(mrc2.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], muc.modulesIn);

    systems.add(ModuleCasStart(area: this));
    systems.add(
      ModuleCasAllocation(area: this, allocationPlace: mlc.moduleGroupPlace),
    );
  }
}

class DoubleColumnGrandeDrawerModuleProductDefinition
    extends ProductDefinition {
  DoubleColumnGrandeDrawerModuleProductDefinition()
    : super(
        areaFactory: (productDefinition) => [
          LiveBirdHandlingAreaFake(productDefinition),
        ],
        birdType: 'Chicken',
        lineSpeedInShacklesPerHour: 12000,
        lineShacklePitchInInches: 6,
        casRecipe: const CasRecipe.standardChickenRecipe(),
        truckRows: [
          TruckRow({
            PositionWithinModuleGroup.firstBottom: BrandBuilder()
                .meyn
                .grandeDrawer
                .m4
                .c2
                .l4
                .gs
                .build()
                .withBirdsPerCompartment(24),
            PositionWithinModuleGroup.firstTop: BrandBuilder()
                .meyn
                .grandeDrawer
                .m4
                .c2
                .l5
                .gs
                .build()
                .withBirdsPerCompartment(24),
          }),
        ],
      );
}
