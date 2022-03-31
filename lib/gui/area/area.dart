import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/gui/area/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/gui/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/gui/area/unloading_fork_lift_truck.dart';

import 'loading_fork_lift_truck.dart';
import 'module.dart';
import 'module_cas.dart';
import 'module_cas_allocation.dart';
import 'module_cas_start.dart';
import 'module_conveyor.dart';
import 'module_rotating_conveyor.dart';
import 'module_stacker.dart';

class AreaPanel extends StatefulWidget {
  const AreaPanel({required Key key}) : super(key: key);

  @override
  _AreaPanelState createState() => _AreaPanelState();
}

class _AreaPanelState extends State<AreaPanel> implements UpdateListener {
  Player get player => GetIt.instance<Player>();

  _AreaPanelState() {
    player.addUpdateListener(this);
  }

  @override
  void dispose() {
    player.removeUpdateListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => player.scenario == null
      ? const Text("No scenario's")
      : Container(
          color: Colors.grey.shade200,
          child: Column(
            children: [
              FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(player.scenario!.area.toString(),
                      style: const TextStyle(fontSize: 25))),
              Expanded(
                child: CustomMultiChildLayout(
                    delegate: AreaWidgetDelegate(player.scenario!.area),
                    children: createChildren(player.scenario!.area)),
              )
            ],
          ),
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

  @override
  void onUpdate() {
    setState(() {
      if (player.scenario != null) {
        player.scenario!.area.onUpdateToNextPointInTime(player.jump);
      }
    });
  }
}

class EmptyCellWidget extends StatelessWidget {
  const EmptyCellWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(size: Size.zero);
}

/// Sizes (lets the children do their layout in given [BoxConstraints])
/// and positions all the child widgets ([Cell]s and [ModuleGroup]s)
/// within the given [AreaPanel] size
class AreaWidgetDelegate extends MultiChildLayoutDelegate {
  final LiveBirdHandlingArea area;
  final CellRange cashedCellRange;

  AreaWidgetDelegate(this.area) : cashedCellRange = area.cellRange;

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
      (size.width - (childSize.width * cashedCellRange.width)) / 2,
      (size.height - (childSize.height * cashedCellRange.height)) / 2,
    );
    return offSet;
  }

  Size _childSize(Size area) {
    var childWidth = area.width / cashedCellRange.width;
    var childHeight = area.height / cashedCellRange.height;
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
      (position.x - cashedCellRange.minX) * childSize.width + offSet.dx,
      (position.y - cashedCellRange.minY) * childSize.height + offSet.dy,
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
    return const EmptyCellWidget();
  }
}
