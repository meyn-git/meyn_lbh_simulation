import 'layout.dart';
import 'module.dart';
import 'state_machine.dart';

class ModuleTilter extends StateMachineCell implements BirdBuffer {
  final CardinalDirection inFeedDirection;
  final CardinalDirection birdDirection;
  int birdsOnDumpBelt = 0;
  int maxBirdsOnDumpBelt;
  ///Number of birds on dumping belt between module and hanger (a buffer).
  ///The tilter starts tilting when birdsOnDumpBelt<dumpBeltBufferSize
  ///Normally this number is between the number of birds in 1 or 2 modules
  final int minBirdsOnDumpBeltBuffer;
  final Duration checkIfEmptyDuration;
  final Duration tiltForwardDuration;
  final Duration tiltBackDuration;



  ModuleTilter(
      {required Layout layout,
      required Position position,
      int? seqNr,
      required this.inFeedDirection,
      required this.birdDirection,
      this.checkIfEmptyDuration = const Duration(seconds: 18),
      Duration inFeedDuration = const Duration(seconds: 12),
      this.tiltForwardDuration = const Duration(seconds: 9),
      this.tiltBackDuration = const Duration(seconds: 5),
      Duration outFeedDuration = const Duration(seconds: 12),
      required this.minBirdsOnDumpBeltBuffer})
      : maxBirdsOnDumpBelt=minBirdsOnDumpBeltBuffer,
        super(
          layout: layout,
          position: position,
          seqNr: seqNr,
          initialState: CheckIfEmpty(),
          inFeedDuration: inFeedDuration,
          outFeedDuration: outFeedDuration,
        ) {
    _verifyDirections();
  }

  bool get dumpBeltCanReceiveBirds =>
      birdsOnDumpBelt < minBirdsOnDumpBeltBuffer;

  /// 1=dump belt full with birds
  /// 0=dump belt empty
  double get dumpBeltLoad   {
    if (birdsOnDumpBelt>maxBirdsOnDumpBelt) {
      maxBirdsOnDumpBelt=birdsOnDumpBelt;
    }
    return birdsOnDumpBelt/maxBirdsOnDumpBelt;
  }

  void _verifyDirections() {
    if (inFeedDirection.isParallelTo(birdDirection)) {
      throw ArgumentError(
          "Layout error: $name: inFeedDirection and birdDirection must be perpendicular in layout configuration.");
    }
  }

  Cell get receivingNeighbour =>
      layout.neighbouringCell(this, inFeedDirection.opposite);

  Cell get sendingNeighbour => layout.neighbouringCell(this, inFeedDirection);

  @override
  bool isFeedIn(CardinalDirection direction) => direction == inFeedDirection;

  @override
  bool waitingToFeedIn(CardinalDirection direction) =>
      direction == inFeedDirection && currentState is WaitToFeedIn;

  @override
  bool isFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite && currentState is WaitToFeedOut;

  @override
  bool removeBird() {
    if (birdsOnDumpBelt > 0) {
      birdsOnDumpBelt--;
      return true;
    } else {
      return false;
    }
  }
}

class CheckIfEmpty extends DurationState<ModuleTilter> {
  CheckIfEmpty()
      : super(
            durationFunction: (tilter) => tilter.checkIfEmptyDuration,
            nextStateFunction: (tilter) => WaitToFeedIn());
}

class WaitToFeedIn extends State<ModuleTilter> {
  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_moduleGroupTransportedTo(tilter)) {
      return FeedIn();
    }
  }

  bool _moduleGroupTransportedTo(ModuleTilter tilter) {
    return tilter.layout.moduleGroups
        .any((moduleGroup) => moduleGroup.position.destination == tilter);
  }
}

class FeedIn extends State<ModuleTilter> {
  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_transportCompleted(tilter)) {
      return WaitToTilt();
    }
  }

  bool _transportCompleted(ModuleTilter tilter) => tilter.moduleGroup != null;

  @override
  void onCompleted(ModuleTilter tilter) {
    _verifyDoorDirection(tilter);
  }

  void _verifyDoorDirection(ModuleTilter tilter) {
    if (tilter.moduleGroup!.doorDirection.toCardinalDirection() !=
        tilter.birdDirection) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${tilter.name}');
    }
  }
}

class WaitToTilt extends State<ModuleTilter> {
  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (tilter.dumpBeltCanReceiveBirds) {
      return TiltForward();
    }
  }
}

class TiltForward extends DurationState<ModuleTilter> {
  TiltForward()
      : super(
            durationFunction: (tilter) => tilter.tiltForwardDuration,
            nextStateFunction: (tilter) => TiltBack());

  @override
  void onCompleted(ModuleTilter tilter) {
    var moduleGroup = tilter.moduleGroup!;
    tilter.birdsOnDumpBelt+=moduleGroup.numberOfBirds;
    moduleGroup.unloadBirds();
  }
}

class TiltBack extends DurationState<ModuleTilter> {
  TiltBack()
      : super(
            durationFunction: (tilter) => tilter.tiltBackDuration,
            nextStateFunction: (tilter) => WaitToFeedOut());
}

class WaitToFeedOut extends State<ModuleTilter> {
  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_neighbourCanFeedIn(tilter) && !_moduleGroupAtDestination(tilter)) {
      return FeedOut();
    }
  }

  bool _moduleGroupAtDestination(ModuleTilter tilter) =>
      tilter.moduleGroup!.destination == tilter;

  _neighbourCanFeedIn(ModuleTilter tilter) =>
      tilter.receivingNeighbour.waitingToFeedIn(tilter.inFeedDirection);
}

class FeedOut extends State<ModuleTilter> {
  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleTilter tilter) {
    transportedModuleGroup = tilter.moduleGroup;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: tilter,
        destination: tilter.receivingNeighbour as StateMachineCell);
  }

  @override
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_transportCompleted(tilter)) {
      return WaitToFeedIn();
    }
  }

  bool _transportCompleted(ModuleTilter tilter) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != tilter;
}
