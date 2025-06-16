import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas_tunnel/module_cas_tunnel.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_unloading_conveyor/module_unloading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';

import 'site.dart';

class ModuleTunnelStunnerSite extends Site {
  ModuleTunnelStunnerSite()
    : super(
        meynLayoutNumber: 0000, // Innovation demo for a module tunnel stunner.
        organizationName: 'Meyn',
        city: 'Oostzaan',
        country: 'Netherlands',
        productDefinitions: ProductDefinitions(),
      );
}

class ProductDefinitions extends DelegatingList<ProductDefinition> {
  ProductDefinitions()
    : super([
        _createProductDefinition(birdsPerHour: 1_000, tunnelSections: 3),
        _createProductDefinition(birdsPerHour: 3_000, tunnelSections: 3),
        _createProductDefinition(birdsPerHour: 6_000, tunnelSections: 5),
        _createProductDefinition(birdsPerHour: 9_000, tunnelSections: 8),
        _createProductDefinition(birdsPerHour: 12_000, tunnelSections: 10),
        _createProductDefinition(birdsPerHour: 15_000, tunnelSections: 13),
        _createProductDefinition(birdsPerHour: 18_000, tunnelSections: 16),

        //_createProductDefinition(birdsPerHour: 19_500, tunnelSections: 18), FIXME OutFeedLift has negative duration > 90.9 modules/hour
      ]);

  static ProductDefinition _createProductDefinition({
    required int birdsPerHour,
    required int tunnelSections,
  }) {
    return ProductDefinition(
      areaFactory: (ProductDefinition productDefinition) => [
        Area(productDefinition, numberOfTunnelSections: tunnelSections),
      ],
      birdType: 'Chicken',
      lineSpeedInShacklesPerHour: birdsPerHour,
      lineShacklePitchInInches: 6,
      casRecipe: const CasRecipe.standardChickenRecipe(),
      truckRows: [
        TruckRow({
          PositionWithinModuleGroup.firstBottom: BrandBuilder()
              .meyn
              .grandeDrawer
              .m1
              .c2
              .l4
              .gs
              .build()
              .withBirdsPerCompartment(22),
          PositionWithinModuleGroup.firstTop: BrandBuilder()
              .meyn
              .grandeDrawer
              .m1
              .c2
              .l5
              .gs
              .build()
              .withBirdsPerCompartment(22),
        }),
      ],
    );
  }
}

class Area extends LiveBirdHandlingArea {
  final int numberOfTunnelSections;

  Area(
    ProductDefinition productDefinition, {
    required this.numberOfTunnelSections,
  }) : super(
         lineName: 'demo of module CAS tunnel',
         productDefinition: productDefinition,
       );

  late final List<ModuleCasTunnelMiddleSection> middleSections =
      _createMiddleSections();

  List<ModuleCasTunnelMiddleSection> _createMiddleSections() {
    var middleSections = <ModuleCasTunnelMiddleSection>[];
    for (int i = 0; i < numberOfTunnelSections - 2; i++) {
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

    var deStacker = ModuleDeStacker(area: this);

    var stacker = ModuleStacker(area: this);
    var unLoadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, deStacker.modulesIn);
    systems.link(deStacker.modulesOut, inFeedLift.modulesIn);
    ModuleCasTunnelSection previousSection = inFeedLift;
    for (var middleSection in middleSections) {
      systems.link(previousSection.modulesOut, middleSection.modulesIn);
      previousSection = middleSection;
    }
    systems.link(middleSections.last.modulesOut, outFeedLift.modulesIn);
    systems.link(outFeedLift.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, unLoadingConveyor.modulesIn);
    systems.link(
      unLoadingConveyor.modulesOut,
      unLoadingForkLiftTruck.modulesIn,
    );
  }
}
