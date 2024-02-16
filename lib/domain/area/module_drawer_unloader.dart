// ignore_for_file: avoid_renaming_method_parameters

import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/machine.dart';
import 'package:meyn_lbh_simulation/gui/area/area.dart';

import '../util/title_builder.dart';
import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

class ModuleDrawerUnloader extends StateMachineCell
    implements Machine, BirdBuffer //TODO get rid of BirdBuffer
{
  final CardinalDirection inFeedDirection;

  ///Number of birds on dumping belt between module and hanger (a buffer).
  ///The unloader starts tilting when birdsOnDumpBelt<dumpBeltBufferSize
  ///Normally this number is between the number of birds in 1 or 2 modules
  final Duration checkIfEmptyDuration;
  final Duration pusherOutDuration;
  final Duration pusherInDuration;
  final Duration feedInToSecondColumn;
  final bool drawersToLeft;
  Duration? durationPerModule;

  Durations durationsPerModule = Durations(maxSize: 8);

  ModuleDrawerUnloader({
    required super.area,
    required super.position,
    super.name = 'ModuleDrawerUnloader',
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
  late SizeInMeters sizeWhenFacingNorth = const SizeInMeters(
      widthInMeters: 3, heightInMeters: 3); //TODO 3 metert is an assumption

  late DrawersOutLink drawersOut = DrawersOutLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: drawersToLeft
              ? -sizeWhenFacingNorth.widthInMeters / 2
              : sizeWhenFacingNorth.widthInMeters / 2,
          metersFromTop: sizeWhenFacingNorth.heightInMeters / 2),
      directionFromCenter: drawersToLeft
          ? CardinalDirection.west.toCompassDirection()
          : CardinalDirection.east.toCompassDirection());

  @override
  late List<Link> links = [drawersOut]; //TODO add containerIn and containerOut

  late DrawerUnloaderLift drawerLift =
      drawersOut.linkedTo.owner as DrawerUnloaderLift;

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
  String toString() => TitleBuilder(name)
      .appendProperty('currentState', currentState)
      .appendProperty('speed',
          '${durationsPerModule.averagePerHour.toStringAsFixed(1)} modules/hour')
      .appendProperty('moduleGroup', moduleGroup)
      .toString();

  void onEndOfCycle() {
    durationsPerModule.add(durationPerModule);
    durationPerModule = Duration.zero;
  }

  @override
  CardinalDirection get birdDirection =>
      CardinalDirection.north; //TODO get rid of this

  @override
  bool removeBird() => true;
}

class CheckIfEmpty extends DurationState<ModuleDrawerUnloader> {
  @override
  String get name => 'CheckIfEmpty';

  CheckIfEmpty()
      : super(
            durationFunction: (unloader) => unloader.checkIfEmptyDuration,
            nextStateFunction: (unloader) =>
                FeedOutAndFeedInToFirstColumnSimultaneously());
}

class FeedOutAndFeedInToFirstColumnSimultaneously
    extends State<ModuleDrawerUnloader> {
  @override
  String get name => 'FeedInAndFeedOutSimultaneously';

  ModuleGroup? moduleGroupTransportedOut;
  InFeedState inFeedState = InFeedState.waitingToFeedOut;
  OutFeedState outFeedState = OutFeedState.waitingOnNeighbor;

  @override
  void onStart(ModuleDrawerUnloader unloader) {
    outFeedState = unloader.moduleGroup == null
        ? OutFeedState.done
        : OutFeedState.waitingOnNeighbor;
  }

  @override
  void onUpdateToNextPointInTime(ModuleDrawerUnloader unloader, Duration jump) {
    processInFeedState(unloader, jump);
    processOutFeedState(unloader, jump);
  }

  void processInFeedState(ModuleDrawerUnloader unloader, Duration jump) {
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

  bool _inFeedCompleted(ModuleDrawerUnloader unloader) =>
      unloader.moduleGroup != null;

  bool _inFeedStarted(ModuleDrawerUnloader unloader) {
    return unloader.area.moduleGroups
        .any((moduleGroup) => moduleGroup.position.destination == unloader);
  }

  void processOutFeedState(ModuleDrawerUnloader unloader, Duration jump) {
    switch (outFeedState) {
      case OutFeedState.waitingOnNeighbor:
        if (_outFeedStarted(unloader)) {
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

  void transportModuleOut(ModuleDrawerUnloader unloader) {
    moduleGroupTransportedOut = unloader.moduleGroup;
    moduleGroupTransportedOut!.position = ModulePosition.betweenCells(
        source: unloader,
        destination: unloader.outFeedNeighbor as StateMachineCell);
  }

  _outFeedStarted(ModuleDrawerUnloader unloader) =>
      unloader.receivingNeighbor.waitingToFeedIn(unloader.inFeedDirection);

  @override
  State<ModuleDrawerUnloader>? nextState(ModuleDrawerUnloader unloader) {
    if (inFeedState == InFeedState.done && outFeedState == OutFeedState.done) {
      return WaitToUnloadFirstColumn();
    }
    return null;
  }

  @override
  void onCompleted(ModuleDrawerUnloader unloader) {
    _verifyDoorDirection(unloader);
  }

  void _verifyDoorDirection(ModuleDrawerUnloader unloader) {
    // var moduleGroup = unloader.moduleGroup!;
    // var hasDoors =
    //     moduleGroup.moduleFamily.compartmentType == CompartmentType.door;
    // if (hasDoors &&
    //     moduleGroup.direction.toCardinalDirection() != unloader.birdDirection) {
    //   throw ('In correct door direction of the $ModuleGroup that was fed in to ${unloader.name}');
    // }
  }

  bool _outFeedCompleted(ModuleDrawerUnloader unloader) =>
      moduleGroupTransportedOut != null &&
      moduleGroupTransportedOut!.position.destination ==
          unloader.outFeedNeighbor;
}

enum InFeedState { waitingToFeedOut, waitingOnNeighbor, transporting, done }

enum OutFeedState { waitingOnNeighbor, transporting, done }

class WaitToUnloadFirstColumn extends State<ModuleDrawerUnloader> {
  @override
  String get name => 'WaitToUnloadFirstColumn';

  @override
  State<ModuleDrawerUnloader>? nextState(ModuleDrawerUnloader unloader) {
    var moduleGroup = unloader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle stacked containers');
    }
    int levels = moduleGroup.firstModule.levels;
    unloader.drawerLift.waitingDrawersToBePushedIn = levels;
    if (unloader.drawerLift.canReceiveDrawers) {
      return PushOutFirstColumn();
    }
    return null;
  }
}

class PushOutFirstColumn extends DurationState<ModuleDrawerUnloader> {
  @override
  String get name => 'PushOutFirstColumn';

  PushOutFirstColumn()
      : super(
            durationFunction: (unloader) => unloader.pusherOutDuration,
            nextStateFunction: (unloader) => PusherInFirstColumn());
  @override
  void onStart(ModuleDrawerUnloader unloader) {
    super.onStart(unloader);
    unloader.drawerLift.onStartPushingDrawersToLift();
  }

  @override
  void onCompleted(ModuleDrawerUnloader unloader) {
    super.onCompleted(unloader);
    unloader.drawerLift.onCompletePushingDrawersToLift();
    unloader.drawerLift.waitingDrawersToBePushedIn = 0;
  }
}

class PusherInFirstColumn extends DurationState<ModuleDrawerUnloader> {
  @override
  String get name => 'PusherInFirstColumn';

  PusherInFirstColumn()
      : super(
            durationFunction: (unloader) => unloader.pusherInDuration,
            nextStateFunction: (unloader) => FeedInToSecondColumn());
}

class FeedInToSecondColumn extends DurationState<ModuleDrawerUnloader> {
  @override
  String get name => 'FeedInToSecondColumn';

  FeedInToSecondColumn()
      : super(
            durationFunction: (unloader) => unloader.feedInToSecondColumn,
            nextStateFunction: (unloader) => WaitToUnloadSecondColumn());
}

class WaitToUnloadSecondColumn extends State<ModuleDrawerUnloader> {
  @override
  String get name => 'WaitToUnloadSecondColumn';

  @override
  State<ModuleDrawerUnloader>? nextState(ModuleDrawerUnloader unloader) {
    var moduleGroup = unloader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle stacked containers');
    }
    int levels = moduleGroup.firstModule.levels;
    unloader.drawerLift.waitingDrawersToBePushedIn = levels;
    if (unloader.drawerLift.canReceiveDrawers) {
      return PushOutSecondColumn();
    }
    return null;
  }
}

class PushOutSecondColumn extends DurationState<ModuleDrawerUnloader> {
  @override
  String get name => 'PushOutSecondColumn';

  PushOutSecondColumn()
      : super(
            durationFunction: (unloader) => unloader.pusherOutDuration,
            nextStateFunction: (unloader) => PusherInSecondColumn());

  @override
  void onStart(ModuleDrawerUnloader unloader) {
    super.onStart(unloader);
    unloader.drawerLift.onStartPushingDrawersToLift();
  }

  @override
  void onCompleted(ModuleDrawerUnloader unloader) {
    super.onCompleted(unloader);
    var moduleGroup = unloader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle stacked containers');
    }
    unloader.drawerLift.onCompletePushingDrawersToLift();
    moduleGroup.unloadBirds();
    unloader.drawerLift.waitingDrawersToBePushedIn = 0;
  }
}

class PusherInSecondColumn extends DurationState<ModuleDrawerUnloader> {
  @override
  String get name => 'PusherInSecondColumn';

  PusherInSecondColumn()
      : super(
            durationFunction: (unloader) => unloader.pusherInDuration,
            nextStateFunction: (unloader) =>
                FeedOutAndFeedInToFirstColumnSimultaneously());

  @override
  void onCompleted(ModuleDrawerUnloader unloader) {
    super.onCompleted(unloader);
    unloader.onEndOfCycle();
  }
}

class DrawerUnloaderLift extends StateMachine implements Machine {
  final LiveBirdHandlingArea area;
  late ModuleDrawerUnloader moduleDrawerUnloader = _findModuleDrawerUnloader();
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
  final String name = 'UnloaderDrawerLift';

  Duration drawerPushOutCycle = Duration.zero;
  Duration drawerPushOutCycleBuffer = Duration.zero;
  Durations drawerPushOutCycles = Durations(maxSize: 8);

//TODO the DrawerHangingConveyor should tell if there is space to recieve a drawer
  late Duration minimumInterval =
      Duration(milliseconds: 3600000 ~/ maxDrawersPerHour);
  late double offsetInMeters = 0.2;

  DrawerUnloaderLift({
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

  late DrawersInLink<DrawerUnloaderLift> drawersIn =
      DrawersInLink<DrawerUnloaderLift>(
          owner: this,
          offsetFromCenter: OffsetInMeters(
              metersFromLeft: 0,
              metersFromTop: sizeWhenFacingNorth.heightInMeters / 2),
          directionFromCenter: const CompassDirection.south());

  late DrawerOutLink<DrawerUnloaderLift> drawerOut =
      DrawerOutLink<DrawerUnloaderLift>(
          owner: this,
          offsetFromCenter: OffsetInMeters(
              metersFromLeft: 0,
              metersFromTop: -sizeWhenFacingNorth.heightInMeters / 2),
          directionFromCenter: const CompassDirection.north());

  @override
  late List<Link> links = [
    /// TODO add drawersIn when the ModuleDrawerUnloader is changed from a cell to a Machine
    drawerOut
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
  String toString() => TitleBuilder(name)
      .appendProperty('currentState', currentState)
      .appendProperty('speed',
          '${drawerPushOutCycles.averagePerHour.toStringAsFixed(1)} drawers/hour')
      .toString();

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    drawerPushOutCycle += jump;
    // buffer conveyor between unloader and hanging no bigger than 4 drawers
    if (drawerPushOutCycleBuffer <
        (minimumInterval +
            minimumInterval +
            minimumInterval +
            minimumInterval)) {
      drawerPushOutCycleBuffer += jump;
    }
  }

// This method is called by the unloader
  void onStartPushingDrawersToLift() {
    var drawers = moduleDrawerUnloader.area.drawers;
    ModuleDrawerUnloader unloader =
        drawersIn.linkedTo.owner as ModuleDrawerUnloader;
    var module = unloader.moduleGroup!.firstModule;
    var levels = module.levels;
    var nrOfBirdsPerDrawer = module.nrOfBirds / 2 ~/ levels;
    var contents = unloader.moduleGroup!.contents;
    for (int level = levels - 1; level >= 0; level--) {
      /// creating a temporary conveyor to move the drawer from DrawerUnloader to lift position
      var drawer = GrandeDrawer(
        startPosition: unloader.position,
        nrOfBirds: nrOfBirdsPerDrawer,
        contents: contents,
        position: UnloaderToLiftPosition(lift: this, level: level),
      );
      drawers.add(drawer);
    }
  }

// This method is called by the unloader
  void onCompletePushingDrawersToLift() {
    if (!canReceiveDrawers) {
      throw Exception('You can not push $waitingDrawersToBePushedIn drawer(s)'
          ' into the $name');
    }
    var drawersBeingPushedIn = area.drawers.where((drawer) =>
        drawer.position is UnloaderToLiftPosition &&
        (drawer.position as UnloaderToLiftPosition).lift == this);
    for (var drawer in drawersBeingPushedIn) {
      int level = (drawer.position as UnloaderToLiftPosition).level;
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
    var conveyorAfterUnloaderLift = drawerOut.linkedTo.owner as DrawerConveyor;
    conveyorAfterUnloaderLift.metersPerSecond =
        conveyorAfterUnloaderLift.drawerPath.totalLength /
            pushOutDuration.inMicroseconds *
            1000000;
    drawerBeingPushedOut.position =
        OnConveyorPosition(conveyorAfterUnloaderLift);
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

  ModuleDrawerUnloader _findModuleDrawerUnloader() {
    //TODO get this via a link
    return area.cells.whereType<ModuleDrawerUnloader>().first;
  }
}

class Decide extends State<DrawerUnloaderLift> {
  @override
  String get name => 'DecideRaiseOrPushOut';

  @override
  State<DrawerUnloaderLift>? nextState(DrawerUnloaderLift lift) {
    if (lift.liftPositions.last != null) {
      return WaitToPushOut();
    }
    if (lift.canReceiveDrawers) {
      return WaitOnPushIn();
    }
    return RaiseLift();
  }
}

class RaiseLift extends DurationState<DrawerUnloaderLift> {
  RaiseLift()
      : super(
            durationFunction: (drawerLift) => drawerLift.upDuration,
            nextStateFunction: (drawerLift) => Decide());

  @override
  String get name => 'RaiseLift';

  @override
  void onStart(DrawerUnloaderLift lift) {
    super.onStart(lift);
    if (lift.liftPositions.last != null) {
      throw Exception(
          'Can not raise UnloaderDrawerLift when drawer is in top.');
    }
    for (var liftPos in lift.liftPositions) {
      if (liftPos is GrandeDrawer && liftPos.position is LiftPosition) {
        var level = (liftPos.position as LiftPosition).level;
        liftPos.position = LiftPositionUp(lift: lift, startLevel: level);
      }
    }
  }

  @override
  void onCompleted(DrawerUnloaderLift lift) {
    super.onCompleted(lift);
    if (lift.liftPositions.last != null) {
      throw Exception(
          'Can not raise UnloaderDrawerLift when drawer is in top.');
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

class WaitToPushOut extends State<DrawerUnloaderLift> {
  Duration maxDuration = const Duration(hours: 1);

  @override
  String get name => 'WaitToPushOut';

  @override
  State<DrawerUnloaderLift>? nextState(DrawerUnloaderLift lift) {
    if (lift.canPushOut) {
      return PushOut();
    }
    return null;
  }
}

class PushOut extends DurationState<DrawerUnloaderLift> {
  PushOut()
      : super(
            durationFunction: (drawerLift) => drawerLift.pushOutDuration,
            nextStateFunction: (drawerLift) => Decide());

  @override
  String get name => 'PushOut';

  @override
  void onStart(DrawerUnloaderLift lift) {
    super.onStart(lift);
    lift.onStartPushOutTopPosition();
  }

  @override
  void onCompleted(DrawerUnloaderLift lift) {
    super.onCompleted(lift);
    lift.onCompletePushOutTopPosition();
  }
}

class WaitOnPushIn extends State<DrawerUnloaderLift> {
  @override
  String get name => 'WaitOnPushIn';

  @override
  State<DrawerUnloaderLift>? nextState(DrawerUnloaderLift lift) {
    if (!lift.canReceiveDrawers) {
      return Decide();
    }
    return null;
  }
}

class UnloaderToLiftPosition extends DrawerPosition implements TimeProcessor {
  late DrawerUnloaderLift lift;
  int level;
  final OffsetInMeters vector;
  Duration elapsed = Duration.zero;
  final Duration duration;

  UnloaderToLiftPosition({required this.lift, required this.level})
      : vector = lift.topLeftToLiftLevel(level) - lift.topLeftToDrawerInModule,
        duration = (lift.drawersIn.linkedTo.owner as ModuleDrawerUnloader)
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

  // @override
  // Offset topLeft(MachineLayout layout, double sizePerMeter) {
  //   var completed = elapsed.inMilliseconds / duration.inMilliseconds;
  //   return layout.topLeftOffset(lift, sizePerMeter) +
  //       lift.topLeftToDrawerInModule * sizePerMeter +
  //       vector.toOffset() * sizePerMeter * completed;
  // }
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
  DrawerUnloaderLift lift;
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
  final DrawerUnloaderLift lift;
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
