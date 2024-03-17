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

  List<GrandeDrawer> get drawersToFeedOut =>
      liftPositions.getRange(1, liftPositions.length).whereNotNull().toList();

  bool get canFeedOutDrawers =>
      moduleDrawerLoader.moduleGroup != null &&
      moduleDrawerLoader.moduleGroup!.firstModule.levels ==
          drawersToFeedOut.length;

  var length = GrandeDrawerModuleType.drawerOutSideLengthInMeters * 1.2;
  SizeInMeters _size() {
    return SizeInMeters(widthInMeters: length, heightInMeters: length);
  }

  late DrawerInLink<DrawerLoaderLift> drawerIn = DrawerInLink<DrawerLoaderLift>(
      owner: this,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          metersFromLeft: 0,
          metersFromTop: sizeWhenFacingNorth.heightInMeters / 2),
      directionFromCenter: CardinalDirection.south.toCompassDirection());

  late DrawersOutLink<DrawerLoaderLift> drawersOut =
      DrawersOutLink<DrawerLoaderLift>(
          owner: this,
          offsetFromCenterWhenFacingNorth: OffsetInMeters(
              metersFromLeft: 0,
              metersFromTop: -sizeWhenFacingNorth.heightInMeters / 2),
          directionFromCenter: CardinalDirection.north.toCompassDirection());

  @override
  late List<Link> links = [
    drawerIn, //TODO drawerOut
    //TODO modulePositions
  ];

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

  /// How far apart the minimized drawers are displayed.
  /// See [minimizedDrawerSize]
  late double minimizedDrawerDistance =
      sizeWhenFacingNorth.heightInMeters / (nrOfLiftPositions + 1);

  /// the drawers are minimized inside the lift to show all drawers in the lift
  late SizeInMeters minimizedDrawerSize = SizeInMeters(
      widthInMeters: minimizedDrawerDistance * 0.8,
      heightInMeters: minimizedDrawerDistance * 0.8);

  OffsetInMeters centerLiftToCenterDrawerInLift(int level) => OffsetInMeters(
      metersFromLeft: sizeWhenFacingNorth.widthInMeters / 2,
      metersFromTop: (nrOfLiftPositions - level) * minimizedDrawerDistance
      // +    sizeWhenFacingNorth.heightInMeters / 2
      );
}

typedef DrawerFeedInState = State<DrawerLoaderLift>;

class WaitingToFeedInDrawer extends DrawerFeedInState {
  @override
  String get name => 'WaitingToFeedInDrawer';

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) {
    var drawerToFeedIn = lift.drawerAtEndOfPrecedingConveyor();
    if (canStartFeedInDrawer(drawerToFeedIn, lift)) {
      return FeedingInDrawer(drawerToFeedIn!);
    }
    return null;
  }

  bool canStartFeedInDrawer(
          GrandeDrawer? drawerToFeedIn, DrawerLoaderLift lift) =>
      drawerToFeedIn != null && lift.bottomPositionIsEmpty;
}

class FeedingInDrawer extends DrawerFeedInState {
  final GrandeDrawer drawerToFeedIn;

  FeedingInDrawer(this.drawerToFeedIn);

  @override
  String get name => 'FeedingInDrawer';

  @override
  void onStart(DrawerLoaderLift lift) {
    drawerToFeedIn.position = InToLiftPosition(lift);
  }

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) {
    if ((drawerToFeedIn.position as InToLiftPosition).completed) {
      return CompletedFeedInDrawer(drawerToFeedIn);
    }
    return null;
  }
}

class CompletedFeedInDrawer extends DrawerFeedInState {
  final GrandeDrawer drawerToFeedIn;

  CompletedFeedInDrawer(this.drawerToFeedIn);

  @override
  String get name => 'CompletedFeedInDrawer';

  @override
  void onStart(DrawerLoaderLift lift) {
    drawerToFeedIn.position = LiftPosition(lift: lift, level: 0);
    lift.liftPositions[0] = drawerToFeedIn;
  }

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift stateMachine) {
    return null;
  }
}

typedef DrawersFeedOutState = State<DrawerLoaderLift>;

class WaitingToFeedOutDrawers extends DrawersFeedOutState {
  @override
  String get name => 'WaitingToFeedOutDrawers';

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) {
    if (lift.canFeedOutDrawers) {
      return FeedingOutDrawers(lift.drawersToFeedOut);
    }
    return null;
  }
}

class FeedingOutDrawers extends DrawersFeedOutState {
  final List<GrandeDrawer> drawersToFeedOut;
  FeedingOutDrawers(this.drawersToFeedOut);

  @override
  String get name => 'FeedingOutDrawers';

  @override
  void onStart(DrawerLoaderLift lift) {
    for (int level = 0; level < drawersToFeedOut.length; level++) {
      var drawerToFeedOut = drawersToFeedOut[level];
      drawerToFeedOut.position = LiftToLoaderPosition(lift: lift, level: level);
    }
  }

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift stateMachine) {
    if (completed) {
      return CompletedFeedOutDrawer(drawersToFeedOut);
    }
    return null;
  }

  bool get completed =>
      (drawersToFeedOut.first.position is LiftToLoaderPosition) &&
      (drawersToFeedOut.first.position as LiftToLoaderPosition).completed;
}

class CompletedFeedOutDrawer extends DrawersFeedOutState {
  final List<GrandeDrawer> drawersToFeedOut;
  CompletedFeedOutDrawer(this.drawersToFeedOut);

  @override
  String get name => 'CompletedFeedOutDrawer';

  @override
  void onStart(DrawerLoaderLift lift) {
    for (var drawer in drawersToFeedOut) {
      var index = lift.liftPositions.indexOf(drawer);
      lift.liftPositions[index] = null;
      lift.area.drawers.remove(drawer);
    }
    lift.moduleDrawerLoader.onDrawersFeedInCompleted(drawersToFeedOut);
  }

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift stateMachine) {
    return null;
  }
}

class SimultaneouslyFeedInAndFeedOutDrawers extends State<DrawerLoaderLift> {
  SimultaneouslyFeedInAndFeedOutDrawers();
  DrawerFeedInState drawerInFeedState = WaitingToFeedInDrawer();
  DrawersFeedOutState drawersOutFeedState = WaitingToFeedOutDrawers();
  GrandeDrawer? drawerToFeedIn;
  List<GrandeDrawer> drawersToFeedOut = [];
  @override
  String get name => '${drawerInFeedState.name}, '
      '${drawersOutFeedState.name}';

  /// this method acts like a state machine for parallel states:
  /// * [drawerInFeedState]
  /// * [drawerInFeedState]
  @override
  void onUpdateToNextPointInTime(DrawerLoaderLift lift, Duration jump) {
    drawerInFeedState.onUpdateToNextPointInTime(lift, jump);
    var nextInFeedState = drawerInFeedState.nextState(lift);
    if (nextInFeedState != null) {
      drawerInFeedState.onCompleted(lift);
      drawerInFeedState = nextInFeedState;
      nextInFeedState.onStart(lift);
    }

    drawersOutFeedState.onUpdateToNextPointInTime(lift, jump);
    var nextOutFeedState = drawersOutFeedState.nextState(lift);
    if (nextOutFeedState != null) {
      drawersOutFeedState.onCompleted(lift);
      drawersOutFeedState = nextOutFeedState;
      nextOutFeedState.onStart(lift);
    }
  }

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) {
    if (drawerInFeedState is FeedingInDrawer ||
        drawersOutFeedState is FeedingOutDrawers) {
      // wait until feed in or feed out is completed
      return null;
    }
    if (lift.canGoUp) {
      return RaiseLift();
    }
    //wait until lift can go up
    return null;
  }

  bool get feedingInDrawer =>
      drawerToFeedIn != null &&
      drawerToFeedIn!.position is InToLiftPosition &&
      !(drawerToFeedIn!.position as InToLiftPosition).completed;

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

class InToLiftPosition extends DrawerPositionAndSize implements TimeProcessor {
  final DrawerLoaderLift lift;
  OffsetInMeters? vector;
  OffsetInMeters? startPosition;
  Duration elapsed = Duration.zero;
  final Duration duration;

  final double startScale = 1;
  late double endScale = lift.minimizedDrawerSize.widthInMeters /
      GrandeDrawerModuleType.drawerOutSideLengthInMeters;
  InToLiftPosition(this.lift) : duration = lift.pusherOutDuration;

  bool get completed => elapsed >= duration;

  @override
  double rotationInFraction(MachineLayout layout) =>
      layout.rotationOf(lift).toFraction();

  @override
  OffsetInMeters topLeft(MachineLayout layout) {
    vector ??= _vector(layout);
    startPosition ??= _startPosition(layout);
    return startPosition! + vector! * completedFraction;
  }

  double get completedFraction =>
      elapsed.inMilliseconds / duration.inMilliseconds;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (elapsed < duration) {
      elapsed += jump;
    }
    if (elapsed > duration) {
      elapsed = duration;
    }
  }

  OffsetInMeters _vector(MachineLayout layout) {
    var drawerLeadingCenterToTopLeftDrawer = const OffsetInMeters(
        metersFromLeft:
            GrandeDrawerModuleType.drawerOutSideLengthInMeters * 0.5,
        metersFromTop: GrandeDrawerModuleType.drawerOutSideLengthInMeters * -1);
    var startPosition = layout.positionOnMachine(
            lift, lift.drawerIn.offsetFromCenterWhenFacingNorth) +
        drawerLeadingCenterToTopLeftDrawer;
    var endPosition =
        layout.positionOnMachine(lift, lift.centerLiftToCenterDrawerInLift(0));
    return endPosition - startPosition;
  }

  OffsetInMeters _startPosition(MachineLayout layout) =>
      layout.positionOnMachine(
          lift, lift.drawerIn.offsetFromCenterWhenFacingNorth) -

      ///TODO: See [OnConveyorPosition.drawerStartToTopLeftDrawer]
      const OffsetInMeters(
          metersFromLeft:
              GrandeDrawerModuleType.drawerOutSideLengthInMeters * 0.5,
          metersFromTop: GrandeDrawerModuleType.drawerOutSideLengthInMeters);

  @override
  double scale() => (startScale - endScale) * (1-completedFraction) + endScale;
}

class LiftToLoaderPosition extends DrawerPosition implements TimeProcessor {
  late DrawerLoaderLift lift;
  int level;
  OffsetInMeters? vector;
  OffsetInMeters? startPosition;
  Duration elapsed = Duration.zero;
  final Duration duration;

  LiftToLoaderPosition({required this.lift, required this.level})
      : duration = lift.pusherOutDuration;

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
    startPosition ??= _startPosition(layout);
    vector ??= _vector(layout);
    var completed = elapsed.inMilliseconds / duration.inMilliseconds;
    return startPosition! + vector! * completed;
  }

  @override
  double rotationInFraction(MachineLayout layout) =>
      layout.rotationOf(lift).toFraction();

  OffsetInMeters _vector(MachineLayout layout) {
    var endPosition = layout.centerOf(lift) +
        const OffsetInMeters(metersFromLeft: 0, metersFromTop: 2);
    var startPosition = layout.positionOnMachine(
        lift, lift.centerLiftToCenterDrawerInLift(level));
    return endPosition - startPosition;
  }

  OffsetInMeters _startPosition(MachineLayout layout) => layout
      .positionOnMachine(lift, lift.centerLiftToCenterDrawerInLift(level));
}

class LiftPosition extends DrawerPositionAndSize {
  DrawerLoaderLift lift;
  int level;
  late OffsetInMeters centerDrawerToTopLeft =
      GrandeDrawerModuleType.size.toOffset() * -0.5 * _scale;
  LiftPosition({
    required this.lift,
    required this.level,
  });

  @override
  OffsetInMeters topLeft(MachineLayout layout) => layout.positionOnMachine(
      lift, lift.centerLiftToCenterDrawerInLift(level) + centerDrawerToTopLeft);

  @override
  double rotationInFraction(MachineLayout layout) =>
      layout.rotationOf(lift).toFraction();

  late final double _scale = lift.minimizedDrawerSize.widthInMeters /
      GrandeDrawerModuleType.drawerOutSideLengthInMeters;

  @override
  double scale() => _scale;
}

class LiftPositionUp extends DrawerPositionAndSize implements TimeProcessor {
  final DrawerLoaderLift lift;
  int startLevel;
  OffsetInMeters? vector;
  OffsetInMeters? startPosition;
  Duration elapsed = Duration.zero;
  final Duration duration;

  late OffsetInMeters centerDrawerToTopLeft =
      GrandeDrawerModuleType.size.toOffset() * -0.5 * _scale;

  LiftPositionUp({required this.lift, required this.startLevel})
      : duration = lift.upDuration;

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
    startPosition ??= _startPosition(layout);
    vector ??= _vector(layout);
    var completed = elapsed.inMilliseconds / duration.inMilliseconds;
    return startPosition! + vector! * completed;
  }

  @override
  double rotationInFraction(MachineLayout layout) =>
      layout.rotationOf(lift).toFraction();

  OffsetInMeters _vector(MachineLayout layout) =>
      vector = (lift.centerLiftToCenterDrawerInLift(startLevel + 1) -
              lift.centerLiftToCenterDrawerInLift(startLevel))
          .rotate(layout.rotationOf(lift));

  OffsetInMeters _startPosition(MachineLayout layout) =>
      layout.positionOnMachine(
          lift,
          lift.centerLiftToCenterDrawerInLift(startLevel) +
              centerDrawerToTopLeft);

  late final double _scale = lift.minimizedDrawerSize.widthInMeters /
      GrandeDrawerModuleType.drawerOutSideLengthInMeters;

  @override
  double scale() => _scale;
}

class ModuleDrawerLoader extends StateMachineCell implements Machine {
  final CardinalDirection inFeedDirection;

  ///Number of birds on dumping belt between module and hanger (a buffer).
  ///The loader starts tilting when birdsOnDumpBelt<dumpBeltBufferSize
  ///Normally this number is between the number of birds in 1 or 2 modules
  final Duration checkIfEmptyDuration;
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
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
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
