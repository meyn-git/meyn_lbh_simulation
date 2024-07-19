// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/module/drawer.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module_variant_builder.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/state_machine.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_column_unloader.dart';
import 'package:user_command/user_command.dart';

class ModuleDrawerColumnUnloader extends StateMachine
    implements PhysicalSystem {
  final LiveBirdHandlingArea area;

  ///Number of birds on dumping belt between module and hanger (a buffer).
  ///The unloader starts tilting when birdsOnDumpBelt<dumpBeltBufferSize
  ///Normally this number is between the number of birds in 1 or 2 modules
  final Duration checkIfEmptyDuration;
  final Duration inFeedDuration;
  final Duration outFeedDuration;
  final Duration pusherOutDuration;
  final Duration pusherInDuration;
  final Duration feedInToSecondColumn;
  final Direction drawerOutDirection;

  @override
  late List<Command> commands = [
    RemoveFromMonitorPanel(this),
  ];

  Duration? durationPerModule;

  Durations durationsPerModule = Durations(maxSize: 8);

  late final List<DrawerPlace> drawerPlaces = [
    for (int level = 0; level < 5; level++)
      DrawerPlace(
          system: this,
          centerToDrawerCenterWhenSystemFacesNorth:
              shape.centerToConveyorCenter)
  ];

  late final CompassDirection drawerFeedOutDirection = drawersOut
      .directionToOtherLink
      .rotate(area.layout.rotationOf(this).degrees);

  ModuleDrawerColumnUnloader({
    required this.area,
    required this.drawerOutDirection,
    this.checkIfEmptyDuration = const Duration(seconds: 18),
    Duration? inFeedDuration =
        const Duration(milliseconds: 9300), // TODO remove default value?
    Duration? outFeedDuration =
        const Duration(milliseconds: 9300), // TODO remove default value?
    this.pusherOutDuration = const Duration(
        milliseconds:
            3400), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    this.pusherInDuration = const Duration(
        milliseconds:
            3400), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    this.feedInToSecondColumn = const Duration(
        milliseconds:
            6000), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
  })  : inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        super(
          initialState: CheckIfEmpty(),
        );

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late DrawersOutLink drawersOut = DrawersOutLink(
      system: this,
      offsetFromCenterWhenFacingNorth: shape.centerToDrawersOutLink,
      directionToOtherLink: drawerOutDirection == Direction.counterClockWise
          ? const CompassDirection.west()
          : const CompassDirection.east());

  late final ModuleDrawerColumnUnloaderShape shape =
      ModuleDrawerColumnUnloaderShape(this);

  late ModuleGroupPlace moduleGroupPositionFirstColumn = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToFirstColumn,
  );

  late ModuleGroupPlace moduleGroupPositionSecondColumn = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToSecondColumn,
  );

  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPositionFirstColumn,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleInLink,
    directionToOtherLink: const CompassDirection.south(),
    inFeedDuration: inFeedDuration,
    canFeedIn: canFeedIn,
  );

  bool canFeedIn() {
    return currentState is FeedOutAndFeedInModuleSimultaneously &&
        (currentState as FeedOutAndFeedInModuleSimultaneously).inFeedState ==
            InFeedState.waitingOnNeighbor;
  }

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPositionSecondColumn,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleOutLink,
    directionToOtherLink: const CompassDirection.north(),
    outFeedDuration: outFeedDuration,
    durationUntilCanFeedOut: () =>
        canFeedOut() ? Duration.zero : unknownDuration,
  );

  bool canFeedOut() {
    return currentState is FeedOutAndFeedInModuleSimultaneously &&
        (currentState as FeedOutAndFeedInModuleSimultaneously).outFeedState ==
            OutFeedState.waitingOnNeighbor;
  }

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
      .appendProperty('speed',
          '${durationsPerModule.averagePerHour.toStringAsFixed(1)} modules/hour')
      .appendProperty(
          'moduleGroup',
          moduleGroupPositionFirstColumn.moduleGroup ??
              moduleGroupPositionSecondColumn.moduleGroup);

  void onEndOfCycle() {
    durationsPerModule.add(durationPerModule);
    durationPerModule = Duration.zero;
  }

  @override
  late final String name = 'ModuleDrawerUnloader$seqNr';

  late final int seqNr = area.systems.seqNrOf(this);
}

class CheckIfEmpty extends DurationState<ModuleDrawerColumnUnloader> {
  @override
  String get name => 'CheckIfEmpty';

  CheckIfEmpty()
      : super(
            durationFunction: (unloader) => unloader.checkIfEmptyDuration,
            nextStateFunction: (unloader) =>
                FeedOutAndFeedInModuleSimultaneously());
}

class FeedOutAndFeedInModuleSimultaneously
    extends State<ModuleDrawerColumnUnloader> {
  @override
  String get name => 'FeedOutAndFeedInModuleSimultaneously\n'
      '  $inFeedState\n'
      '  $outFeedState';

  ModuleGroup? moduleGroupTransportedOut;
  InFeedState inFeedState = InFeedState.waitingToFeedOut;
  OutFeedState outFeedState = OutFeedState.waitingOnNeighbor;

  @override
  void onStart(ModuleDrawerColumnUnloader unloader) {
    outFeedState = unloader.moduleGroupPositionSecondColumn.moduleGroup == null
        ? OutFeedState.done
        : OutFeedState.waitingOnNeighbor;
  }

  @override
  void onUpdateToNextPointInTime(
      ModuleDrawerColumnUnloader unloader, Duration jump) {
    processInFeedState(unloader, jump);
    processOutFeedState(unloader, jump);
  }

  void processInFeedState(ModuleDrawerColumnUnloader unloader, Duration jump) {
    switch (inFeedState) {
      case InFeedState.waitingToFeedOut:
        if (outFeedState != OutFeedState.waitingOnNeighbor) {
          inFeedState = InFeedState.waitingOnNeighbor;
        }
      case InFeedState.waitingOnNeighbor:
        if (_inFeedStarted(unloader)) {
          inFeedState = InFeedState.transporting;
        }
        break;
      case InFeedState.transporting:
        if (_inFeedCompleted(unloader)) {
          inFeedState = InFeedState.done;
        }
        break;
      default:
    }
  }

  bool _inFeedCompleted(ModuleDrawerColumnUnloader unloader) =>
      unloader.moduleGroupPositionFirstColumn.moduleGroup != null;

  bool _inFeedStarted(ModuleDrawerColumnUnloader unloader) =>
      unloader.area.moduleGroups
          .any((moduleGroup) => moduleGroup.isBeingTransportedTo(unloader));

  void processOutFeedState(ModuleDrawerColumnUnloader unloader, Duration jump) {
    switch (outFeedState) {
      case OutFeedState.waitingOnNeighbor:
        if (_outFeedCanStart(unloader)) {
          outFeedState = OutFeedState.transporting;
          transportModuleOut(unloader);
        }
        break;
      case OutFeedState.transporting:
        if (_outFeedCompleted(unloader)) {
          outFeedState = OutFeedState.done;
        }
        break;
      default:
    }
  }

  void transportModuleOut(ModuleDrawerColumnUnloader unloader) {
    moduleGroupTransportedOut =
        unloader.moduleGroupPositionSecondColumn.moduleGroup!;
    moduleGroupTransportedOut!.position =
        BetweenModuleGroupPlaces.forModuleOutLink(unloader.modulesOut);
  }

  _outFeedCanStart(ModuleDrawerColumnUnloader unloader) =>
      unloader.modulesOut.linkedTo!.canFeedIn();

  @override
  State<ModuleDrawerColumnUnloader>? nextState(
      ModuleDrawerColumnUnloader unloader) {
    if (inFeedState == InFeedState.done
        // We are not going to wait until feed out is completed && outFeedState == OutFeedState.done
        ) {
      return WaitToPushOutFirstColumn();
    }
    return null;
  }

  @override
  void onCompleted(ModuleDrawerColumnUnloader unloader) {
    _verifyModule(unloader);
  }

  void _verifyModule(ModuleDrawerColumnUnloader unloader) {
    var moduleGroup = (unloader.moduleGroupPositionFirstColumn.moduleGroup ??
        unloader.moduleGroupPositionSecondColumn.moduleGroup)!;
    if (moduleGroup.compartment.birdsExitOnOneSide &&
        moduleGroup.direction.rotate(-90) != unloader.drawerFeedOutDirection) {
      if (moduleGroup.compartment is CompartmentWithDoor) {
        throw ('In correct container type of the $ModuleGroup '
            'that was fed in to ${unloader.name}');
      } else {
        throw ('Incorrect drawer out feed direction of the $ModuleGroup '
            'that was fed in to ${unloader.name}');
      }
    }
  }

  bool _outFeedCompleted(ModuleDrawerColumnUnloader unloader) =>
      moduleGroupTransportedOut != null &&
      moduleGroupTransportedOut!.position is AtModuleGroupPlace &&
      (moduleGroupTransportedOut!.position as AtModuleGroupPlace).place ==
          unloader.modulesOut.linkedTo!.place;
}

enum InFeedState { waitingToFeedOut, waitingOnNeighbor, transporting, done }

enum OutFeedState { waitingOnNeighbor, transporting, done }

class WaitToPushOutFirstColumn extends State<ModuleDrawerColumnUnloader> {
  @override
  String get name => 'WaitToPushOutFirstColumn';

  @override
  State<ModuleDrawerColumnUnloader>? nextState(
      ModuleDrawerColumnUnloader unloader) {
    var moduleGroup = (unloader.moduleGroupPositionFirstColumn.moduleGroup ??
        unloader.moduleGroupPositionSecondColumn.moduleGroup)!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle stacked containers');
    }
    int levels = moduleGroup.modules.first.variant.levels;
    if (unloader.drawersOut.linkedTo!.numberOfDrawersToFeedIn() >= levels) {
      return PushOutFirstColumn();
    }
    return null;
  }
}

class PushOutFirstColumn extends DurationState<ModuleDrawerColumnUnloader> {
  @override
  String get name => 'PushOutFirstColumn';

  PushOutFirstColumn()
      : super(
            durationFunction: (unloader) => unloader.pusherOutDuration,
            nextStateFunction: (unloader) => PusherInFirstColumn());
  @override
  void onStart(ModuleDrawerColumnUnloader unloader) {
    super.onStart(unloader);
    var drawers = unloader.area.drawers;
    var moduleGroup = unloader.moduleGroupPositionFirstColumn.moduleGroup!;
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
      drawer.position =
          UnloaderToLiftPosition(unloader: unloader, level: level);
    }
  }

  @override
  void onCompleted(ModuleDrawerColumnUnloader unloader) {
    super.onCompleted(unloader);
    var moduleGroup = unloader.moduleGroupPositionFirstColumn.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle stacked containers');
    }
  }
}

class PusherInFirstColumn extends DurationState<ModuleDrawerColumnUnloader> {
  @override
  String get name => 'PusherInFirstColumn';

  PusherInFirstColumn()
      : super(
            durationFunction: (unloader) => unloader.pusherInDuration,
            nextStateFunction: (unloader) => FeedInToSecondColumn());
}

class FeedInToSecondColumn extends State<ModuleDrawerColumnUnloader>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedInToSecondColumn';

  @override
  void onStart(ModuleDrawerColumnUnloader unloader) {
    var moduleGroup = unloader.moduleGroupPositionFirstColumn.moduleGroup!;
    moduleGroup.position = BetweenModuleGroupPlaces(
        source: unloader.moduleGroupPositionFirstColumn,
        destination: unloader.moduleGroupPositionSecondColumn,
        duration: unloader.feedInToSecondColumn);
  }

  @override
  State<ModuleDrawerColumnUnloader>? nextState(
      ModuleDrawerColumnUnloader stateMachine) {
    if (transportCompleted) {
      return WaitToPushOutSecondColumn();
    }
    return null;
  }

  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class WaitToPushOutSecondColumn extends State<ModuleDrawerColumnUnloader> {
  @override
  String get name => 'WaitToPushOutSecondColumn';

  @override
  State<ModuleDrawerColumnUnloader>? nextState(
      ModuleDrawerColumnUnloader unloader) {
    var moduleGroup = unloader.moduleGroupPositionSecondColumn.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle stacked containers');
    }
    int levels = moduleGroup.modules.first.variant.levels;
    if (unloader.drawersOut.linkedTo!.numberOfDrawersToFeedIn() >= levels) {
      return PusherOutSecondColumn();
    }
    return null;
  }
}

class PusherOutSecondColumn extends DurationState<ModuleDrawerColumnUnloader> {
  @override
  String get name => 'PusherOutSecondColumn';

  PusherOutSecondColumn()
      : super(
            durationFunction: (unloader) => unloader.pusherOutDuration,
            nextStateFunction: (unloader) => PusherInSecondColumn());

  @override
  void onStart(ModuleDrawerColumnUnloader unloader) {
    super.onStart(unloader);
    var drawers = unloader.area.drawers;
    var moduleGroup = unloader.moduleGroupPositionSecondColumn.moduleGroup!;
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
      drawer.position =
          UnloaderToLiftPosition(unloader: unloader, level: level);
    }
  }

  @override
  void onCompleted(ModuleDrawerColumnUnloader unloader) {
    super.onCompleted(unloader);
    var moduleGroup = unloader.moduleGroupPositionSecondColumn.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle stacked containers');
    }
    moduleGroup.unloadBirds();
  }
}

class PusherInSecondColumn extends DurationState<ModuleDrawerColumnUnloader> {
  @override
  String get name => 'PusherInSecondColumn';

  PusherInSecondColumn()
      : super(
            durationFunction: (unloader) => unloader.pusherInDuration,
            nextStateFunction: (unloader) =>
                FeedOutAndFeedInModuleSimultaneously());

  @override
  void onCompleted(ModuleDrawerColumnUnloader unloader) {
    super.onCompleted(unloader);
    unloader.onEndOfCycle();
  }
}

class DrawerUnloaderLift extends StateMachine implements PhysicalSystem {
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
  Durations drawerPushOutCycles = Durations(maxSize: 8);

  GrandeDrawer? precedingDrawer;

  late final DrawerUnloaderLiftShape shape = DrawerUnloaderLiftShape(this);

  // bool feedingInDrawers = false;

  late final ModuleDrawerColumnUnloader unloader =
      drawersIn.linkedTo! as ModuleDrawerColumnUnloader;
  late final FeedOutCrossOver feedOutCrossOver = FeedOutCrossOver(this);

  late final List<DrawerPlace> drawerPlaces = shape
      .centerLiftToDrawerCenterInLift
      .map((offset) => DrawerPlace(
          system: this, centerToDrawerCenterWhenSystemFacesNorth: offset))
      .toList();

  bool get feedingInDrawers =>
      currentState is PushOutFirstColumn ||
      currentState is PusherInFirstColumn ||
      currentState is PusherOutSecondColumn ||
      currentState is PusherInSecondColumn;

  DrawerUnloaderLift({
    required this.area,
    this.upDuration = const Duration(
        milliseconds:
            1600), // Based on "Speed calculations_estimates_V3_Erik.xlsx"

    this.pushOutDuration = const Duration(
        milliseconds:
            2500), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    this.levels = 6,
    this.lengthInMeters = 1.2 // TODO
    ,
  }) : super(
          initialState: SimultaneouslyFeedInAndFeedOutDrawers(),
        );

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
          directionToOtherLink: const CompassDirection.north());

  @override
  late List<Link> links = [drawersIn, drawerOut];

  bool get liftIsEmpty =>
      drawerPlaces.every((drawerPlace) => drawerPlace.drawer == null);

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendProperty('speed',
          '${drawerPushOutCycles.averagePerHour.toStringAsFixed(1)} drawers/hour');

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
                SimultaneouslyFeedInAndFeedOutDrawers());

  @override
  String get name => 'RaiseLift';

  @override
  void onStart(DrawerUnloaderLift lift) {
    super.onStart(lift);
    if (lift.drawerPlaces.last.drawer != null) {
      throw Exception(
          'Can not raise UnloaderDrawerLift when drawer is in top.');
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
            nextStateFunction: (_) => WaitToPushOutDrawer());

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
          precedingDrawer: lift.precedingDrawer);
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

  UnloaderToLiftPosition._(
      {required this.lift,
      required super.drawerRotation,
      required super.duration,
      required super.startPlace,
      required super.destinationPlace});

  factory UnloaderToLiftPosition(
      {required ModuleDrawerColumnUnloader unloader, required int level}) {
    var drawerRotation = unloader.area.layout.rotationOf(unloader);
    var lift = unloader.drawersOut.linkedTo!.system as DrawerUnloaderLift;
    var startPlace = unloader.drawerPlaces[level];
    var destinationPlace = lift.drawerPlaces[level];
    return UnloaderToLiftPosition._(
        lift: lift,
        drawerRotation: drawerRotation,
        duration: lift.upDuration,
        startPlace: startPlace,
        destinationPlace: destinationPlace);
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

  factory LiftPosition({
    required DrawerUnloaderLift lift,
    required int level,
  }) {
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

  LiftPositionUp._(
      {required this.lift,
      required super.drawerRotation,
      required super.duration,
      required super.startPlace,
      required super.destinationPlace});

  factory LiftPositionUp(
      {required DrawerUnloaderLift lift, required int startLevel}) {
    var drawerRotation = lift.area.layout.rotationOf(lift);
    var startPlace = lift.drawerPlaces[startLevel];
    var destinationPlace = lift.drawerPlaces[startLevel + 1];
    return LiftPositionUp._(
        lift: lift,
        drawerRotation: drawerRotation,
        duration: lift.upDuration,
        startPlace: startPlace,
        destinationPlace: destinationPlace);
  }

  @override
  double get scale => _scale;
}
