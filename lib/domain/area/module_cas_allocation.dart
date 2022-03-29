import 'package:meyn_lbh_simulation/domain/area/state_machine.dart';
import 'package:meyn_lbh_simulation/domain/util/title_builder.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_cas.dart';

/// Allocates the destination of a [ModuleGroup] of a given location depending on the
/// state of the [ModuleCas] units and transport modules between this position
/// and the [ModuleCas] units
class ModuleCasAllocation extends ActiveCell {
  final Position positionToAllocate;
  List<Route> _cashedRoutesToCasUnits = [];

  ModuleCasAllocation({
    required LiveBirdHandlingArea area,
    required Position position,
    required this.positionToAllocate,
  }) : super(area, position) {
    validatePositionToAllocateIsStateMachineCell();
  }

  @override
  String get name => runtimeType.toString();

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
    var cellToAllocate = area.cellForPosition(positionToAllocate);
    if (cellToAllocate is StateMachineCell) {
      var destination = casWithHighestScore;
      if (destination != null) {
        var moduleGroupToAllocate = cellToAllocate.moduleGroup;
        if (moduleGroupToAllocate != null) {
          moduleGroupToAllocate.destination = destination;
        }
      }
    }
  }

  @override
  String toString() {
    var destination = casWithHighestScore;
    return TitleBuilder(name)
        .appendProperty(
            'destination', destination == null ? 'none' : destination.name)
        .toString();
  }

  List<Route> get routesToCasUnits {
    if (_cashedRoutesToCasUnits.isEmpty) {
      var cellToAllocate =
          area.cellForPosition(positionToAllocate) as StateMachineCell;
      _cashedRoutesToCasUnits = [];
      for (var casUnit in allModuleCasUnits) {
        var route =
            area.findRoute(source: cellToAllocate, destination: casUnit);
        if (route != null) {
          _cashedRoutesToCasUnits.add(route);
        }
      }
    }
    return _cashedRoutesToCasUnits;
  }

  List<ModuleCas> get allModuleCasUnits {
    List<ModuleCas> allCasUnits =
        area.cells.whereType<ModuleCas>().map((cell) => cell).toList();
    return allCasUnits;
  }

  ModuleCas? get casWithHighestScore {
    Map<String, double> casUnitScores = {}; //for debugging
    double highScore = 0;
    ModuleCas? casWithHighestScore;
    for (var route in routesToCasUnits) {
      var score = route.casNewStackScore;
      casUnitScores[route.cas.name] = score;
      if (score > highScore) {
        highScore = score;
        casWithHighestScore = route.cas;
      }
    }

    // print('${casWithHighestScore == null ? 'none' : casWithHighestScore.name} $casUnitScores');
    if (highScore == 0) {
      return null;
    } else {
      return casWithHighestScore;
    }
  }

  @override
  ModuleGroup? get moduleGroup => null;

  void validatePositionToAllocateIsStateMachineCell() {
    var cellToAllocate = area.cellForPosition(positionToAllocate);
    if (cellToAllocate is! StateMachineCell) {
      throw ArgumentError(
          '$ModuleCasAllocation positionToAllocate=$positionToAllocate does not point to a $StateMachineCell');
    }
  }
}
