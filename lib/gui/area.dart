import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/module_tilter.dart';
import 'package:meyn_lbh_simulation/gui/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/gui/module_tilter.dart';
import 'package:meyn_lbh_simulation/gui/unloading_fork_lift_truck.dart';

import '/domain/life_bird_handling_area.dart';
import '/domain/loading_fork_lift_truck.dart';
import '/domain/module.dart';
import '/domain/module_cas.dart';
import '/domain/module_cas_allocation.dart';
import '/domain/module_conveyor.dart';
import '/domain/module_rotating_conveyor.dart';
import '/domain/player.dart';
import '/domain/unloading_fork_lift_truck.dart';
import '/gui/loading_fork_lift_truck.dart';
import '/gui/module_cas.dart';
import '/gui/module_cas_allocation.dart';
import '/gui/module_conveyor.dart';
import '/gui/module_rotating_conveyor.dart';
import 'module.dart';
import 'module_cas_start.dart';
import 'module_stacker.dart';

class AreaWidget extends StatefulWidget {
  AreaWidget({required Key key}) : super(key: key);

  @override
  _AreaWidgetState createState() => _AreaWidgetState();
}

class _AreaWidgetState extends State<AreaWidget> {
  final Player player = Player();

  _AreaWidgetState() {
    player.timerListener((Timer t) {
      setState(() {
        player.scenario.area.onUpdateToNextPointInTime(player.jump);
      });
    });
  }

  @override
  Widget build(BuildContext context) => Container(
    color:Colors.grey.shade200,
    child: CustomMultiChildLayout(
        delegate: AreaWidgetDelegate(player.scenario.area),
        children: createChildren(player.scenario.area)),
  );

  static List<Widget> createChildren(LiveBirdHandlingArea area) {
    List<Widget> children = [];
    children.addAll(createModuleGroupWidgets(area));
    children.addAll(createCellWidgets(area));
    return children;
  }

  static List<Widget> createModuleGroupWidgets(LiveBirdHandlingArea area) {
    var moduleGroupWidgets = area.moduleGroups
        .map<Widget>((moduleGroup) =>
            LayoutId(id: moduleGroup, child: ModuleGroupWidget(moduleGroup)))
        .toList();
    return moduleGroupWidgets;
  }

  static List<Widget> createCellWidgets(LiveBirdHandlingArea area) {
    var cellWidgets = area.cells
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
/// within the given [AreaWidget] size
class AreaWidgetDelegate extends MultiChildLayoutDelegate {
  final LiveBirdHandlingArea area;
  final CellRange cellRange;

  AreaWidgetDelegate(this.area) : cellRange = CellRange(area.cells);

  @override
  void performLayout(Size size) {
    var childSize = _childSize(size);
    var childOffset = _offsetForAllChildren(size, childSize);
    _layoutAndPositionModuleGroups(childSize, childOffset);
    //positioning cells last so they are on top so that the tooltips work
    _layoutAndPositionCells(childSize, childOffset);
  }

  void _layoutAndPositionModuleGroups(Size childSize, Offset childOffset) {
    for (var moduleGroup in area.moduleGroups) {
      layoutChild(moduleGroup, BoxConstraints.tight(childSize));
      var moduleGroupOffSet =
          _createModuleGroupOffset(moduleGroup, childSize, childOffset);
      positionChild(moduleGroup, moduleGroupOffSet);
    }
  }

  void _layoutAndPositionCells(Size childSize, Offset childOffset) {
    for (var cell in area.cells) {
      layoutChild(cell, BoxConstraints.tight(childSize));
      var cellOffset = _createCellOffset(cell.position, childSize, childOffset);
      positionChild(cell, cellOffset);
    }
  }

  Offset _offsetForAllChildren(Size size, Size childSize) {
    var offSet = Offset(
      (size.width - (childSize.width * cellRange.width)) / 2,
      (size.height - (childSize.height * cellRange.height)) / 2,
    );
    return offSet;
  }

  Size _childSize(Size area) {
    var childWidth = area.width / cellRange.width;
    var childHeight = area.height / cellRange.height;
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
    if (cell is UnLoadingForkLiftTruck) {
      return UnLoadingForkLiftTruckWidget(cell);
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
    if (cell is ModuleTilter) {
      return ModuleTilterWidget(cell);
    }
    if (cell is BirdHangingConveyor) {
      return BirdHangingConveyorWidget(cell);
    }
    if (cell is ModuleDeStacker) {
      return ModuleDeStackerWidget(cell);
    }
    if (cell is ModuleStacker) {
      return ModuleStackerWidget(cell);
    }

    if (cell is ModuleCasAllocation) {
      return ModuleCasAllocationWidget(cell);
    }
    if (cell is ModuleCasStart) {
      return ModuleCasStartWidget(cell);
    }
    return EmptyCellWidget();
  }
}
