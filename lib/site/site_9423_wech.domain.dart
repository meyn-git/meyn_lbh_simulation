import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/area/module/brand.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_buffer_lane/module_buffer_lane.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_rotating_conveyor/module_rotating_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_shuttle/module_suttle.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter_dump_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_washer/module_washer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shackle_conveyor/shackle_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_loading_conveyor/module_loading_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
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

class WechSite extends Site {
  WechSite()
    : super(
        meynLayoutNumber: 9423,
        organizationName: 'Wech Geflugel GmbH',
        city: 'st Andrä im Lavanttal',
        country: 'Austria',
        productDefinitions: WechProductDefinitions(),
      );
}

const smallBirdsPerCompartment = 48;
const smallBirdsPerContainer = smallBirdsPerCompartment * 8;
const bigBirdsPerCompartment = 28;
const bigBirdsPerContainer = smallBirdsPerCompartment * 8;

/// information from email Marc van der Giessen 2025-01-17
class WechProductDefinitions extends DelegatingList<ProductDefinition> {
  WechProductDefinitions()
    : super([
        // as sold 9000
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            WechLiveBirdHandlingArea(
              productDefinition,
              LayoutVariant.installed2013,
            ),
          ],
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 9000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: truckRows,
        ),
        // as sold 15000
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            WechLiveBirdHandlingArea(
              productDefinition,
              LayoutVariant.installed2013,
            ),
          ],
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 15000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: truckRows,
        ),
        // with4thCasUnitsInLine 15000
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            WechLiveBirdHandlingArea(
              productDefinition,
              LayoutVariant.with4thCasUnitInLine,
            ),
          ],
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 15000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: truckRows,
        ),
        // with4thCasUnitOtherSide 15000
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            WechLiveBirdHandlingArea(
              productDefinition,
              LayoutVariant.with4thCasUnitOtherSide,
            ),
          ],
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 15000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: truckRows,
        ),
        // with4thCasUnitAndTurnTables 20000
        ProductDefinition(
          areaFactory: (ProductDefinition productDefinition) => [
            WechLiveBirdHandlingArea(
              productDefinition,
              LayoutVariant.with4thCasUnitAndTurnTables,
            ),
          ],
          birdType: 'Chicken',
          lineSpeedInShacklesPerHour: 20000,
          lineShacklePitchInInches: 6,
          casRecipe: const CasRecipe.standardChickenRecipe(),
          truckRows: truckRows,
        ),
      ]);

  static List<TruckRow> get truckRows {
    return [
      TruckRow({
        PositionWithinModuleGroup.firstBottom: BrandBuilder().marel.gpl.l4
            .build()
            .withBirdsPerCompartment(bigBirdsPerCompartment),
        PositionWithinModuleGroup.firstTop: BrandBuilder().marel.gpl.l4
            .build()
            .withBirdsPerCompartment(bigBirdsPerCompartment),
      }),
    ];
  }
}

enum LayoutVariant {
  installed2013('As installed on 2013'),
  with4thCasUnitInLine('With 4th CAS units in line'),
  with4thCasUnitOtherSide('With 4th CAS units on other side'),
  with4thCasUnitAndTurnTables('With 4th CAS units and turn tables');

  final String name;
  const LayoutVariant(this.name);
}

class WechLiveBirdHandlingArea extends LiveBirdHandlingArea {
  static const int levelsOfModulesInCas = 2;
  static const int numberOfModuleStacksForCasUnits = 1;
  final LayoutVariant variant;
  WechLiveBirdHandlingArea(ProductDefinition productDefinition, this.variant)
    : super(lineName: variant.name, productDefinition: productDefinition);

  @override
  void createSystemsAndLinks() {
    systems.startDirection = const CompassDirection.east();

    var loadingForkLiftTruck = LoadingForkLiftTruck(
      area: this,
      moduleBirdExitDirection: ModuleBirdExitDirection.right,
    );

    var loadingConveyor = ModuleLoadingConveyor(area: this);

    var mc1 = ModuleConveyor(area: this);

    var cas1 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesInCas,
      moduleDoor: _casDoor,
    );

    var cas2 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesInCas,
      moduleDoor: _casDoor,
    );

    var cas3 = ModuleCas(
      area: this,
      gasDuctsLeft: true,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesInCas,
      moduleDoor: _casDoor,
    );

    var cas4 = ModuleCas(
      area: this,
      numberOfModuleStacks: numberOfModuleStacksForCasUnits,
      levelsOfModules: levelsOfModulesInCas,
      gasDuctsLeft: !(variant == LayoutVariant.with4thCasUnitOtherSide),
      moduleDoor: _casDoor,
      conveyorSpeedProfile: variant == LayoutVariant.with4thCasUnitOtherSide
          ? SpeedProfile.total(
              totalDistance: 3.05,

              /// adding 10 seconds for extra conveyor because we need to go trough a wall
              totalDurationInSeconds: 13.8 + 10,
              accelerationInSeconds: 1.5,
              decelerationInSeconds: 0.7,
            )
          : null,
    );

    var destacker = ModuleDeStacker(area: this);

    var moduleTilter = ModuleTilter(
      area: this,
      tiltDirection: Direction.clockWise,
    );

    var dumpConveyor = ModuleTilterDumpConveyor(area: this);

    var shackleConveyor = ShackleConveyor(
      area: this,
      direction: Direction.counterClockWise,
    );

    var mc2 = ModuleConveyor(area: this);

    var mrc6 = ModuleRotatingConveyor(
      area: this,
      turnPositions: [
        TurnPosition(direction: CompassDirection.west()),
        TurnPosition(direction: CompassDirection.north().rotate(-10)),
      ],
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );

    var containerDipper = ModuleWasherConveyor(area: this, lengthInMeters: 5.5);
    var preWasher = ModuleWasherConveyor(area: this, lengthInMeters: 5.5);

    var mc3 = ModuleConveyor(area: this);

    var mrc7 = ModuleRotatingConveyor(
      area: this,
      turnPositions: [
        TurnPosition(direction: CompassDirection.south().rotate(-10)),
        TurnPosition(direction: CompassDirection.east()),
      ],
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );

    var buffer1_1 = ModuleBufferAngleTransferInFeed(
      area: this,
      moduleOutDirection: Direction.clockWise,
    );
    var buffer1_2 = ModuleBufferConveyor(area: this);
    var buffer1_3 = ModuleBufferConveyor(area: this);
    var buffer1_4 = ModuleBufferConveyor(area: this);
    var buffer1_5 = ModuleBufferConveyor(area: this);
    var buffer1_6 = ModuleBufferConveyor(area: this);
    var buffer1_7 = ModuleBufferAngleTransferOutFeed(
      area: this,
      moduleOutDirection: Direction.counterClockWise,
    );

    var mainWasher2 = ModuleWasherConveyor(area: this, lengthInMeters: 4.4);

    var mainWasher3 = ModuleWasherConveyor(area: this, lengthInMeters: 4.4);

    var mainWasher4 = ModuleWasherConveyor(area: this, lengthInMeters: 4.4);

    var mc4 = ModuleConveyor(area: this);

    var stacker = ModuleStacker(area: this);

    var unLoadingForkLiftTruck = UnLoadingForkLiftTruck(area: this);

    /// module transport
    systems.link(loadingForkLiftTruck.modulesOut, loadingConveyor.modulesIn);
    systems.link(loadingConveyor.modulesOut, mc1.modulesIn);

    if (variant == LayoutVariant.with4thCasUnitAndTurnTables) {
      createAndLinkCasTurnTables(
        mc1: mc1,
        cas1: cas1,
        cas2: cas2,
        cas3: cas3,
        cas4: cas4,
        destacker: destacker,
      );
    } else {
      createAndLinkCasShuttle(
        mc1: mc1,
        cas1: cas1,
        cas2: cas2,
        cas3: cas3,
        cas4: cas4,
        destacker: destacker,
      );
    }

    systems.link(destacker.modulesOut, moduleTilter.modulesIn);
    systems.link(moduleTilter.modulesOut, mc2.modulesIn);
    systems.link(mc2.modulesOut, mrc6.modulesIns[0]);
    systems.link(mrc6.modulesOuts[1], containerDipper.modulesIn);
    systems.link(containerDipper.modulesOut, preWasher.modulesIn);
    systems.link(preWasher.modulesOut, mc3.modulesIn);
    systems.link(mc3.modulesOut, mrc7.modulesIns[0]);
    systems.link(mrc7.modulesOuts[1], mainWasher2.modulesIn);
    systems.link(mainWasher2.modulesOut, mainWasher3.modulesIn);
    systems.link(mainWasher3.modulesOut, mainWasher4.modulesIn);
    systems.link(mainWasher4.modulesOut, mc4.modulesIn);
    systems.link(mc4.modulesOut, stacker.modulesIn);
    systems.link(stacker.modulesOut, buffer1_1.modulesIn);
    systems.link(buffer1_1.modulesOut, buffer1_2.modulesIn);
    systems.link(buffer1_2.modulesOut, buffer1_3.modulesIn);
    systems.link(buffer1_3.modulesOut, buffer1_4.modulesIn);
    systems.link(buffer1_4.modulesOut, buffer1_5.modulesIn);
    systems.link(buffer1_5.modulesOut, buffer1_6.modulesIn);
    systems.link(buffer1_6.modulesOut, buffer1_7.modulesIn);
    systems.link(buffer1_7.modulesOut, unLoadingForkLiftTruck.modulesIn);

    /// bird transport
    systems.link(moduleTilter.birdsOut, dumpConveyor.birdsIn);
    systems.link(dumpConveyor.birdOut, shackleConveyor.birdsIn);

    systems.add(
      ModuleCasAllocation(area: this, allocationPlace: mc1.moduleGroupPlace),
    );

    systems.add(ModuleCasStart(area: this));
  }

  ModuleDoor get _casDoor =>
      variant == LayoutVariant.with4thCasUnitAndTurnTables
      ? ModuleDoor.slideDoorToLeft
      : ModuleDoor.rollDoorUp;

  void createAndLinkCasShuttle({
    required ModuleCas cas4,
    required ModuleCas cas3,
    required ModuleCas cas2,
    required ModuleCas cas1,
    required ModuleConveyor mc1,
    required ModuleDeStacker destacker,
  }) {
    /// Shuttle durations and speeds from time measurements
    /// at 9423 Wech via e-won by Roel on 2025-01-22
    var shuttle = ModuleShuttle(
      area: this,

      /// Locking takes 3.2 seconds
      /// but the CAS doors also open (3.5sec) when locking
      /// terfore locking is set to 3.5s
      lockDuration: Duration(milliseconds: 3500),

      /// unlocking takes 3.2 seconds
      /// unlock occurs middle container sensor on carrier
      /// is (de) activated, while container is still transporting
      /// so outside the critical time path and therefore 0s
      unlockDuration: Duration.zero,

      /// stack into destacker	                      14.5 s
      /// stack into shuttle at pos 0/1               12.4 s
      /// stack into destacker & shuttle at pos 0/1	  18.5 s
      /// Start delay simontanuously feed in after feed out started= 18.5 - 14.5 = 4s
      conveyorSimultaneousFeedInDelay: Duration(seconds: 4),

      // 	                        Total duration	Distance	Calculated max speed
      //  stack into CAS	                13.8 s	  3.050 m	    0.2402 m/s
      //  stack out of CAS	              13.8 s	  3.050 m	    0.2402 m/s
      //  stack into destacker            14.5 s	  3.200 m	    0.2388 m/s
      //  stack into shuttle at pos 0/1   12.4 s	  2.800 m	    0.2478 m/s
      conveyorSpeedProfile: SpeedProfile.total(
        totalDistance: 3.2,
        // added 1 sec because simulation seems to be running a bit faster
        totalDurationInSeconds: 14.5 + 1,
        accelerationInSeconds: 1.5,
        decelerationInSeconds: 0.7,
      ),

      // Between	                    And	 total duration	Distance	Calculated  max speed
      // Infeed conveyor\ destacker	  CAS1	  15.4 s    	 4.279 m    0.3193 m/s
      // Infeed conveyor\ destacker	  CAS2	  27.3 s    	 7.976 m    0.3153 m/s
      // Infeed conveyor\ destacker	  CAS3	  35.5 s    	10.464 m	  0.3124 m/s
      // CAS1	                        CAS2	  14.2 s    	 3.697 m	  0.3030 m/s
      // CAS2	                        CAS3	  10.3 s    	 2.488 m	  0.2998 m/s
      // CAS1	                        CAS3	  22.3 s    	 6.185 m	  0.3047 m/s
      carrierSpeedProfile: SpeedProfile.total(
        totalDistance: 10.464,
        //// added 2 sec because simulation seems to be running a bit faster
        totalDurationInSeconds: 35.5 + 2,
        accelerationInSeconds: 2,
        decelerationInSeconds: 2,
      ),

      // distances from layout 9423s114z0001 sketch
      betweenPositionsInMeters: [
        /// assumption: if we add an addtional cas unit by
        /// extending the shuttle, we will use the same
        /// CAS unit pitch as the last 2 CAS units
        if (variant == LayoutVariant.with4thCasUnitInLine) 2.488,
        2.488,
        3.697,
        4.279,
      ],
    );

    var shuttlePos = 0;
    // first shuttle pos 0 (Left)
    if (variant == LayoutVariant.with4thCasUnitInLine) {
      systems.link(
        cas4.modulesOut,
        shuttle.modulesIns[ShuttleLinkLocation(
          position: shuttlePos,
          side: ShuttleSide.b,
        )]!,
      );
      systems.link(
        shuttle.modulesOuts[ShuttleLinkLocation(
          position: shuttlePos,
          side: ShuttleSide.b,
        )]!,
        cas4.modulesIn,
      );
      shuttlePos++;
    }

    systems.link(
      shuttle.modulesOuts[ShuttleLinkLocation(
        position: shuttlePos,
        side: ShuttleSide.b,
      )]!,
      cas3.modulesIn,
    );
    systems.link(
      cas3.modulesOut,
      shuttle.modulesIns[ShuttleLinkLocation(
        position: shuttlePos,
        side: ShuttleSide.b,
      )]!,
    );
    shuttlePos++;

    systems.link(
      shuttle.modulesOuts[ShuttleLinkLocation(
        position: shuttlePos,
        side: ShuttleSide.b,
      )]!,
      cas2.modulesIn,
    );
    systems.link(
      cas2.modulesOut,
      shuttle.modulesIns[ShuttleLinkLocation(
        position: shuttlePos,
        side: ShuttleSide.b,
      )]!,
    );
    shuttlePos++;

    systems.link(
      shuttle.modulesOuts[ShuttleLinkLocation(
        position: shuttlePos,
        side: ShuttleSide.b,
      )]!,
      cas1.modulesIn,
    );
    systems.link(
      cas1.modulesOut,
      shuttle.modulesIns[ShuttleLinkLocation(
        position: shuttlePos,
        side: ShuttleSide.b,
      )]!,
    );

    if (variant == LayoutVariant.with4thCasUnitOtherSide) {
      systems.link(
        shuttle.modulesOuts[ShuttleLinkLocation(
          position: shuttlePos,
          side: ShuttleSide.a,
        )]!,
        cas4.modulesIn,
      );
      systems.link(
        cas4.modulesOut,
        shuttle.modulesIns[ShuttleLinkLocation(
          position: shuttlePos,
          side: ShuttleSide.a,
        )]!,
      );
    }
    shuttlePos++;

    // last shuttle pos (Right)
    systems.link(
      mc1.modulesOut,
      shuttle.modulesIns[ShuttleLinkLocation(
        position: shuttlePos,
        side: ShuttleSide.a,
      )]!,
    );
    systems.link(
      shuttle.modulesOuts[ShuttleLinkLocation(
        position: shuttlePos,
        side: ShuttleSide.b,
      )]!,
      destacker.modulesIn,
    );
  }

  void createAndLinkCasTurnTables({
    required ModuleConveyor mc1,
    required ModuleCas cas1,
    required ModuleCas cas2,
    required ModuleCas cas3,
    required ModuleCas cas4,
    required ModuleDeStacker destacker,
  }) {
    var mrc1 = ModuleRotatingConveyor(
      area: this,
      turnPositions: [
        TurnPosition(direction: CompassDirection.west()),
        TurnPosition(direction: CompassDirection.east(), reverseFeedIn: true),
        TurnPosition(direction: CompassDirection.south()),
      ],
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );

    var mrc2 = ModuleRotatingConveyor(
      area: this,
      turnPositions: [
        TurnPosition(direction: CompassDirection.north()),
        TurnPosition(direction: CompassDirection.east(), reverseFeedIn: true),
        TurnPosition(direction: CompassDirection.south()),
      ],
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );

    var mrc3 = ModuleRotatingConveyor(
      area: this,
      turnPositions: [
        TurnPosition(direction: CompassDirection.north()),
        TurnPosition(direction: CompassDirection.east(), reverseFeedIn: true),
        TurnPosition(direction: CompassDirection.south()),
      ],
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );

    var mrc4 = ModuleRotatingConveyor(
      area: this,
      turnPositions: [
        TurnPosition(direction: CompassDirection.north()),
        TurnPosition(direction: CompassDirection.east(), reverseFeedIn: true),
        TurnPosition(direction: CompassDirection.south()),
      ],
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );

    var mrc5 = ModuleRotatingConveyor(
      area: this,
      turnPositions: [
        TurnPosition(direction: CompassDirection.north()),
        TurnPosition(direction: CompassDirection.east()),
      ],
      diameter: ModuleRotatingConveyorDiameter.beforeModuleCas,
    );

    systems.link(mc1.modulesOut, mrc1.modulesIns[0]);
    systems.link(mrc1.modulesOuts[1], cas1.modulesIn);
    systems.link(cas1.modulesOut, mrc1.modulesIns[1]);
    systems.link(mrc1.modulesOuts[2], mrc2.modulesIns[0]);

    systems.link(mrc2.modulesOuts[1], cas2.modulesIn);
    systems.link(cas2.modulesOut, mrc2.modulesIns[1]);
    systems.link(mrc2.modulesOuts[2], mrc3.modulesIns[0]);

    systems.link(mrc3.modulesOuts[1], cas3.modulesIn);
    systems.link(cas3.modulesOut, mrc3.modulesIns[1]);
    systems.link(mrc3.modulesOuts[2], mrc4.modulesIns[0]);

    systems.link(mrc4.modulesOuts[1], cas4.modulesIn);
    systems.link(cas4.modulesOut, mrc4.modulesIns[1]);
    systems.link(mrc4.modulesOuts[2], mrc5.modulesIns[0]);

    systems.link(mrc5.modulesOuts[1], destacker.modulesIn);
  }
}
