import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as material;
import 'package:meyn_lbh_simulation/state_machine_widgets/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/module_cas.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/module_conveyor.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

import 'module_cas_allocation.dart';

class Layout implements TimeProcessor {
  final List<ActiveCell> cells = [];
  final List<ModuleGroup> moduleGroups = [];
  int secondsSinceStart = 1;
  int moduleSequenceNumber = 0;

  Layout() {
    put(LoadingForkLiftTruck(
        layout: this,
        position: Position(2, 1),
        outFeedDirection: CardinalDirection.east,
        createModuleGroup: () => ModuleGroup(
              destination: Position(3, 1),
              doorDirection: CardinalDirection.north.toCompassDirection(),
              position: ModulePosition.forCel(
                  this.cellForPosition(Position(2, 1)) as StateMachineCell),
              firstModule: Module(
                  sequenceNumber: ++moduleSequenceNumber, nrOfBirds: 400),
              secondModule: Module(
                  sequenceNumber: ++moduleSequenceNumber, nrOfBirds: 400),
            )));
    // put(
    //     2,
    //     1,
    //     ModuleConveyor(
    //       layout: this,
    //       seqNr: 1,
    //       inFeedPosition: CardinalDirection.west,
    //     ));
    put(ModuleConveyor(
      layout: this,
      position: Position(3, 1),
      seqNr: 2,
      inFeedDirection: CardinalDirection.west,
    ));

    put(ModuleRotatingConveyor(
      layout: this,
      position: Position(4, 1),
      seqNr: 1,
      homingDirection: CardinalDirection.north,
      defaultPositionWhenIdle: CardinalDirection.west,
    ));
    put(ModuleCas(
        layout: this,
        position: Position(3, 2),
        seqNr: 1,
        inAndOutFeedDirection: CardinalDirection.east,
        moduleDestinationAfterStunning: Position(4, 3)));
    put(ModuleRotatingConveyor(
      layout: this,
      position: Position(4, 2),
      seqNr: 2,
      homingDirection: CardinalDirection.north,
    ));
    put(ModuleConveyor(
      layout: this,
      position: Position(4, 3),
      seqNr: 3,
      inFeedDirection: CardinalDirection.north,
    ));
    put(ModuleCasAllocation(
      layout: this,
      position: Position(1, 3),
      positionToAllocate: Position(3, 1),
    ));
  }

  Cell neighbouringCell(StateMachineCell cell, CardinalDirection direction) {
    Position relativePosition = cell.position.neighbour(direction);
    return cellForPosition(relativePosition);
  }

  void put(ActiveCell cell) {
    checkIfPositionIsUnique(cell.position);
    checkIfNameIsUnique(cell);
    cells.add(cell);
  }

  void checkIfPositionIsUnique(Position position) {
    if (cells.map((cell) => cell.position).contains(position))
      throw new Exception('$position was already defined');
  }

  checkIfNameIsUnique(ActiveCell cell) {
    bool exists = cells
        .any((existingStateMachine) => cell.name == existingStateMachine.name);
    if (exists)
      throw Exception('StateMachine name: ${cell.name} is not unique');
  }

  Cell cellForPosition(Position positionToFind) {
    var foundCell =
        cells.firstWhereOrNull((cell) => cell.position == positionToFind);
    return foundCell ?? EmptyCell();
  }

  @override
  processNextTimeFrame(Duration jump) {
    secondsSinceStart++;
    cells.forEach((cell) {
      cell.processNextTimeFrame(jump);
    });
    moduleGroups.forEach((moduleGroup) {
      moduleGroup.processNextTimeFrame(jump);
    });
  }

  Route? findRoute({
    required StateMachineCell source,
    required StateMachineCell destination,
    Route routeSoFar = const Route.empty(),
  }) {
    if (source is! StateMachineCell || destination is! StateMachineCell) {
      return null;
    }
    if (source.position == destination.position) {
      return Route([...routeSoFar, destination]);
    }
    routeSoFar = Route([...routeSoFar, source]);
    for (var direction in CardinalDirection.values) {
      var neighbour = neighbouringCell(source, direction);
      if (neighbour is StateMachineCell &&
          neighbour.isFeedIn(direction.opposite) &&
          !routeSoFar.contains(neighbour)) {
        // recursive call
        var foundRoute = findRoute(
          source: neighbour,
          destination: destination,
          routeSoFar: routeSoFar,
        );
        if (foundRoute != null) {
          return foundRoute;
        }
      }
    }
    // tried all directions, no success
    return null;
  }
}


class LayoutWidget extends material.StatefulWidget {
  @override
  _LayoutWidgetState createState() => _LayoutWidgetState();
}

class _LayoutWidgetState extends material.State<LayoutWidget> {
  Layout layout = Layout();

  _LayoutWidgetState() {
    const interval = const Duration(milliseconds: 200);
    Timer.periodic(interval, (Timer t) {
      setState(() {
        layout.processNextTimeFrame(const Duration(seconds: 1));
      });
    });
  }

  @override
  material.Widget build(material.BuildContext context) => material.CustomMultiChildLayout (
            delegate: LayoutWidgetDelegate(layout),
            children: createChildren(layout));

  static List<material.Widget> createChildren(layout) => layout.cells
      .map<material.Widget>((cell) => material.LayoutId(id: cell, child: cell.widget))
      .toList();
}

/// positions all the child widgets
class LayoutWidgetDelegate extends material.MultiChildLayoutDelegate {
  final List<ActiveCell> cells;
  final CellRange cellRange;

  LayoutWidgetDelegate(Layout layout)
      : cells = layout.cells,
        cellRange = CellRange(layout.cells);

  @override
  void performLayout(material.Size size) {
    var childWidth = size.width / cellRange.width;
    var childHeight = size.height / cellRange.height;
    var childSide = min(childWidth, childHeight);
    material.Size childSize = material.Size(childSide, childSide);
    material.Offset offSet = material.Offset(
      (size.width - (childSide * cellRange.width)) / 2,
      (size.height - (childSide * cellRange.height)) / 2,
    );
    for (ActiveCell cell in cells) {
      layoutChild(cell, material.BoxConstraints.tight(childSize));
      positionChild(
          cell,
          material.Offset(
            (cell.position.x - cellRange.minX) * childSide + offSet.dx,
            (cell.position.y - cellRange.minY) * childSide + offSet.dy,
          ));
    }
  }

  @override
  bool shouldRelayout(covariant material.MultiChildLayoutDelegate oldDelegate) => false;
}

class CellRange {
  int? _minX;
  int? _maxX;
  int? _minY;
  int? _maxY;

  CellRange(List<ActiveCell> cells) {
    if (cells.isEmpty) {
      throw ('You must put cells in the layout as part of the Layout constructor');
    }
    Position firstPosition = cells.first.position;
    _minX = firstPosition.x;
    _maxX = firstPosition.x;
    _minY = firstPosition.y;
    _maxY = firstPosition.y;
    cells.map<Position>((cell) => cell.position).forEach((position) {
      _minX = min(_minX!, position.x);
      _maxX = max(_maxX!, position.x);
      _minY = min(_minY!, position.y);
      _maxY = max(_maxY!, position.y);
    });
  }

  int get minX => _minX!;

  int get maxX => _maxX!;

  int get minY => _minY!;

  int get maxY => _maxY!;

  int get width => (minX - maxX).abs() + 1;

  int get height => (minY - maxY).abs() + 1;
}

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return 'Position{x: $x, y: $y}';
  }

  Position neighbour(CardinalDirection relativePosition) {
    switch (relativePosition) {
      case CardinalDirection.north:
        return Position(x, y - 1);
      case CardinalDirection.east:
        return Position(x + 1, y);
      case CardinalDirection.south:
        return Position(x, y + 1);
      case CardinalDirection.west:
        return Position(x - 1, y);
    }
  }
}

/// A [ModuleGroup] can be one or 2 modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side
class ModuleGroup extends TimeProcessor {
  final Module firstModule;
  final Module? secondModule;
  CompassDirection doorDirection;
  Position destination;
  ModulePosition position;

  ModuleGroup({
    required this.firstModule,
    this.secondModule,
    required this.doorDirection,
    required this.destination,
    required this.position,
  });

  int get numberOfModules => 1 + ((secondModule == null) ? 0 : 1);

  @override
  processNextTimeFrame(Duration jump) {
    position.processNextTimeFrame(this, jump);
  }
}

/// A module location is either at a given position or traveling between 2 positions
class ModulePosition {
  StateMachineCell source;
  StateMachineCell destination;
  Duration remainingDuration;

  ModulePosition.forCel(StateMachineCell cell)
      : source = cell,
        destination = cell,
        remainingDuration = Duration.zero;

  ModulePosition.betweenCells({
    required this.source,
    required this.destination,
  }) : remainingDuration = findLongestDuration(source, destination);

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
}

class Module {
  final int sequenceNumber;
  final int nrOfBirds;
  DateTime? startStun;

  Module({
    required this.sequenceNumber,
    required this.nrOfBirds,
  });

  Module get clone => Module(
        sequenceNumber: sequenceNumber,
        nrOfBirds: nrOfBirds,
      );

  @override
  String toString() {
    return 'Module{sequenceNumber: $sequenceNumber, nrOfBirds: $nrOfBirds}';
  }
}

abstract class Cell {
  material.Widget get widget;

  /// whether a given direction can feed out modules
  bool isFeedIn(CardinalDirection inFeedDirection);

  /// waiting to feed in module(s) from the preceding transport system
  bool okToFeedIn(CardinalDirection inFeedDirection);

  /// whether a given direction can feed out modules
  bool isFeedOut(CardinalDirection outFeedDirection);

  /// used to request to turn the turn table to this position in advance.
  bool almostOkToFeedOut(CardinalDirection outFeedDirection);

  /// module(s) waiting to feed out to next transport system
  bool okToFeedOut(CardinalDirection outFeedDirection);

  /// to be increased with [nrOfModules] when the StateMachine has fed out
  int nrOfModulesMoved = 0;

  ModuleGroup? get moduleGroup;
}

class EmptyCell extends Cell {
  static EmptyCell _emptyCell = EmptyCell._();

  EmptyCell._();

  factory EmptyCell() => _emptyCell;

  @override
  material.Widget get widget => material.SizedBox.fromSize(
        size: material.Size(20, 20),
      );

  @override
  bool almostOkToFeedOut(CardinalDirection direction) => false;

  @override
  bool okToFeedIn(CardinalDirection direction) => false;

  @override
  bool okToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => false;

  @override
  bool isFeedOut(CardinalDirection direction) => false;

  @override
  ModuleGroup? get moduleGroup => null;
}

enum CardinalDirection { north, east, south, west }

extension CardinalDirectionExtension on CardinalDirection {
  CompassDirection toCompassDirection() {
    switch (this) {
      case CardinalDirection.north:
        return CompassDirection(0);
      case CardinalDirection.east:
        return CompassDirection(90);
      case CardinalDirection.south:
        return CompassDirection(180);
      case CardinalDirection.west:
        return CompassDirection(270);
    }
  }

  CardinalDirection get opposite {
    switch (this) {
      case CardinalDirection.north:
        return CardinalDirection.south;
      case CardinalDirection.east:
        return CardinalDirection.west;
      case CardinalDirection.south:
        return CardinalDirection.north;
      case CardinalDirection.west:
        return CardinalDirection.east;
    }
  }

  bool isParallelTo(CardinalDirection otherDirection) =>
      this == otherDirection || this == otherDirection.opposite;

  bool isPerpendicularTo(CardinalDirection otherDirection) =>
      !isParallelTo(otherDirection);
}

class CompassDirection {
  final double degrees;
  static final double max = 360;

  CompassDirection(double degrees) : degrees = degrees % max;

  CompassDirection rotate(double rotation) {
    return CompassDirection(degrees + rotation);
  }

  double error = 1;

  CardinalDirection? toCardinalDirection() {
    for (var cardinalDirection in CardinalDirection.values) {
      if (cardinalDirection.toCompassDirection().degrees == degrees) {
        return cardinalDirection;
      }
      // if (degrees >
      //         cardinalDirection.toCompassDirection().rotate(-error).degrees &&
      //     degrees <
      //         cardinalDirection.toCompassDirection().rotate(error).degrees) {
      //   return cardinalDirection;
      // }
    }
    return null;
  }

  double clockWiseDistanceInDegrees(CompassDirection destination) {
    if (this.degrees < destination.degrees) {
      return destination.degrees - this.degrees;
    } else {
      return max - this.degrees + destination.degrees;
    }
  }

  double counterClockWiseDistanceInDegrees(CompassDirection destination) {
    if (this.degrees > destination.degrees) {
      return this.degrees - destination.degrees;
    } else {
      return this.degrees + max - destination.degrees;
    }
  }

  @override
  String toString() => degrees.toString();
}

abstract class TimeProcessor {
  /// method to change the state of the object to the next point in time
  processNextTimeFrame(Duration jump);
}

abstract class ActiveCell extends Cell implements TimeProcessor {
  final Layout layout;
  final Position position;

  ActiveCell(this.layout, this.position);

  String get name;
}

/// A list of [StateMachineCell]s to get to a [ModuleCas] within a [Layout]
class Route extends DelegatingList<StateMachineCell> {
  Route(
    List<StateMachineCell> cellRoute,
  ) : super(cellRoute);

  const Route.empty() : super(const []);

  /// [ModuleCas] score for getting a new, un-stunned [ModuleGroup].
  /// =0 when [ModuleCas] is NOT waiting for a new un-stunned [ModuleGroup]
  ///    or there is already a new un-stunned [ModuleGroup].
  /// >0 the higher the score the higher the priority (e.g. when more [Route]s are competing
  ///    - the longest route has the highest score (send stacks to furthest units first)
  ///    - the [ModuleCas] that is most ready to receive a module will get the highest
  ///      score when routes of equal length are competing (see .3, .2, .1).
  double get casNewStackScore {
    if (_stackOnRoute()) {
      return 0;
    }

    if (casIsOkToFeedIn) {
      return length + 0.3;
    } else if (casIsOkToFeedOut) {
      return length + 0.2;
    } else if (casIsAlmostOkToFeedOut) {
      return length + 0.1;
    } else {
      return 0;
    }
  }

  bool _stackOnRoute() => this.any((celOnRoute) =>
      celOnRoute.moduleGroup != null &&
      celOnRoute.moduleGroup!.destination == cas.position);

  bool get casIsOkToFeedIn => cas.okToFeedIn(cas.inAndOutFeedDirection);

  bool get casIsOkToFeedOut => cas.okToFeedOut(cas.inAndOutFeedDirection);

  bool get casIsAlmostOkToFeedOut =>
      cas.almostOkToFeedOut(cas.inAndOutFeedDirection);

  ModuleCas get cas {
    var destination = last;
    if (destination is ModuleCas) {
      return destination;
    } else {
      throw Exception('The last cell in the route is not a $ModuleCas');
    }
  }
}
