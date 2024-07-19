import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module/module.dart';
import 'module_cas.dart';

/// Starts CAS units depending on the line speed, nr of birds per module
/// (=modules/hour) compensated for the number of stunned modules waiting
class ModuleCasStart implements System, TimeProcessor {
  final LiveBirdHandlingArea area;
  @override
  late String name = "ModuleCasStart";
  final List<double> startIntervalFractions;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  static const Duration hold = Duration(seconds: 999999999);

  Duration elapsedTime = Duration.zero;

  static const Duration maxElapsedTime = Duration(minutes: 30);

  /// travel time corrections for the CAS units
  /// e.g.
  ///     CAS6  CAS4  CAS2
  /// =>   TT    TT    TT  =>
  ///     CAS5  CAS3  CAS1
  ///
  /// Than [transportTimeCorrections] = {1: 12, 2:12, 5:-12, 6:-12}
  /// So that the start interval for:
  /// * CAS 1 & 2 will be 12 seconds later
  /// * CAS 5 & 6 will be 12 seconds sooner
  final Map<
      ModuleCas,

      /// seconds of start interval correction
      int> transportTimeCorrections;

  Duration startInterval = hold;

  ModuleCasStart({
    required this.area,
    this.startIntervalFractions = defaultIntervalFractions,
    this.transportTimeCorrections = const {},
  });

  @override
  onUpdateToNextPointInTime(Duration jump) {
    var longestWaitingCasUnit = _longestWaitingCasUnit;
    startInterval = _startInterval(longestWaitingCasUnit);

    if (elapsedTime > maxElapsedTime) {
      elapsedTime = maxElapsedTime;
    } else {
      elapsedTime = elapsedTime + jump;
      if (elapsedTime > startInterval && longestWaitingCasUnit != null) {
        longestWaitingCasUnit.start();
        elapsedTime = Duration.zero;
      }
    }
  }

  Duration _startInterval(ModuleCas? longestWaitingCasUnit) {
    var nrStunnedModules = numberOfWaitingStunnedModules;
    if (nrStunnedModules >= startIntervalFractions.length) {
      return hold;
    } else {
      return normalStartInterval * startIntervalFractions[nrStunnedModules] +
          _transportTimeCorrection(longestWaitingCasUnit);
    }
  }

  /// nr of stunned containers = normal CAS start interval * fraction
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
      .appendProperty('baseInterval', normalStartInterval)
      .appendProperty(
          'startInterval', startInterval == hold ? 'onHold' : startInterval)
      .appendProperty('elapsedTime', elapsedTime);

  @override
  String toString() => objectDetails.toString();

  int get numberOfWaitingStunnedModules => area.moduleGroups
      .where((groupModule) => groupModule.contents == BirdContents.stunnedBirds)
      .fold(
          0,
          (previousValue, groupModule) =>
              previousValue + groupModule.numberOfModules);

  late int shacklesPerHour = area.productDefinition.lineSpeedInShacklesPerHour;

  late double birdsPerModuleGroup =
      area.productDefinition.averageProductsPerModuleGroup;

  late Duration normalStartInterval = Duration(
      microseconds: (3600 /
              shacklesPerHour *
              birdsPerModuleGroup *
              Duration.microsecondsPerSecond)
          .round());

  ModuleCas? get _longestWaitingCasUnit {
    if (casUnits.isEmpty) {
      throw Exception('$LiveBirdHandlingArea error: No $ModuleCas cells found');
    }
    List<ModuleCas> casUnitsOrderedByLongestWaiting = casUnits
        .where((moduleCas) => moduleCas.currentState is WaitForStart)
        .toList()
      ..sort((a, b) =>
          a.waitingForStartDuration.compareTo(b.waitingForStartDuration) * -1);
    return casUnitsOrderedByLongestWaiting.firstOrNull;
  }

  late Iterable<ModuleCas> casUnits = area.systems.whereType<ModuleCas>();

  Duration _transportTimeCorrection(ModuleCas? longestWaitingCasUnit) {
    if (longestWaitingCasUnit == null ||
        !transportTimeCorrections.containsKey(longestWaitingCasUnit)) {
      return Duration.zero;
    } else {
      return Duration(
          seconds: transportTimeCorrections[longestWaitingCasUnit]!);
    }
  }
}
