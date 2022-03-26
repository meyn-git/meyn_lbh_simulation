import 'package:collection/collection.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'title_builder.dart';

abstract class StateMachineCell extends ActiveCell {
  /// A sequence number for when there are multiple [StateMachineCell] implementations of the same type
  final int? seqNr;
  State currentState;

  final Duration inFeedDuration;

  final Duration outFeedDuration;

  StateMachineCell({
    required LiveBirdHandlingArea area,
    required Position position,
    this.seqNr,
    required State initialState,
    required this.inFeedDuration,
    required this.outFeedDuration,
  })  : currentState = initialState,
        super(area, position) {
    initialState.onStart(this);
  }

  //TODO word spacing
  @override
  String get name => "${runtimeType.toString()}${seqNr ?? ''}";

  /// This method gets called with a regular time interval by the [LiveBirdHandlingArea]
  /// to update the [StateMachineCell]
  @override
  onUpdateToNextPointInTime(Duration jump) {
    currentState.onUpdateToNextPointInTime(this, jump);
    var nextState = currentState.nextState(this);
    if (nextState != null) {
      currentState.onCompleted(this);
      currentState = nextState;
      nextState.onStart(this);
    }
  }

  @override
  String toString() => TitleBuilder(name)
      .appendProperty('currentState', currentState)
      .appendProperty('moduleGroup', moduleGroup)
      .toString();

  @override
  ModuleGroup? get moduleGroup => area.moduleGroups
      .firstWhereOrNull((moduleGroup) => moduleGroup.position.equals(this));
}

abstract class State<T extends StateMachineCell> {
  String get name => runtimeType.toString();

  /// this method is called when the state starts
  /// (when another [State.nextState] method returned this [State]).
  /// You can override this method e.g. when initialization is needed
  void onStart(T stateMachine) {}

  /// All active [State]s are updated with a regular interval time to
  /// update the state of the [ActiveCell]
  /// You can override this method e.g.:
  /// - when an animation is needed
  /// - or a remaining duration needs to be calculated
  void onUpdateToNextPointInTime(T stateMachine, Duration jump) {}

  /// this method is called when the state is completed
  /// (when [State.nextState] method returned a new [State]).
  /// You can override this method
  /// e.g. when you need to do something at the end of a state
  void onCompleted(T stateMachine) {}

  /// returns the next state or
  /// returns null when the state remains the same
  State<T>? nextState(T stateMachine);

  @override
  String toString() => name;
}

class DurationState<T extends StateMachineCell> extends State<T> {
  final Duration Function(T) durationFunction;
  final State<T> Function(T) nextStateFunction;
  Duration? _remainingDuration;

  DurationState(
      {required this.durationFunction, required this.nextStateFunction});

  Duration get remainingDuration => _remainingDuration ?? Duration.zero;

  @override
  void onStart(T stateMachine) {
    _remainingDuration = durationFunction(stateMachine);
  }

  @override
  void onUpdateToNextPointInTime(T stateMachine, Duration jump) {
    _remainingDuration = remainingDuration - jump;
    if (_remainingDuration! < Duration.zero) {
      _remainingDuration = Duration.zero;
    }
  }

  @override
  State<T>? nextState(T stateMachine) {
    if (_remainingDuration != null && _remainingDuration == Duration.zero) {
      return nextStateFunction(stateMachine);
    }
  }

  @override
  String toString() {
    return '$name remaining:${remainingDuration.inSeconds}sec';
  }
}
