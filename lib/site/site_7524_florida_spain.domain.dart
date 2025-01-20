import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_buffer_lane/module_buffer_lane.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_shuttle/module_suttle.domain.dart';
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
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/unloading_fork_lift_truck.domain.dart';

import 'site.dart';

class FloridaSite extends Site {
  FloridaSite()
      : super(
          meynLayoutNumber: 7524,
          organizationName: 'Florida',
          city: 'Castellon',
          country: 'Spain',
          productDefinitions: FloridaProductDefinitions(),
        );
}

class FloridaProductDefinitions extends DelegatingList<ProductDefinition> {
  FloridaProductDefinitions()
      : super([
          ProductDefinition(
              //2,82286 stacks per hour
              areaFactory: (ProductDefinition productDefinition) =>
                  [FloridaLiveBirdHandlingArea(productDefinition)],
              birdType: 'Chicken',

              /// TODO get numbers
              lineSpeedInShacklesPerHour: 15000,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: [
                /// TODO get numbers
                TruckRow({
                  PositionWithinModuleGroup.firstBottom: BrandBuilder()
                      .marel
                      .gpl
                      .l4
                      .build()
                      // TODO: 25 birds was from Schildermans
                      //.withLoadDensity( LoadDensity.eec64_432(averageWeightHaviestFlock, 90),averageWeightHaviestFlock ),
                      .withBirdsPerCompartment(25),
                  PositionWithinModuleGroup.firstTop: BrandBuilder()
                      .marel
                      .gpl
                      .l4
                      .build()
                      // TODO: 25 birds was from Schildermans
                      //.withLoadDensity( LoadDensity.eec64_432(averageWeightHaviestFlock, 90),averageWeightHaviestFlock ),
                      .withBirdsPerCompartment(25),
                })
              ]),
        ]);

  static Mass get averageWeightHaviestFlock => grams(3600);
}

class FloridaLiveBirdHandlingArea extends LiveBirdHandlingArea {
  FloridaLiveBirdHandlingArea(ProductDefinition productDefinition)
      : super(
          lineName: 'Chicken line',
          productDefinition: productDefinition,
        );

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.west();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.left,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mc1 = ModuleConveyor(area: this);

    /// pos0: CAS3 is at left position
    ///   in between 2.488m
    /// pos1: CAS1+2 is at middle position
    ///   in between 2.488m
    /// pos2: Infeedconveyor and destacker are at right position
    var shuttle =
        ModuleShuttle(area: this, betweenPositionsInMeters: [2.488, 2.488]);

    // var mrc1 = ModuleRotatingConveyor(
    //   area: this,
    //   diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
    //   turnPositions: [
    //     TurnPosition(direction: const CompassDirection.south()),
    //     TurnPosition(
    //         direction: const CompassDirection.west(), reverseFeedIn: true),
    //     TurnPosition(
    //         direction: const CompassDirection.east(), reverseFeedOut: true),
    //     TurnPosition(direction: const CompassDirection.north()),
    //   ],
    // );

    // var mrc2 = ModuleRotatingConveyor(
    //   area: this,
    //   diameter: ModuleRotatingConveyorDiameter.twoSingleColumnModules,
    //   turnPositions: [
    //     TurnPosition(direction: const CompassDirection.south()),
    //     TurnPosition(
    //         direction: const CompassDirection.west(), reverseFeedIn: true),
    //     TurnPosition(direction: const CompassDirection.north()),
    //   ],
    // );

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

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      slideDoorLeft: true,
    );

    var destacker = ModuleDeStacker(area: this);

    var mc2 = ModuleConveyor(area: this);

    var moduleTilter = ModuleTilter(
      area: this,
      tiltDirection: Direction.counterClockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.clockWise,
    );

    var mc3 = ModuleConveyor(area: this);

    var mainWasher1 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 4.23,
    );

    var buffer1_1 = ModuleBufferAngleTransferInFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );
    var buffer1_2 = ModuleBufferConveyor(area: this);
    var buffer1_3 = ModuleBufferConveyor(area: this);
    var buffer1_4 = ModuleBufferAngleTransferOutFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );

    var mainWasher2 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 4.23,
    );

    var mainWasher3 = ModuleWasherConveyor(
      area: this,
      lengthInMeters: 4.23,
    );

    var mc4 = ModuleConveyor(area: this);

    var unloadingConveyor = ModuleUnLoadingConveyor(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    /// module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mc1.modulesIn);
    // systems.link(mc1.modulesOut, mrc1.modulesIns[0]);
    // systems.link(mrc1.modulesOuts[1], cas1.modulesIn);
    // systems.link(cas1.modulesOut, mrc1.modulesIns[1]);
    // systems.link(mrc1.modulesOuts[2], cas2.modulesIn);
    // systems.link(cas2.modulesOut, mrc1.modulesIns[2]);
    // systems.link(mrc1.modulesOuts[3], mrc2.modulesIns[0]);
    // systems.link(mrc2.modulesOuts[1], cas3.modulesIn);
    // systems.link(cas3.modulesOut, mrc2.modulesIns[1]);
    // systems.link(mrc2.modulesOuts[2], destacker.modulesIn);

    // shuttle Left
    systems.link(
        shuttle.modulesOuts[
            ShuttleLinkLocation(position: 0, side: ShuttleSide.a)]!,
        cas3.modulesIn);
    systems.link(
        cas3.modulesOut,
        shuttle.modulesIns[
            ShuttleLinkLocation(position: 0, side: ShuttleSide.a)]!);

    systems.link(
        shuttle.modulesOuts[
            ShuttleLinkLocation(position: 0, side: ShuttleSide.b)]!,
        cas4.modulesIn);
    systems.link(
        cas4.modulesOut,
        shuttle.modulesIns[
            ShuttleLinkLocation(position: 0, side: ShuttleSide.b)]!);

    // shuttle middle
    systems.link(
        shuttle.modulesOuts[
            ShuttleLinkLocation(position: 1, side: ShuttleSide.a)]!,
        cas1.modulesIn);
    systems.link(
        cas1.modulesOut,
        shuttle.modulesIns[
            ShuttleLinkLocation(position: 1, side: ShuttleSide.a)]!);

    systems.link(
        shuttle.modulesOuts[
            ShuttleLinkLocation(position: 1, side: ShuttleSide.b)]!,
        cas2.modulesIn);
    systems.link(
        cas2.modulesOut,
        shuttle.modulesIns[
            ShuttleLinkLocation(position: 1, side: ShuttleSide.b)]!);

    // shuttle right
    systems.link(
        mc1.modulesOut,
        shuttle.modulesIns[
            ShuttleLinkLocation(position: 2, side: ShuttleSide.a)]!);
    systems.link(
        shuttle.modulesOuts[
            ShuttleLinkLocation(position: 2, side: ShuttleSide.b)]!,
        destacker.modulesIn);

    systems.link(destacker.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, moduleTilter.modulesIn);
    systems.link(moduleTilter.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, mainWasher1.modulesIn);
    systems.link(mainWasher1.modulesOut, buffer1_1.modulesIn);
    systems.link(buffer1_1.modulesOut, buffer1_2.modulesIn);
    systems.link(buffer1_2.modulesOut, buffer1_3.modulesIn);
    systems.link(buffer1_3.modulesOut, buffer1_4.modulesIn);
    systems.link(buffer1_4.modulesOut, mainWasher2.modulesIn);
    systems.link(mainWasher2.modulesOut, mainWasher3.modulesIn);
    systems.link(mainWasher3.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, unloadingConveyor.modulesIn);
    systems.link(
        unloadingConveyor.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// bird transport
    systems.link(moduleTilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdIn);

    systems.add(
        ModuleCasAllocation(area: this, allocationPlace: mc1.moduleGroupPlace));

    systems.add(ModuleCasStart(area: this, startIntervalFractions: [
      0.6,
      0.8,
      1,
      1.25,
      1.5,
      1.75,
      2,
      2.5,
      3,
    ]));
  }
}
