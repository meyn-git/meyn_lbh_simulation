import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/util/title_builder.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';

abstract class StateMachine {
  /// A sequence number for when there are multiple [StateMachineCell] implementations of the same type
  State currentState;

  StateMachine({
    required State initialState,
  }) : currentState = initialState {
    initialState.onStart(this);
  }
}

abstract class StateMachineCell extends StateMachine implements ActiveCell {
  /// A sequence number for when there are multiple [StateMachineCell] implementations of the same type
  @override
  late LiveBirdHandlingArea area;
  @override
  late Position position;
  @override
  late String name;
  final int? seqNr;
  final Duration inFeedDuration;
  final Duration outFeedDuration;

  StateMachineCell({
    required this.area,
    required this.position,
    required String name,
    this.seqNr,
    required super.initialState,
    required this.inFeedDuration,
    required this.outFeedDuration,
  }) : name = "$name${seqNr ?? ''}";

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

abstract class State<T extends StateMachine> {
  String get name;

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

abstract class DurationState<T extends StateMachineCell> extends State<T> {
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
    return null;
  }

  @override
  String toString() {
    return '$name remaining:${remainingDuration.inSeconds}sec';
  }
}
