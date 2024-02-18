import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:user_command/user_command.dart';

import '../util/title_builder.dart';
import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

class ModuleTilter extends StateMachineCell implements BirdBuffer {
  final CardinalDirection inFeedDirection;
  @override
  final CardinalDirection birdDirection;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

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
      {required super.area,
      required super.position,
      super.name = 'ModuleTilter',
      super.seqNr,
      required this.inFeedDirection,
      required this.birdDirection,
      this.checkIfEmptyDuration = const Duration(seconds: 18),
      Duration? inFeedDuration,
      this.tiltForwardDuration = const Duration(seconds: 9),
      this.tiltBackDuration = const Duration(seconds: 5),
      Duration? outFeedDuration,
      required this.minBirdsOnDumpBeltBuffer})
      : maxBirdsOnDumpBelt = minBirdsOnDumpBeltBuffer,
        super(
          initialState: CheckIfEmpty(),
          inFeedDuration: inFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
          outFeedDuration: outFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
        ) {
    _verifyDirections();
  }

  bool get dumpBeltCanReceiveBirds =>
      birdsOnDumpBelt < minBirdsOnDumpBeltBuffer;

  /// 1=dump belt full with birds
  /// 0=dump belt empty
  double get dumpBeltLoad {
    if (birdsOnDumpBelt > maxBirdsOnDumpBelt) {
      maxBirdsOnDumpBelt = birdsOnDumpBelt;
    }
    return birdsOnDumpBelt / maxBirdsOnDumpBelt;
  }

  void _verifyDirections() {
    if (inFeedDirection.isParallelTo(birdDirection)) {
      throw ArgumentError(
          "$LiveBirdHandlingArea error: $name: inFeedDirection and birdDirection must be perpendicular in layout configuration.");
    }
  }

  Cell get receivingneighbor =>
      area.neighboringCell(this, inFeedDirection.opposite);

  Cell get sendingneighbor => area.neighboringCell(this, inFeedDirection);

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

  @override
  String toString() => TitleBuilder(name)
      .appendProperty('currentState', currentState)
      .appendProperty('maxBirdsOnDumpBelt', maxBirdsOnDumpBelt)
      .appendProperty('minBirdsOnDumpBeltBuffer', minBirdsOnDumpBeltBuffer)
      .appendProperty('birdsOnDumpBelt', birdsOnDumpBelt)
      .appendProperty('moduleGroup', moduleGroup)
      .toString();
}

class CheckIfEmpty extends DurationState<ModuleTilter> {
  @override
  String get name => 'CheckIfEmpty';

  CheckIfEmpty()
      : super(
            durationFunction: (tilter) => tilter.checkIfEmptyDuration,
            nextStateFunction: (tilter) => WaitToFeedIn());
}

class WaitToFeedIn extends State<ModuleTilter> {
  @override
  String get name => 'WaitToFeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_moduleGroupTransportedTo(tilter)) {
      return FeedIn();
    }
    return null;
  }

  bool _moduleGroupTransportedTo(ModuleTilter tilter) {
    return tilter.area.moduleGroups
        .any((moduleGroup) => moduleGroup.position.destination == tilter);
  }
}

class FeedIn extends State<ModuleTilter> {
  @override
  String get name => 'FeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_transportCompleted(tilter)) {
      return WaitToTilt();
    }
    return null;
  }

  bool _transportCompleted(ModuleTilter tilter) => tilter.moduleGroup != null;

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleTilter tilter) {
    _verifyDoorDirection(tilter);
  }

  void _verifyDoorDirection(ModuleTilter tilter) {
    var moduleGroup = tilter.moduleGroup!;
    var hasDoors =
        moduleGroup.moduleFamily.compartmentType == CompartmentType.door;
    if (hasDoors &&
        moduleGroup.direction.toCardinalDirection() != tilter.birdDirection) {
      throw ('In correct door direction of the $ModuleGroup that was fed in to ${tilter.name}');
    }
  }
}

class WaitToTilt extends State<ModuleTilter> {
  @override
  String get name => 'WaitToTilt';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (tilter.dumpBeltCanReceiveBirds) {
      return TiltForward();
    }
    return null;
  }
}

class TiltForward extends DurationState<ModuleTilter> {
  @override
  String get name => 'TiltForward';

  TiltForward()
      : super(
            durationFunction: (tilter) => tilter.tiltForwardDuration,
            nextStateFunction: (tilter) => TiltBack());

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleTilter tilter) {
    var moduleGroup = tilter.moduleGroup!;
    tilter.birdsOnDumpBelt += moduleGroup.numberOfBirds;
    moduleGroup.unloadBirds();
  }
}

class TiltBack extends DurationState<ModuleTilter> {
  @override
  String get name => 'TiltBack';

  TiltBack()
      : super(
            durationFunction: (tilter) => tilter.tiltBackDuration,
            nextStateFunction: (tilter) => WaitToFeedOut());
}

class WaitToFeedOut extends State<ModuleTilter> {
  @override
  String get name => 'WaitToFeedOut';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_neighborCanFeedIn(tilter) && !_moduleGroupAtDestination(tilter)) {
      return FeedOut();
    }
    return null;
  }

  bool _moduleGroupAtDestination(ModuleTilter tilter) =>
      tilter.moduleGroup!.destination == tilter;

  _neighborCanFeedIn(ModuleTilter tilter) =>
      tilter.receivingneighbor.waitingToFeedIn(tilter.inFeedDirection);
}

class FeedOut extends State<ModuleTilter> {
  @override
  String get name => 'FeedOut';

  ModuleGroup? transportedModuleGroup;

  @override
  // ignore: avoid_renaming_method_parameters
  void onStart(ModuleTilter tilter) {
    transportedModuleGroup = tilter.moduleGroup;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: tilter,
        destination: tilter.receivingneighbor as StateMachineCell);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleTilter>? nextState(ModuleTilter tilter) {
    if (_transportCompleted(tilter)) {
      return WaitToFeedIn();
    }
    return null;
  }

  bool _transportCompleted(ModuleTilter tilter) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != tilter;
}
