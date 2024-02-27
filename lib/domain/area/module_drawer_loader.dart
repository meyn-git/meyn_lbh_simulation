// ignore_for_file: avoid_renaming_method_parameters

import 'package:collection/collection.dart';
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

class DrawerLoaderLift extends StateMachine implements Machine {
  final LiveBirdHandlingArea area;
  @override
  late String name = 'DrawerLoaderLift';
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];
  late ModuleDrawerLoader moduleDrawerLoader = _findModuleDrawerLoader();
  final int nrOfLiftPositions;
  int nrOfDrawersToBePushedInModule = 0;

  /// position[0]=bottom position in lift
  /// position[nrOfPositions-1]=top position in lift
  /// null =  without drawer
  List<GrandeDrawer?> liftPositions;
  final Duration upDuration;
  final Duration feedInDrawerDuration;
  final Duration pusherOutDuration;
  final Duration pusherInDuration;

  Duration drawerPushOutCycle = Duration.zero;
  Durations drawerPushOutCycles = Durations(maxSize: 8);

  static const double verticalLevelOffsetInMeters = 0.2;
  static const double horizontalLevelOffsetInMeters =
      verticalLevelOffsetInMeters / 4;

  DrawerLoaderLift({
    required this.area,
    this.upDuration = const Duration(
        milliseconds:
            1600), // Based on "Speed calculations_estimates_V3_Erik.xlsx"

    this.feedInDrawerDuration = const Duration(milliseconds: 2500), // TODO
    this.pusherOutDuration = const Duration(
        milliseconds:
            2500), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    this.pusherInDuration = const Duration(milliseconds: 2500), // TODO
    this.nrOfLiftPositions = 6,
  })  : liftPositions = List.filled(
          nrOfLiftPositions,
          null,
        ),
        super(
          initialState: SimultaneouslyFeedInAndFeedOutDrawers(),
        );

  @override
  late SizeInMeters sizeWhenFacingNorth = _size();

  bool get canGoUp =>
      !bottomPositionIsEmpty &&
      liftPositions.where((drawerPosition) => drawerPosition != null).length <=
          levelsToLoad;

  int get levelsToLoad => drawersOut.linkedTo.numberOfDrawersToFeedIn() == 0
      ? minimumNumberOfLevelsInModule + 1
      : drawersOut.linkedTo.numberOfDrawersToFeedIn();

  int minimumNumberOfLevelsInModule = 4; //TODO get this from productDefinition

  List<GrandeDrawer> get drawersToFeedOut => liftPositions
      .getRange(1, liftPositions.length - 1)
      .whereNotNull()
      .toList();

  bool get canFeedOutDrawers =>
      moduleDrawerLoader.moduleGroup != null &&
      moduleDrawerLoader.moduleGroup!.firstModule.levels ==
          drawersToFeedOut.length;

  SizeInMeters _size() {
    var length = GrandeDrawerModuleType.drawerOutSideLengthInMeters +
        verticalLevelOffsetInMeters * (nrOfLiftPositions + 1);
    return SizeInMeters(widthInMeters: length, heightInMeters: length);
  }

  late DrawerInLink<DrawerLoaderLift> drawerIn = DrawerInLink<DrawerLoaderLift>(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: 0,
          metersFromTop: sizeWhenFacingNorth.heightInMeters / 2),
      directionFromCenter: CardinalDirection.south.toCompassDirection());

  late DrawersOutLink<DrawerLoaderLift> drawersOut =
      DrawersOutLink<DrawerLoaderLift>(
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

  late OffsetInMeters topLeftToBottomConveyorEnd = _topLeftToTopConveyorEnd();
  OffsetInMeters _topLeftToTopConveyorEnd() => OffsetInMeters(
      metersFromLeft: sizeWhenFacingNorth.widthInMeters / 2, metersFromTop: 0);

  OffsetInMeters topLeftToLiftLevel(int level) =>
      topLeftToBottomConveyorEnd -
      const OffsetInMeters(
          metersFromLeft:
              GrandeDrawerModuleType.drawerOutSideLengthInMeters / 2,
          metersFromTop: 0) +
      OffsetInMeters(
          metersFromLeft: horizontalLevelOffsetInMeters * (level),
          metersFromTop:
              verticalLevelOffsetInMeters * (nrOfLiftPositions - level));

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
  }

  List<GrandeDrawer> get drawers => moduleDrawerLoader.area.drawers;

  late DrawerConveyor precedingConveyor =
      drawerIn.linkedTo.owner as DrawerConveyor;
  void onStartPushOutTopPosition() {
    for (int level = 1; level < liftPositions.length - 2; level++) {
      var drawer = liftPositions[level]!;
      drawer.position = LiftToLoaderPosition(lift: this, level: level);
    }
  }

  void onCompletePushOutTopPosition() {
    liftPositions = [
      ...liftPositions.getRange(0, liftPositions.length - 1),
      null
    ];
    drawerPushOutCycles.add(drawerPushOutCycle);
    drawerPushOutCycle = Duration.zero;
  }

  bool get bottomPositionIsEmpty {
    return liftPositions.firstOrNull == null;
  }

  ModuleDrawerLoader _findModuleDrawerLoader() {
    //TODO get this via a link
    return area.cells.whereType<ModuleDrawerLoader>().first;
  }

  GrandeDrawer? drawerAtEndOfPrecedingConveyor() =>
      drawers.firstWhereOrNull((drawer) =>
          drawer.position is OnConveyorPosition &&
          (drawer.position as OnConveyorPosition).conveyor ==
              precedingConveyor &&
          (drawer.position as OnConveyorPosition).atEnd);
}

class SimultaneouslyFeedInAndFeedOutDrawers extends State<DrawerLoaderLift> {
  SimultaneouslyFeedInAndFeedOutDrawers();
  GrandeDrawer? drawerToFeedIn;
  List<GrandeDrawer> drawersToFeedOut = [];
  @override
  String get name => 'SimultaneouslyFeedInAndFeedOutDrawers';

  bool get feedOutDrawersCompleted => drawersToFeedOut.isEmpty
      ? false
      : (drawersToFeedOut.first.position is LiftToLoaderPosition) &&
          (drawersToFeedOut.first.position as LiftToLoaderPosition).completed;

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) {
    var drawerAtEndOfPrecedingConveyor = lift.drawerAtEndOfPrecedingConveyor();
    if (canStartFeedInDrawer(drawerAtEndOfPrecedingConveyor, lift)) {
      startFeedInDrawer(drawerAtEndOfPrecedingConveyor, lift);
    }
    if (canStartFeedOutDrawers(lift)) {
      startFeedOutDrawers(lift);
    }
    if (feedInDrawerCompleted) {
      drawerToFeedIn!.position = LiftPosition(lift: lift, level: 0);
      lift.liftPositions[0] = drawerToFeedIn;
    }
    if (feedOutDrawersCompleted) {
      for (var drawer in drawersToFeedOut) {
        var index = lift.liftPositions.indexOf(drawer);
        lift.liftPositions[index] == null;
        lift.area.drawers.remove(drawer);
      }
      lift.moduleDrawerLoader.onDrawersFeedInCompleted(drawersToFeedOut);
    }
    if (feedingInDrawer || feedingOutDrawers) {
      //wait
      return null;
    }
    if (lift.canGoUp) {
      return RaiseLift();
    }
    //wait
    return null;
  }

  bool get feedInDrawerCompleted => drawerToFeedIn == null
      ? false
      : (drawerToFeedIn!.position is InToLiftPosition) &&
          (drawerToFeedIn!.position as InToLiftPosition).completed;
  bool canStartFeedInDrawer(GrandeDrawer? drawerAtEndOfPrecedingConveyor,
          DrawerLoaderLift lift) =>
      drawerToFeedIn == null &&
      drawerAtEndOfPrecedingConveyor != null &&
      lift.bottomPositionIsEmpty;

  void startFeedInDrawer(
      GrandeDrawer? drawerAtEndOfPrecedingConveyor, DrawerLoaderLift lift) {
    drawerToFeedIn = drawerAtEndOfPrecedingConveyor;
    drawerToFeedIn!.position = InToLiftPosition(lift);
  }

  bool get feedingInDrawer =>
      drawerToFeedIn != null &&
      drawerToFeedIn!.position is InToLiftPosition &&
      !(drawerToFeedIn!.position as InToLiftPosition).completed;

  bool canStartFeedOutDrawers(DrawerLoaderLift lift) =>
      drawersToFeedOut.isEmpty && lift.canFeedOutDrawers;

  void startFeedOutDrawers(DrawerLoaderLift lift) {
    var drawersToFeedOut = lift.drawersToFeedOut;
    for (int level = 0; level <= drawersToFeedOut.length; level++) {
      var drawerToFeedOut = drawersToFeedOut[level];
      drawerToFeedOut.position = LiftToLoaderPosition(lift: lift, level: level);
    }
  }

  bool get feedingOutDrawers =>
      drawersToFeedOut.isNotEmpty &&
      !drawersToFeedOut.any(
          (drawer) => !(drawer.position as LiftToLoaderPosition).completed);
}

class RaiseLift extends DurationState<DrawerLoaderLift> {
  RaiseLift()
      : super(
            durationFunction: (drawerLift) => drawerLift.upDuration,
            nextStateFunction: (drawerLift) =>
                SimultaneouslyFeedInAndFeedOutDrawers());

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

class InToLiftPosition extends DrawerPosition implements TimeProcessor {
  final DrawerLoaderLift lift;
  final OffsetInMeters vector;
  Duration elapsed = Duration.zero;
  final Duration duration;
  InToLiftPosition(this.lift)
      : vector = lift.topLeftToLiftLevel(0) - lift.drawerIn.offsetFromCenter,
        duration = lift.pusherOutDuration;

  bool get completed => elapsed >= duration;

  @override
  double rotationInFraction(MachineLayout layout) =>
      layout.rotationOf(lift).toFraction();

  @override
  OffsetInMeters topLeft(MachineLayout layout) {
    var completed = elapsed.inMilliseconds / duration.inMilliseconds;
    return layout.topLeftWhenFacingNorthOf(lift) +
        lift.topLeftToDrawerInModule +
        vector * completed;
  }

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (elapsed < duration) {
      elapsed += jump;
    }
    if (elapsed > duration) {
      elapsed = duration;
    }
  }
}

class LiftToLoaderPosition extends DrawerPosition implements TimeProcessor {
  late DrawerLoaderLift lift;
  int level;
  final OffsetInMeters vector;
  Duration elapsed = Duration.zero;
  final Duration duration;

  LiftToLoaderPosition({required this.lift, required this.level})
      : vector = lift.topLeftToDrawerInModule - lift.topLeftToLiftLevel(level),
        duration = (lift.drawerIn.linkedTo.owner as ModuleDrawerLoader)
            .pusherOutDuration;

  bool get completed => elapsed >= duration;

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
  final bool drawersFromLeft;
  Duration? durationPerModule;

  Durations durationsPerModule = Durations(maxSize: 8);

  ModuleDrawerLoader({
    required super.area,
    required super.position,
    super.name = 'ModuleDrawerLoader',
    super.seqNr,
    required this.inFeedDirection,
    required this.drawersFromLeft,
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

  late DrawersInLink drawersIn = DrawersInLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: drawersFromLeft
              ? -sizeWhenFacingNorth.widthInMeters / 2
              : sizeWhenFacingNorth.widthInMeters / 2,
          metersFromTop: 0),
      directionFromCenter: drawersFromLeft
          ? inFeedDirection.toCompassDirection().rotate(-90)
          : inFeedDirection.toCompassDirection().rotate(90),
      numberOfDrawersToFeedIn: numberOfDrawersToFeedIn,
      onFeedInStarted: onDrawersFeedInStarted,
      onFeedInCompleted: onDrawersFeedInCompleted);

  @override
  late List<Link> links = [drawersIn]; //TODO add containerIn and containerOut

  late DrawerLoaderLift drawerLift =
      drawersIn.linkedTo.owner as DrawerLoaderLift;

  get inFeedNeighbor => area.neighboringCell(this, inFeedDirection);

  get outFeedNeighbor => area.neighboringCell(this, inFeedDirection.opposite);

  bool get waitingToFeedInDrawers => (currentState is WaitToPushInFirstColumn ||
      currentState is WaitToPushInSecondColumn);

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

  int numberOfDrawersToFeedIn() =>
      !waitingToFeedInDrawers ? 0 : moduleGroup!.firstModule.levels;

  void onDrawersFeedInStarted() {
    //TODO
  }

  void onDrawersFeedInCompleted(List<GrandeDrawer> drawers) {
    if (currentState is WaitToPushInFirstColumn) {
      (currentState as WaitToPushInFirstColumn).completed = true;
    }
    if (currentState is WaitToPushInSecondColumn) {
      (currentState as WaitToPushInSecondColumn).completed = true;
    }
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
      return WaitToPushInFirstColumn();
    }
    return null;
  }

  @override
  void onCompleted(ModuleDrawerLoader loader) {
    _verifyDoorDirection(loader);
  }

  void _verifyDoorDirection(ModuleDrawerLoader loader) {
    var moduleGroup = loader.moduleGroup!;
    var oneSideIn = moduleGroup.moduleFamily.compartmentType ==
        CompartmentType.doorOnOneSide;
    if (oneSideIn &&
        moduleGroup.direction !=
            loader.inFeedDirection
                .toCompassDirection()
                .rotate(loader.drawersFromLeft ? -90 : 90)) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${loader.name}');
    }
  }

  bool _outFeedCompleted(ModuleDrawerLoader loader) =>
      moduleGroupTransportedOut != null &&
      moduleGroupTransportedOut!.position.destination == loader.outFeedNeighbor;
}

enum InFeedState { waitingToFeedOut, waitingOnNeighbor, transporting, done }

enum OutFeedState { waitingOnNeighbor, transporting, done }

class WaitToPushInFirstColumn extends WaitOnCompletedState<ModuleDrawerLoader> {
  WaitToPushInFirstColumn()
      : super(nextStateFunction: (_) => FeedInToSecondColumn());

  @override
  String get name => 'WaitToPushInFirstColumn';

  @override
  State<ModuleDrawerLoader>? nextState(ModuleDrawerLoader loader) {
    var moduleGroup = loader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Loader can not handle stacked containers');
    }
    return super.nextState(loader);
  }
}

class FeedInToSecondColumn extends DurationState<ModuleDrawerLoader> {
  @override
  String get name => 'FeedInToSecondColumn';

  FeedInToSecondColumn()
      : super(
            durationFunction: (loader) => loader.feedInToSecondColumn,
            nextStateFunction: (loader) => WaitToPushInSecondColumn());
}

class WaitToPushInSecondColumn
    extends WaitOnCompletedState<ModuleDrawerLoader> {
  WaitToPushInSecondColumn()
      : super(
            nextStateFunction: (_) =>
                FeedOutAndFeedInToFirstColumnSimultaneously());

  @override
  String get name => 'WaitToPushInSecondColumn';

  @override
  State<ModuleDrawerLoader>? nextState(ModuleDrawerLoader loader) {
    var moduleGroup = loader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Loader can not handle stacked containers');
    }
    return super.nextState(loader);
  }
}
