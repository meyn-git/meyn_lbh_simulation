import 'package:meyn_lbh_simulation/domain/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/title_builder.dart';

import 'layout.dart';
import 'module.dart';
import 'module_cas.dart';

/// Starts CAS units depending on the line speed, nr of birds per module
/// (=modules/hour) compensated for the number of stunned modules waiting
class ModuleCasStart extends ActiveCell {
  static final Duration hold = Duration(seconds: 999999999);


  Duration elapsedTime = Duration.zero;

  ModuleCasStart({
    required Layout layout,
    required Position position,
  }) : super(layout, position);

  String get name => "${this.runtimeType.toString()}";

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => false;

  @override
  bool isFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedIn(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) => false;

  @override
  onUpdateToNextPointInTime(Duration jump) {
    var startInterval = nextStartInterval;
    if (startInterval == Duration.zero) {
      startLongestWaitingCasUnit();
      elapsedTime = Duration.zero;
    }
    if (startInterval == hold) {
      elapsedTime = Duration.zero;
    } else {
      elapsedTime = elapsedTime + jump;
      if (elapsedTime > startInterval) {
        if (startLongestWaitingCasUnit()) {
          elapsedTime = Duration.zero;
        }
      }
    }
  }

  Duration get nextStartInterval {
    var nrStunnedModules = numberOfWaitingStunnedModules;
    if (nrStunnedModules == 0) {
      return Duration.zero;
    }
    switch (nrStunnedModules) {
      case 1:
        return _normalStartInterval * 0.5;
      case 2:
        return _normalStartInterval * 1;
      case 3:
        return _normalStartInterval * 1;
      case 4:
        return _normalStartInterval * 1;
      default:
        return hold;
    }
  }

  @override
  String toString() {
    return TitleBuilder(name)
      .appendProperty('stunnedModules', numberOfWaitingStunnedModules)
      .appendProperty('baseInterval', _normalStartInterval)
      .appendProperty('nextInterval', nextStartInterval==hold?'onHold':nextStartInterval)
      .appendProperty('elapsedTime', elapsedTime)
      .toString();
  }



  int get numberOfWaitingStunnedModules => layout.moduleGroups
      .where(
          (groupModule) => groupModule.contents == ModuleContents.stunnedBirds)
      .fold(
          0,
          (previousValue, groupModule) =>
              previousValue + groupModule.numberOfModules);

  BirdHangingConveyor _findBirdHangingConveyors() {
    var hangingConveyors =
        layout.cells.where((cell) => cell is BirdHangingConveyor);
    if (hangingConveyors.isEmpty) {
      throw Exception('Could not find a $BirdHangingConveyor in layout');
    }
    if (hangingConveyors.length > 1) {
      throw Exception("Found multiple $BirdHangingConveyor's in layout");
    }
    return hangingConveyors.first as BirdHangingConveyor;
  }

  Duration get _normalStartInterval {
    var shacklesPerHour = _findBirdHangingConveyors().shacklesPerHour;
    var birdsPerModuleGroup = _findNrOfBirdsPerModuleGroup();
    Duration startInterval = Duration(
        microseconds: (3600 / shacklesPerHour * birdsPerModuleGroup*Duration.microsecondsPerSecond).round());
    return startInterval;
  }

  LoadingForkLiftTruck _findLoadingForkLiftTruck() {
    var forkLiftTrucks =
        layout.cells.where((cell) => cell is LoadingForkLiftTruck);
    if (forkLiftTrucks.isEmpty) {
      throw Exception('Could not find any $LoadingForkLiftTruck in layout');
    }
    if (forkLiftTrucks.length > 1) {
      throw Exception("Found multiple $LoadingForkLiftTruck's in layout");
    }
    return forkLiftTrucks.first as LoadingForkLiftTruck;
  }

  /// Starts longest waiting CAS unit
  /// returns true if a CAS unit was started
  bool startLongestWaitingCasUnit() {
    List<ModuleCas> casUnits=layout.cells.where((cell) => cell is ModuleCas).map((cell) => cell as ModuleCas).toList();
    if (casUnits.isEmpty) {
      throw Exception('Layout error: No $ModuleCas cells found');
    }
    List<ModuleCas> casUnitsOrderedByLongestWaiting=casUnits..sort((a,b) => a.waitingForStartDuration.compareTo(b.waitingForStartDuration)*-1);
    var longestWaitingCasUnit=casUnitsOrderedByLongestWaiting.first;
    if (longestWaitingCasUnit.currentState is WaitForStart) {
      longestWaitingCasUnit.start();
      return true;
    } else {
      return false;
    }
  }

  int _findNrOfBirdsPerModuleGroup() {
    var forkLiftTruck = _findLoadingForkLiftTruck();
    var moduleGroup = forkLiftTruck.createModuleGroup();
    return moduleGroup.numberOfBirds;
  }

  @override
  ModuleGroup? get moduleGroup => null;
}
