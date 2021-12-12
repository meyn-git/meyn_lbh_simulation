import 'package:meyn_lbh_simulation/domain/title_builder.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_cas.dart';
import 'state_machine.dart';

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
    Route? route = findRouteWithHighestWaitingForStackScore();
    if (route != null) {
      var cellToAllocate = area.cellForPosition(positionToAllocate);
      if (cellToAllocate is StateMachineCell) {
        var moduleGroupToAllocate = cellToAllocate.moduleGroup;
        if (moduleGroupToAllocate != null) {
          moduleGroupToAllocate.destination = route.cas;
        }
      }
    }
  }

  @override
  String toString() {
    var route = findRouteWithHighestWaitingForStackScore();
    return TitleBuilder(name)
        .appendProperty('bestRoute', route == null ? 'none' : route.cas.name)
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
    List<ModuleCas> allCasUnits = area.cells
        .where((cell) => cell is ModuleCas)
        .map((cell) => cell as ModuleCas)
        .toList();
    return allCasUnits;
  }

  Route? findRouteWithHighestWaitingForStackScore() {
    routesToCasUnits
        .sort((a, b) => a.casNewStackScore.compareTo(b.casNewStackScore) * -1);
    Route bestCandidate = routesToCasUnits.first;
    if (bestCandidate.casNewStackScore == 0) {
      return null;
    } else {
      return bestCandidate;
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
