// ignore_for_file: avoid_renaming_method_parameters

import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_loader.dart';
import 'package:user_command/user_command.dart';

import 'object_details.dart';
import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

// final OffsetInMeters mysteryCorrection =
//     GrandeDrawerModuleType.size.toOffset() * -0.4;

class DrawerLoaderLift extends StateMachine implements PhysicalSystem {
  final LiveBirdHandlingArea area;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];
  late final ModuleDrawerLoader moduleDrawerLoader =
      drawersOut.linkedTo!.system as ModuleDrawerLoader;
  final int nrOfLiftPositions;
  int nrOfDrawersToBePushedInModule = 0;

  late final DrawerLoaderLiftShape shape = DrawerLoaderLiftShape(this);

  /// position[0]=bottom position in lift
  /// position[nrOfPositions-1]=top position in lift
  /// null =  without drawer
  //List<GrandeDrawer?> liftPositions;
  final Duration upDuration;
  final Duration feedInDrawerDuration;
  final Duration pusherPushDuration;
  final Duration pusherBackDuration;

  Duration drawerPushOutCycle = Duration.zero;
  Durations drawerPushOutCycles = Durations(maxSize: 8);

  late final List<DrawerLiftPlace> drawerLiftPlaces =
      shape.centerLiftToDrawerCenterInLift
          .map((offset) => DrawerLiftPlace(
                system: this,
                centerToDrawerCenterWhenSystemFacesNorth: offset,
                level: shape.centerLiftToDrawerCenterInLift.indexOf(offset),
              ))
          .toList();

  late final DrawerPlace drawerInPlace = DrawerPlace(
      system: this,
      centerToDrawerCenterWhenSystemFacesNorth: shape.centerToDrawerInLink
          .addY(GrandeDrawerModuleType.drawerOutSideLengthInMeters / 2));

  DrawerLoaderLift({
    required this.area,
    this.upDuration = const Duration(
        milliseconds:
            1600), // Based on "Speed calculations_estimates_V3_Erik.xlsx"

    this.feedInDrawerDuration = const Duration(milliseconds: 2500), // TODO
    this.pusherPushDuration = const Duration(
        milliseconds:
            2500), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
    this.pusherBackDuration = const Duration(milliseconds: 2500), // TODO
    this.nrOfLiftPositions = 6,
  }) :
        // liftPositions = List.filled(
        //         nrOfLiftPositions,
        //         null,
        //       ),
        super(
          initialState: SimultaneouslyFeedInAndFeedOutDrawers(),
        );

  @override
  late SizeInMeters sizeWhenFacingNorth = _size();

  bool get canGoUp {
    var drawersToPushOut = drawerLiftPlaces
        .where((drawerPlace) =>
            drawerPlace.level > 0 && drawerPlace.drawer != null)
        .length;
    return !bottomPositionIsEmpty && drawersToPushOut < levelsToLoad;
  }

  int get levelsToLoad => drawersOut.linkedTo!.numberOfDrawersToFeedIn() == 0
      ? minimumNumberOfLevelsInModule
      : drawersOut.linkedTo!.numberOfDrawersToFeedIn();

  int minimumNumberOfLevelsInModule = 4; //TODO get this from productDefinition

  List<GrandeDrawer> get drawersToFeedOut => drawerLiftPlaces
      .getRange(1, drawerLiftPlaces.length)
      .map((e) => e.drawer)
      .whereNotNull()
      .toList();

  bool get canFeedOutDrawers =>
      moduleDrawerLoader.moduleGroup != null &&
      moduleDrawerLoader.moduleGroup!.firstModule.levels ==
          drawersToFeedOut.length;

  SizeInMeters _size() => shape.size;

  late DrawerInLink<DrawerLoaderLift> drawerIn = DrawerInLink<DrawerLoaderLift>(
      system: this,
      offsetFromCenterWhenFacingNorth: shape.centerToDrawerInLink,
      directionToOtherLink: const CompassDirection.south());

  late DrawersOutLink<DrawerLoaderLift> drawersOut =
      DrawersOutLink<DrawerLoaderLift>(
          system: this,
          offsetFromCenterWhenFacingNorth: shape.centerToDrawersOutLink,
          directionToOtherLink: const CompassDirection.north());

  @override
  late List<Link> links = [drawerIn, drawersOut];

  bool get liftIsEmpty =>
      drawerLiftPlaces.every((drawerPlace) => drawerPlace.drawer == null);

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

  late final DrawerConveyor precedingConveyor =
      drawerIn.linkedTo!.system as DrawerConveyor;

  bool get bottomPositionIsEmpty => drawerLiftPlaces.first.drawer == null;

  GrandeDrawer? drawerAtEndOfPrecedingConveyor() =>
      drawers.firstWhereOrNull((drawer) =>
          drawer.position is OnConveyorPosition &&
          (drawer.position as OnConveyorPosition).conveyor ==
              precedingConveyor &&
          (drawer.position as OnConveyorPosition).atEnd);

  @override
  late final String name = 'DrawerLoaderLift$seqNr';

  late final seqNr = area.systems.seqNrOf(this);
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

class FeedingInDrawer extends DrawerFeedInState
    implements DrawerTransportCompletedListener {
  final GrandeDrawer drawerToFeedIn;

  bool transportCompleted = false;

  FeedingInDrawer(this.drawerToFeedIn);

  @override
  String get name => 'FeedingInDrawer';

  @override
  void onStart(DrawerLoaderLift lift) {
    drawerToFeedIn.position = BetweenDrawerConveyorAndDrawerLoader(lift);
  }

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) =>
      transportCompleted ? CompletedFeedInDrawer(drawerToFeedIn) : null;

  @override
  onDrawerTransportCompleted(BetweenDrawerPlaces betweenDrawerPlaces) {
    if (betweenDrawerPlaces is BetweenDrawerConveyorAndDrawerLoader) {
      transportCompleted = true;
    }
  }
}

class CompletedFeedInDrawer extends DrawerFeedInState {
  final GrandeDrawer drawerToFeedIn;

  CompletedFeedInDrawer(this.drawerToFeedIn);

  @override
  String get name => 'CompletedFeedInDrawer';

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift drawerLoaderLift) {
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

class FeedingOutDrawers extends DrawersFeedOutState
    implements DrawerTransportCompletedListener {
  final List<GrandeDrawer> drawersToFeedOut;

  bool transportCompleted = false;
  FeedingOutDrawers(this.drawersToFeedOut);

  @override
  String get name => 'FeedingOutDrawers';

  @override
  void onStart(DrawerLoaderLift lift) {
    for (var drawerToFeedOut in drawersToFeedOut) {
      var position = (drawerToFeedOut.position as AtDrawerPlace);
      var level = (position.drawerPlace as DrawerLiftPlace).level;
      drawerToFeedOut.position =
          BetweenLiftAndDrawerLoader(lift: lift, level: level);
    }
  }

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift drawerLoaderLift) =>
      transportCompleted ? CompletedFeedOutDrawers() : null;

  @override
  onDrawerTransportCompleted(BetweenDrawerPlaces betweenDrawerPlaces) {
    if (betweenDrawerPlaces is BetweenLiftAndDrawerLoader) {
      transportCompleted = true;
    }
  }

  @override
  void onCompleted(DrawerLoaderLift lift) {
    for (var drawer in drawersToFeedOut) {
      lift.area.drawers.remove(drawer);
    }
  }
}

class CompletedFeedOutDrawers extends DrawersFeedOutState {
  @override
  String get name => 'CompletedFeedOutDrawer';

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift drawerLoaderLift) {
    return null;
  }
}

class SimultaneouslyFeedInAndFeedOutDrawers extends State<DrawerLoaderLift>
    implements DrawerTransportCompletedListener {
  DrawerFeedInState drawerFeedInState = WaitingToFeedInDrawer();
  DrawersFeedOutState drawersFeedOutState = WaitingToFeedOutDrawers();
  GrandeDrawer? drawerToFeedIn;
  List<GrandeDrawer> drawersToFeedOut = [];
  @override
  String get name => 'SimultaneouslyFeedInAndFeedOutDrawers\n'
      '  ${drawerFeedInState.name}\n'
      '  ${drawersFeedOutState.name}';

  /// this method acts like a state system for parallel states:
  /// * [drawerFeedInState]
  /// * [drawerFeedInState]
  @override
  void onUpdateToNextPointInTime(DrawerLoaderLift lift, Duration jump) {
    drawerFeedInState.onUpdateToNextPointInTime(lift, jump);
    var nextInFeedState = drawerFeedInState.nextState(lift);
    if (nextInFeedState != null) {
      drawerFeedInState.onCompleted(lift);
      drawerFeedInState = nextInFeedState;
      nextInFeedState.onStart(lift);
    }

    drawersFeedOutState.onUpdateToNextPointInTime(lift, jump);
    var nextOutFeedState = drawersFeedOutState.nextState(lift);
    if (nextOutFeedState != null) {
      drawersFeedOutState.onCompleted(lift);
      drawersFeedOutState = nextOutFeedState;
      nextOutFeedState.onStart(lift);
    }
  }

  @override
  State<DrawerLoaderLift>? nextState(DrawerLoaderLift lift) {
    if (drawerFeedInState is FeedingInDrawer ||
        drawersFeedOutState is FeedingOutDrawers) {
      // wait until feed in or feed out is completed
      return null;
    }
    if (lift.canGoUp) {
      return RaiseLift();
    }
    //wait until lift can go up
    return null;
  }

  @override
  onDrawerTransportCompleted(BetweenDrawerPlaces betweenDrawerPlaces) {
    if (drawerFeedInState is DrawerTransportCompletedListener) {
      (drawerFeedInState as DrawerTransportCompletedListener)
          .onDrawerTransportCompleted(betweenDrawerPlaces);
    }
    if (drawersFeedOutState is DrawerTransportCompletedListener) {
      (drawersFeedOutState as DrawerTransportCompletedListener)
          .onDrawerTransportCompleted(betweenDrawerPlaces);
    }
  }
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
    if (lift.drawerLiftPlaces.last.drawer != null) {
      throw Exception('Can not raise LoaderDrawerLift when drawer is in top.');
    }
    for (DrawerLiftPlace drawerPlace in lift.drawerLiftPlaces) {
      GrandeDrawer? drawer = drawerPlace.drawer;
      if (drawer != null) {
        drawer.position =
            BetweenLiftPositions(lift: lift, startLevel: drawerPlace.level);
      }
    }
  }
}

class BetweenDrawerConveyorAndDrawerLoader extends BetweenDrawerPlaces
    implements TimeProcessor {
  late DrawerLoaderLift lift;

  final double startScale = 1;
  late final double endScale = lift.shape.minimizedDrawerSize.xInMeters /
      GrandeDrawerModuleType.drawerOutSideLengthInMeters;

  BetweenDrawerConveyorAndDrawerLoader._(
      {required this.lift,
      required super.drawerRotation,
      required super.duration,
      required super.startPlace,
      required super.destinationPlace});

  factory BetweenDrawerConveyorAndDrawerLoader(DrawerLoaderLift lift) {
    var drawerRotation = lift.area.layout.rotationOf(lift);
    var startPlace = lift.drawerInPlace;
    var drawer = lift.drawerAtEndOfPrecedingConveyor();
    if (drawer == null) {
      throw Exception('No drawer at lift.drawerInPlace');
    }
    startPlace.drawer = drawer;
    var destinationPlace = lift.drawerLiftPlaces[0];
    return BetweenDrawerConveyorAndDrawerLoader._(
        lift: lift,
        drawerRotation: drawerRotation,
        duration: lift.pusherPushDuration,
        startPlace: startPlace,
        destinationPlace: destinationPlace);
  }

  @override
  double get scale => (endScale - startScale) * completedFraction + startScale;
}

class BetweenLiftAndDrawerLoader extends BetweenDrawerPlaces
    implements TimeProcessor {
  late DrawerLoaderLift lift;

  late double startScale = lift.shape.minimizedDrawerSize.xInMeters /
      GrandeDrawerModuleType.drawerOutSideLengthInMeters;
  final double endScale = 1;

  BetweenLiftAndDrawerLoader._(
      {required this.lift,
      required super.drawerRotation,
      required super.duration,
      required super.startPlace,
      required super.destinationPlace});

  factory BetweenLiftAndDrawerLoader(
      {required DrawerLoaderLift lift, required int level}) {
    var drawerRotation = lift.area.layout.rotationOf(lift);
    var loader = lift.drawersOut.linkedTo!.system as ModuleDrawerLoader;
    var startPlace = lift.drawerLiftPlaces[level];
    var destinationPlace = loader.drawerPlaces[level];
    return BetweenLiftAndDrawerLoader._(
        lift: lift,
        drawerRotation: drawerRotation,
        duration: lift.pusherPushDuration,
        startPlace: startPlace,
        destinationPlace: destinationPlace);
  }

// // TODO can not do this while drawers are iterated
// // See https://stackoverflow.com/questions/54150583/concurrent-modification-during-iteration-while-trying-to-remove-object-from-a-li
//   @override
//   void onCompleted() {
//     super.onCompleted();
//     lift.area.drawers.remove(transportedDrawer);
//   }

  @override
  double get scale => (endScale - startScale) * completedFraction + startScale;
}

class LiftPosition extends AtDrawerPlace {
  DrawerLoaderLift lift;
  int level;

  late final double _scale = lift.shape.minimizedDrawerSize.xInMeters /
      GrandeDrawerModuleType.drawerOutSideLengthInMeters;

  LiftPosition._(super.drawerPlace, {required this.lift, required this.level});

  factory LiftPosition({
    required DrawerLoaderLift lift,
    required int level,
  }) {
    var destinationPlace = lift.drawerLiftPlaces[level];
    return LiftPosition._(destinationPlace, lift: lift, level: level);
  }

  @override
  double get scale => _scale;
}

class BetweenLiftPositions extends BetweenDrawerPlaces {
  final DrawerLoaderLift lift;
  // int startLevel;

  late final double _scale = lift.shape.minimizedDrawerSize.xInMeters /
      GrandeDrawerModuleType.drawerOutSideLengthInMeters;

  BetweenLiftPositions._(
      {required this.lift,
      required super.drawerRotation,
      required super.duration,
      required super.startPlace,
      required super.destinationPlace});

  factory BetweenLiftPositions(
      {required DrawerLoaderLift lift, required int startLevel}) {
    var drawerRotation = lift.area.layout.rotationOf(lift);
    var startPlace = lift.drawerLiftPlaces[startLevel];
    var destinationPlace = lift.drawerLiftPlaces[startLevel + 1];
    return BetweenLiftPositions._(
        lift: lift,
        drawerRotation: drawerRotation,
        duration: lift.upDuration,
        startPlace: startPlace,
        destinationPlace: destinationPlace);
  }

  @override
  double get scale => _scale;
}

class ModuleDrawerLoader extends StateMachine implements PhysicalSystem {
  final LiveBirdHandlingArea area;

  ///Number of birds on dumping belt between module and hanger (a buffer).
  ///The loader starts tilting when birdsOnDumpBelt<dumpBeltBufferSize
  ///Normally this number is between the number of birds in 1 or 2 modules
  final Duration checkIfEmptyDuration;
  final Duration feedInToSecondColumn;
  final Duration inFeedDuration;
  final Duration outFeedDuration;
  final bool drawersFromLeft;
  Duration? durationPerModule;

  Durations durationsPerModule = Durations(maxSize: 8);

  late final ModuleDrawerLoaderShape shape = ModuleDrawerLoaderShape(this);

  late final List<DrawerPlace> drawerPlaces = [
    for (int level = 0; level <= 5; level++)
      DrawerPlace(
          system: this,
          centerToDrawerCenterWhenSystemFacesNorth:
              shape.centerToConveyorCenter)
  ];

  late final CompassDirection drawerFeedInDirection = drawersIn
      .directionToOtherLink
      .rotate(area.layout.rotationOf(this).degrees);

  ModuleGroup? get moduleGroup =>
      moduleGroupPositionFirstColumn.moduleGroup ??
      moduleGroupPositionSecondColumn.moduleGroup;

  ModuleDrawerLoader({
    required this.area,
    required this.drawersFromLeft,
    this.checkIfEmptyDuration = const Duration(seconds: 18),
    Duration? inFeedDuration =
        const Duration(milliseconds: 9300), // TODO remove default value?
    Duration? outFeedDuration =
        const Duration(milliseconds: 9300), // TODO remove default value?
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
  late List<Command> commands = [
    RemoveFromMonitorPanel(this),
  ];

  @override
  late final SizeInMeters sizeWhenFacingNorth = shape.size;

  late final DrawersInLink drawersIn = DrawersInLink(
    system: this,
    offsetFromCenterWhenFacingNorth: shape.centerToDrawersInLink,
    directionToOtherLink: drawersFromLeft
        ? const CompassDirection.east()
        : const CompassDirection.west(),
    numberOfDrawersToFeedIn: numberOfDrawersToFeedIn,
  );

  late final ModuleGroupPlace moduleGroupPositionFirstColumn = ModuleGroupPlace(
    system: this,
    moduleGroups: area.moduleGroups,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToFirstColumn,
  );

  late final ModuleGroupPlace moduleGroupPositionSecondColumn =
      ModuleGroupPlace(
    system: this,
    moduleGroups: area.moduleGroups,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToSecondColumn,
  );

  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    position: moduleGroupPositionFirstColumn,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleInLink,
    directionToOtherLink: const CompassDirection.south(),
    inFeedDuration: inFeedDuration,
    canFeedIn: canFeedIn,
  );

  bool canFeedIn() {
    return currentState is FeedOutAndFeedInToFirstColumnSimultaneously &&
        (currentState as FeedOutAndFeedInToFirstColumnSimultaneously)
                .inFeedState ==
            InFeedState.waitingOnNeighbor;
  }

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    position: moduleGroupPositionSecondColumn,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleOutLink,
    directionToOtherLink: const CompassDirection.north(),
    outFeedDuration: outFeedDuration,
    durationUntilCanFeedOut: () =>
        canFeedOut() ? Duration.zero : unknownDuration,
  );

  bool canFeedOut() {
    return currentState is FeedOutAndFeedInToFirstColumnSimultaneously &&
        (currentState as FeedOutAndFeedInToFirstColumnSimultaneously)
                .outFeedState ==
            OutFeedState.waitingOnNeighbor;
  }

  @override
  late List<Link> links = [modulesIn, drawersIn, modulesOut];

  late DrawerLoaderLift drawerLift =
      drawersIn.linkedTo!.system as DrawerLoaderLift;

  bool get waitingToFeedInDrawers => (currentState is WaitToPushInFirstColumn ||
      currentState is WaitToPushInSecondColumn);

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
      .appendProperty('moduleGroup', moduleGroup);

  void onEndOfCycle() {
    durationsPerModule.add(durationPerModule);
    durationPerModule = Duration.zero;
  }

  int numberOfDrawersToFeedIn() =>
      !waitingToFeedInDrawers ? 0 : moduleGroup!.firstModule.levels;

  @override
  late final String name = 'ModuleDrawerLoader$seqNr';

  late final int seqNr = area.systems.seqNrOf(this);
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

  bool _inFeedStarted(ModuleDrawerLoader loader) => loader.area.moduleGroups
      .any((moduleGroup) => moduleGroup.isBeingTransportedTo(loader));

  void processOutFeedState(ModuleDrawerLoader loader, Duration jump) {
    switch (outFeedState) {
      case OutFeedState.waitingOnNeighbor:
        if (_outFeedCanStart(loader)) {
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
    moduleGroupTransportedOut =
        loader.moduleGroupPositionSecondColumn.moduleGroup!;
    moduleGroupTransportedOut!.position =
        BetweenModuleGroupPlaces.forModuleOutLink(loader.modulesOut);
  }

  _outFeedCanStart(ModuleDrawerLoader loader) =>
      loader.modulesOut.linkedTo!.canFeedIn();

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
    if (moduleGroup.moduleFamily.compartmentType.birdsExitOnOneSide &&
        moduleGroup.direction.rotate(90) != loader.drawerFeedInDirection) {
      throw ('Incorrect drawer in feed direction of the $ModuleGroup '
          'that was fed in to ${loader.name}');
    }
  }

  bool _outFeedCompleted(ModuleDrawerLoader loader) =>
      moduleGroupTransportedOut != null &&
      moduleGroupTransportedOut!.position is AtModuleGroupPlace &&
      (moduleGroupTransportedOut!.position as AtModuleGroupPlace).place ==
          loader.modulesOut.linkedTo!.position;
}

enum InFeedState { waitingToFeedOut, waitingOnNeighbor, transporting, done }

enum OutFeedState { waitingOnNeighbor, transporting, done }

class WaitToPushInFirstColumn extends State<ModuleDrawerLoader>
    implements DrawerTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'WaitToPushInFirstColumn';

  @override
  void onStart(ModuleDrawerLoader loader) {
    var moduleGroup = loader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Loader can not handle stacked containers');
    }
  }

  @override
  State<ModuleDrawerLoader>? nextState(ModuleDrawerLoader loader) =>
      transportCompleted ? FeedInToSecondColumn() : null;

  @override
  onDrawerTransportCompleted(BetweenDrawerPlaces betweenDrawerPlaces) {
    if (betweenDrawerPlaces is BetweenLiftAndDrawerLoader) {
      transportCompleted = true;
    }
  }
}

class FeedInToSecondColumn extends State<ModuleDrawerLoader>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedInToSecondColumn';

  @override
  void onStart(ModuleDrawerLoader loader) {
    var moduleGroup = loader.moduleGroupPositionFirstColumn.moduleGroup!;
    moduleGroup.position = BetweenModuleGroupPlaces(
        source: loader.moduleGroupPositionFirstColumn,
        destination: loader.moduleGroupPositionSecondColumn,
        duration: loader.feedInToSecondColumn);
  }

  @override
  State<ModuleDrawerLoader>? nextState(ModuleDrawerLoader loader) =>
      transportCompleted ? WaitToPushInSecondColumn() : null;

  @override
  void onModuleTransportCompleted() {
    transportCompleted = true;
  }
}

class WaitToPushInSecondColumn extends State<ModuleDrawerLoader>
    implements DrawerTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'WaitToPushInSecondColumn';

  @override
  State<ModuleDrawerLoader>? nextState(ModuleDrawerLoader loader) =>
      transportCompleted ? FeedOutAndFeedInToFirstColumnSimultaneously() : null;

  @override
  onDrawerTransportCompleted(BetweenDrawerPlaces betweenDrawerPlaces) {
    if (betweenDrawerPlaces is BetweenLiftAndDrawerLoader) {
      transportCompleted = true;
    }
  }
}
