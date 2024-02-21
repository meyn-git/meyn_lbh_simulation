import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:meyn_lbh_simulation/domain/area/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/loading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/area/machine.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/module_rotating_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/domain/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/domain/site/scenario.dart';
import 'package:meyn_lbh_simulation/gui/area/bird_hanging_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/drawer.dart';
import 'package:meyn_lbh_simulation/gui/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_unloader.dart';
import 'package:meyn_lbh_simulation/gui/area/module_tilter.dart';
import 'package:meyn_lbh_simulation/gui/area/unloading_fork_lift_truck.dart';
import 'package:meyn_lbh_simulation/gui/style.dart';

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
  AreaPanelState createState() => AreaPanelState();
}

class AreaPanelState extends State<AreaPanel> implements UpdateListener {
  Player get player => GetIt.instance<Player>();

  AreaPanelState() {
    player.addUpdateListener(this);
  }

  @override
  void dispose() {
    player.removeUpdateListener(this);
    super.dispose();
  }

  String get scenarioTitle =>
      '${player.scenario!.site}-${player.scenario!.area}';

  @override
  Widget build(BuildContext context) {
    var style = LiveBirdsHandlingStyle.of(context);
    var areaWidgetDelegate = AreaWidgetDelegate(player.scenario!);
    return player.scenario == null
        ? const Text("No scenario's")
        : Container(
            color: style.backGroundColor,
            child: Column(
              children: [
                FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text(scenarioTitle,
                        style: const TextStyle(fontSize: 25))),
                Expanded(
                  child: InteractiveViewer(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Listener(
                        onPointerUp: (event) =>
                            onPointerUp(event, areaWidgetDelegate, constraints),
                        child: CustomMultiChildLayout(
                            delegate: areaWidgetDelegate,
                            children: createChildren(player.scenario!)),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
  }

  static List<Widget> createChildren(Scenario scenario) {
    List<Widget> children = [];
    var area = scenario.area;
    children.addAll(createModuleGroupWidgets(area));
    children.addAll(createMachineWidgets(area, scenario.layout));
    children.addAll(createDrawerWidgets(area, scenario.layout));
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

  static List<Widget> createMachineWidgets(
      LiveBirdHandlingArea area, MachineLayout layout) {
    List<Widget> widgets = [];
    for (var machine in area.machines) {
      widgets.add(LayoutId(id: machine, child: MachineWidget(layout, machine)));
    }
    return widgets;
  }

  static List<Widget> createDrawerWidgets(
      LiveBirdHandlingArea area, MachineLayout layout) {
    List<Widget> widgets = [];
    var drawers = area.drawers;
    for (var drawer in drawers) {
      widgets
          .add(LayoutId(id: drawer, child: GrandeDrawerWidget(layout, drawer)));
    }
    return widgets;
  }

  static List<Widget> createCellWidgets(LiveBirdHandlingArea area) {
    var cellWidgets = area.cells
        .map<Widget>(
            (cell) => LayoutId(id: cell, child: createCellWidgetFor(cell)))
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

  void onPointerUp(PointerUpEvent event, AreaWidgetDelegate areaWidgetDelegate,
      BoxConstraints constraints) {
    var size = areaWidgetDelegate.getSize(constraints);
    var objectsToMonitor = <Object>{};
    objectsToMonitor
        .addAll(cellsToAddToMonitor(event, areaWidgetDelegate, size));
    objectsToMonitor
        .addAll(machinesToAddToMonitor(event, areaWidgetDelegate, size));
    GetIt.instance<Player>().objectsToMonitor.addAll(objectsToMonitor);
  }

  List<Cell> cellsToAddToMonitor(
      PointerUpEvent event, AreaWidgetDelegate areaWidgetDelegate, Size size) {
    var cellSize = areaWidgetDelegate._childSize(size);
    var padding = areaWidgetDelegate._offsetForAllChildren(size, cellSize);
    var pointer = event.position - padding;
    var clickedCellPosition = Position(
      pointer.dx ~/ cellSize.width + 1,
      pointer.dy ~/ cellSize.height + 1,
    );
    var cells = areaWidgetDelegate.area.cells;
    var clickedCells =
        cells.where((cell) => cell.position == clickedCellPosition);
    if (clickedCells.isEmpty) {
      return [];
    }
    var clickedCell = clickedCells.first;
    if (clickedCell is EmptyCell) {
      return [];
    }
    return linkedCells(cells, clickedCell);
  }

  List<Machine> machinesToAddToMonitor(
      PointerUpEvent event, AreaWidgetDelegate areaWidgetDelegate, Size size) {
    var clickedMachines = <Machine>[];
    var cellSize = areaWidgetDelegate._childSize(size);
    var padding = areaWidgetDelegate._offsetForAllChildren(size, cellSize);
    var pointer = event.position - padding - const Offset(0, 85);
    var sizePerMeter = areaWidgetDelegate._sizePerMeter(cellSize);
    for (var machine in areaWidgetDelegate.area.machines) {
      if (clickedOnMachine(
        areaWidgetDelegate.layout,
        machine,
        sizePerMeter,
        pointer,
      )) {
        clickedMachines.add(machine);
      }
    }
    return clickedMachines;
  }

  bool clickedOnMachine(MachineLayout layout, Machine machine,
      double sizePerMeter, Offset pointer) {
    /// TODO: Listener only listens when there is a child where clicked.
    /// We place all machines facing north and then rotate,
    /// but the size is still facing north.
    /// The begin end end of a long conveyor that is rotated 90 degrees
    /// is therefore not clickable.
    /// We need to extend its size to Size(max(s.x,s.y),max(s.x,s.y))

    var pointerWhenMachineFacesNorth = rotateOffset(
        pointer,
        layout.centerOf(machine).toOffset() * sizePerMeter,
        -layout.rotationOf(machine).toRadians());
    var topLeftWhenMachineFacesNorth =
        layout.topLeftWhenFacingNorthOf(machine).toOffset() * sizePerMeter;
    var bottomRightWhenMachineFacesNorth = topLeftWhenMachineFacesNorth +
        machine.sizeWhenFacingNorth.toOffset().toOffset() * sizePerMeter;
    return pointerWhenMachineFacesNorth >= topLeftWhenMachineFacesNorth &&
        pointerWhenMachineFacesNorth <= bottomRightWhenMachineFacesNorth;
  }

  Offset rotateOffset(Offset input, Offset center, double angle) {
    final double x = input.dx;
    final double y = input.dy;
    final double rx0 = center.dx;
    final double ry0 = center.dy;
    final double x0 = (x - rx0) * cos(angle) - (y - ry0) * sin(angle) + rx0;
    final double y0 = (x - rx0) * sin(angle) + (y - ry0) * cos(angle) + ry0;
    return Offset(x0, y0);
  }

  List<Cell> linkedCells(List<ActiveCell> cells, ActiveCell clickedCell) {
    if (clickedCell is ModuleCas) {
      return [...cells.whereType<ModuleCasStart>(), clickedCell];
    }
    var moduleCasAllocations = cells.whereType<ModuleCasAllocation>();
    for (var moduleCasAllocation in moduleCasAllocations) {
      if ((moduleCasAllocation).positionToAllocate == clickedCell.position) {
        return [moduleCasAllocation, clickedCell];
      }
    }
    return [clickedCell];
  }
}

class EmptyCellWidget extends StatelessWidget {
  const EmptyCellWidget({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(size: Size.zero);
}

/// Sizes (lets the children do their layout in given [BoxConstraints])
/// and positions all the child widgets ([Cell]s and [ModuleGroup]s)
/// within the given [AreaPanel] size
class AreaWidgetDelegate extends MultiChildLayoutDelegate {
  final LiveBirdHandlingArea area;
  final CellRange cashedCellRange;
  final MachineLayout layout;

  AreaWidgetDelegate(Scenario scenario)
      : area = scenario.area,
        cashedCellRange = scenario.area.cellRange,
        layout = scenario.layout;

  @override
  void performLayout(Size size) {
    var childSize = _childSize(size);
    var childOffset = _offsetForAllChildren(size, childSize);
    _layoutAndPositionModuleGroups(childSize, childOffset);
    _layoutAndPositionMachines(childSize, childOffset);
    _layoutAndPositionDrawers(childSize, childOffset);
    _layoutAndPositionCells(childSize, childOffset);
  }

  void _layoutAndPositionMachines(Size childSize, Offset childOffset) {
    var sizePerMeter = _sizePerMeter(childSize);
    for (var machine in area.machines) {
      var size = machine.sizeWhenFacingNorth.toSize() * sizePerMeter;
      layoutChild(machine, BoxConstraints.tight(size));
      var topLeft =
          childOffset + layout._topLefts[machine]!.toOffset() * sizePerMeter;
      positionChild(machine, topLeft);
    }
  }

  double _sizePerMeter(Size childSize) =>
      childSize.width / 3.5; //assuming 1 child == 3 meter

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

  void _layoutAndPositionDrawers(Size childSize, Offset childOffset) {
    var sizePerMeter = _sizePerMeter(childSize);
    Size? size;
    for (var drawer in area.drawers) {
      if (size == null) {
        var length = drawer.outSideLengthInMeters * sizePerMeter;
        size = Size(length, length);
      }
      layoutChild(drawer, BoxConstraints.tight(size));
      var drawerPosition = childOffset +
          drawer.position.topLeft(layout).toOffset() * sizePerMeter;
      positionChild(drawer, drawerPosition);
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

/// Calculates the [_topLefts], [_centers], [_rotations] and [_drawerPaths] of
/// all machines and caches the values for performance, because we only need
/// to calculate this once per [Scenario]
class MachineLayout {
  final Map<Machine, OffsetInMeters> _topLefts = {};
  final Map<Machine, OffsetInMeters> _centers = {};
  final Map<Machine, CompassDirection> _rotations = {};
  final Map<DrawerConveyor, DrawerPath> _drawerPaths = {};
  final Map<DrawerConveyor, OffsetInMeters> _drawerStarts = {};
  late SizeInMeters size = _size();

  final Machines machines;

  MachineLayout(
      {required this.machines,
      CompassDirection startDirection = const CompassDirection(0)}) {
    _placeMachines(startDirection,
        const OffsetInMeters(metersFromLeft: 7.5, metersFromTop: -7.5));
  }

  void _placeMachines(
      CompassDirection startDirection,
      //TODO remove offset when Cells have been made as Machines
      OffsetInMeters offset) {
    if (machines.isEmpty) {
      return;
    }
    var machine = machines.first;
    var topLeft = OffsetInMeters.zero;
    var rotation = startDirection;
    //place all machines recursively (assuming they are all linked)
    _placeLinkedMachines(machine, topLeft, rotation);
    _validateAllMachinesArePlaced();
    var correction = offsetCorrection() + offset;
    _correctOffsets(_topLefts, correction);
    _correctOffsets(_centers, correction);
    _correctOffsets(_drawerStarts, correction);
  }

  void _correctOffsets(
      Map<Machine, OffsetInMeters> map, OffsetInMeters correction) {
    for (var entry in map.entries) {
      map[entry.key] = entry.value + correction;
    }
  }

  /// Correction for all [OffsetInMeters] so that there are no negative values
  OffsetInMeters offsetCorrection() {
    var minX = _topLefts.values.map((pos) => pos.metersFromLeft).reduce(min);
    var minY = _topLefts.values.map((pos) => pos.metersFromTop).reduce(min);
    var correction =
        OffsetInMeters(metersFromLeft: minX, metersFromTop: minY) * -1;
    return correction;
  }

  void _placeLinkedMachines(
    Machine machine,
    OffsetInMeters topLeft,
    CompassDirection rotation,
  ) {
    _topLefts[machine] = topLeft;
    _rotations[machine] = rotation;
    _centers[machine] = topLeft + machine.sizeWhenFacingNorth.toOffset() * 0.5;
    if (machine is DrawerConveyor) {
      var toCenter = _centers[machine]!;
      var centerToStart = machine.drawerIn.offsetFromCenter.rotate(rotation);
      _drawerStarts[machine] = toCenter + centerToStart;
      var originalDrawerPath = machine.drawerPath;
      var rotatedDrawerPath = originalDrawerPath.rotate(rotation);
      _drawerPaths[machine] = rotatedDrawerPath;
    }
    for (var link in machine.links) {
      var machine1 = machine;
      var machine1TopLeft = topLeft;
      var machine1Rotation = rotation;
      var machine2 = link.linkedTo.owner;
      if (_unknownPosition(machine2)) {
        var machine2Rotation = rotation +
            link.directionFromCenter +
            link.linkedTo.directionFromCenter.opposite;
        var machine1TopLeftToCenter =
            machine1.sizeWhenFacingNorth.toOffset() * 0.5;
        var machine1CenterToLink =
            link.offsetFromCenter.rotate(machine1Rotation);
        var machine2LinkToCenter =
            link.linkedTo.offsetFromCenter.rotate(machine2Rotation) * -1;
        var machine2CenterToTopLeft =
            machine2.sizeWhenFacingNorth.toOffset() * -0.5;
        var machine2TopLeft = machine1TopLeft +
            machine1TopLeftToCenter +
            machine1CenterToLink +
            machine2LinkToCenter +
            machine2CenterToTopLeft;
        // print('\n'
        //     'machine1:${machine1.runtimeType} size: ${offsetString(machine1.sizeWhenNorthBound.toOffset())}\n'
        //     'machine2:${machine2.runtimeType} size: ${offsetString(machine2.sizeWhenNorthBound.toOffset())}\n'
        //     'machine1TopLeft:${offsetString(machine1TopLeft)}\n'
        //     'machine1TopLeftToCenter:${offsetString(machine1TopLeftToCenter)}\n'
        //     'machine1CenterToLink:${offsetString(machine1CenterToLink)}\n'
        //     'machine2LinkToCenter:${offsetString(machine2LinkToCenter)}\n'
        //     'machine2CenterToTopLeft:${offsetString(machine2CenterToTopLeft)}\n'
        //     'machine2TopLeft:${offsetString(machine2TopLeft)}\n');
        _placeLinkedMachines(machine2, machine2TopLeft, machine2Rotation);
      }
    }
  }

  /// Returns the cached offset from the top left of the [LiveBirdHandlingArea]
  /// to the top left of the [Machine]
  OffsetInMeters topLeftWhenFacingNorthOf(Machine machine) =>
      _topLefts[machine]!;

  /// Returns the cached offset from the top left of the [LiveBirdHandlingArea]
  /// to the center of the [Machine]
  OffsetInMeters centerOf(Machine machine) => _centers[machine]!;

  /// Returns the cached rotation od a [Machine]
  CompassDirection rotationOf(Machine machine) => _rotations[machine]!;

  /// Returns the cached [DrawerPath] of a [Machine]
  DrawerPath drawerPathOf(DrawerConveyor drawerConveyor) =>
      _drawerPaths[drawerConveyor]!;

  /// Returns the cached offset from the top left of the [LiveBirdHandlingArea]
  /// to the start of the [DrawerPath]
  OffsetInMeters drawerStartOf(DrawerConveyor drawerConveyor) =>
      _drawerStarts[drawerConveyor]!;

  String offsetString(OffsetInMeters offset) =>
      '${offset.metersFromLeft.toStringAsFixed(1)},${offset.metersFromTop.toStringAsFixed(1)}';

  bool _unknownPosition(Machine machine) => !_topLefts.keys.contains(machine);

  SizeInMeters _size() {
    if (_topLefts.isEmpty) {
      return SizeInMeters.zero;
    }
    var maxX = _topLefts
        .map((machine, pos) => MapEntry(machine,
            pos.metersFromLeft + machine.sizeWhenFacingNorth.widthInMeters))
        .values
        .max;
    var maxY = _topLefts
        .map((machine, pos) => MapEntry(machine,
            pos.metersFromTop + machine.sizeWhenFacingNorth.heightInMeters))
        .values
        .max;
    return SizeInMeters(widthInMeters: maxX, heightInMeters: maxY);
  }

  void _validateAllMachinesArePlaced() {
    for (var machine in machines) {
      if (_unknownPosition(machine)) {
        throw Exception('$machine is not linked to other machines');
      }
    }
  }
}

Widget createCellWidgetFor(ActiveCell cell) {
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
  if (cell is ModuleDrawerUnloader) {
    return ModuleDrawerUnloaderWidget(cell);
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
