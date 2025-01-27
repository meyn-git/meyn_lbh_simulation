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
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';

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
              areaFactory: (ProductDefinition productDefinition) => [
                    FloridaLiveBirdHandlingArea(
                        productDefinition, LayoutVariant.asIs)
                  ],
              birdType: 'Chicken',

              /// TODO get numbers
              lineSpeedInShacklesPerHour: 15000,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: truckRows),
          ProductDefinition(
              //2,82286 stacks per hour
              areaFactory: (ProductDefinition productDefinition) => [
                    FloridaLiveBirdHandlingArea(
                        productDefinition, LayoutVariant.toBe)
                  ],
              birdType: 'Chicken',

              /// TODO get numbers
              lineSpeedInShacklesPerHour: 15000,
              lineShacklePitchInInches: 6,
              casRecipe: const CasRecipe.standardChickenRecipe(),
              truckRows: truckRows),
        ]);

  static List<TruckRow> get truckRows {
    return [
      // 2024-01-08 From Albert Ribalta Pardo <aribalta@meyn.com>
      // Are Meyn Systenate containers (compatable with Marel GP)
      TruckRow({
        PositionWithinModuleGroup.firstBottom: BrandBuilder()
            .marel
            .gpl
            .l4
            .build()
            // 2024-01-08 worst case 3.1kg/bird=25birds per compartment
            .withBirdsPerCompartment(25),
        PositionWithinModuleGroup.firstTop: BrandBuilder()
            .marel
            .gpl
            .l4
            .build()
            // 2024-01-08 worst case 3.1kg/bird=25birds per compartment
            .withBirdsPerCompartment(25),
      })
    ];
  }

  static Mass get averageWeightHaviestFlock => grams(3600);
}

enum LayoutVariant {
  asIs('as is with 3 CAS units'),
  toBe('to be with 4 CAS units'),
  ;

  final String name;
  const LayoutVariant(this.name);
}

class FloridaLiveBirdHandlingArea extends LiveBirdHandlingArea {
  final LayoutVariant layoutVariant;
  FloridaLiveBirdHandlingArea(
      ProductDefinition productDefinition, this.layoutVariant)
      : super(
          lineName: layoutVariant.name,
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

    /// Shuttle durations and speeds from time measurements
    /// at 9423 Wech via e-won by Roel on 2025-01-22
    var shuttleConveyorSpeedProfile = SpeedProfile.total(
        totalDistance: 3.05,
        // added 1 sec because simulation seems to be running a bit faster
        totalDurationInSeconds: 14.5 + 1,
        accelerationInSeconds: 1.5,
        decelerationInSeconds: 0.7);

    var shuttle = ModuleShuttle(
      area: this,

      /// Shuttle (un)locking is switched off (takes 3.2 seconds at Wech)
      /// but the shuttle needs to wait unti the CAS doors open
      /// CAS1 +2 door open in 3.5sec (as Wech)
      /// CAS 3 door open in 7 sec (assuming we can bring change this to 3.5 sec)
      lockDuration: Duration(milliseconds: 3500),

      /// Shuttle (un)locking is switched off (takes 3.2 seconds at Wech)
      /// Normaly unlock occurs middle container sensor on carrier
      /// is (de) activated, while container is still transporting
      /// so outside the critical time path and therefore 0s
      unlockDuration: Duration.zero,

      /// stack into destacker	                      16.5 s
      /// stack into shuttle at pos 0/1               14.0 s
      /// stack into destacker & shuttle at pos 0/1	  20.5 s
      /// Start delay simontanuously feed in after feed out started= 20.5 - 16.5 = 4s
      conveyorSimultaneousFeedInDelay: Duration(seconds: 4),

      //                        	Total duration	Distance	  Calculated max speed
      // stack into CAS		                14.5 s	  3.050 m	  0.2276 m/s
      // stack out of CAS		              14.5 s	  3.050 m	  0.2276 m/s
      // stack into destacker		          16.5 s	  3.200 m	  0.2078 m/s
      // stack into shuttle at pos 0/1		14.0 s	  2.800 m	  0.2171 m/s

      conveyorSpeedProfile: shuttleConveyorSpeedProfile,

      // Between	                    And	    Total duration	Distance	Calculated max speed
      // Infeed conveyor\ destacker	  CAS 1+2	       9.7 s	  2.488 m	  0.3231 m/s
      // Infeed conveyor\ destacker	  CAS 3+4	      17.0 s	  4.976 m	  0.3317 m/s
      // CAS 1+2	                    CAS 3+4	       9.7 s	  2.488 m	  0.3231 m/s

      carrierSpeedProfile: SpeedProfile.total(
          totalDistance: 2.488,
          //// added 1 sec because simulation seems to be running a bit faster
          totalDurationInSeconds: 9.7 + 1,
          accelerationInSeconds: 2,
          decelerationInSeconds: 2),

      /// distances from layout
      /// pos0: CAS3 is at left position
      ///   in between 2.488m
      /// pos1: CAS1+2 is at middle position
      ///   in between 2.488m
      /// pos2: Infeedconveyor and destacker are at right position
      betweenPositionsInMeters: [2.488, 2.488],
    );

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.rollDoorUp,
      conveyorSpeedProfile: shuttleConveyorSpeedProfile,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      moduleDoor: ModuleDoor.rollDoorUp,
      conveyorSpeedProfile: shuttleConveyorSpeedProfile,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: false,
      moduleDoor: ModuleDoor.rollDoorUp,
      conveyorSpeedProfile: shuttleConveyorSpeedProfile,
    );

    var cas4 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      moduleDoor: ModuleDoor.rollDoorUp,
      conveyorSpeedProfile: shuttleConveyorSpeedProfile,
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
    if (layoutVariant == LayoutVariant.toBe) {
      systems.link(
          shuttle.modulesOuts[
              ShuttleLinkLocation(position: 0, side: ShuttleSide.a)]!,
          cas4.modulesIn);
      systems.link(
          cas4.modulesOut,
          shuttle.modulesIns[
              ShuttleLinkLocation(position: 0, side: ShuttleSide.a)]!);
    }
    systems.link(
        shuttle.modulesOuts[
            ShuttleLinkLocation(position: 0, side: ShuttleSide.b)]!,
        cas3.modulesIn);
    systems.link(
        cas3.modulesOut,
        shuttle.modulesIns[
            ShuttleLinkLocation(position: 0, side: ShuttleSide.b)]!);

    // shuttle middle
    systems.link(
        shuttle.modulesOuts[
            ShuttleLinkLocation(position: 1, side: ShuttleSide.b)]!,
        cas1.modulesIn);
    systems.link(
        cas1.modulesOut,
        shuttle.modulesIns[
            ShuttleLinkLocation(position: 1, side: ShuttleSide.b)]!);

    systems.link(
        shuttle.modulesOuts[
            ShuttleLinkLocation(position: 1, side: ShuttleSide.a)]!,
        cas2.modulesIn);
    systems.link(
        cas2.modulesOut,
        shuttle.modulesIns[
            ShuttleLinkLocation(position: 1, side: ShuttleSide.a)]!);

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
