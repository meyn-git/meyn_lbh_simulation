import 'package:meyn_lbh_simulation/domain/area/direction.dart';

import '../util/title_builder.dart';
import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

class ModuleDrawerUnloader extends StateMachineCell {
  final CardinalDirection inFeedDirection;
  final CardinalDirection birdDirection;
  late UnloaderDrawerLift drawerLift;

  ///Number of birds on dumping belt between module and hanger (a buffer).
  ///The unloader starts tilting when birdsOnDumpBelt<dumpBeltBufferSize
  ///Normally this number is between the number of birds in 1 or 2 modules
  final Duration checkIfEmptyDuration;
  final Duration pusherOutDuration;
  final Duration pusherInDuration;
  final Duration feedInToSecondColumn;

  Duration? durationPerModule;

  Durations durationsPerModule = Durations(maxSize: 8);

  ModuleDrawerUnloader({
    required LiveBirdHandlingArea area,
    required Position position,
    super.name='ModuleDrawerUnloader',
    super.seqNr,
    required this.inFeedDirection,
    required this.birdDirection,
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
          area: area,
          position: position,
          initialState: CheckIfEmpty(),
          inFeedDuration: inFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
          outFeedDuration: outFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
        ) {
    _verifyDirections();
    var cell = area.neighboringCell(this, birdDirection);
    if (cell is! UnloaderDrawerLift) {
      throw Exception(
          'Expected an UnloaderDrawerLift $birdDirection of $name at $position');
    }
    drawerLift = cell;
  }

  get inFeedNeighbor => area.neighboringCell(this, inFeedDirection);

  get outFeedNeighbor => area.neighboringCell(this, inFeedDirection.opposite);

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    if (durationPerModule != null) {
      durationPerModule = durationPerModule! + jump;
    }
  }

  void _verifyDirections() {
    if (inFeedDirection.isParallelTo(birdDirection)) {
      throw ArgumentError(
          "$LiveBirdHandlingArea error: $name: inFeedDirection and birdDirection must be perpendicular in layout configuration.");
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
          InFeedState.waitingOnNeighbor;

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
  // ignore: avoid_renaming_method_parameters
  void onStart(ModuleDrawerUnloader unloader) {
    outFeedState = unloader.moduleGroup == null
        ? OutFeedState.done
        : OutFeedState.waitingOnNeighbor;
  }

  @override
  void onUpdateToNextPointInTime(ModuleDrawerUnloader unloader, Duration jump) {
    processInFeedState(unloader, jump);
    processOutFeedState(unloader, jump);
    print('$inFeedState : $outFeedState');
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
  // ignore: avoid_renaming_method_parameters
  State<ModuleDrawerUnloader>? nextState(ModuleDrawerUnloader unloader) {
    if (inFeedState == InFeedState.done && outFeedState == OutFeedState.done) {
      return WaitToUnloadFirstColumn();
    }
    return null;
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleDrawerUnloader unloader) {
    _verifyDoorDirection(unloader);
  }

  void _verifyDoorDirection(ModuleDrawerUnloader unloader) {
    var moduleGroup = unloader.moduleGroup!;
    var hasDoors =
        moduleGroup.moduleFamily.compartmentType == CompartmentType.door;
    if (hasDoors &&
        moduleGroup.direction.toCardinalDirection() != unloader.birdDirection) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${unloader.name}');
    }
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
  // ignore: avoid_renaming_method_parameters
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
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleDrawerUnloader unloader) {
    // var moduleGroup = unloader.moduleGroup!;
    // if (moduleGroup.numberOfModules > 2) {
    //   throw Exception('Unloader can not handle stacked containers');
    // }
    // int levels = moduleGroup.firstModule.levels;
    unloader.drawerLift.pushInDrawersAtBottom();
    unloader.drawerLift.waitingDrawersToBePushedIn = 0;
    //moduleGroup.unloadBirds();
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
  // ignore: avoid_renaming_method_parameters
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
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleDrawerUnloader unloader) {
    var moduleGroup = unloader.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle stacked containers');
    }
    //int levels = moduleGroup.firstModule.levels;
    unloader.drawerLift.pushInDrawersAtBottom();
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
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleDrawerUnloader unloader) {
    super.onCompleted(unloader);
    unloader.onEndOfCycle();
  }
}

class UnloaderDrawerLift extends StateMachineCell implements BirdBuffer {
  final int nrOfPositions;
  int waitingDrawersToBePushedIn = 0;

  /// position[0]=bottom position in lift
  /// position[nrOfPositions-1]=top position in lift
  /// true = position with drawer
  /// false = position without drawer
  List<bool> positions;
  @override
  final CardinalDirection birdDirection;
  late ModuleDrawerUnloader unloader = findUnloader();
  final Duration upDuration;
  final int maxDrawersPerHour;
  final Duration pushOutDuration;

  Duration drawerPushOutCycle = Duration.zero;
  Duration drawerPushOutCycleBuffer = Duration.zero;
  Durations drawerPushOutCycles = Durations(maxSize: 8);

//TODO the DrawerHangingConveyor should tell if there is space to recieve a drawer
  late Duration minimumInterval =
      Duration(milliseconds: 3600000 ~/ maxDrawersPerHour);
  //-     pushOutDuration ;
  //-     upDuration;

  UnloaderDrawerLift(
      {required super.area,
      required super.position,
      super.name='UnloaderDrawerLift',
      super.seqNr,
      required this.birdDirection,
      this.upDuration = const Duration(
          milliseconds:
              1600), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
      required this.maxDrawersPerHour, // Aiming for 750-800
      this.pushOutDuration = const Duration(
          milliseconds:
              2500), // Based on "Speed calculations_estimates_V3_Erik.xlsx"
      this.nrOfPositions = 6})
      : positions = List.filled(
          nrOfPositions,
          false,
        ),
        super(
            initialState: Decide(),
            inFeedDuration: Duration.zero,
            outFeedDuration: Duration.zero);

  bool get liftIsEmpty =>
      positions.every((drawerPosition) => drawerPosition = false);

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => false;

  @override
  bool isFeedOut(CardinalDirection direction) => false;

  @override
  ModuleGroup? get moduleGroup => null;

  @override
  bool waitingToFeedIn(CardinalDirection direction) {
    throw UnimplementedError();
  }

  @override
  bool waitingToFeedOut(CardinalDirection direction) {
    throw UnimplementedError();
  }

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

  void pushInDrawersAtBottom() {
    if (!canReceiveDrawers) {
      throw Exception('You can not push $waitingDrawersToBePushedIn drawer(s)'
          ' into the $name');
    }
    for (int i = 0; i < waitingDrawersToBePushedIn; i++) {
      positions[i] = true;
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
    if (waitingDrawersToBePushedIn > (nrOfPositions - 1)) {
      // not enough positions to push drawers in
      return false;
    }
    for (int i = 0; i < waitingDrawersToBePushedIn; i++) {
      if (positions[i] == true) {
        // position is not free
        return false;
      }
    }
    return true;
  }

  ModuleDrawerUnloader findUnloader() {
    var cell = area.neighboringCell(this, birdDirection.opposite);
    if (cell is! ModuleDrawerUnloader) {
      throw Exception('Expected an ModuleDrawerUnloader '
          '${birdDirection.opposite} of $name at $position');
    }
    return cell;
  }

  @override
  bool removeBird() {
    return true; //TODO move to DrawerHangingConveyor
  }

  void pushOutTopPosition() {
    positions = [...positions.getRange(0, positions.length - 1), false];
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
}

class Decide extends State<UnloaderDrawerLift> {
  @override
  String get name => 'DecideRaiseOrPushOut';

  @override
  // ignore: avoid_renaming_method_parameters
  State<UnloaderDrawerLift>? nextState(UnloaderDrawerLift lift) {
    if (lift.positions.last) {
      return WaitToPushOut();
    }
    if (lift.canReceiveDrawers) {
      return WaitOnPushIn();
    }
    return RaiseLift();
  }
}

class RaiseLift extends DurationState<UnloaderDrawerLift> {
  RaiseLift()
      : super(
            durationFunction: (drawerLift) => drawerLift.upDuration,
            nextStateFunction: (drawerLift) => Decide());

  @override
  String get name => 'RaiseLift';

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(UnloaderDrawerLift drawerLift) {
    if (drawerLift.positions.last) {
      throw Exception(
          'Can not raise UnloaderDrawerLift when drawer is in top.');
    }
    movePositionsUp(drawerLift);
  }

  void movePositionsUp(UnloaderDrawerLift drawerLift) {
    var newPositions = [
      false,
      ...drawerLift.positions.getRange(0, drawerLift.nrOfPositions - 1)
    ];
    drawerLift.positions = newPositions;
  }
}

class WaitToPushOut extends State<UnloaderDrawerLift> {
  Duration maxDuration = const Duration(hours: 1);

  @override
  String get name => 'WaitToPushOut';

  @override
  // ignore: avoid_renaming_method_parameters
  State<UnloaderDrawerLift>? nextState(UnloaderDrawerLift lift) {
    if (lift.canPushOut) {
      return PushOut();
    }
    return null;
  }
}

class PushOut extends DurationState<UnloaderDrawerLift> {
  PushOut()
      : super(
            durationFunction: (drawerLift) => drawerLift.pushOutDuration,
            nextStateFunction: (drawerLift) => Decide());

  @override
  String get name => 'PushOut';

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(UnloaderDrawerLift lift) {
    clearTopPosition(lift);
  }

  void clearTopPosition(UnloaderDrawerLift lift) {
    lift.pushOutTopPosition();
  }
}

class WaitOnPushIn extends State<UnloaderDrawerLift> {
  @override
  String get name => 'WaitOnPushIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<UnloaderDrawerLift>? nextState(UnloaderDrawerLift lift) {
    if (!lift.canReceiveDrawers) {
      return Decide();
    }
    return null;
  }
}

class Durations {
  List<Duration> durations = [];
  final int maxSize;

  Durations({required this.maxSize});

  add(Duration? duration) {
    if (duration == null) {
      return;
    }
    durations.insert(0, duration);
    if (durations.length > maxSize) {
      durations.length = maxSize;
    }
  }

  Duration get total => durations.reduce((a, b) => a + b);

  Duration get average => durations.isEmpty
      ? Duration.zero
      : Duration(
          milliseconds: (total.inMilliseconds / durations.length).round());

  double get averagePerHour =>
      durations.isEmpty ? 0 : 3600000 / average.inMilliseconds;
}
