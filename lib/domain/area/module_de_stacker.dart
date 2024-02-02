import 'package:meyn_lbh_simulation/domain/area/direction.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_lift_position.dart';
import 'state_machine.dart';

class ModuleDeStacker extends StateMachineCell {
  final CardinalDirection inFeedDirection;

  int nrOfModulesFeedingIn = 0;
  int currentHeightInCentiMeter;
  final Map<LiftPosition, int> heightsInCentiMeter;
  final int liftSpeedInCentiMeterPerSecond;
  final Duration supportsCloseDuration;
  final Duration supportsOpenDuration;
  ModuleGroup? moduleGroupOnSupports;

  
  ModuleDeStacker({
    required super.area,
    required super.position,
    super.name='ModuleDeStacker',
    super.seqNr,
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
      LiftPosition.supportTopModule: 150 + 150 + 30,
      LiftPosition.pickUpTopModule: 150 + 30
    },
  }) : super(
          initialState: MoveLift(LiftPosition.inFeed, WaitToFeedIn()),
          inFeedDuration: inFeedDuration ??
              area.productDefinition.moduleSystem.stackerInFeedDuration,
          outFeedDuration: outFeedDuration ??
              area.productDefinition.moduleSystem.conveyorTransportDuration,
        );

  Cell get receivingNeighbor =>
      area.neighboringCell(this, inFeedDirection.opposite);

  Cell get sendingNeighbor => area.neighboringCell(this, inFeedDirection);

  @override
  bool isFeedIn(CardinalDirection direction) => direction == inFeedDirection;

  @override
  bool waitingToFeedIn(CardinalDirection direction) =>
      direction == inFeedDirection &&
      currentState is WaitToFeedIn &&
      moduleGroupOnSupports == null;

  @override
  bool isFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite && currentState is WaitToFeedOut;
}

class MoveLift extends DurationState<ModuleDeStacker> {
  final LiftPosition goToPosition;

  MoveLift(this.goToPosition, State<ModuleDeStacker> nextState)
      : super(
            durationFunction: createDurationFunction(goToPosition),
            nextStateFunction: (deStacker) => nextState);

  static Duration Function(ModuleDeStacker) createDurationFunction(
      LiftPosition goToPosition) {
    return (deStacker) {
      var currentHeightInCentiMeter = deStacker.currentHeightInCentiMeter;
      var goToHeightInCentiMeter = deStacker.heightsInCentiMeter[goToPosition]!;
      var distanceInCentiMeter =
          (currentHeightInCentiMeter - goToHeightInCentiMeter).abs();
      Duration duration = Duration(
          milliseconds: (distanceInCentiMeter /
                  deStacker.liftSpeedInCentiMeterPerSecond *
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
  void onCompleted(ModuleDeStacker deStacker) {
    deStacker.currentHeightInCentiMeter =
        deStacker.heightsInCentiMeter[goToPosition]!;
  }

  @override
  String get name => 'MoveLift';
}

class WaitToFeedIn extends State<ModuleDeStacker> {
  @override
  String get name => 'WaitToFeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (_moduleGroupTransportedTo(deStacker)) {
      return FeedIn();
    }
    return null;
  }

  bool _moduleGroupTransportedTo(ModuleDeStacker deStacker) {
    return deStacker.area.moduleGroups
        .any((moduleGroup) => moduleGroup.position.destination == deStacker);
  }
}

class FeedIn extends State<ModuleDeStacker> {
  @override
  String get name => 'FeedIn';

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (_transportCompleted(deStacker)) {
      if (deStacker.moduleGroup!.numberOfModules == 1) {
        return MoveLift(LiftPosition.outFeed, WaitToFeedOut());
      } else {
        return MoveLift(LiftPosition.supportTopModule, CloseModuleSupports());
      }
    }
    return null;
  }

  bool _transportCompleted(ModuleDeStacker deStacker) =>
      deStacker.moduleGroup != null;
}

class CloseModuleSupports extends DurationState<ModuleDeStacker> {
  @override
  String get name => 'CloseModuleSupports';

  CloseModuleSupports()
      : super(
          durationFunction: (deStacker) => deStacker.supportsCloseDuration,
          nextStateFunction: (deStacker) =>
              MoveLift(LiftPosition.outFeed, WaitToFeedOut()),
        );

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleDeStacker deStacker) {
    deStacker.moduleGroupOnSupports = deStacker.moduleGroup!.split();
    deStacker.area.moduleGroups.add(deStacker.moduleGroupOnSupports!);
  }
}

class OpenModuleSupports extends DurationState<ModuleDeStacker> {
  @override
  String get name => 'OpenModuleSupports';

  OpenModuleSupports()
      : super(
          durationFunction: (deStacker) => deStacker.supportsOpenDuration,
          nextStateFunction: (deStacker) =>
              MoveLift(LiftPosition.outFeed, WaitToFeedOut()),
        );

  @override
  // ignore: avoid_renaming_method_parameters
  void onCompleted(ModuleDeStacker deStacker) {
    deStacker.moduleGroupOnSupports = null;
  }
}

class WaitToFeedOut extends State<ModuleDeStacker> {
  @override
  String get name => 'WaitToFeedOut';
  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (_neighborCanFeedIn(deStacker) &&
        !_moduleGroupAtDestination(deStacker)) {
      return FeedOut();
    }
    return null;
  }

  bool _moduleGroupAtDestination(ModuleDeStacker deStacker) =>
      deStacker.moduleGroup!.destination == deStacker;

  _neighborCanFeedIn(ModuleDeStacker deStacker) =>
      deStacker.receivingNeighbor.waitingToFeedIn(deStacker.inFeedDirection);
}

class FeedOut extends State<ModuleDeStacker> {
  @override
  String get name => 'FeedOut';
  ModuleGroup? transportedModuleGroup;

  @override
  // ignore: avoid_renaming_method_parameters
  void onStart(ModuleDeStacker deStacker) {
    transportedModuleGroup = deStacker.moduleGroup;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: deStacker,
        destination: deStacker.receivingNeighbor as StateMachineCell);
  }

  @override
  // ignore: avoid_renaming_method_parameters
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (_transportCompleted(deStacker)) {
      if (deStacker.moduleGroupOnSupports == null) {
        return MoveLift(LiftPosition.inFeed, WaitToFeedIn());
      } else {
        return MoveLift(LiftPosition.pickUpTopModule, OpenModuleSupports());
      }
    }
    return null;
  }

  bool _transportCompleted(ModuleDeStacker deStacker) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != deStacker;
}
