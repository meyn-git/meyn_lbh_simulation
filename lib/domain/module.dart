import 'dart:math';

import 'layout.dart';
import 'state_machine.dart';
import 'title_builder.dart';

/// A [ModuleGroup] can be one or 2 modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side
class ModuleGroup extends TimeProcessor {
  final Module firstModule;
  final Module? secondModule;
  final ModuleType type;
  CompassDirection doorDirection;
  StateMachineCell destination;
  ModulePosition position;

  ModuleGroup({
    required this.type,
    required this.firstModule,
    this.secondModule,
    required this.doorDirection,
    required this.destination,
    required this.position,
  });

  int get numberOfModules => 1 + ((secondModule == null) ? 0 : 1);

  @override
  onUpdateToNextPointInTime(Duration jump) {
    position.processNextTimeFrame(this, jump);
    if (sinceLoadedOnSystem != null) {
      sinceLoadedOnSystem = sinceLoadedOnSystem! + jump;
    }
    if (sinceStartStun != null) {
      sinceStartStun = sinceStartStun! + jump;
    }
    if (sinceBirdsUnloaded != null) {
      sinceBirdsUnloaded = sinceBirdsUnloaded! + jump;
    }
  }

  @override
  String toString() => TitleBuilder('ModuleGroup')
      .appendProperty('doorDirection', doorDirection)
      .appendProperty('destination', destination.name)
      //.appendProperty('position', position) removed because its obvious
      .appendProperty('firstModule', firstModule)
      .appendProperty('secondModule', secondModule)
      .toString();

  Duration? get sinceLoadedOnSystem => firstModule.sinceLoadedOnSystem;

  set sinceLoadedOnSystem(Duration? duration) {
    firstModule.sinceLoadedOnSystem = duration;
    if (secondModule != null) {
      secondModule!.sinceLoadedOnSystem = duration;
    }
  }

  void startedLoadingOnToSystem() {
    sinceLoadedOnSystem = Duration.zero;
  }

  Duration? get sinceStartStun => firstModule.sinceStartStun;

  set sinceStartStun(Duration? duration) {
    firstModule.sinceStartStun = duration;
    if (secondModule != null) {
      secondModule!.sinceStartStun = duration;
    }
  }

  void startedStunning() {
    sinceStartStun = Duration.zero;
  }

  Duration? get sinceBirdsUnloaded => firstModule.sinceBirdsUnloaded;

  set sinceBirdsUnloaded(Duration? duration) {
    firstModule.sinceBirdsUnloaded = duration;
    if (secondModule != null) {
      secondModule!.sinceBirdsUnloaded = duration;
    }
  }

  void startedUnloadingBirds() {
    sinceBirdsUnloaded = Duration.zero;
  }

}

/// A module location is either at a given position or traveling between 2 positions
class ModulePosition {
  StateMachineCell source;
  StateMachineCell destination;
  late Duration duration;
  late Duration remainingDuration;

  ModulePosition.forCel(StateMachineCell cell)
      : source = cell,
        destination = cell,
        duration = Duration.zero,
        remainingDuration = Duration.zero;

  ModulePosition.betweenCells(
      {required this.source, required this.destination, Duration? duration}) {
    this.duration = duration ?? findLongestDuration(source, destination);
    remainingDuration = this.duration;
  }

  /// 0  =  0% of transportation is completed
  /// 0.5= 50% of transportation is completed
  /// 1  =100% of transportation is completed
  double get percentageCompleted => duration == Duration.zero
      ? 1
      : 1 - remainingDuration.inMilliseconds / duration.inMilliseconds;

  processNextTimeFrame(ModuleGroup moduleGroup, Duration jump) {
    if (remainingDuration > Duration.zero) {
      remainingDuration = remainingDuration - jump;
      if (remainingDuration <= Duration.zero) {
        source = destination;
      }
    } else {
      remainingDuration = Duration.zero;
    }
  }

  equals(StateMachineCell cell) =>
      source.position == cell.position &&
      destination.position == cell.position &&
      remainingDuration == Duration.zero;

  static Duration findLongestDuration(
    StateMachineCell source,
    StateMachineCell destination,
  ) {
    Duration outFeedDuration = source.outFeedDuration;
    Duration inFeedDuration = destination.inFeedDuration;
    return Duration(
        milliseconds:
            max(outFeedDuration.inMilliseconds, inFeedDuration.inMilliseconds));
  }

  @override
  String toString() {
    if (source == destination) {
      return TitleBuilder('ModulePosition')
          .appendProperty('at', source.name)
          .toString();
    } else {
      return TitleBuilder('ModulePosition')
          .appendProperty('source', source.name)
          .appendProperty('destination', destination.name)
          .appendProperty('remainingDuration', remainingDuration)
          .toString();
    }
  }
}

class Module {
  final int sequenceNumber;
  final int nrOfBirds;
  Duration? sinceLoadedOnSystem;
  Duration? sinceStartStun;
  Duration? sinceBirdsUnloaded;

  Module({
    required this.sequenceNumber,
    required this.nrOfBirds,
  });

  @override
  String toString() => TitleBuilder('Module')
      .appendProperty('sequenceNumber', sequenceNumber)
      .appendProperty('nrOfBirds', nrOfBirds)
      .appendProperty('sinceLoadedOnSystem', sinceLoadedOnSystem)
      .appendProperty('sinceStartStun', sinceStartStun)
      .appendProperty('sinceBirdsUnloaded', sinceBirdsUnloaded)
      .toString();
}

enum ModuleType { square, rectangular }
