import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';

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

  @override
  String get name => "ModuleStacker${seqNr ?? ''}";

  ModuleStacker({
    required LiveBirdHandlingArea area,
    required Position position,
    int? seqNr,
    required this.inFeedDirection,
    this.supportsCloseDuration = const Duration(seconds: 3),
    this.supportsOpenDuration = const Duration(seconds: 3),
    Duration? inFeedDuration,
    Duration? outFeedDuration,
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
          inFeedDuration: inFeedDuration ??
              area.productDefinition.moduleSystem.stackerInFeedDuration,
          outFeedDuration: outFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
        );

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
  @override
  String get name => 'MoveLift';

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
    return '$name to:${goToPosition.toString().replaceFirst('$LiftPosition.', '')} remaining:${remainingDuration.inSeconds}sec';
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleStacker stacker) {
    stacker.currentHeightInCentiMeter =
        stacker.heightsInCentiMeter[goToPosition]!;
  }
}

class WaitToFeedIn extends State<ModuleStacker> {
  @override
  String get name => 'WaitToFeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (_moduleGroupTransportedTo(stacker)) {
      return FeedIn();
    }
    return null;
  }

  bool _moduleGroupTransportedTo(ModuleStacker stacker) {
    return stacker.area.moduleGroups.any((moduleGroup) =>
        moduleGroup != stacker.moduleGroupOnSupports &&
        moduleGroup.position.destination == stacker);
  }
}

class FeedIn extends State<ModuleStacker> {
  @override
  String get name => 'FeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (_transportCompleted(stacker)) {
      if (stacker.moduleGroupOnSupports == null) {
        return MoveLift(LiftPosition.supportTopModule, CloseModuleSupports());
      } else {
        return MoveLift(LiftPosition.pickUpTopModule, OpenModuleSupports());
      }
    }
    return null;
  }

  bool _transportCompleted(ModuleStacker stacker) =>
      stacker.moduleGroup != null;
}

class CloseModuleSupports extends DurationState<ModuleStacker> {
  @override
  String get name => 'CloseModuleSupports';

  CloseModuleSupports()
      : super(
          durationFunction: (stacker) => stacker.supportsCloseDuration,
          nextStateFunction: (stacker) =>
              MoveLift(LiftPosition.inFeed, WaitToFeedIn()),
        );

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleStacker stacker) {
    stacker.moduleGroupOnSupports = stacker.moduleGroup;
  }
}

class OpenModuleSupports extends DurationState<ModuleStacker> {
  @override
  String get name => 'OpenModuleSupports';

  OpenModuleSupports()
      : super(
          durationFunction: (stacker) => stacker.supportsOpenDuration,
          nextStateFunction: (stacker) =>
              MoveLift(LiftPosition.outFeed, WaitToFeedOut()),
        );

  @override
  // ignore: avoid_renaming_method_parameters
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
  String get name => 'WaitToFeedOut';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (_neighborCanFeedIn(stacker) && !_moduleGroupAtDestination(stacker)) {
      return FeedOut();
    }
    return null;
  }

  bool _moduleGroupAtDestination(ModuleStacker stacker) =>
      stacker.moduleGroup!.destination == stacker;

  _neighborCanFeedIn(ModuleStacker stacker) =>
      stacker.receivingneighbor.waitingToFeedIn(stacker.inFeedDirection);
}

class FeedOut extends State<ModuleStacker> {
  @override
  String get name => 'FeedOut';

  ModuleGroup? transportedModuleGroup;

  @override
  // ignore: avoid_renaming_method_parameters
  void onStart(ModuleStacker stacker) {
    transportedModuleGroup = stacker.moduleGroup;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: stacker,
        destination: stacker.receivingneighbor as StateMachineCell);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleStacker>? nextState(ModuleStacker stacker) {
    if (_transportCompleted(stacker)) {
      return MoveLift(LiftPosition.inFeed, WaitToFeedIn());
    }
    return null;
  }

  bool _transportCompleted(ModuleStacker stacker) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != stacker;
}
