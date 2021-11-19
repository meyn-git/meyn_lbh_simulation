import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/layout.dart';
import 'package:meyn_lbh_simulation/domain/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/module.dart';
import 'package:meyn_lbh_simulation/domain/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/player.dart';
import 'package:meyn_lbh_simulation/gui/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/gui/module_cas.dart';
import 'package:meyn_lbh_simulation/gui/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/gui/module_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/module_rotating_conveyor.dart';

import 'module.dart';

class LayoutWidget extends StatefulWidget {
  final Player player;

  LayoutWidget({required Key key, required this.player}) : super(key: key);

  @override
  _LayoutWidgetState createState() => _LayoutWidgetState(player);
}

class _LayoutWidgetState extends State<LayoutWidget> {
  Layout layout = Layout();

  _LayoutWidgetState(Player player) {
    player.timerListener((Timer t) {
      setState(() {
        layout.onUpdateToNextPointInTime(player.jump);
      });
    });
  }

  @override
  Widget build(BuildContext context) => CustomMultiChildLayout(
      delegate: LayoutWidgetDelegate(layout), children: createChildren(layout));

  static List<Widget> createChildren(Layout layout) {
    List<Widget> children = [];
    children.addAll(createModuleGroupWidgets(layout));
    children.addAll(createCellWidgets(layout));
    return children;
  }

  static List<Widget> createModuleGroupWidgets(Layout layout) {
    var moduleGroupWidgets = layout.moduleGroups
        .map<Widget>((moduleGroup) =>
            LayoutId(id: moduleGroup, child: ModuleGroupWidget(moduleGroup)))
        .toList();
    return moduleGroupWidgets;
  }

  static List<Widget> createCellWidgets(Layout layout) {
    var cellWidgets = layout.cells
        .map<Widget>((cell) =>
            LayoutId(id: cell, child: CellWidgetFactory.createFor(cell)))
        .toList();
    return cellWidgets;
  }
}

class EmptyCellWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox.fromSize(size: Size.zero);
}

/// Sizes (lets the children do their layout in given [BoxConstraints])
/// and positions all the child widgets ([Cell]s and [ModuleGroup]s)
/// within the given [LayoutWidget] size
class LayoutWidgetDelegate extends MultiChildLayoutDelegate {
  final Layout layout;
  final CellRange cellRange;

  LayoutWidgetDelegate(this.layout) : cellRange = CellRange(layout.cells);

  @override
  void performLayout(Size layoutSize) {
    var childSize = _childSize(layoutSize);
    var childOffset = _offsetForAllChildren(layoutSize, childSize);
    _layoutAndPositionModuleGroups(childSize, childOffset);
    //positioning cells last so they are on top so that the tooltips work
    _layoutAndPositionCells(childSize, childOffset);
  }

  void _layoutAndPositionModuleGroups(Size childSize, Offset childOffset) {
    for (var moduleGroup in layout.moduleGroups) {
      layoutChild(moduleGroup, BoxConstraints.tight(childSize));
      var moduleGroupOffSet =
          _createModuleGroupOffset(moduleGroup, childSize, childOffset);
      positionChild(moduleGroup, moduleGroupOffSet);
    }
  }

  void _layoutAndPositionCells(Size childSize, Offset childOffset) {
    for (var cell in layout.cells) {
      layoutChild(cell, BoxConstraints.tight(childSize));
      var cellOffset = _createCellOffset(cell.position, childSize, childOffset);
      positionChild(cell, cellOffset);
    }
  }

  Offset _offsetForAllChildren(Size layoutSize, Size childSize) {
    var offSet = Offset(
      (layoutSize.width - (childSize.width * cellRange.width)) / 2,
      (layoutSize.height - (childSize.height * cellRange.height)) / 2,
    );
    return offSet;
  }

  Size _childSize(Size layoutSize) {
    var childWidth = layoutSize.width / cellRange.width;
    var childHeight = layoutSize.height / cellRange.height;
    var childSide = min(childWidth, childHeight);
    return Size(childSide, childSide);
  }

  Offset _createModuleGroupOffset(
      ModuleGroup moduleGroup, Size childSize, Offset offSet) {
    var source = moduleGroup.position.source;
    var sourceOffset = _createCellOffset(source.position, childSize, offSet);
    var destination = moduleGroup.position.destination;
    var destinationOffset =
        _createCellOffset(destination.position, childSize, offSet);
    var percentageCompleted = moduleGroup.position.percentageCompleted;
    var moduleGroupOffSet = Offset(
      ((destinationOffset.dx - sourceOffset.dx) * percentageCompleted) +
          sourceOffset.dx,
      ((destinationOffset.dy - sourceOffset.dy) * percentageCompleted) +
          sourceOffset.dy,
    );
    return moduleGroupOffSet;
  }

  Offset _createCellOffset(Position position, Size childSize, Offset offSet) {
    return Offset(
      (position.x - cellRange.minX) * childSize.width + offSet.dx,
      (position.y - cellRange.minY) * childSize.height + offSet.dy,
    );
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) => true;
}

class CellWidgetFactory {
  static Widget createFor(ActiveCell cell) {
    if (cell is LoadingForkLiftTruck) {
      return LoadingForkLiftTruckWidget(cell);
    }
    if (cell is ModuleCas) {
      return ModuleCasWidget(cell);
    }
    if (cell is ModuleConveyor) {
      return ModuleConveyorWidget(cell);
    }
    if (cell is ModuleRotatingConveyor) {
      return ModuleRotatingConveyorWidget(cell);
    }
    if (cell is ModuleCasAllocation) {
      return ModuleCasAllocationWidget(cell);
    }
    return EmptyCellWidget();
  }
}
