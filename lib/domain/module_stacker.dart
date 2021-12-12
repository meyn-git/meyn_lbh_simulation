import 'package:collection/collection.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_lift_position.dart';
import 'state_machine.dart';

class ModuleStacker extends StateMachineCell {
  final CardinalDirection inFeedDirection;

  int nrOfModulesFeedingIn = 0;
  int currentHeightInCentiMeter;
  final Map<LiftPosition, int> heightsInCentiMeter;
  final int liftSpeedInCentiMeterPerSecond;
  final Duration supportsCloseDuration;
  final Duration supportsOpenDuration;
  ModuleGroup? moduleGroupOnSupports;

  ModuleStacker({
    required LiveBirdHandlingArea area,
    required Position position,
    int? seqNr,
    required this.inFeedDirection,
    this.supportsCloseDuration = const Duration(seconds: 3),
    this.supportsOpenDuration = const Duration(seconds: 3),
    Duration inFeedDuration = const Duration(seconds: 14),
    Duration outFeedDuration = const Duration(seconds: 12),
    this.currentHeightInCentiMeter = 150,
    this.liftSpeedInCentiMeterPerSecond = 30,
    this.heightsInCentiMeter = const {
      LiftPosition.inFeed: 150,
      LiftPosition.outFeed: 150,
      LiftPosition.pickUpTopModule: 150 + 150,
      LiftPosition.supportTopModule: 150 + 150 + 20,
    },
  }) : super(
          area: area,
          position: position,
          seqNr: seqNr,
          initialState: MoveLift(LiftPosition.inFeed, WaitToFeedIn()),
          inFeedDuration: inFeedDuration,
          outFeedDuration: outFeedDuration,
        );

  Cell get receivingNeighbour =>
      area.neighbouringCell(this, inFeedDirection.opposite);

  Cell get sendingNeighbour => area.neighbouringCell(this, inFeedDirection);

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

  /// needed override: When [moduleGroupOnSupports]!=null than
  /// there could be 2 [ModuleGroup]s in [LiveBirdHandlingArea.modelGroups] for this [StateMachineCell].
  /// In this case we do not want the [moduleGroupOnSupports] but the other one
  /// That is why we need to override the default behaviour.
  @override
  ModuleGroup? get moduleGroup =>
      area.moduleGroups.firstWhereOrNull((moduleGroup) =>
          moduleGroup != moduleGroupOnSupports &&
          moduleGroup.position.equals(this));
}

class MoveLift extends DurationState<ModuleStacker> {
  final LiftPosition goToPosition;

  MoveLift(this.goToPosition, State<ModuleStacker> nextState)
      : super(
            durationFunction: createDurationFunction(goToPosition),
            nextStateFunction: (stacker) => nextState);

  static Duration Function(ModuleStacker) createDurationFunction(
      LiftPosition goToPosition) {
    return (stacker) {
      var currentHeightInCentiMeter = stacker.currentHeightInCentiMeter;
      var goToHeightInCentiMeter = stacker.heightsInCentiMeter[goToPosition]!;
      var distanceInCentiMeter =
          (currentHeightInCentiMeter - goToHeightInCentiMeter).abs();
      Duration duration = Duration(
          milliseconds: (distanceInCentiMeter /
                  stacker.liftSpeedInCentiMeterPerSecond *
                  1000)
              .round());
      return duration;
    };
  }

  @override
  String toString() {
    return '${this.name} to:${goToPosition.toString().replaceFirst('$LiftPosition.', '')} remaining:${remainingDuration.inSeconds}sec';
  }

  @override
  void onCompleted(ModuleStacker stacker) {
    stacker.currentHeightInCentiMeter =
        stacker.heightsInCentiMeter[goToPosition]!;
  }
}

class WaitToFeedIn extends State<ModuleStacker> {
  @override
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (_moduleGroupTransportedTo(stacker)) {
      return FeedIn();
    }
  }

  bool _moduleGroupTransportedTo(ModuleStacker stacker) {
    return stacker.area.moduleGroups.any((moduleGroup) =>
        moduleGroup != stacker.moduleGroupOnSupports &&
        moduleGroup.position.destination == stacker);
  }
}

class FeedIn extends State<ModuleStacker> {
  @override
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (_transportCompleted(stacker)) {
      if (stacker.moduleGroupOnSupports == null) {
        return MoveLift(LiftPosition.supportTopModule, CloseModuleSupports());
      } else {
        return MoveLift(LiftPosition.pickUpTopModule, OpenModuleSupports());
      }
    }
  }

  bool _transportCompleted(ModuleStacker stacker) =>
      stacker.moduleGroup != null;
}

class CloseModuleSupports extends DurationState<ModuleStacker> {
  CloseModuleSupports()
      : super(
          durationFunction: (stacker) => stacker.supportsCloseDuration,
          nextStateFunction: (stacker) =>
              MoveLift(LiftPosition.inFeed, WaitToFeedIn()),
        );

  @override
  void onCompleted(ModuleStacker stacker) {
    stacker.moduleGroupOnSupports = stacker.moduleGroup;
  }
}

class OpenModuleSupports extends DurationState<ModuleStacker> {
  OpenModuleSupports()
      : super(
          durationFunction: (stacker) => stacker.supportsOpenDuration,
          nextStateFunction: (stacker) =>
              MoveLift(LiftPosition.outFeed, WaitToFeedOut()),
        );

  @override
  void onCompleted(ModuleStacker stacker) {
    _mergeModuleGroup(stacker);
  }

  void _mergeModuleGroup(ModuleStacker stacker) {
    stacker.moduleGroup!.secondModule =
        stacker.moduleGroupOnSupports!.firstModule;
    stacker.area.moduleGroups.remove(stacker.moduleGroupOnSupports);
    stacker.moduleGroupOnSupports = null;
  }
}

class WaitToFeedOut extends State<ModuleStacker> {
  @override
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (_neighbourCanFeedIn(stacker) && !_moduleGroupAtDestination(stacker)) {
      return FeedOut();
    }
  }

  bool _moduleGroupAtDestination(ModuleStacker stacker) =>
      stacker.moduleGroup!.destination == stacker;

  _neighbourCanFeedIn(ModuleStacker stacker) =>
      stacker.receivingNeighbour.waitingToFeedIn(stacker.inFeedDirection);
}

class FeedOut extends State<ModuleStacker> {
  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleStacker stacker) {
    transportedModuleGroup = stacker.moduleGroup;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: stacker,
        destination: stacker.receivingNeighbour as StateMachineCell);
  }

  @override
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (_transportCompleted(stacker)) {
      return MoveLift(LiftPosition.inFeed, WaitToFeedIn());
    }
  }

  bool _transportCompleted(ModuleStacker stacker) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != stacker;
}
