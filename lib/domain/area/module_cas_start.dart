import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:user_command/user_command.dart';

import 'bird_hanging_conveyor.dart';
import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_cas.dart';

/// Starts CAS units depending on the line speed, nr of birds per module
/// (=modules/hour) compensated for the number of stunned modules waiting
class ModuleCasStart implements ActiveCell {
  @override
  late LiveBirdHandlingArea area;
  @override
  late Position position;
  @override
  late String name;
  final List<double> startIntervalFractions;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  static const Duration hold = Duration(seconds: 999999999);

  Duration elapsedTime = Duration.zero;

  static const Duration maxElapsedTime = Duration(minutes: 30);

  ModuleCasStart(
      {required this.area,
      required this.position,
      this.startIntervalFractions = defaultIntervalFractions,
      this.name = "ModuleCasStart"});

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

    if (elapsedTime > maxElapsedTime) {
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
    if (nrStunnedModules >= startIntervalFractions.length) {
      return hold;
    } else {
      return _normalStartInterval * startIntervalFractions[nrStunnedModules];
    }
  }

  /// nr of stunned containers = normal CAS start interval *
  ///                        0 = _normalStartInterval * 0 = 0 = start ASAP
  ///                        1 = _normalStartInterval * 0.5
  ///                        2 = _normalStartInterval * 0.75
  ///                        3 = _normalStartInterval * 1
  ///                        4 = _normalStartInterval * 1
  ///                        5 = _normalStartInterval * 1.25
  ///                        6 = _normalStartInterval * 1.5
  ///                        7 = _normalStartInterval * 1.75
  ///                        8 = _normalStartInterval * 2
  ///                        9 = _normalStartInterval * 2.25
  ///                otherwise = _normalStartInterval * [double.infinity]
  static const defaultIntervalFractions = <double>[
    0,
    0.5,
    0.75,
    1,
    1,
    1.25,
    1.5,
    1.75,
    2,
    2.25,
  ];

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('stunnedModules', numberOfWaitingStunnedModules)
      .appendProperty('baseInterval', _normalStartInterval)
      .appendProperty('nextInterval',
          nextStartInterval == hold ? 'onHold' : nextStartInterval)
      .appendProperty('elapsedTime', elapsedTime);

  @override
  String toString() => objectDetails.toString();

  int get numberOfWaitingStunnedModules => area.moduleGroups
      .where((groupModule) => groupModule.contents == BirdContents.stunnedBirds)
      .fold(
          0,
          (previousValue, groupModule) =>
              previousValue + groupModule.numberOfModules);

  BirdHangingConveyor _findBirdHangingConveyors() {
    var hangingConveyors = area.cells.whereType<BirdHangingConveyor>();
    if (hangingConveyors.isEmpty) {
      throw Exception(
          'Could not find a $BirdHangingConveyor in $LiveBirdHandlingArea');
    }
    if (hangingConveyors.length > 1) {
      throw Exception(
          "Found multiple $BirdHangingConveyor's in $LiveBirdHandlingArea");
    }
    return hangingConveyors.first;
  }

  Duration get _normalStartInterval {
    var shacklesPerHour = _findBirdHangingConveyors().shacklesPerHour;
    var birdsPerModuleGroup =
        area.productDefinition.averageProductsPerModuleGroup;
    Duration startInterval = Duration(
        microseconds: (3600 /
                shacklesPerHour *
                birdsPerModuleGroup *
                Duration.microsecondsPerSecond)
            .round());
    return startInterval;
  }

  /// Starts longest waiting CAS unit
  /// returns true if a CAS unit was started
  bool startLongestWaitingCasUnit() {
    List<ModuleCas> casUnits =
        area.cells.whereType<ModuleCas>().map((cell) => cell).toList();
    if (casUnits.isEmpty) {
      throw Exception('$LiveBirdHandlingArea error: No $ModuleCas cells found');
    }
    List<ModuleCas> casUnitsOrderedByLongestWaiting = casUnits
      ..sort((a, b) =>
          a.waitingForStartDuration.compareTo(b.waitingForStartDuration) * -1);
    var longestWaitingCasUnit = casUnitsOrderedByLongestWaiting.first;
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
