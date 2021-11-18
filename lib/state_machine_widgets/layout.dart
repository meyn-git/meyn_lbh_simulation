import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as material;
import 'package:meyn_lbh_simulation/state_machine_widgets/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/module_cas.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/module_conveyor.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

import 'module.dart';
import 'module_cas_allocation.dart';

class Layout implements TimeProcessor {
  final List<ActiveCell> cells = [];
  final List<ModuleGroup> moduleGroups = [];
  Duration durationSinceStart = Duration.zero;
  int moduleSequenceNumber = 0;

  Layout() {
    put(LoadingForkLiftTruck(
        layout: this,
        position: Position(2, 1),
        outFeedDirection: CardinalDirection.east,
        createModuleGroup: () => ModuleGroup(
              destination: this.cellForPosition(Position(3, 1)) as StateMachineCell,
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
        moduleDestinationPositionAfterStunning: Position(4, 3)));
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

  /// Updates all the [ActiveCell]s and [ModuleGroup]s
  @override
  onUpdateToNextPointInTime(Duration jump) {
    durationSinceStart = durationSinceStart + jump;
    cells.forEach((cell) {
      cell.onUpdateToNextPointInTime(jump);
    });
    moduleGroups.forEach((moduleGroup) {
      moduleGroup.onUpdateToNextPointInTime(jump);
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
        layout.onUpdateToNextPointInTime(const Duration(seconds: 1));
      });
    });
  }

  @override
  material.Widget build(material.BuildContext context) =>
      material.CustomMultiChildLayout(
          delegate: LayoutWidgetDelegate(layout),
          children: createChildren(layout));

  static List<material.Widget> createChildren(Layout layout) {
    List<material.Widget> children = [];
    children.addAll(createModuleGroupWidgets(layout));
    children.addAll(createCellWidgets(layout));
    return children;
  }

  static List<material.Widget> createModuleGroupWidgets(Layout layout) {
    var moduleGroupWidgets = layout.moduleGroups
        .map<material.Widget>((moduleGroup) => material.LayoutId(
            id: moduleGroup, child: ModuleGroupWidget(moduleGroup)))
        .toList();
    return moduleGroupWidgets;
  }

  static List<material.Widget> createCellWidgets(Layout layout) {
    var cellWidgets = layout.cells
        .map<material.Widget>(
            (cell) => material.LayoutId(id: cell, child: cell.widget))
        .toList();
    return cellWidgets;
  }
}

/// Sizes (lets the children do their layout in given [material.BoxConstraints])
/// and positions all the child widgets ([Cell]s and [ModuleGroup]s)
/// within the given [LayoutWidget] size
class LayoutWidgetDelegate extends material.MultiChildLayoutDelegate {
  final Layout layout;
  final CellRange cellRange;

  LayoutWidgetDelegate(this.layout) : cellRange = CellRange(layout.cells);

  @override
  void performLayout(material.Size layoutSize) {
    var childSize = _childSize(layoutSize);
    var childOffset = _offsetForAllChildren(layoutSize, childSize);
    _layoutAndPositionModuleGroups(childSize, childOffset);
    //positioning cells last so they are on top so that the tooltips work
    _layoutAndPositionCells(childSize, childOffset);
  }

  void _layoutAndPositionModuleGroups(
      material.Size childSize, material.Offset childOffset) {
    for (var moduleGroup in layout.moduleGroups) {
      layoutChild(moduleGroup, material.BoxConstraints.tight(childSize));
      var moduleGroupOffSet =
          _createModuleGroupOffset(moduleGroup, childSize, childOffset);
      positionChild(moduleGroup, moduleGroupOffSet);
    }
  }

  void _layoutAndPositionCells(
      material.Size childSize, material.Offset childOffset) {
    for (var cell in layout.cells) {
      layoutChild(cell, material.BoxConstraints.tight(childSize));
      var cellOffset = _createCellOffset(cell.position, childSize, childOffset);
      positionChild(cell, cellOffset);
    }
  }

  material.Offset _offsetForAllChildren(
      material.Size layoutSize, material.Size childSize) {
    var offSet = material.Offset(
      (layoutSize.width - (childSize.width * cellRange.width)) / 2,
      (layoutSize.height - (childSize.height * cellRange.height)) / 2,
    );
    return offSet;
  }

  material.Size _childSize(material.Size layoutSize) {
    var childWidth = layoutSize.width / cellRange.width;
    var childHeight = layoutSize.height / cellRange.height;
    var childSide = min(childWidth, childHeight);
    return material.Size(childSide, childSide);
  }

  material.Offset _createModuleGroupOffset(ModuleGroup moduleGroup,
      material.Size childSize, material.Offset offSet) {
    var source = moduleGroup.position.source;
    var sourceOffset = _createCellOffset(source.position, childSize, offSet);
    var destination = moduleGroup.position.destination;
    var destinationOffset =
        _createCellOffset(destination.position, childSize, offSet);
    var percentageCompleted = moduleGroup.position.percentageCompleted;
    var moduleGroupOffSet = material.Offset(
      ((destinationOffset.dx - sourceOffset.dx) * percentageCompleted) +
          sourceOffset.dx,
      ((destinationOffset.dy - sourceOffset.dy) * percentageCompleted) +
          sourceOffset.dy,
    );
    return moduleGroupOffSet;
  }

  material.Offset _createCellOffset(
      Position position, material.Size childSize, material.Offset offSet) {
    return material.Offset(
      (position.x - cellRange.minX) * childSize.width + offSet.dx,
      (position.y - cellRange.minY) * childSize.height + offSet.dy,
    );
  }

  @override
  bool shouldRelayout(
          covariant material.MultiChildLayoutDelegate oldDelegate) =>
      true;
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

abstract class Cell {
  material.Widget get widget;

  /// whether a given direction can feed out modules
  bool isFeedIn(CardinalDirection inFeedDirection);

  /// waiting to feed in a [ModuleGroup] from the preceding transport system
  /// e.g.: when a [StateMachineCell] is in WaitToFeedIn
  bool waitingToFeedIn(CardinalDirection inFeedDirection);

  /// whether a given direction can feed out modules
  bool isFeedOut(CardinalDirection outFeedDirection);

  /// used to request to turn the turn table to this position in advance.
  bool almostWaitingToFeedOut(CardinalDirection outFeedDirection);

  /// module(s) waiting to feed out to next transport system
  /// e.g. when a [StateMachineCell] is WaitToFeedOut
  bool waitingToFeedOut(CardinalDirection outFeedDirection);

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
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedIn(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) => false;

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
  onUpdateToNextPointInTime(Duration jump);
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
    if (_moduleGroupGoingTo(cas)) {
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

  bool _moduleGroupGoingTo(ModuleCas cas) => cas.layout.moduleGroups
      .any((moduleGroup) => moduleGroup.destination == cas);

  bool get casIsOkToFeedIn => cas.waitingToFeedIn(cas.inAndOutFeedDirection);

  bool get casIsOkToFeedOut => cas.waitingToFeedOut(cas.inAndOutFeedDirection);

  bool get casIsAlmostOkToFeedOut =>
      cas.almostWaitingToFeedOut(cas.inAndOutFeedDirection);

  ModuleCas get cas {
    var destination = last;
    if (destination is ModuleCas) {
      return destination;
    } else {
      throw Exception('The last cell in the route is not a $ModuleCas');
    }
  }
}
