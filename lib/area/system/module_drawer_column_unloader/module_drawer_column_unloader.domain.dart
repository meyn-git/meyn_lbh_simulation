// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/drawer/drawer.domain.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/module/drawer.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module_variant_builder.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_bird_unloader.dart';
import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_column_unloader/module_drawer_column_unloader.presentation.dart';
import 'package:user_command/user_command.dart';

class ModuleDrawerColumnUnloader extends StateMachine
    implements ModuleBirdUnloader {
  final LiveBirdHandlingArea area;

  ///Number of birds on dumping belt between module and hanger (a buffer).
  ///The unloader starts tilting when birdsOnDumpBelt<dumpBeltBufferSize
  ///Normally this number is between the number of birds in 1 or 2 modules
  // final Duration checkIfEmptyDuration;
  // final Duration inFeedDuration;
  // final Duration outFeedDuration;
  final Duration pusherOutDuration;
  final Duration pusherInDuration;
  final Duration feedInToSecondColumn;
  final Direction drawerOutDirection;
  final bool singleColumnOfCompartments;
  final SpeedProfile conveyorSpeedProfile;

  @override
  final double waitingCasModuleLoadSetPoint = 1.0;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  Duration? durationPerModule;
  Durations durationsPerModule = Durations(maxSize: 8);

  late final List<DrawerPlace> drawerPlaces = [
    for (int level = 0; level < 5; level++)
      DrawerPlace(
        system: this,
        centerToDrawerCenterWhenSystemFacesNorth: shape.centerToConveyorCenter,
      ),
  ];

  late final CompassDirection drawerFeedOutDirection = drawersOut
      .directionToOtherLink
      .rotate(area.layout.rotationOf(this).degrees);

  ModuleDrawerColumnUnloader({
    required this.area,
    required this.drawerOutDirection,
    SpeedProfile? conveyorSpeed,
    this.pusherOutDuration = const Duration(
      milliseconds: 3400,
    ), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    this.pusherInDuration = const Duration(
      milliseconds: 3400,
    ), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    this.feedInToSecondColumn = const Duration(
      milliseconds: 6000,
    ), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
  }) : conveyorSpeedProfile =
           conveyorSpeed ?? area.productDefinition.speedProfiles.moduleConveyor,
       singleColumnOfCompartments = allModulesHaveOneSingleCompartmentColumn(
         area,
       ),
       super(initialState: CheckIfEmpty());

  static bool allModulesHaveOneSingleCompartmentColumn(
    LiveBirdHandlingArea area,
  ) => area.productDefinition.truckRows.every(
    (truckRow) => truckRow.templates.every(
      (moduleTemplate) => moduleTemplate.variant.compartmentsPerLevel == 1,
    ),
  );

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late DrawersOutLink drawersOut = DrawersOutLink(
    system: this,
    offsetFromCenterWhenFacingNorth: shape.centerToDrawersOutLink,
    directionToOtherLink: drawerOutDirection == Direction.counterClockWise
        ? const CompassDirection.west()
        : const CompassDirection.east(),
  );

  late final ModuleDrawerColumnUnloaderShape shape =
      ModuleDrawerColumnUnloaderShape(this);

  late ModuleGroupPlace moduleGroupFirstColumnPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToFirstColumn,
  );

  late ModuleGroupPlace moduleGroupSecondColumnPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToSecondColumn,
  );

  late ModuleGroupPlace moduleGroupSingleColumnPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter,
  );

  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: singleColumnOfCompartments
        ? moduleGroupSingleColumnPlace
        : moduleGroupFirstColumnPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleInLink,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () =>
        SimultaneousFeedOutFeedInModuleGroup.canFeedIn(currentState),
  );

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: singleColumnOfCompartments
        ? moduleGroupSingleColumnPlace
        : moduleGroupSecondColumnPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleOutLink,
    directionToOtherLink: const CompassDirection.north(),
    durationUntilCanFeedOut: () =>
        SimultaneousFeedOutFeedInModuleGroup.durationUntilCanFeedOut(
          currentState,
        ),
  );

  @override
  late List<Link> links = [modulesIn, modulesOut, drawersOut];

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    if (durationPerModule != null) {
      durationPerModule = durationPerModule! + jump;
    }
  }

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendProperty(
        ' speed',
        '${durationsPerModule.averagePerHour.toStringAsFixed(1)} modules/hour',
      )
      .appendProperty(
        'moduleGroup',
        moduleGroupFirstColumnPlace.moduleGroup ??
            moduleGroupSecondColumnPlace.moduleGroup,
      );

  void onEndOfCycle() {
    durationsPerModule.add(durationPerModule);
    durationPerModule = Duration.zero;
  }

  @override
  late final String name = 'ModuleDrawerColumnUnloader$seqNr';

  late final int seqNr = area.systems.seqNrOf(this);
}

class CheckIfEmpty extends DurationState<ModuleDrawerColumnUnloader> {
  @override
  String get name => 'CheckIfEmpty';

  CheckIfEmpty()
    : super(
        durationFunction: (unloader) => unloader.conveyorSpeedProfile
            .durationOfDistance(unloader.shape.xInMeters * 1.5),
        nextStateFunction: (unloader) => SimultaneousFeedOutFeedInModuleGroup(
          modulesIn: unloader.modulesIn,
          modulesOut: unloader.modulesOut,
          inFeedDelay: Duration.zero,
          nextStateCondition:
              NextStateCondition.whenFeedInIsCompletedAndFeedOutIsStarted,
          stateWhenCompleted: WaitToPushOutColumn(
            unloader.singleColumnOfCompartments
                ? ColumnToProcess.only
                : ColumnToProcess.first,
          ),
        ),
      );
}

enum ColumnToProcess {
  first('First'),
  second('Second'),
  only('Only');

  final String name;

  const ColumnToProcess(this.name);

  ModuleGroup moduleGroupOf(ModuleDrawerColumnUnloader unloader) {
    switch (this) {
      case first:
        return unloader.moduleGroupFirstColumnPlace.moduleGroup!;
      case second:
        return unloader.moduleGroupSecondColumnPlace.moduleGroup!;
      default:
        return unloader.moduleGroupSingleColumnPlace.moduleGroup!;
    }
  }

  State<ModuleDrawerColumnUnloader> nextStateAfterPusherIn(
    ModuleDrawerColumnUnloader unloader,
  ) {
    switch (this) {
      case first:
        return FeedInToSecondColumn();
      default:
        return SimultaneousFeedOutFeedInModuleGroup(
          modulesIn: unloader.modulesIn,
          modulesOut: unloader.modulesOut,
          inFeedDelay: Duration.zero,
          nextStateCondition:
              NextStateCondition.whenFeedInIsCompletedAndFeedOutIsStarted,
          stateWhenCompleted: WaitToPushOutColumn(
            unloader.singleColumnOfCompartments
                ? ColumnToProcess.only
                : ColumnToProcess.first,
          ),
        );
    }
  }
}

class WaitToPushOutColumn extends State<ModuleDrawerColumnUnloader> {
  final ColumnToProcess columnToProcess;

  WaitToPushOutColumn(this.columnToProcess);

  @override
  String get name => 'WaitToPushOut${columnToProcess.name}Column';

  @override
  State<ModuleDrawerColumnUnloader>? nextState(
    ModuleDrawerColumnUnloader unloader,
  ) {
    var moduleGroup = columnToProcess.moduleGroupOf(unloader);
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle multiple modules');
    }
    int levels = moduleGroup.modules.first.variant.levels;
    if (unloader.drawersOut.linkedTo!.numberOfDrawersToFeedIn() >= levels) {
      return PushOutColumn(columnToProcess);
    }
    return null;
  }
}

class PushOutColumn extends DurationState<ModuleDrawerColumnUnloader> {
  final ColumnToProcess columnToProcess;

  @override
  String get name => 'PushOut${columnToProcess.name}Column';

  PushOutColumn(this.columnToProcess)
    : super(
        durationFunction: (unloader) => unloader.pusherOutDuration,
        nextStateFunction: (unloader) => PusherIn(columnToProcess),
      );
  @override
  void onStart(ModuleDrawerColumnUnloader unloader) {
    super.onStart(unloader);
    _verifyModuleGroup(unloader);
    _createAndTransportDrawers(unloader);
  }

  void _createAndTransportDrawers(ModuleDrawerColumnUnloader unloader) {
    var drawers = unloader.area.drawers;
    var moduleGroup = columnToProcess.moduleGroupOf(unloader);
    var module = moduleGroup.modules.first;
    var levels = module.variant.levels;
    var nrOfBirdsPerDrawer = module.nrOfBirds / 2 ~/ levels;
    var contents = moduleGroup.contents;
    for (int level = levels - 1; level >= 0; level--) {
      var drawer = GrandeDrawer(
        nrOfBirds: nrOfBirdsPerDrawer,
        contents: contents,
        position: AtDrawerPlace(unloader.drawerPlaces[level]),
        sinceEndStun: moduleGroup.sinceEndStun,
      );
      drawers.add(drawer);
      unloader.drawerPlaces[level].drawer = drawer;
      drawer.position = UnloaderToLiftPosition(
        unloader: unloader,
        level: level,
      );
    }
  }

  void _verifyModuleGroup(ModuleDrawerColumnUnloader unloader) {
    var moduleGroup = columnToProcess.moduleGroupOf(unloader);
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('${unloader.name}:  can not handle multiple modules');
    }
    if (moduleGroup.compartment.birdsExitOnOneSide &&
        moduleGroup.direction.rotate(-90) != unloader.drawerFeedOutDirection) {
      if (moduleGroup.compartment is CompartmentWithDoor) {
        throw ('${unloader.name}: Can not process containers');
      } else {
        throw ('${unloader.name}: Incorrect drawer out feed direction '
            'of: $ModuleGroup');
      }
    }
  }
}

class PusherIn extends DurationState<ModuleDrawerColumnUnloader> {
  final ColumnToProcess columnToProcess;

  @override
  String get name => 'PusherInFirstColumn';

  PusherIn(this.columnToProcess)
    : super(
        durationFunction: (unloader) => unloader.pusherInDuration,
        nextStateFunction: (unloader) =>
            columnToProcess.nextStateAfterPusherIn(unloader),
      );

  @override
  void onCompleted(ModuleDrawerColumnUnloader unloader) {
    if (columnToProcess != ColumnToProcess.first) {
      super.onCompleted(unloader);
      unloader.onEndOfCycle();
      columnToProcess.moduleGroupOf(unloader).unloadBirds();
    }
  }
}

class FeedInToSecondColumn extends State<ModuleDrawerColumnUnloader>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedInToSecondColumn';

  @override
  void onStart(ModuleDrawerColumnUnloader unloader) {
    var moduleGroup = unloader.moduleGroupFirstColumnPlace.moduleGroup!;
    moduleGroup.position = BetweenModuleGroupPlaces(
      source: unloader.moduleGroupFirstColumnPlace,
      destination: unloader.moduleGroupSecondColumnPlace,
      duration: unloader.feedInToSecondColumn,
    );
  }

  @override
  State<ModuleDrawerColumnUnloader>? nextState(
    ModuleDrawerColumnUnloader stateMachine,
  ) {
    if (transportCompleted) {
      return WaitToPushOutColumn(ColumnToProcess.second);
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}
// TODO remove?
// class WaitToPushOutSecondColumn extends State<ModuleDrawerColumnUnloader> {
//   @override
//   String get name => 'WaitToPushOutSecondColumn';

//   @override
//   State<ModuleDrawerColumnUnloader>? nextState(
//       ModuleDrawerColumnUnloader unloader) {
//     var moduleGroup = unloader.moduleGroupSecondColumnPlace.moduleGroup!;
//     if (moduleGroup.numberOfModules > 2) {
//       throw Exception('Unloader can not handle stacked containers');
//     }
//     int levels = moduleGroup.modules.first.variant.levels;
//     if (unloader.drawersOut.linkedTo!.numberOfDrawersToFeedIn() >= levels) {
//       return PusherOutSecondColumn();
//     }
//     return null;
//   }
// }

// class PusherOutSecondColumn extends DurationState<ModuleDrawerColumnUnloader> {
//   @override
//   String get name => 'PusherOutSecondColumn';

//   PusherOutSecondColumn()
//       : super(
//             durationFunction: (unloader) => unloader.pusherOutDuration,
//             nextStateFunction: (unloader) => PusherInSecondColumn());

//   @override
//   void onStart(ModuleDrawerColumnUnloader unloader) {
//     super.onStart(unloader);
//     var drawers = unloader.area.drawers;
//     var moduleGroup = unloader.moduleGroupSecondColumnPlace.moduleGroup!;
//     var module = moduleGroup.modules.first;
//     var levels = module.variant.levels;
//     var nrOfBirdsPerDrawer = module.nrOfBirds / 2 ~/ levels;
//     var contents = moduleGroup.contents;
//     for (int level = levels - 1; level >= 0; level--) {
//       var drawer = GrandeDrawer(
//         nrOfBirds: nrOfBirdsPerDrawer,
//         contents: contents,
//         position: AtDrawerPlace(unloader.drawerPlaces[level]),
//         sinceEndStun: moduleGroup.sinceEndStun,
//       );
//       drawers.add(drawer);
//       unloader.drawerPlaces[level].drawer = drawer;
//       drawer.position =
//           UnloaderToLiftPosition(unloader: unloader, level: level);
//     }
//   }

//   @override
//   void onCompleted(ModuleDrawerColumnUnloader unloader) {
//     super.onCompleted(unloader);
//     var moduleGroup = unloader.moduleGroupSecondColumnPlace.moduleGroup!;
//     if (moduleGroup.numberOfModules > 2) {
//       throw Exception('Unloader can not handle stacked containers');
//     }
//     moduleGroup.unloadBirds();
//   }
// }

// class PusherInSecondColumn extends DurationState<ModuleDrawerColumnUnloader> {
//   @override
//   String get name => 'PusherInSecondColumn';

//   PusherInSecondColumn()
//       : super(
//           durationFunction: (unloader) => unloader.pusherInDuration,
//           nextStateFunction: (unloader) => SimultaneousFeedOutFeedInModuleGroup(
//             modulesIn: unloader.modulesIn,
//             modulesOut: unloader.modulesOut,
//             inFeedDelay: Duration.zero,
//             nextStateCondition:
//                 NextStateCondition.whenFeedInIsCompletedAndFeedOutIsStarted,
//             stateWhenCompleted: WaitToPushOutColumn(),
//           ),
//         );

//   @override
//   void onCompleted(ModuleDrawerColumnUnloader unloader) {
//     super.onCompleted(unloader);
//     unloader.onEndOfCycle();
//   }
// }

class DrawerUnloaderLift extends StateMachine implements LinkedSystem {
  final LiveBirdHandlingArea area;
  @override
  late final String name = 'DrawerUnloaderLift$seqNr';

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];
  final int levels;
  final double lengthInMeters;

  /// position[0]=bottom position in lift
  /// position[nrOfPositions-1]=top position in lift
  /// null =  without drawer
  final Duration upDuration;
  final Duration pushOutDuration;

  Duration drawerPushOutCycle = Duration.zero;
  Durations drawerPushOutCycles = Durations(maxSize: 20);

  GrandeDrawer? precedingDrawer;

  late final DrawerUnloaderLiftShape shape = DrawerUnloaderLiftShape(this);

  // bool feedingInDrawers = false;

  late final ModuleDrawerColumnUnloader unloader =
      drawersIn.linkedTo! as ModuleDrawerColumnUnloader;
  late final FeedOutCrossOver feedOutCrossOver = FeedOutCrossOver(this);

  late final List<DrawerPlace> drawerPlaces = shape
      .centerLiftToDrawerCenterInLift
      .map(
        (offset) => DrawerPlace(
          system: this,
          centerToDrawerCenterWhenSystemFacesNorth: offset,
        ),
      )
      .toList();

  bool get feedingInDrawers =>
      currentState is PushOutColumn || currentState is PusherIn;
  // TODO remove? ||
  // currentState is PusherOutSecondColumn ||
  // currentState is PusherInSecondColumn;

  DrawerUnloaderLift({
    required this.area,
    this.upDuration = const Duration(
      milliseconds: 1600,
    ), // Based on "Speed calculations_estimates_V3_Erik.xlsx"

    this.pushOutDuration = const Duration(
      milliseconds: 2500,
    ), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    this.levels = 6,
    this.lengthInMeters = 1.2, // TODO
  }) : super(initialState: SimultaneouslyFeedInAndFeedOutDrawers());

  @override
  late final SizeInMeters sizeWhenFacingNorth = shape.size;

  late DrawersInLink<DrawerUnloaderLift> drawersIn =
      DrawersInLink<DrawerUnloaderLift>(
        system: this,
        offsetFromCenterWhenFacingNorth: shape.centerToDrawersInLink,
        directionToOtherLink: const CompassDirection.south(),
        numberOfDrawersToFeedIn: numberOfDrawersToFeedIn,
      );

  late DrawerOutLink<DrawerUnloaderLift> drawerOut =
      DrawerOutLink<DrawerUnloaderLift>(
        system: this,
        offsetFromCenterWhenFacingNorth: shape.centerToDrawerOutLink,
        directionToOtherLink: const CompassDirection.north(),
      );

  @override
  late List<Link> links = [drawersIn, drawerOut];

  bool get liftIsEmpty =>
      drawerPlaces.every((drawerPlace) => drawerPlace.drawer == null);

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendProperty(
        'speed',
        '${drawerPushOutCycles.averagePerHour.toStringAsFixed(1)} drawers/hour',
      );

  bool get canGoUp =>
      drawerPlaces.last.drawer == null &&
      drawerPlaces.any((place) => place.drawer != null);

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    feedOutCrossOver.onUpdateToNextPointInTime(jump);
    drawerPushOutCycle += jump;
  }

  bool get canPushTopDrawerOut {
    if (drawerPlaces.last.drawer == null) {
      return false;
    }
    if (currentState is RaiseLift) {
      return false;
    }
    if (precedingDrawer == null ||
        precedingDrawer!.position is! OnConveyorPosition) {
      return true;
    }
    return (precedingDrawer!.position as OnConveyorPosition)
            .metersTraveledOnDrawerConveyors >
        (DrawerVariant.lengthInMeters * 2.05);
  }

  int numberOfDrawersToFeedIn() {
    if (currentState is RaiseLift) {
      // lift is moving
      return 0;
    }
    for (int level = 0; level < levels; level++) {
      if (drawerPlaces[level].drawer != null) {
        // level is not free
        return level;
      }
    }
    return levels - 1;
  }

  // void onDrawersFeedInCompleted(List<GrandeDrawer> transferredDrawers) {
  //   for (var drawer in transferredDrawers) {
  //     int level = (drawer.position as UnloaderToLiftPosition).level;
  //     drawer.position = LiftPosition(lift: this, level: level);
  //     liftPositions[level] = drawer;
  //   }
  //   if (currentState is WaitOnPushIn) {
  //     (currentState as WaitOnPushIn).completed = true;
  //   }
  // }
}

// class Decide extends State<DrawerUnloaderLift> {
//   @override
//   String get name => 'DecideRaiseOrPushOut';

//   @override
//   State<DrawerUnloaderLift>? nextState(DrawerUnloaderLift lift) {
//     if (lift.drawerPlaces.last.drawer != null) {
//       return WaitToPushOutDrawer();
//     }
//     if (lift.feedingInDrawers) {
//       return WaitOnPushIn();
//     }
//     return RaiseLift();
//   }
// }

class SimultaneouslyFeedInAndFeedOutDrawers extends State<DrawerUnloaderLift> {
  GrandeDrawer? drawerToFeedIn;
  List<GrandeDrawer> drawersToFeedOut = [];
  @override
  final String name = 'SimultaneouslyFeedInAndFeedOutDrawers';

  @override
  State<DrawerUnloaderLift>? nextState(DrawerUnloaderLift lift) {
    if (lift.feedingInDrawers || lift.feedOutCrossOver.feedingOutDrawer) {
      // wait until feed in or feed out is completed
      return null;
    }
    if (lift.canGoUp) {
      return RaiseLift();
    }
    //wait until lift can go up
    return null;
  }
}

class RaiseLift extends DurationState<DrawerUnloaderLift> {
  RaiseLift()
    : super(
        durationFunction: (drawerLift) => drawerLift.upDuration,
        nextStateFunction: (drawerLift) =>
            SimultaneouslyFeedInAndFeedOutDrawers(),
      );

  @override
  String get name => 'RaiseLift';

  @override
  void onStart(DrawerUnloaderLift lift) {
    super.onStart(lift);
    if (lift.drawerPlaces.last.drawer != null) {
      throw Exception(
        'Can not raise UnloaderDrawerLift when drawer is in top.',
      );
    }
    var drawers = lift.drawerPlaces.map((e) => e.drawer).toList();
    for (var drawer in drawers) {
      if (drawer is GrandeDrawer && drawer.position is AtDrawerPlace) {
        var level = drawers.indexOf(drawer);
        drawer.position = LiftPositionUp(lift: lift, startLevel: level);
      }
    }
  }

  // @override
  // void onCompleted(DrawerUnloaderLift lift) {
  //   super.onCompleted(lift);
  //   if (lift.drawerPlaces.last.drawer != null) {
  //     throw Exception(
  //         'Can not raise UnloaderDrawerLift when drawer is in top.');
  //   }
  //   var newPositions = [
  //     null,
  //     ...lift.liftPositions.getRange(0, lift.levels - 1)
  //   ];
  //   lift.liftPositions = newPositions;
  //   for (int level = 0; level < lift.liftPositions.length; level++) {
  //     var pos = lift.liftPositions[level];
  //     if (pos is GrandeDrawer) {
  //       pos.position = LiftPosition(lift: lift, level: level);
  //     }
  //   }
  // }
}

class FeedOutCrossOver extends StateMachine {
  final DrawerUnloaderLift lift;

  late final Duration pushOutDuration = lift.pushOutDuration;

  FeedOutCrossOver(this.lift) : super(initialState: WaitToPushOutDrawer());

  @override
  String get name => 'FeedOutCrossOver';

  bool get feedingOutDrawer => currentState is PushOutDrawer;
}

class WaitToPushOutDrawer extends State<FeedOutCrossOver> {
  @override
  String get name => 'WaitToPushOut';

  @override
  State<FeedOutCrossOver>? nextState(FeedOutCrossOver feedOutCrossOver) {
    if (feedOutCrossOver.lift.canPushTopDrawerOut) {
      return PushOutDrawer();
    }
    return null;
  }
}

class PushOutDrawer extends DurationState<FeedOutCrossOver> {
  PushOutDrawer()
    : super(
        durationFunction: (feedOutCrossOver) =>
            feedOutCrossOver.pushOutDuration,
        nextStateFunction: (_) => WaitToPushOutDrawer(),
      );

  @override
  String get name => 'PushOut';

  @override
  void onStart(FeedOutCrossOver feedOutCrossOver) {
    super.onStart(feedOutCrossOver);
    var lift = feedOutCrossOver.lift;
    var drawerBeingPushedOut = lift.drawerPlaces.last.drawer!;
    var conveyorAfterUnloaderLift = lift.drawerOut.linkedTo?.system;
    if (conveyorAfterUnloaderLift != null) {
      conveyorAfterUnloaderLift as DrawerConveyor;
      conveyorAfterUnloaderLift.metersPerSecond =
          conveyorAfterUnloaderLift.drawerPath.totalLengthInMeters /
          lift.pushOutDuration.inMicroseconds *
          1000000;
      drawerBeingPushedOut.position = OnConveyorPosition(
        conveyorAfterUnloaderLift,
        precedingDrawer: lift.precedingDrawer,
      );
      lift.precedingDrawer = drawerBeingPushedOut;
    }
  }

  @override
  void onCompleted(FeedOutCrossOver feedOutCrossOver) {
    var lift = feedOutCrossOver.lift;
    lift.drawerPlaces.last.drawer = null;
    lift.drawerPushOutCycles.add(lift.drawerPushOutCycle);
    lift.drawerPushOutCycle = Duration.zero;
  }
}

class UnloaderToLiftPosition extends BetweenDrawerPlaces {
  late final DrawerUnloaderLift lift;

  final double startScale = 1;
  late final double endScale =
      lift.shape.minimizedDrawerSize.xInMeters / DrawerVariant.lengthInMeters;

  UnloaderToLiftPosition._({
    required this.lift,
    required super.drawerRotation,
    required super.duration,
    required super.startPlace,
    required super.destinationPlace,
  });

  factory UnloaderToLiftPosition({
    required ModuleDrawerColumnUnloader unloader,
    required int level,
  }) {
    var drawerRotation = unloader.area.layout.rotationOf(unloader);
    var lift = unloader.drawersOut.linkedTo!.system as DrawerUnloaderLift;
    var startPlace = unloader.drawerPlaces[level];
    var destinationPlace = lift.drawerPlaces[level];
    return UnloaderToLiftPosition._(
      lift: lift,
      drawerRotation: drawerRotation,
      duration: lift.upDuration,
      startPlace: startPlace,
      destinationPlace: destinationPlace,
    );
  }

  @override
  double get scale =>
      (startScale - endScale) * (1 - completedFraction) + endScale;
}

class LiftPosition extends AtDrawerPlace {
  DrawerUnloaderLift lift;
  int level;
  late final double _scale =
      lift.shape.minimizedDrawerSize.xInMeters / DrawerVariant.lengthInMeters;

  LiftPosition._(super.drawerPlace, {required this.lift, required this.level});

  factory LiftPosition({required DrawerUnloaderLift lift, required int level}) {
    var destinationPlace = lift.drawerPlaces[level];
    return LiftPosition._(destinationPlace, lift: lift, level: level);
  }

  @override
  double get scale => _scale;
}

class LiftPositionUp extends BetweenDrawerPlaces {
  final DrawerUnloaderLift lift;

  late final double _scale =
      lift.shape.minimizedDrawerSize.xInMeters / DrawerVariant.lengthInMeters;

  LiftPositionUp._({
    required this.lift,
    required super.drawerRotation,
    required super.duration,
    required super.startPlace,
    required super.destinationPlace,
  });

  factory LiftPositionUp({
    required DrawerUnloaderLift lift,
    required int startLevel,
  }) {
    var drawerRotation = lift.area.layout.rotationOf(lift);
    var startPlace = lift.drawerPlaces[startLevel];
    var destinationPlace = lift.drawerPlaces[startLevel + 1];
    return LiftPositionUp._(
      lift: lift,
      drawerRotation: drawerRotation,
      duration: lift.upDuration,
      startPlace: startPlace,
      destinationPlace: destinationPlace,
    );
  }

  @override
  double get scale => _scale;
}
