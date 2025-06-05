import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_bird_unloader.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_row_unloader/module_drawer_row_unloader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/fork_lift_truck/loading_fork_lift_truck.domain.dart';
import 'package:user_command/user_command.dart';

/// Starts CAS units depending on the line speed, nr of birds per module
/// (=modules/hour) compensated for the number of stunned modules waiting
class ModuleCasStart implements System, TimeProcessor {
  final LiveBirdHandlingArea area;

  WaitingModuleCorrection? waitingModuleCorrection;

  @override
  late String name = "ModuleCasStart";

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
  /// Than [transportTimeCorrections] = {cas1: 12, cas2:12, cas5:-12, cas6:-12}
  /// So that the start interval for:
  /// * CAS 1 & 2 will be 12 seconds later
  /// * CAS 5 & 6 will be 12 seconds sooner
  final Map<
    ModuleCas,

    /// seconds of start interval correction
    int
  >
  transportTimeCorrections;

  Duration calculatedStartInterval = hold;

  ModuleCasStart({
    required this.area,
    this.waitingModuleCorrection,
    this.transportTimeCorrections = const {},
  });

  @override
  onUpdateToNextPointInTime(Duration jump) {
    averageWaitingModules.onUpdateToNextPointInTime(jump);
    if (elapsedTime > maxElapsedTime) {
      elapsedTime = maxElapsedTime;
    } else {
      elapsedTime = elapsedTime + jump;
    }

    if (numberOfStunnedModules >= maximumNumberOfStunnedModules) {
      calculatedStartInterval = hold;
      waitingModuleCorrectionDuration = Duration.zero;
      transportTimeCorrectionDuration = Duration.zero;
    } else {
      var longestWaitingCasUnit = _longestWaitingCasUnit;
      waitingModulesBeforeUnloader = averageWaitingModules._average;
      waitingModuleCorrection ??= WaitingModuleCorrection.calculated(area);
      waitingModuleCorrectionDuration =
          baseStartInterval *
              waitingModuleCorrection!.calculateFraction(
                waitingModulesBeforeUnloader,
              ) -
          baseStartInterval;
      transportTimeCorrectionDuration = _transportTimeCorrection(
        longestWaitingCasUnit,
      );
      calculatedStartInterval =
          baseStartInterval +
          waitingModuleCorrectionDuration +
          transportTimeCorrectionDuration;

      if (elapsedTime > calculatedStartInterval &&
          longestWaitingCasUnit != null) {
        longestWaitingCasUnit.start();
        elapsedTime = Duration.zero;
      }
    }
  }

  LinkedSystem _moduleUnloader() {
    var moduleBirdUnloaders = area.systems.linkedSystems
        .whereType<ModuleBirdUnloader>();
    if (moduleBirdUnloaders.isEmpty) {
      throw Exception(
        '$LiveBirdHandlingArea error: No $ModuleBirdUnloader found',
      );
    }
    if (moduleBirdUnloaders.length > 1) {
      throw Exception(
        '$LiveBirdHandlingArea error: More than one $ModuleDrawerRowUnloader found',
      );
    }
    return moduleBirdUnloaders.first;
  }

  LoadingForkLiftTruck _loadingForkLiftTrucks() {
    var loadingForkLiftTrucks = area.systems.linkedSystems
        .whereType<LoadingForkLiftTruck>();
    if (loadingForkLiftTrucks.isEmpty) {
      throw Exception(
        '$LiveBirdHandlingArea error: No $LoadingForkLiftTruck found',
      );
    }
    if (loadingForkLiftTrucks.length > 1) {
      throw Exception(
        '$LiveBirdHandlingArea error: More than one $LoadingForkLiftTruck found',
      );
    }
    return loadingForkLiftTrucks.first;
  }

  late final Iterable<LinkedSystem> systemsBeforeModuleUnloader =
      _systemsBeforeModuleUnloader();

  Iterable<LinkedSystem> _systemsBeforeModuleUnloader() {
    var route = _loadingForkLiftTrucks().links
        .whereType<ModuleGroupOutLink>()
        .first
        .findRoute(destination: _moduleUnloader());
    if (route == null) {
      throw Exception(
        '$LiveBirdHandlingArea error: No route found to $ModuleBirdUnloader',
      );
    }
    route.removeLast();
    return route.systems.reversed;
  }

  late final RollingAverageOverTime averageWaitingModules =
      RollingAverageOverTime(
        windowDuration: baseStartInterval,
        windowCount: 50,
        countFunction: _waitingModulesBeforeUnloader,
      );

  double _waitingModulesBeforeUnloader() {
    var waitingModuleGroups = <ModuleGroup>{};
    for (var system in systemsBeforeModuleUnloader) {
      var moduleGroupsAtSystem = area.moduleGroups
          .findOnOrGoingToSystem(system)
          .where(
            (moduleGroup) => moduleGroup.contents == BirdContents.stunnedBirds,
          );

      if (moduleGroupsAtSystem.isEmpty) {
        return waitingModuleGroups
            .map((e) => e.numberOfModules)
            .fold(0, (total, count) => total + count);
      } else {
        waitingModuleGroups.addAll(moduleGroupsAtSystem);
      }
    }
    return waitingModuleGroups
        .map((e) => e.numberOfModules)
        .fold(0, (total, count) => total + count);
  }

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('stunnedModules', numberOfStunnedModules)
      .appendProperty('baseInterval', baseStartInterval)
      .appendObjectDetails(
        ObjectDetails('waitingModuleCorrection')
            .appendProperty(
              'waitingModulesAverage',
              waitingModulesBeforeUnloader,
            )
            .appendProperty('waitingModulesSetPoint', waitingModuleSetPoint)
            .appendProperty(
              'waitingModulesCorrection',
              waitingModuleCorrectionDuration,
            ),
      )
      .appendProperty(
        'transportTimeCorrection',
        transportTimeCorrections.isEmpty
            ? null
            : transportTimeCorrectionDuration,
      )
      .appendProperty(
        'calculatedStartInterval',
        calculatedStartInterval == hold ? 'onHold' : calculatedStartInterval,
      )
      .appendProperty('elapsedTime', elapsedTime);

  @override
  String toString() => objectDetails.toString();

  int get numberOfStunnedModules => area.moduleGroups
      .where((groupModule) => groupModule.contents == BirdContents.stunnedBirds)
      .fold(
        0,
        (previousValue, groupModule) =>
            previousValue + groupModule.numberOfModules,
      );

  late int shacklesPerHour = area.productDefinition.lineSpeedInShacklesPerHour;

  late double averageBirdsPerCasCycle =
      area.productDefinition.averageNumberOfBirdsPerModule *
      numberOfModulesPerCasCycle();

  int numberOfModulesPerCasCycle() {
    var stunners = area.systems.whereType<ModuleCas>();
    if (stunners.isEmpty) {
      throw Exception('Expected this project to have ModuleCAS systems');
    }
    int? nrOfModulesPerCasCycle;
    for (var stunner in stunners) {
      if (nrOfModulesPerCasCycle == null) {
        nrOfModulesPerCasCycle = stunner.numberOfModules;
      } else if (nrOfModulesPerCasCycle != stunner.numberOfModules) {
        throw Exception(
          'Expected all CAS units to be able to process the same number of modules',
        );
      }
    }
    return nrOfModulesPerCasCycle!;
  }

  late Duration baseStartInterval = Duration(
    microseconds:
        (3600 /
                shacklesPerHour *
                averageBirdsPerCasCycle *
                Duration.microsecondsPerSecond)
            .round(),
  );

  ModuleCas? get _longestWaitingCasUnit {
    if (casUnits.isEmpty) {
      throw Exception('$LiveBirdHandlingArea error: No $ModuleCas cells found');
    }
    List<ModuleCas> casUnitsOrderedByLongestWaiting =
        casUnits
            .where((moduleCas) => moduleCas.currentState is WaitForStart)
            .toList()
          ..sort(
            (a, b) =>
                a.waitingForStartDuration.compareTo(b.waitingForStartDuration) *
                -1,
          );
    return casUnitsOrderedByLongestWaiting.firstOrNull;
  }

  late Iterable<ModuleCas> casUnits = area.systems.whereType<ModuleCas>();

  late final int maximumNumberOfStunnedModules =
      _maximumNumberOfStunnedModules();

  Duration waitingModuleCorrectionDuration = Duration.zero;

  Duration transportTimeCorrectionDuration = Duration.zero;

  double waitingModulesBeforeUnloader = 0.0;

  late final double waitingModuleSetPoint =
      (1 - waitingModuleCorrection!.baseFraction) /
      waitingModuleCorrection!.fractionPerModule;

  int _maximumNumberOfStunnedModules() {
    var averageNumberOfBirdsPerModule =
        area.productDefinition.averageNumberOfBirdsPerModule;
    double averageModuleDurationInSeconds =
        3600 /
        (area.productDefinition.lineSpeedInShacklesPerHour /
            averageNumberOfBirdsPerModule);

    //assumption
    var maximumTransportCasToUnloaderInSeconds = 3 * 60.0;
    var casStunCycleInSeconds = area.productDefinition.casRecipe!
        .totalDurationWithoutModuleTransport()
        .inSeconds;

    var maximumBufferInSeconds =
        casStunCycleInSeconds + maximumTransportCasToUnloaderInSeconds;

    return (maximumBufferInSeconds / averageModuleDurationInSeconds).ceil();
  }

  Duration _transportTimeCorrection(ModuleCas? longestWaitingCasUnit) {
    if (longestWaitingCasUnit == null ||
        !transportTimeCorrections.containsKey(longestWaitingCasUnit)) {
      return Duration.zero;
    } else {
      return Duration(
        seconds: transportTimeCorrections[longestWaitingCasUnit]!,
      );
    }
  }
}

class WaitingModuleCorrection {
  /// the start interval fraction when there are no waiting modules
  double baseFraction;

  /// how much the start interval fraction increases per module
  double fractionPerModule;

  WaitingModuleCorrection({
    required this.baseFraction,
    required this.fractionPerModule,
  });

  factory WaitingModuleCorrection.withSetPoint({
    double baseFraction = 0.75,
    required double waitingModulesSetPoint,
  }) {
    var fractionPerModule = (1 - baseFraction) / waitingModulesSetPoint;
    return WaitingModuleCorrection(
      baseFraction: baseFraction,
      fractionPerModule: fractionPerModule,
    );
  }

  factory WaitingModuleCorrection.calculated(
    LiveBirdHandlingArea area, {
    double baseFraction = 0.75,
  }) => WaitingModuleCorrection.withSetPoint(
    baseFraction: baseFraction,
    waitingModulesSetPoint: _calculateWaitingModulesSetPoint(area),
  );

  static double _calculateWaitingModulesSetPoint(LiveBirdHandlingArea area) =>
      area.modulesPerCasUnitCycle.toDouble() *
      _setPointWaitingModulesFromUnloader(area);

  static double _setPointWaitingModulesFromUnloader(LiveBirdHandlingArea area) {
    var moduleBirdUnloaders = area.systems.linkedSystems
        .whereType<ModuleBirdUnloader>();
    if (moduleBirdUnloaders.isEmpty) {
      throw Exception(
        '$LiveBirdHandlingArea error: No $ModuleBirdUnloader found',
      );
    }
    if (moduleBirdUnloaders.length > 1) {
      throw Exception(
        '$LiveBirdHandlingArea error: More then 1 $ModuleBirdUnloader found',
      );
    }
    return moduleBirdUnloaders.first.waitingCasModuleLoadSetPoint;
  }

  /// returns a correction on the CAS start interval time based on the number of
  /// waiting modules between the CAS units and the module unloader/tilter
  ///
  /// if there are too few waiting containers: returns < 1 (less interval time between CAS starts)
  /// if correct number of waiting containers: returns 1 (normal interval time between CAS starts)
  /// if there are to many waiting containers: returns > 1 (more interval time)between CAS starts)
  ///
  /// This is calculated with a first-degree math function: f(x)=slope.x+base
  ///
  /// * x= the number of waiting modules
  /// * y = a fraction of the normal CAS start interval time:
  ///   * <1: shorter start interval time, when the there are too few waiting modules
  ///   * =1: normal start interval time, when the correct number of modules are waiting
  ///   * >1: longer start interval time, when the there are too many waiting modules
  /// slope = [fractionPerModule] so how much the fraction will increase for every module waiting too many
  ///         or decrease for every module too few
  /// base =  [baseFraction]: the y-intercept when x=0, so the fraction when no modules are waiting
  double calculateFraction(double nrOfWaitingModules) =>
      fractionPerModule * nrOfWaitingModules + baseFraction;
}

class RollingAverageOverTime implements TimeProcessor {
  Duration windowDuration;
  int windowCount;
  Duration windowInterval;
  Duration elapsed = Duration.zero;
  double Function() countFunction;
  List<double> values = [];
  double _average = 0;

  RollingAverageOverTime({
    required this.windowDuration,
    this.windowCount = 20,
    required this.countFunction,
  }) : windowInterval = windowDuration ~/ windowCount;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    elapsed += jump;
    if (elapsed >= windowInterval) {
      elapsed -= windowInterval;
      values.add(countFunction());
      if (values.length > windowCount) {
        values.removeAt(0);
      }
    }
    _average = values.isEmpty
        ? 0
        : values.reduce((a, b) => a + b) / values.length;
  }

  double get average => _average;
}
