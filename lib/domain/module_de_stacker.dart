import 'layout.dart';
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
    required Layout layout,
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
      LiftPosition.supportTopModule: 150 + 150,
      LiftPosition.pickUpTopModule: 150 + 150 + 20
    },
  }) : super(
          layout: layout,
          position: position,
          seqNr: seqNr,
          initialState: MoveLift(LiftPosition.inFeed, WaitToFeedIn()),
          inFeedDuration: inFeedDuration,
          outFeedDuration: outFeedDuration,
        );

  Cell get receivingNeighbour =>
      layout.neighbouringCell(this, inFeedDirection.opposite);

  Cell get sendingNeighbour => layout.neighbouringCell(this, inFeedDirection);

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
    return '${this.name} to:${goToPosition.toString().replaceFirst('$LiftPosition.', '')} remaining:${remainingDuration.inSeconds}sec';
  }

  @override
  void onCompleted(ModuleDeStacker deStacker) {
    deStacker.currentHeightInCentiMeter =
        deStacker.heightsInCentiMeter[goToPosition]!;
  }
}

class WaitToFeedIn extends State<ModuleDeStacker> {
  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (_moduleGroupTransportedTo(deStacker)) {
      return FeedIn();
    }
  }

  bool _moduleGroupTransportedTo(ModuleDeStacker deStacker) {
    return deStacker.layout.moduleGroups
        .any((moduleGroup) => moduleGroup.position.destination == deStacker);
  }
}

class FeedIn extends State<ModuleDeStacker> {
  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (_transportCompleted(deStacker)) {
      if (deStacker.moduleGroup!.numberOfModules == 1) {
        return MoveLift(LiftPosition.outFeed, WaitToFeedOut());
      } else {
        return MoveLift(LiftPosition.supportTopModule, CloseModuleSupports());
      }
    }
  }

  bool _transportCompleted(ModuleDeStacker deStacker) =>
      deStacker.moduleGroup != null;
}

class CloseModuleSupports extends DurationState<ModuleDeStacker> {
  CloseModuleSupports()
      : super(
          durationFunction: (deStacker) => deStacker.supportsCloseDuration,
          nextStateFunction: (deStacker) =>
              MoveLift(LiftPosition.outFeed, WaitToFeedOut()),
        );

  @override
  void onCompleted(ModuleDeStacker deStacker) {
    deStacker.moduleGroupOnSupports = deStacker.moduleGroup!.split();
    deStacker.layout.moduleGroups.add(deStacker.moduleGroupOnSupports!);
  }
}

class OpenModuleSupports extends DurationState<ModuleDeStacker> {
  OpenModuleSupports()
      : super(
          durationFunction: (deStacker) => deStacker.supportsOpenDuration,
          nextStateFunction: (deStacker) =>
              MoveLift(LiftPosition.outFeed, WaitToFeedOut()),
        );

  @override
  void onCompleted(ModuleDeStacker deStacker) {
    deStacker.moduleGroupOnSupports = null;
  }
}

class WaitToFeedOut extends State<ModuleDeStacker> {
  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (_neighbourCanFeedIn(deStacker) &&
        !_moduleGroupAtDestination(deStacker)) {
      return FeedOut();
    }
  }

  bool _moduleGroupAtDestination(ModuleDeStacker deStacker) =>
      deStacker.moduleGroup!.destination == deStacker;

  _neighbourCanFeedIn(ModuleDeStacker deStacker) =>
      deStacker.receivingNeighbour.waitingToFeedIn(deStacker.inFeedDirection);
}

class FeedOut extends State<ModuleDeStacker> {
  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleDeStacker deStacker) {
    transportedModuleGroup = deStacker.moduleGroup;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: deStacker,
        destination: deStacker.receivingNeighbour as StateMachineCell);
  }

  @override
  State<ModuleDeStacker>? nextState(ModuleDeStacker deStacker) {
    if (_transportCompleted(deStacker)) {
      if (deStacker.moduleGroupOnSupports == null) {
        return MoveLift(LiftPosition.inFeed, WaitToFeedIn());
      } else {
        return MoveLift(LiftPosition.pickUpTopModule, OpenModuleSupports());
      }
    }
  }

  bool _transportCompleted(ModuleDeStacker deStacker) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != deStacker;
}
