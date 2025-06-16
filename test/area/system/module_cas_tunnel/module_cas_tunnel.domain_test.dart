import 'package:flutter_test/flutter_test.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';
import 'package:shouldly/shouldly.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas_tunnel/module_cas_tunnel.domain.dart';

/// the following numbers are expected for:
/// shacklesPerHour = 7920
/// (8 comp *22 birds) = 176 birds/mod
/// 7920/176 = 45 modules/hour
/// 7 module tunnel sections
const transportDurationBetweenConveyorAndLift = Duration(milliseconds: 11723);
const transportDurationBetweenSections = Duration(milliseconds: 6966);
const transportDurationBetweenLiftAndConveyor = Duration(milliseconds: 12198);
const noneEffectiveStunningTimeOfTunnel = Duration(milliseconds: 89_717);
const stunDuration = Duration(minutes: 6);

void main() {
  group('ModuleCasTunnelMiddleSection class', () {
    late ModuleCasTunnelMiddleSection middleSection;
    setUp(() {
      var area = _AreaWithModuleCasTunnel(
        shacklesPerHour: 7920,
        tunnelSections: 7,
      );
      middleSection = area.middleSections.first;
    });
    test('minimumCycleDuration must return a correct value', () {
      middleSection.minimumCycleDuration.should.be(
        transportDurationBetweenSections * 2,
      );
    });
    test('noneStunDurationPerCycle must return a correct value', () {
      middleSection.noneStunDurationPerCycle.should.be(
        transportDurationBetweenSections * 0.5 * 2,
      );
    });
  });

  group('ModuleCasTunnelInFeedLift class', () {
    late ModuleCasTunnelInFeedLift inFeedLift;
    setUp(() {
      var area = _AreaWithModuleCasTunnel(
        shacklesPerHour: 7920,
        tunnelSections: 6,
      );
      inFeedLift = area.inFeedLift;
    });
    test('minimumCycleDuration must return a correct value', () {
      inFeedLift.minimumCycleDuration.should.be(
        transportDurationBetweenConveyorAndLift +
            ModuleCasTunnelLift.defaultUpOrDownDuration +
            transportDurationBetweenSections +
            ModuleCasTunnelLift.defaultUpOrDownDuration,
      );
    });
    test('noneStunDurationPerCycle must return a correct value', () {
      inFeedLift.noneStunDurationPerCycle.should.be(
        transportDurationBetweenSections * 0.5 +
            ModuleCasTunnelLift.defaultUpOrDownDuration +
            transportDurationBetweenConveyorAndLift,
      );
    });
  });

  group('ModuleCasTunnelOutFeedLift class', () {
    late ModuleCasTunnelOutFeedLift outFeedLift;
    setUp(() {
      var area = _AreaWithModuleCasTunnel(
        shacklesPerHour: 7920,
        tunnelSections: 6,
      );
      outFeedLift = area.outFeedLift;
    });
    test('minimumCycleDuration must return a correct value', () {
      outFeedLift.minimumCycleDuration.should.be(
        transportDurationBetweenSections +
            ModuleCasTunnelLift.defaultUpOrDownDuration +
            transportDurationBetweenLiftAndConveyor +
            ModuleCasTunnelLift.defaultUpOrDownDuration,
      );
    });
    test('noneStunDurationPerCycle must return a correct value', () {
      outFeedLift.noneStunDurationPerCycle.should.be(
        transportDurationBetweenSections * 0.5 +
            ModuleCasTunnelLift.defaultUpOrDownDuration +
            transportDurationBetweenLiftAndConveyor +
            ModuleCasTunnelLift.defaultUpOrDownDuration,
      );
    });
  });

  group('ModuleCasTunnelConfiguration', () {
    late ProductDefinition productDefinition;
    late LiveBirdHandlingArea area;

    setUp(() {
      area = _AreaWithModuleCasTunnel(shacklesPerHour: 7920, tunnelSections: 7);
      productDefinition = area.productDefinition;
    });

    test('should have a valid startInterval', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.startInterval.should.be(Duration(minutes: 1, seconds: 20));
      config.startInterval.inMilliseconds.should.beGreaterThan(0);
    });

    test('should have a valid maxTotalTunnelDuration', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.maxDurationPerSection.inMilliseconds.should.be(
        (stunDuration.inMilliseconds *
                    ModuleCasTunnelConfiguration.additionalCapacityFactor +
                noneEffectiveStunningTimeOfTunnel.inMilliseconds) ~/
            config.numberOfSections,
      );
    });

    test('should have a valid maxDurationPerSection', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.maxDurationPerSection.inMilliseconds.should.be(
        (stunDuration.inMilliseconds *
                    ModuleCasTunnelConfiguration.additionalCapacityFactor +
                noneEffectiveStunningTimeOfTunnel.inMilliseconds) ~/
            config.numberOfSections,
      );
    });

    test('should have a valid totalTunnelDuration', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.totalTunnelDuration.inMilliseconds.should.be(
        stunDuration.inMilliseconds +
            noneEffectiveStunningTimeOfTunnel.inMilliseconds,
      );
    });

    test('should have a valid durationPerSection', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.durationPerSection.inMilliseconds.should.be(
        (stunDuration.inMilliseconds +
                noneEffectiveStunningTimeOfTunnel.inMilliseconds) ~/
            config.numberOfSections,
      );
    });

    test('should calculate totalStunDuration from casRecipe', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.totalStunDuration.should.be(stunDuration);
    });

    test('should calculate modulesPerHour correctly', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.modulesPerHour.should.beCloseTo(
        productDefinition.lineSpeedInShacklesPerHour /
            productDefinition.averageNumberOfBirdsPerModule,
        delta: 0.0001,
      );
    });

    test('should calculate startInterval correctly', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.startInterval.inMilliseconds.should.be(80 * 1000);
    });

    test('should calculate noneEffectiveStunningTimeOfTunnel correctly', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.noneEffectiveStunningTimeOfTunnel.should.be(
        noneEffectiveStunningTimeOfTunnel,
      );
    });

    test('should calculate durationPerSection correctly', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.maxDurationPerSection.inMilliseconds.should.be(
        (stunDuration.inMilliseconds *
                    ModuleCasTunnelConfiguration.additionalCapacityFactor +
                noneEffectiveStunningTimeOfTunnel.inMilliseconds) ~/
            7,
      );
    });

    test('should calculate numberOfSections correctly', () {
      final config = ModuleCasTunnelConfiguration(area);
      config.numberOfSections.should.be(7);
    });

    group('sectionConfigurations', () {
      group('3168 b/h, 176 birds/mod, 18 modules/h, 3 sections', () {
        late LiveBirdHandlingArea area;
        setUp(() {
          area = _AreaWithModuleCasTunnel(
            shacklesPerHour: 3168,
            tunnelSections: 3,
          );
        });

        test('sectionConfigurations.length should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations.length.should.be(3);
        });
        test(
          'sum of sectionConfigurations.effectiveStunDuration should be close to 6 minutes',
          () {
            final config = ModuleCasTunnelConfiguration(area);
            var totalStunDuration = config.sectionConfigurations
                .map((item) => item.effectiveStunDuration)
                .reduce((a, b) => a + b);
            totalStunDuration.inSeconds.should.be(stunDuration.inSeconds);
          },
        );
        test('sectionConfigurations[0] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[0].effectiveStunDuration.should.be(
            Duration(minutes: 1, seconds: 57, microseconds: 411_667),
          );
          config.sectionConfigurations[0].co2Concentration.should.beCloseTo(
            22.871,
            delta: 0.001,
          );
        });
        test('sectionConfigurations[1] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[1].effectiveStunDuration.should.be(
            Duration(minutes: 2, seconds: 13, microseconds: 651_667),
          );
          config.sectionConfigurations[1].co2Concentration.should.beCloseTo(
            37.323,
            delta: 0.001,
          );
        });
        test('sectionConfigurations[2] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[2].effectiveStunDuration.should.be(
            Duration(minutes: 1, seconds: 48, microseconds: 936_667),
          );
          config.sectionConfigurations[2].co2Concentration.should.beCloseTo(
            62,
            delta: 0.001,
          );
        });
      });
      group('7920 b/h, 176 birds/mod, 45 modules/h, 7 sections', () {
        late LiveBirdHandlingArea area;
        setUp(() {
          area = _AreaWithModuleCasTunnel(
            shacklesPerHour: 7920,
            tunnelSections: 7,
          );
        });
        test('sectionConfigurations.length should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations.length.should.be(7);
        });
        test(
          'sum of sectionConfigurations.effectiveStunDuration should be close to 6 minutes',
          () {
            final config = ModuleCasTunnelConfiguration(area);
            var totalStunDuration = config.sectionConfigurations
                .map((item) => item.effectiveStunDuration)
                .reduce((a, b) => a + b);
            totalStunDuration.inSeconds.should.be(stunDuration.inSeconds);
          },
        );
        test('sectionConfigurations[0] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[0].effectiveStunDuration.should.be(
            Duration(seconds: 41, microseconds: 039_286),
          );
          config.sectionConfigurations[0].co2Concentration.should.beCloseTo(
            18.0,
            delta: 0.001,
          );
        });
        test('sectionConfigurations[1] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[1].effectiveStunDuration.should.be(
            Duration(seconds: 57, microseconds: 279_286),
          );
          config.sectionConfigurations[1].co2Concentration.should.beCloseTo(
            24.666,
            delta: 0.001,
          );
        });
        test('sectionConfigurations[2] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[2].effectiveStunDuration.should.be(
            Duration(seconds: 57, microseconds: 279_286),
          );
          config.sectionConfigurations[2].co2Concentration.should.beCloseTo(
            31.070,
            delta: 0.001,
          );
        });
        test('sectionConfigurations[3] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[3].effectiveStunDuration.should.be(
            Duration(seconds: 57, microseconds: 279_286),
          );
          config.sectionConfigurations[3].co2Concentration.should.beCloseTo(
            35.807,
            delta: 0.001,
          );
        });
        test('sectionConfigurations[4] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[4].effectiveStunDuration.should.be(
            Duration(seconds: 57, microseconds: 279_286),
          );
          config.sectionConfigurations[4].co2Concentration.should.beCloseTo(
            50.210,
            delta: 0.001,
          );
        });
        test('sectionConfigurations[5] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[5].effectiveStunDuration.should.be(
            Duration(seconds: 57, microseconds: 279_286),
          );
          config.sectionConfigurations[5].co2Concentration.should.beCloseTo(
            62,
            delta: 0.001,
          );
        });
        test('sectionConfigurations[6] should have a valid value', () {
          final config = ModuleCasTunnelConfiguration(area);
          config.sectionConfigurations[6].effectiveStunDuration.should.be(
            Duration(seconds: 32, microseconds: 564_286),
          );
          config.sectionConfigurations[6].co2Concentration.should.beCloseTo(
            62,
            delta: 0.001,
          );
        });
      });
    });
  });
}

ProductDefinition _createProductDefinition({
  required int shacklesPerHour,
  required int tunnelSections,
}) => ProductDefinition(
  areaFactory: (productDefinition) => [
    _AreaWithModuleCasTunnel(
      shacklesPerHour: shacklesPerHour,
      tunnelSections: tunnelSections,
    ),
  ],
  birdType: 'chicken',
  lineSpeedInShacklesPerHour: shacklesPerHour,
  lineShacklePitchInInches: 6,
  truckRows: [
    TruckRow({
      PositionWithinModuleGroup.firstTop: BrandBuilder()
          .meyn
          .grandeDrawer
          .m1
          .c2
          .l4
          .gs
          .build()
          .withBirdsPerCompartment(22),
    }),
  ],
  casRecipe: CasRecipe.standardChickenRecipe(),
);

class _AreaWithModuleCasTunnel extends LiveBirdHandlingArea {
  final int tunnelSections;
  _AreaWithModuleCasTunnel({
    required int shacklesPerHour,
    required this.tunnelSections,
  }) : super(
         lineName: 'TestMock',
         productDefinition: _createProductDefinition(
           shacklesPerHour: shacklesPerHour,
           tunnelSections: tunnelSections,
         ),
       );

  late final List<ModuleCasTunnelMiddleSection> middleSections =
      _createMiddleSections();

  List<ModuleCasTunnelMiddleSection> _createMiddleSections() {
    var middleSections = <ModuleCasTunnelMiddleSection>[];
    for (int i = 0; i < tunnelSections - 2; i++) {
      middleSections.add(ModuleCasTunnelMiddleSection(area: this));
    }
    return middleSections;
  }

  late final inFeedLift = ModuleCasTunnelInFeedLift(
    area: this,
    moduleOutDirection: Direction.clockWise,
  );

  late final outFeedLift = ModuleCasTunnelOutFeedLift(
    area: this,
    moduleOutDirection: Direction.clockWise,
  );

  @override
  void createSystemsAndLinks() {
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var moduleConveyor1 = ModuleConveyor(area: this);

    var moduleConveyor2 = ModuleConveyor(area: this);
    var unLoadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, moduleConveyor1.modulesIn);
    systems.link(moduleConveyor1.modulesOut, inFeedLift.modulesIn);
    ModuleCasTunnelSection previousSection = inFeedLift;
    for (var middleSection in middleSections) {
      systems.link(previousSection.modulesOut, middleSection.modulesIn);
      previousSection = middleSection;
    }
    systems.link(middleSections.last.modulesOut, outFeedLift.modulesIn);
    systems.link(outFeedLift.modulesOut, moduleConveyor2.modulesIn);
    systems.link(moduleConveyor2.modulesOut, unLoadingConveyor.modulesIn);
    systems.link(
      unLoadingConveyor.modulesOut,
      unLoadingForkLiftTruck.modulesIn,
    );
  }
}
