// ignore_for_file: avoid_renaming_method_parameters

import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/machine.dart';
import 'package:meyn_lbh_simulation/gui/area/area.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:user_command/user_command.dart';

import 'object_details.dart';
import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

/// TODO this was copied from module_drawer_unloader.dart and renamed Unloader to Loader. It will need some more adjustments
class ModuleDrawerLoader extends StateMachineCell implements Machine {
  final CardinalDirection inFeedDirection;

  ///Number of birds on dumping belt between module and hanger (a buffer).
  ///The loader starts tilting when birdsOnDumpBelt<dumpBeltBufferSize
  ///Normally this number is between the number of birds in 1 or 2 modules
  final Duration checkIfEmptyDuration;
  final Duration pusherOutDuration;
  final Duration pusherInDuration;
  final Duration feedInToSecondColumn;
  final bool drawersToLeft;
  Duration? durationPerModule;

  Durations durationsPerModule = Durations(maxSize: 8);

  ModuleDrawerLoader({
    required super.area,
    required super.position,
    super.name = 'ModuleDrawerLoader',
    super.seqNr,
    required this.inFeedDirection,
    required this.drawersToLeft,
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
  }) : super(
          initialState: CheckIfEmpty(),
          inFeedDuration: inFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
          outFeedDuration: outFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
        );

  @override
  late List<Command> commands = [
    RemoveFromMonitorPanel(this),
  ];

  @override
  late SizeInMeters sizeWhenFacingNorth = const SizeInMeters(
      widthInMeters: 3, heightInMeters: 3); //TODO 3 meters is an assumption

  late DrawersOutLink drawersOut = DrawersOutLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: drawersToLeft
              ? -sizeWhenFacingNorth.widthInMeters / 2
              : sizeWhenFacingNorth.widthInMeters / 2,
          metersFromTop: 0),
      directionFromCenter: drawersToLeft
          ? inFeedDirection.toCompassDirection().rotate(-90)
          : inFeedDirection.toCompassDirection().rotate(90));

  @override
  late List<Link> links = [drawersOut]; //TODO add containerIn and containerOut

  late DrawerLoaderLift drawerLift =
      drawersOut.linkedTo.owner as DrawerLoaderLift;

  get inFeedNeighbor => area.neighboringCell(this, inFeedDirection);

  get outFeedNeighbor => area.neighboringCell(this, inFeedDirection.opposite);

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    if (durationPerModule != null) {
      durationPerModule = durationPerModule! + jump;
    }
  }

  Cell get receivingNeighbor =>
      area.neighboringCell(this, inFeedDirection.opposite);

  Cell get sendingNeighbor => area.neighboringCell(this, inFeedDirection);

  @override
  bool isFeedIn(CardinalDirection direction) => direction == inFeedDirection;

  @override
  bool waitingToFeedIn(CardinalDirection direction) =>
      direction == inFeedDirection &&
      currentState is FeedOutAndFeedInToFirstColumnSimultaneously &&
      (currentState as FeedOutAndFeedInToFirstColumnSimultaneously)
              .inFeedState ==
          InFeedState.waitingOnNeighbor;

  @override
  bool isFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite &&
      currentState is FeedOutAndFeedInToFirstColumnSimultaneously &&
      (currentState as FeedOutAndFeedInToFirstColumnSimultaneously)
              .outFeedState ==
          OutFeedState.waitingOnNeighbor;

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendProperty('speed',
          '${durationsPerModule.averagePerHour.toStringAsFixed(1)} modules/hour')
      .appendProperty('moduleGroup', moduleGroup);

  void onEndOfCycle() {
    durationsPerModule.add(durationPerModule);
    durationPerModule = Duration.zero;
  }
}

class CheckIfEmpty extends DurationState<ModuleDrawerLoader> {
  @override
  String get name => 'CheckIfEmpty';

  CheckIfEmpty()
      : super(
            durationFunction: (loader) => loader.checkIfEmptyDuration,
            nextStateFunction: (loader) =>
                FeedOutAndFeedInToFirstColumnSimultaneously());
}

class FeedOutAndFeedInToFirstColumnSimultaneously
    extends State<ModuleDrawerLoader> {
  @override
  String get name => 'FeedInAndFeedOutSimultaneously';

  ModuleGroup? moduleGroupTransportedOut;
  InFeedState inFeedState = InFeedState.waitingToFeedOut;
  OutFeedState outFeedState = OutFeedState.waitingOnNeighbor;

  @override
  void onStart(ModuleDrawerLoader loader) {
    outFeedState = loader.moduleGroup == null
        ? OutFeedState.done
        : OutFeedState.waitingOnNeighbor;
  }

  @override
  void onUpdateToNextPointInTime(ModuleDrawerLoader loader, Duration jump) {
    processInFeedState(loader, jump);
    processOutFeedState(loader, jump);
  }

  void processInFeedState(ModuleDrawerLoader loader, Duration jump) {
    switch (inFeedState) {
      case InFeedState.waitingToFeedOut:
        if (outFeedState != OutFeedState.waitingOnNeighbor) {
          inFeedState = InFeedState.waitingOnNeighbor;
        }
      case InFeedState.waitingOnNeighbor:
        if (_inFeedStarted(loader)) {
          inFeedState = InFeedState.transporting;
        }
        break;
      case InFeedState.transporting:
        if (_inFeedCompleted(loader)) {
          inFeedState = InFeedState.done;
        }
        break;
      default:
    }
  }

  bool _inFeedCompleted(ModuleDrawerLoader loader) =>
      loader.moduleGroup != null;

  bool _inFeedStarted(ModuleDrawerLoader loader) {
    return loader.area.moduleGroups
        .any((moduleGroup) => moduleGroup.position.destination == loader);
  }

  void processOutFeedState(ModuleDrawerLoader loader, Duration jump) {
    switch (outFeedState) {
      case OutFeedState.waitingOnNeighbor:
        if (_outFeedStarted(loader)) {
          outFeedState = OutFeedState.transporting;
          transportModuleOut(loader);
        }
        break;
      case OutFeedState.transporting:
        if (_outFeedCompleted(loader)) {
          outFeedState = OutFeedState.done;
        }
        break;
      default:
    }
  }

  void transportModuleOut(ModuleDrawerLoader loader) {
    moduleGroupTransportedOut = loader.moduleGroup;
    moduleGroupTransportedOut!.position = ModulePosition.betweenCells(
        source: loader,
        destination: loader.outFeedNeighbor as StateMachineCell);
  }

  _outFeedStarted(ModuleDrawerLoader loader) =>
      loader.receivingNeighbor.waitingToFeedIn(loader.inFeedDirection);

  @override
  State<ModuleDrawerLoader>? nextState(ModuleDrawerLoader loader) {
    if (inFeedState == InFeedState.done && outFeedState == OutFeedState.done) {
      return WaitToUnloadFirstColumn();
    }
    return null;
  }

  @override
  void onCompleted(ModuleDrawerLoader loader) {
    _verifyDoorDirection(loader);
  }

  void _verifyDoorDirection(ModuleDrawerLoader loader) {
    // var moduleGroup = loader.moduleGroup!;
    // var hasDoors =
    //     moduleGroup.moduleFamily.compartmentType == CompartmentType.door;
    // if (hasDoors &&
    //     moduleGroup.direction.toCardinalDirection() != loader.birdDirection) {
    //   throw ('In correct door direction of the $ModuleGroup that was fed in to ${loader.name}');
    // }
  }

  bool _outFeedCompleted(ModuleDrawerLoader loader) =>
      moduleGroupTransportedOut != null &&
      moduleGroupTransportedOut!.position.destination == loader.outFeedNeighbor;
}

enum InFeedState { waitingToFeedOut, waitingOnNeighbor, transporting, done }

enum OutFeedState { waitingOnNeighbor, transporting, done }

class WaitToUnloadFirstColumn extends State<ModuleDrawerLoader> {
  @override
  String get name => 'WaitToUnloadFirstColumn';

  @override
  State<ModuleDrawerLoader>? nextState(ModuleDrawerLoader loader) {
    var moduleGroup = loader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Loader can not handle stacked containers');
    }
    int levels = moduleGroup.firstModule.levels;
    loader.drawerLift.waitingDrawersToBePushedIn = levels;
    if (loader.drawerLift.canReceiveDrawers) {
      return PushOutFirstColumn();
    }
    return null;
  }
}

class PushOutFirstColumn extends DurationState<ModuleDrawerLoader> {
  @override
  String get name => 'PushOutFirstColumn';

  PushOutFirstColumn()
      : super(
            durationFunction: (loader) => loader.pusherOutDuration,
            nextStateFunction: (loader) => PusherInFirstColumn());
  @override
  void onStart(ModuleDrawerLoader loader) {
    super.onStart(loader);
    loader.drawerLift.onStartPushingDrawersToLift();
  }

  @override
  void onCompleted(ModuleDrawerLoader loader) {
    super.onCompleted(loader);
    loader.drawerLift.onCompletePushingDrawersToLift();
    loader.drawerLift.waitingDrawersToBePushedIn = 0;
  }
}

class PusherInFirstColumn extends DurationState<ModuleDrawerLoader> {
  @override
  String get name => 'PusherInFirstColumn';

  PusherInFirstColumn()
      : super(
            durationFunction: (loader) => loader.pusherInDuration,
            nextStateFunction: (loader) => FeedInToSecondColumn());
}

class FeedInToSecondColumn extends DurationState<ModuleDrawerLoader> {
  @override
  String get name => 'FeedInToSecondColumn';

  FeedInToSecondColumn()
      : super(
            durationFunction: (loader) => loader.feedInToSecondColumn,
            nextStateFunction: (loader) => WaitToUnloadSecondColumn());
}

class WaitToUnloadSecondColumn extends State<ModuleDrawerLoader> {
  @override
  String get name => 'WaitToUnloadSecondColumn';

  @override
  State<ModuleDrawerLoader>? nextState(ModuleDrawerLoader loader) {
    var moduleGroup = loader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Loader can not handle stacked containers');
    }
    int levels = moduleGroup.firstModule.levels;
    loader.drawerLift.waitingDrawersToBePushedIn = levels;
    if (loader.drawerLift.canReceiveDrawers) {
      return PushOutSecondColumn();
    }
    return null;
  }
}

class PushOutSecondColumn extends DurationState<ModuleDrawerLoader> {
  @override
  String get name => 'PushOutSecondColumn';

  PushOutSecondColumn()
      : super(
            durationFunction: (loader) => loader.pusherOutDuration,
            nextStateFunction: (loader) => PusherInSecondColumn());

  @override
  void onStart(ModuleDrawerLoader loader) {
    super.onStart(loader);
    loader.drawerLift.onStartPushingDrawersToLift();
  }

  @override
  void onCompleted(ModuleDrawerLoader loader) {
    super.onCompleted(loader);
    var moduleGroup = loader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Loader can not handle stacked containers');
    }
    loader.drawerLift.onCompletePushingDrawersToLift();
    moduleGroup.unloadBirds();
    loader.drawerLift.waitingDrawersToBePushedIn = 0;
  }
}

class PusherInSecondColumn extends DurationState<ModuleDrawerLoader> {
  @override
  String get name => 'PusherInSecondColumn';

  PusherInSecondColumn()
      : super(
            durationFunction: (loader) => loader.pusherInDuration,
            nextStateFunction: (loader) =>
                FeedOutAndFeedInToFirstColumnSimultaneously());

  @override
  void onCompleted(ModuleDrawerLoader loader) {
    super.onCompleted(loader);
    loader.onEndOfCycle();
  }
}

class DrawerLoaderLift extends StateMachine implements Machine {
  final LiveBirdHandlingArea area;
  @override
  late String name = 'DrawerLoaderLift';
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];
  late ModuleDrawerLoader moduleDrawerLoader = _findModuleDrawerLoader();
  final int nrOfLiftPositions;
  final double lengthInMeters;
  int waitingDrawersToBePushedIn = 0;

  /// position[0]=bottom position in lift
  /// position[nrOfPositions-1]=top position in lift
  /// null =  without drawer
  List<GrandeDrawer?> liftPositions;
  final Duration upDuration;
  final int maxDrawersPerHour;
  final Duration pushOutDuration;

  Duration drawerPushOutCycle = Duration.zero;
  Duration drawerPushOutCycleBuffer = Duration.zero;
  Durations drawerPushOutCycles = Durations(maxSize: 8);

//TODO the DrawerHangingConveyor should tell if there is space to recieve a drawer
  late Duration minimumInterval =
      Duration(milliseconds: 3600000 ~/ maxDrawersPerHour);
  late double offsetInMeters = 0.2;

  DrawerLoaderLift({
    required this.area,
    this.upDuration = const Duration(
        milliseconds:
            1600), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    required this.maxDrawersPerHour, // Aiming for 750-800
    this.pushOutDuration = const Duration(
        milliseconds:
            2500), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    this.nrOfLiftPositions = 6,
    this.lengthInMeters = 1.2 // TODO
    ,
  })  : liftPositions = List.filled(
          nrOfLiftPositions,
          null,
        ),
        super(
          initialState: Decide(),
        );

  @override
  late SizeInMeters sizeWhenFacingNorth = _size();

  SizeInMeters _size() {
    var length = GrandeDrawerModuleType.drawerOutSideLength.as(meters) + 2;
    return SizeInMeters(widthInMeters: length, heightInMeters: length);
  }

  late DrawerInLink<DrawerLoaderLift> drawerIn = DrawerInLink<DrawerLoaderLift>(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: 0,
          metersFromTop: sizeWhenFacingNorth.heightInMeters / 2),
      directionFromCenter: CardinalDirection.south.toCompassDirection());

  late DrawerOutLink<DrawerLoaderLift> drawerOut =
      DrawerOutLink<DrawerLoaderLift>(
          owner: this,
          offsetFromCenter: OffsetInMeters(
              metersFromLeft: 0,
              metersFromTop: -sizeWhenFacingNorth.heightInMeters / 2),
          directionFromCenter: CardinalDirection.north.toCompassDirection());

  @override
  late List<Link> links = [
    drawerIn, //TODO drawerOut
    //TODO modulePositions
  ];

  late OffsetInMeters topLeftToTopConveyorEnd = _topLeftToTopConveyorEnd();
  OffsetInMeters _topLeftToTopConveyorEnd() => OffsetInMeters(
      metersFromLeft: sizeWhenFacingNorth.widthInMeters / 2, metersFromTop: 0);

  OffsetInMeters topLeftToLiftLevel(int level) =>
      topLeftToTopConveyorEnd -
      OffsetInMeters(
          metersFromLeft:
              GrandeDrawerModuleType.drawerOutSideLength.as(meters) / 2,
          metersFromTop: 0) +
      OffsetInMeters(
          metersFromLeft: offsetInMeters * (nrOfLiftPositions - level) / 4,
          metersFromTop: offsetInMeters * (nrOfLiftPositions - level));

  late OffsetInMeters topLeftToDrawerInModule = _topLeftToDrawerInModule();
  OffsetInMeters _topLeftToDrawerInModule() => OffsetInMeters(
      metersFromLeft: sizeWhenFacingNorth.widthInMeters / 2,
      metersFromTop: sizeWhenFacingNorth.heightInMeters * 0.8);

  bool get liftIsEmpty =>
      liftPositions.every((drawerPosition) => drawerPosition == null);

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendProperty('speed',
          '${drawerPushOutCycles.averagePerHour.toStringAsFixed(1)} drawers/hour');

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    drawerPushOutCycle += jump;
    // buffer conveyor between loader and hanging no bigger than 4 drawers
    if (drawerPushOutCycleBuffer <
        (minimumInterval +
            minimumInterval +
            minimumInterval +
            minimumInterval)) {
      drawerPushOutCycleBuffer += jump;
    }
  }

// This method is called by the loader
  void onStartPushingDrawersToLift() {
    var drawers = moduleDrawerLoader.area.drawers;
    ModuleDrawerLoader loader = drawerIn.linkedTo.owner as ModuleDrawerLoader;
    var module = loader.moduleGroup!.firstModule;
    var levels = module.levels;
    var nrOfBirdsPerDrawer = module.nrOfBirds / 2 ~/ levels;
    var contents = loader.moduleGroup!.contents;
    for (int level = levels - 1; level >= 0; level--) {
      /// creating a temporary conveyor to move the drawer from DrawerLoader to lift position
      var drawer = GrandeDrawer(
        startPosition: loader.position,
        nrOfBirds: nrOfBirdsPerDrawer,
        contents: contents,
        position: LoaderToLiftPosition(lift: this, level: level),
      );
      drawers.add(drawer);
    }
  }

// This method is called by the loader
  void onCompletePushingDrawersToLift() {
    if (!canReceiveDrawers) {
      throw Exception('You can not push $waitingDrawersToBePushedIn drawer(s)'
          ' into the $name');
    }
    var drawersBeingPushedIn = area.drawers.where((drawer) =>
        drawer.position is LoaderToLiftPosition &&
        (drawer.position as LoaderToLiftPosition).lift == this);
    for (var drawer in drawersBeingPushedIn) {
      int level = (drawer.position as LoaderToLiftPosition).level;
      drawer.position = LiftPosition(lift: this, level: level);
      liftPositions[level] = drawer;
    }
  }

  bool get canReceiveDrawers {
    if (currentState is RaiseLift) {
      // lift is moving
      return false;
    }
    if (waitingDrawersToBePushedIn == 0) {
      // no waiting drawers
      return false;
    }
    if (waitingDrawersToBePushedIn > (nrOfLiftPositions - 1)) {
      // not enough positions to push drawers in
      return false;
    }
    for (int i = 0; i < waitingDrawersToBePushedIn; i++) {
      if (liftPositions[i] != null) {
        // position is not free
        return false;
      }
    }
    return true;
  }

  void onStartPushOutTopPosition() {
    var drawerBeingPushedOut = liftPositions.last!;
    var conveyorAfterLoaderLift = drawerOut.linkedTo.owner as DrawerConveyor;
    conveyorAfterLoaderLift.metersPerSecond =
        conveyorAfterLoaderLift.drawerPath.totalLength /
            pushOutDuration.inMicroseconds *
            1000000;
    drawerBeingPushedOut.position = OnConveyorPosition(conveyorAfterLoaderLift);
  }

  void onCompletePushOutTopPosition() {
    liftPositions = [
      ...liftPositions.getRange(0, liftPositions.length - 1),
      null
    ];
    drawerPushOutCycles.add(drawerPushOutCycle);
    drawerPushOutCycle = Duration.zero;
    drawerPushOutCycleBuffer -=
        minimumInterval; // keep the rest so we can catch up
  }

  bool get canPushOut {
    // print(
    //     '$drawerPushOutCycle >= $minimumInterval ${(drawerPushOutCycle >= minimumInterval)}');
    return drawerPushOutCycleBuffer >= minimumInterval;
  }

  ModuleDrawerLoader _findModuleDrawerLoader() {
    //TODO get this via a link
    return area.cells.whereType<ModuleDrawerLoader>().first;
  }
}

class Decide extends State<DrawerLoaderLift> {
  @override
  String get name => 'DecideRaiseOrPushOut';

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) {
    if (lift.liftPositions.last != null) {
      return WaitToPushOut();
    }
    if (lift.canReceiveDrawers) {
      return WaitOnPushIn();
    }
    return RaiseLift();
  }
}

class RaiseLift extends DurationState<DrawerLoaderLift> {
  RaiseLift()
      : super(
            durationFunction: (drawerLift) => drawerLift.upDuration,
            nextStateFunction: (drawerLift) => Decide());

  @override
  String get name => 'RaiseLift';

  @override
  void onStart(DrawerLoaderLift lift) {
    super.onStart(lift);
    if (lift.liftPositions.last != null) {
      throw Exception('Can not raise LoaderDrawerLift when drawer is in top.');
    }
    for (var liftPos in lift.liftPositions) {
      if (liftPos is GrandeDrawer && liftPos.position is LiftPosition) {
        var level = (liftPos.position as LiftPosition).level;
        liftPos.position = LiftPositionUp(lift: lift, startLevel: level);
      }
    }
  }

  @override
  void onCompleted(DrawerLoaderLift lift) {
    super.onCompleted(lift);
    if (lift.liftPositions.last != null) {
      throw Exception('Can not raise LoaderDrawerLift when drawer is in top.');
    }
    var newPositions = [
      null,
      ...lift.liftPositions.getRange(0, lift.nrOfLiftPositions - 1)
    ];
    lift.liftPositions = newPositions;
    for (int level = 0; level < lift.liftPositions.length; level++) {
      var pos = lift.liftPositions[level];
      if (pos is GrandeDrawer) {
        pos.position = LiftPosition(lift: lift, level: level);
      }
    }
  }
}

class WaitToPushOut extends State<DrawerLoaderLift> {
  Duration maxDuration = const Duration(hours: 1);

  @override
  String get name => 'WaitToPushOut';

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) {
    if (lift.canPushOut) {
      return PushOut();
    }
    return null;
  }
}

class PushOut extends DurationState<DrawerLoaderLift> {
  PushOut()
      : super(
            durationFunction: (drawerLift) => drawerLift.pushOutDuration,
            nextStateFunction: (drawerLift) => Decide());

  @override
  String get name => 'PushOut';

  @override
  void onStart(DrawerLoaderLift lift) {
    super.onStart(lift);
    lift.onStartPushOutTopPosition();
  }

  @override
  void onCompleted(DrawerLoaderLift lift) {
    super.onCompleted(lift);
    lift.onCompletePushOutTopPosition();
  }
}

class WaitOnPushIn extends State<DrawerLoaderLift> {
  @override
  String get name => 'WaitOnPushIn';

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) {
    if (!lift.canReceiveDrawers) {
      return Decide();
    }
    return null;
  }
}

class LoaderToLiftPosition extends DrawerPosition implements TimeProcessor {
  late DrawerLoaderLift lift;
  int level;
  final OffsetInMeters vector;
  Duration elapsed = Duration.zero;
  final Duration duration;

  LoaderToLiftPosition({required this.lift, required this.level})
      : vector = lift.topLeftToLiftLevel(level) - lift.topLeftToDrawerInModule,
        duration = (lift.drawerIn.linkedTo.owner as ModuleDrawerLoader)
            .pusherOutDuration;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (elapsed < duration) {
      elapsed += jump;
    }
    if (elapsed > duration) {
      elapsed = duration;
    }
  }

  @override
  OffsetInMeters topLeft(MachineLayout layout) {
    var completed = elapsed.inMilliseconds / duration.inMilliseconds;
    return layout.topLeftWhenFacingNorthOf(lift) +
        lift.topLeftToDrawerInModule +
        vector * completed;
  }

  @override
  double rotationInFraction(MachineLayout layout) =>
      layout.rotationOf(lift).toFraction();
}

class LiftPosition extends DrawerPosition {
  DrawerLoaderLift lift;
  int level;
  LiftPosition({
    required this.lift,
    required this.level,
  });

  @override
  OffsetInMeters topLeft(MachineLayout layout) {
    var topLeft = layout.topLeftWhenFacingNorthOf(lift);
    return topLeft + lift.topLeftToLiftLevel(level);
  }

  @override
  double rotationInFraction(MachineLayout layout) =>
      layout.rotationOf(lift).toFraction();
}

class LiftPositionUp extends DrawerPosition implements TimeProcessor {
  final DrawerLoaderLift lift;
  int startLevel;
  final OffsetInMeters vector;
  Duration elapsed = Duration.zero;
  final Duration duration;

  LiftPositionUp({required this.lift, required this.startLevel})
      : vector = (lift.topLeftToLiftLevel(startLevel + 1) -
            lift.topLeftToLiftLevel(startLevel)),
        duration = lift.upDuration;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (elapsed < duration) {
      elapsed += jump;
    }
    if (elapsed > duration) {
      elapsed = duration;
    }
  }

  @override
  OffsetInMeters topLeft(MachineLayout layout) {
    var completed = elapsed.inMilliseconds / duration.inMilliseconds;
    return layout.topLeftWhenFacingNorthOf(lift) +
        lift.topLeftToLiftLevel(startLevel) +
        vector * completed;
  }

  @override
  double rotationInFraction(MachineLayout layout) =>
      layout.rotationOf(lift).toFraction();
}
