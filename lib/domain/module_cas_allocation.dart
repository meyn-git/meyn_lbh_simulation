import 'module_cas.dart';
import 'state_machine.dart';
import 'layout.dart';
import 'module.dart';

/// Allocates the destination of a [ModuleGroup] of a given location depending on the
/// state of the [ModuleCas] units and transport modules between this position
/// and the [ModuleCas] units
class ModuleCasAllocation extends ActiveCell {
  final Position positionToAllocate;
  List<Route> _cashedRoutesToCasUnits = [];

  ModuleCasAllocation({
    required Layout layout,
    required Position position,
    required this.positionToAllocate,
  }) : super(layout, position) {
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
      var cellToAllocate = layout.cellForPosition(positionToAllocate);
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
    return name;
  }

  List<Route> get routesToCasUnits {
    if (_cashedRoutesToCasUnits.isEmpty) {
      var cellToAllocate = layout.cellForPosition(positionToAllocate) as StateMachineCell;
      _cashedRoutesToCasUnits = [];
      for (var casUnit in allModuleCasUnits) {
        var route = layout.findRoute(source: cellToAllocate, destination: casUnit);
        if (route != null) {
          _cashedRoutesToCasUnits.add(route);
        }
      }
    }
    return _cashedRoutesToCasUnits;
  }

  List<ModuleCas> get allModuleCasUnits {
    List<ModuleCas> allCasUnits = layout.cells
        .where((cell) => cell is ModuleCas)
        .map((cell) => cell as ModuleCas)
        .toList();
    return allCasUnits;
  }

  Route? findRouteWithHighestWaitingForStackScore() {
    routesToCasUnits.sort((a, b) => a.casNewStackScore.compareTo(b.casNewStackScore)*-1);
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
    var cellToAllocate = layout.cellForPosition(positionToAllocate);
    if (cellToAllocate is! StateMachineCell) {
      throw ArgumentError('$ModuleCasAllocation positionToAllocate=$positionToAllocate does not point to a $StateMachineCell');
    }
  }
}

