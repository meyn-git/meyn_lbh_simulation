import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module/brand.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_row_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/site/site.dart';

class HaerlandSite extends Site {
  HaerlandSite()
      : super(
          meynLayoutNumber: 5246,
          organizationName: 'Nortura',
          city: 'Haerland',
          country: 'Norway',
          productDefinitions: HaerlandProductDefinitions(),
        );
}

class HaerlandProductDefinitions extends DelegatingList<ProductDefinition> {
  static int birdsPerCompartment = 34 * 2;

  HaerlandProductDefinitions()
      : super([
          ProductDefinition(
              areaFactory: _areaFactoryTurkey(),
              birdType: 'Small Turkeys',
              lineSpeedInShacklesPerHour: 950,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.standardTurkeyRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .angliaAutoFlow
                      .turkey
                      .build()
                      .withBirdsPerCompartment(8),
                })
              ]),
          ProductDefinition(
              areaFactory: _areaFactoryTurkey(),
              birdType: 'Big Turkeys',
              lineSpeedInShacklesPerHour: 800,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.standardTurkeyRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .angliaAutoFlow
                      .turkey
                      .build()
                      .withBirdsPerCompartment(3),
                })
              ]),
          ProductDefinition(
              areaFactory: _areaFactoryTurkey(),
              birdType: 'Breeder Turkeys',
              lineSpeedInShacklesPerHour: 100,
              lineShacklePitchInInches: 12,
              casRecipe: const CasRecipe.standardTurkeyRecipe(),
              truckRows: [
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .angliaAutoFlow
                      .turkey
                      .build()
                      .withBirdsPerCompartment(1),
                })
              ]),

          // /// Lost chicken line to Marel Atlas
          // ProductDefinition(
          //     areaFactory: _areaFactoryChicken(),
          //     birdType: 'Chickens',
          //     lineSpeedInShacklesPerHour: 12500,
          //     lineShacklePitchInInches: 6,
          //     casRecipe: const CasRecipe.standardChickenRecipe(),
          //     truckRows: [
          //       TruckRow({
          //         PositionWithinModuleGroup.firstBottom: BrandBuilder()
          //             .marel
          //             .gps
          //             .l4
          //             .build()
          //             .withBirdsPerCompartment(birdsPerCompartment),
          //         PositionWithinModuleGroup.firstTop: BrandBuilder()
          //             .marel
          //             .gps
          //             .l4
          //             .build()
          //             .withBirdsPerCompartment(birdsPerCompartment),
          //       })
          //     ]),
          // ProductDefinition(
          //     areaFactory: _areaFactoryChicken(),
          //     birdType: 'Chickens',
          //     lineSpeedInShacklesPerHour: 15000,
          //     lineShacklePitchInInches: 6,
          //     casRecipe: const CasRecipe.standardChickenRecipe(),
          //     truckRows: [
          //       TruckRow({
          //         PositionWithinModuleGroup.firstBottom: BrandBuilder()
          //             .marel
          //             .gps
          //             .l4
          //             .build()
          //             .withBirdsPerCompartment(birdsPerCompartment),
          //         PositionWithinModuleGroup.firstTop: BrandBuilder()
          //             .marel
          //             .gps
          //             .l4
          //             .build()
          //             .withBirdsPerCompartment(birdsPerCompartment),
          //       })
          //     ]),
        ]);

  // static List<LiveBirdHandlingArea> Function(ProductDefinition)
  //     _areaFactoryChicken() => (ProductDefinition productDefinition) =>
  //         [HaerlandLiveBirdHandlingChickenArea(productDefinition)];

  static List<LiveBirdHandlingArea> Function(ProductDefinition)
      _areaFactoryTurkey() => (ProductDefinition productDefinition) =>
          [HaerlandLiveBirdHandlingTurkeyArea(productDefinition)];
}

class HaerlandLiveBirdHandlingTurkeyArea extends LiveBirdHandlingArea {
  static const double drawerSpeedInMetersPerSecond = 0.4;

  HaerlandLiveBirdHandlingTurkeyArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Turkey Line',
          productDefinition: productDefinition,
        );

  /// See "\\meyn.nl\project\acaddrwg\5246 Nortura Haerland - Norway\2023\02 - Meyn drawings\Sales\5246sb06z0001-Model.pdf"
  @override
  void createSystemsAndLinks() {
    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.bothSides,
    );
    var loadingConveyor = ModuleConveyor(
      area: this,
      //lengthInMeters: 3.75,
    );

    var mc1 = ModuleConveyor(area: this);

    var mrc1 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.east()),
        TurnPosition(direction: const CompassDirection.south()),
      ],
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(direction: const CompassDirection.east()),
      ],
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.west()),
        TurnPosition(
          direction: const CompassDirection.north(),
          reverseFeedIn: true,
        ),
        TurnPosition(
          direction: const CompassDirection.south(),
          reverseFeedOut: true,
        ),
      ],
    );
    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var unloader = ModuleDrawerRowUnloader(
        area: this, drawerOutDirection: Direction.counterClockWise);

    var receiver = ModuleDrawerRowUnloaderReceiver(
        area: this,
        drawerOutDirection: Direction.counterClockWise,
        crossOverFeedOutMetersPerSecond: drawerSpeedInMetersPerSecond);

    var drawerConveyor = DrawerConveyorStraight(
        lengthInMeters: 7, metersPerSecond: drawerSpeedInMetersPerSecond);

    var hangingConveyor = DrawerHangingConveyor(
      allDrawers: drawers,
      hangers: 11,
      metersPerSecondOfFirstConveyor: drawerSpeedInMetersPerSecond,
      productDefinition: productDefinition,
    );

    var drawerRemover = DrawerRemover(
      area: this,
      metersPerSecond: drawerSpeedInMetersPerSecond,
    );

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
      turnPositions: [
        TurnPosition(direction: const CompassDirection.north()),
        TurnPosition(direction: const CompassDirection.south().rotate(30)),
      ],
    );

    var unloadingConveyor = ModuleConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mc1.modulesIn);
    systems.link(mc1.modulesOut, mrc1.modulesIns[2]);
    systems.link(mrc1.modulesOuts[0], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], mrc2.modulesIns[0]);
    systems.link(mrc2.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);
    systems.link(mrc3.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[2], unloader.modulesIn);
    systems.link(unloader.modulesOut, mrc4.modulesIns[0]);
    systems.link(mrc4.modulesOuts[1], unloadingConveyor.modulesIn);
    systems.link(
        unloadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// drawer transport
    systems.link(unloader.drawersOut, receiver.drawersIn);
    systems.link(receiver.drawerOut, drawerConveyor.drawerIn);
    systems.link(drawerConveyor.drawerOut, hangingConveyor.drawerIn);
    systems.link(hangingConveyor.drawerOut, drawerRemover.drawerIn);

    systems.add(ModuleCasStart(area: this));

    systems.add(ModuleCasAllocation(
      area: this,
      allocationPlace: mc1.moduleGroupPlace,
    ));
  }
}

/// lost order to Marel Atlas
// class HaerlandLiveBirdHandlingChickenArea extends LiveBirdHandlingArea {
//   HaerlandLiveBirdHandlingChickenArea(ProductDefinition productDefinition)
//       : super(
//           lineName: 'Chicken line',
//           productDefinition: productDefinition,
//         );

//   /// See \\meyn.nl\project\acaddrwg\5246 Nortura Haerland - Norway\2022\02 - Meyn drawings\Sales\5246s104z00g1-Model.pdf
//   @override
//   void createSystemsAndLinks() {
//     var loadingForkLiftTruck = LoadingForkLiftTruck(
//       area: this,
//       moduleBirdExitDirection: ModuleBirdExitDirection.right,
//     );

//     var loadingConveyor = ModuleConveyor(
//       area: this,
//       lengthInMeters: 3.75,
//     );

//     var mrc1 = ModuleRotatingConveyor(
//         area: this,
//         diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
//         turnPositions: [
//           TurnPosition(direction: const CompassDirection.south()),
//           TurnPosition(direction: const CompassDirection.west()),
//         ]);

//     var mrc2 = ModuleRotatingConveyor(
//         area: this,
//         diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
//         turnPositions: [
//           TurnPosition(direction: const CompassDirection.east()),
//           TurnPosition(direction: const CompassDirection.south()),
//         ]);

//     var mrc3 = ModuleRotatingConveyor(
//         area: this,
//         diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
//         turnPositions: [
//           TurnPosition(direction: const CompassDirection.north()),
//           TurnPosition(direction: const CompassDirection.west()),
//         ]);

//     var mrc4 = ModuleRotatingConveyor(
//         area: this,
//        diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
//         turnPositions: [
//           TurnPosition(direction: const CompassDirection.east()),
//           TurnPosition(
//             direction: const CompassDirection.north(),
//             reverseFeedIn: true,
//           ),
//           TurnPosition(direction: const CompassDirection.west()),
//         ]);

//     var mrc5 = ModuleRotatingConveyor(
//         area: this,
//         diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
//         turnPositions: [
//           TurnPosition(direction: const CompassDirection.east()),
//           TurnPosition(
//             direction: const CompassDirection.north(),
//             reverseFeedIn: true,
//           ),
//           TurnPosition(direction: const CompassDirection.west()),
//         ]);

//     var mrc6 = ModuleRotatingConveyor(
//         area: this,
//         diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
//         turnPositions: [
//           TurnPosition(direction: const CompassDirection.east()),
//           TurnPosition(
//             direction: const CompassDirection.north(),
//             reverseFeedIn: true,
//           ),
//           TurnPosition(direction: const CompassDirection.west()),
//         ]);

//     var mrc7 = ModuleRotatingConveyor(
//         area: this,
//         diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
//         turnPositions: [
//           TurnPosition(direction: const CompassDirection.east()),
//           TurnPosition(direction: const CompassDirection.north()),
//           TurnPosition(
//             direction: const CompassDirection.west(),
//             reverseFeedIn: true,
//           ),
//         ]);

//     var cas4 = ModuleCas(
//       area: this,
//       gasDuctsLeft: true,
//       slideDoorLeft: false,
//     );

//     var cas3 = ModuleCas(
//       area: this,
//       gasDuctsLeft: true,
//       slideDoorLeft: false,
//     );

//     var cas2 = ModuleCas(
//       area: this,
//       gasDuctsLeft: true,
//       slideDoorLeft: false,
//     );

//     var cas1 = ModuleCas(
//       area: this,
//       gasDuctsLeft: true,
//       slideDoorLeft: false,
//     );

//     var deStacker = ModuleDeStacker(area: this);

//     var mc1 = ModuleConveyor(area: this);

//     var tilter = ModuleTilter(
//       area: this,
//       tiltDirection: Direction.clockWise,
//     );

//     var dumpConveyor = ModuleTilterDumpConveyor(area: this);

//     var shackleConveyor = ShackleConveyor(
//       area: this,
//       direction: Direction.counterClockWise,
//     );

//     var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

//     /// container transport
//     systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
//     systems.link(loadingConveyor.modulesOut, mrc1.modulesIns[0]);
//     systems.link(mrc1.modulesOuts[1], mrc2.modulesIns[0]);
//     systems.link(mrc2.modulesOuts[1], mrc3.modulesIns[0]);
//     systems.link(mrc3.modulesOuts[1], mrc4.modulesIns[0]);
//     systems.link(mrc4.modulesOuts[1], cas4.modulesIn);
//     systems.link(cas4.modulesOut, mrc4.modulesIns[1]);
//     systems.link(mrc4.modulesOuts[2], mrc5.modulesIns[0]);
//     systems.link(mrc5.modulesOuts[1], cas3.modulesIn);
//     systems.link(cas3.modulesOut, mrc5.modulesIns[1]);
//     systems.link(mrc5.modulesOuts[2], mrc6.modulesIns[0]);
//     systems.link(mrc6.modulesOuts[1], cas2.modulesIn);
//     systems.link(cas2.modulesOut, mrc6.modulesIns[1]);
//     systems.link(mrc6.modulesOuts[2], mrc7.modulesIns[0]);
//     systems.link(mrc7.modulesOuts[1], deStacker.modulesIn);
//     systems.link(mrc7.modulesOuts[2], cas1.modulesIn);
//     systems.link(cas1.modulesOut, mrc7.modulesIns[2]);
//     systems.link(deStacker.modulesOut, mc1.modulesIn);
//     systems.link(mc1.modulesOut, tilter.modulesIn);
//     systems.link(tilter.modulesOut, unLoadingForkLiftTruck.modulesIn);

//     /// bird transport
//     systems.link(tilter.birdsOut, dumpConveyor.birdsIn);
//     systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

//     systems.add(ModuleCasStart(area: this));

//     systems.add(ModuleCasAllocation(
//       area: this,
//       allocationPlace: mrc3.moduleGroupPlace,
//     ));
//   }
// }
