import 'package:meyn_lbh_simulation/domain/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/title_builder.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_cas.dart';

/// Starts CAS units depending on the line speed, nr of birds per module
/// (=modules/hour) compensated for the number of stunned modules waiting
class ModuleCasStart extends ActiveCell {
  static final Duration hold = Duration(seconds: 999999999);


  Duration elapsedTime = Duration.zero;

  static final Duration maxElapsedTime=Duration(minutes: 30);

  ModuleCasStart({
    required LiveBirdHandlingArea area,
    required Position position,
  }) : super(area, position);

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

    if (elapsedTime>maxElapsedTime) {
      elapsedTime = maxElapsedTime;
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
    switch (nrStunnedModules) {
      case 0:
        return Duration.zero;
      case 1:
        return _normalStartInterval * 0.5;
      case 2:
        return _normalStartInterval * 0.75;
      case 3:
        return _normalStartInterval * 1;
      case 4:
        return _normalStartInterval * 1;
      case 5:
        return _normalStartInterval * 1.25;
      case 6:
        return _normalStartInterval * 1.5;
      case 7:
        return _normalStartInterval * 1.75;
      case 8:
        return _normalStartInterval * 2;
      case 9:
        return _normalStartInterval * 2.25;
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



  int get numberOfWaitingStunnedModules => area.moduleGroups
      .where(
          (groupModule) => groupModule.contents == ModuleContents.stunnedBirds)
      .fold(
          0,
          (previousValue, groupModule) =>
              previousValue + groupModule.numberOfModules);

  BirdHangingConveyor _findBirdHangingConveyors() {
    var hangingConveyors =
        area.cells.where((cell) => cell is BirdHangingConveyor);
    if (hangingConveyors.isEmpty) {
      throw Exception('Could not find a $BirdHangingConveyor in $LiveBirdHandlingArea');
    }
    if (hangingConveyors.length > 1) {
      throw Exception("Found multiple $BirdHangingConveyor's in $LiveBirdHandlingArea");
    }
    return hangingConveyors.first as BirdHangingConveyor;
  }

  Duration get _normalStartInterval {
    var shacklesPerHour = _findBirdHangingConveyors().shacklesPerHour;
    var birdsPerModuleGroup = area.productDefinition.averageProductsPerModuleGroup;
    Duration startInterval = Duration(
        microseconds: (3600 / shacklesPerHour * birdsPerModuleGroup*Duration.microsecondsPerSecond).round());
    return startInterval;
  }


  /// Starts longest waiting CAS unit
  /// returns true if a CAS unit was started
  bool startLongestWaitingCasUnit() {
    List<ModuleCas> casUnits=area.cells.where((cell) => cell is ModuleCas).map((cell) => cell as ModuleCas).toList();
    if (casUnits.isEmpty) {
      throw Exception('$LiveBirdHandlingArea error: No $ModuleCas cells found');
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

  // int _findNrOfBirdsPerModuleGroup() {
  //   var forkLiftTruck = _findLoadingForkLiftTruck();
  //   var moduleGroup = forkLiftTruck.createModuleGroup();
  //   if (moduleGroup.type==ModuleType.square) {
  //     return moduleGroup.numberOfBirds*2;// assuming square modules are put on the system 1 by 1, a module group is x2
  //   } else {
  //     return moduleGroup.numberOfBirds;
  //   }
  //
  // }

  @override
  ModuleGroup? get moduleGroup => null;
}
