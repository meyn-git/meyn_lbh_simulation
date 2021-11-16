import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import 'layout.dart';

abstract class StateMachineCell extends ActiveCell {
  // /// where de module(s) need to go, null when there is no destination
  // String? destination;

  /// A sequence number for when there are multiple [StateMachineCell] implementations of the same type
  final int? seqNr;
  State currentState;

  final Duration inFeedDuration;

  final Duration outFeedDuration;

  StateMachineCell({
    required Layout layout,
    required Position position,
    this.seqNr,
    required State initialState,
    required this.inFeedDuration,
    required this.outFeedDuration,
  })  : currentState = initialState,
        super(layout, position);

  //TODO word spacing
  String get name => "${this.runtimeType.toString()}${seqNr ?? ''}";

  /// This method gets called every sec to update all state machines
  @override
  processNextTimeFrame(Duration jump) {
    var nextState = currentState.process(this);
    if (nextState != null) {
      currentState = nextState;
    }
  }

  @override
  Widget get widget => SizedBox(
        width: 20,
        height: 20,
        child: Text(toolTipText()),
      );

  String toolTipText() {
    return "$name\n"
        "${currentState.name}"
        "\n${currentState is DurationState ? '${(currentState as DurationState).remainingSeconds} sec' : 'Waiting'}"
        "${moduleGroup == null ? '' : '\n${moduleGroup!.numberOfModules} modules'}"
        "${moduleGroup == null ? '' : '\ndestination: ${(layout.cellForPosition(moduleGroup!.destination) as StateMachineCell).name}'}";
  }

  @override
  String toString() => name;

  @override
  ModuleGroup? get moduleGroup => layout.moduleGroups
      .firstWhereOrNull((moduleGroup) => moduleGroup.position.equals(this));
}

abstract class State<T extends StateMachineCell> {
  String get name => this.runtimeType.toString(); //TODO word spacing

  /// returns the next state.
  /// null when this the state remains the same
  State? process(T stateMachine);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is State && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class DurationState<T extends StateMachineCell> extends State<T> {
  final Duration Function(T) duration;
  final State Function(T) nextState;
  Duration? _remainingDuration;
  void Function(T)? onStart;
  void Function(T)? onCompleted;
  bool _firstProcess = true;

  DurationState({
    required this.duration,
    required this.nextState,
    this.onStart,
    this.onCompleted,
  });

  State? process(T stateMachine) {
    if (onStart != null && _firstProcess) {
      onStart!(stateMachine);
      _firstProcess = false;
    }
    if (_remainingDuration == null) {
      _remainingDuration = duration(stateMachine) - Duration(seconds: 1);
    } else {
      if (_remainingDuration == Duration.zero) {
        resetDurationTime(stateMachine);
        if (onCompleted != null) onCompleted!(stateMachine);
        return nextState(stateMachine);
      } else {
        _remainingDuration = _remainingDuration! - Duration(seconds: 1);
      }
    }
  }

  void resetDurationTime(T stateMachine) {
    _remainingDuration = duration(stateMachine);
  }

  Duration get remainingSeconds => _remainingDuration ?? Duration.zero;
}
