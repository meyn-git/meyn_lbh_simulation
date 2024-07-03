import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/player.dart';
import 'package:meyn_lbh_simulation/domain/site/scenario.dart';
import 'package:meyn_lbh_simulation/gui/area/drawer.dart';
import 'package:meyn_lbh_simulation/gui/area/module.dart';
import 'package:meyn_lbh_simulation/gui/area/system.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

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
    var theme = Theme.of(context).liveBirdsHandling;
    var areaWidgetDelegate = AreaWidgetDelegate(player.scenario!);
    return player.scenario == null
        ? const Text("No scenario's")
        : Container(
            color: theme.backGroundColor,
            child: Column(
              children: [
                FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text(scenarioTitle,
                        style: const TextStyle(fontSize: 25))),
                Expanded(
                  child: InteractiveViewer(
                    child: Align(
                      alignment: Alignment.center,
                      child: AspectRatio(
                        aspectRatio: areaWidgetDelegate.area.layout.aspectRatio,
                        child: LayoutBuilder(
                          builder: (context, constraints) => Listener(
                            onPointerUp: (event) => onPointerUp(
                                event, areaWidgetDelegate, constraints),
                            child: CustomMultiChildLayout(
                                delegate: areaWidgetDelegate,
                                children: createChildren(player.scenario!)),
                          ),
                        ),
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
    children.addAll(createMachineWidgets(area));
    children.addAll(createDrawerWidgets(area));
    children.addAll(createMarkerWidgets(area));
    return children;
  }

  static List<Widget> createModuleGroupWidgets(LiveBirdHandlingArea area) {
    var moduleGroupWidgets = area.moduleGroups
        .map<Widget>((moduleGroup) =>
            LayoutId(id: moduleGroup, child: ModuleGroupWidget(moduleGroup)))
        .toList();
    return moduleGroupWidgets;
  }

  static List<Widget> createMarkerWidgets(LiveBirdHandlingArea area) {
    var markerWidgets = area.markers
        .map<Widget>((marker) => LayoutId(
            id: marker,
            child: Container(
              color: Colors.red,
            )))
        .toList();
    return markerWidgets;
  }

  static List<Widget> createMachineWidgets(LiveBirdHandlingArea area) {
    List<Widget> widgets = [];
    for (var system in area.systems.physicalSystems) {
      widgets
          .add(LayoutId(id: system, child: MachineWidget(area.layout, system)));
    }
    return widgets;
  }

  static List<Widget> createDrawerWidgets(LiveBirdHandlingArea area) {
    List<Widget> widgets = [];
    var drawers = area.drawers;
    for (var drawer in drawers) {
      widgets.add(
          LayoutId(id: drawer, child: GrandeDrawerWidget(area.layout, drawer)));
    }
    return widgets;
  }

  @override
  void onUpdate() {
    /// TODO can we refresh diferently so we do not need to refresh everything AreaPanelState.onUpDate
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
        .addAll(objectsToAddToMonitor(event, areaWidgetDelegate, size));
    GetIt.instance<Player>().objectsToMonitor.addAll(objectsToMonitor);
  }

  List<Detailable> objectsToAddToMonitor(PointerUpEvent event,
      AreaWidgetDelegate areaWidgetDelegate, Size areaSize) {
    var objectsToAddToMonitor = <Detailable>[];
    var sizePerMeter = areaWidgetDelegate._lengthPerMeter(areaSize);
    for (var system in areaWidgetDelegate.area.systems.physicalSystems) {
      if (clickedOnSystem(
        areaWidgetDelegate.area.layout,
        system,
        sizePerMeter,
        event.position,
      )) {
        objectsToAddToMonitor
            .addAll(relatedObjectsToMonitor(system, areaWidgetDelegate));
        objectsToAddToMonitor.add(system);
      }
    }
    return objectsToAddToMonitor;
  }

  List<Detailable> relatedObjectsToMonitor(
      PhysicalSystem system, AreaWidgetDelegate areaWidgetDelegate) {
    var relatedObjects = <Detailable>[];
    if (system is ModuleCas) {
      relatedObjects
          .addAll(areaWidgetDelegate.area.systems.whereType<ModuleCasStart>());
    }
    for (var moduleCasAllocation
        in areaWidgetDelegate.area.systems.whereType<ModuleCasAllocation>()) {
      if (system == moduleCasAllocation.allocationPlace.system) {
        relatedObjects.add(moduleCasAllocation);
      }
    }

    return relatedObjects;
  }

  bool clickedOnSystem(SystemLayout layout, PhysicalSystem system,
      double sizePerMeter, Offset pointer) {
    /// TODO: Listener only listens when there is a child where clicked.
    /// We place all machines facing north and then rotate,
    /// but the size is still facing north.
    /// The begin end end of a long conveyor that is rotated 90 degrees
    /// is therefore not clickable.
    /// We need to extend its size to Size(max(s.x,s.y),max(s.x,s.y))
    var pointerInMeters = OffsetInMeters(
      xInMeters: pointer.dx / sizePerMeter,
      yInMeters: pointer.dy / sizePerMeter,
    );
    var mysteriousCorrection =
        const OffsetInMeters(xInMeters: 0, yInMeters: 11);
    var systemCenter = layout.centerOf(system) + mysteriousCorrection;
    var systemCenterToPointer = pointerInMeters - systemCenter;
    var rotationToNorth = CompassDirection(-layout.rotationOf(system).degrees);
    var northPointingSystemCenterToPointer =
        systemCenterToPointer.rotate(rotationToNorth);
    var size = system.sizeWhenFacingNorth.toOffsetInMeters();
    var systemCenterToTopLeft = size * -0.5;
    var systemCenterToBottomRight = size * 0.5;
    return northPointingSystemCenterToPointer >= systemCenterToTopLeft &&
        northPointingSystemCenterToPointer <= systemCenterToBottomRight;
  }
}

/// Sizes (lets the children do their layout in given [BoxConstraints])
/// and positions all the child widgets ([Cell]s and [ModuleGroup]s)
/// within the given [AreaPanel] size
class AreaWidgetDelegate extends MultiChildLayoutDelegate {
  final LiveBirdHandlingArea area;
  // final CellRange cashedCellRange;

  AreaWidgetDelegate(Scenario scenario) : area = scenario.area;

  @override
  void performLayout(Size size) {
    var lengthPerMeter = _lengthPerMeter(size);
    _layoutAndPositionModuleGroups(lengthPerMeter);
    _layoutAndPositionSystems(lengthPerMeter);
    _layoutAndPositionDrawers(lengthPerMeter);
    _layoutAndPositionMarkers(lengthPerMeter);
  }

  void _layoutAndPositionSystems(double lengthPerMeter) {
    for (var system in area.systems.physicalSystems) {
      var size = system.sizeWhenFacingNorth.toSize() * lengthPerMeter;
      layoutChild(system, BoxConstraints.tight(size));
      var topLeft = area.layout.topLeftWhenFacingNorthOf(system).toOffset() *
          lengthPerMeter;
      positionChild(system, topLeft);
    }
  }

  void _layoutAndPositionModuleGroups(double lengthPerMeter) {
    var moduleType =
        MeynGrandeDrawerChicken4Level(); //TODO get from modulegroup
    var moduleDimensions = moduleType.dimensions;
    var moduleSize = Size(moduleDimensions.widthShortSide.defaultValue,
            moduleDimensions.lengthLongSide.defaultValue) *
        lengthPerMeter;
    for (var moduleGroup in area.moduleGroups) {
      layoutChild(moduleGroup, BoxConstraints.tight(moduleSize));
      var moduleGroupOffSet = _moduleGroupOffset(moduleGroup, lengthPerMeter);
      positionChild(moduleGroup, moduleGroupOffSet);
    }
  }

  // void _layoutAndPositionCells(Size childSize, Offset childOffset) {
  //   for (var cell in area.cells) {
  //     layoutChild(cell, BoxConstraints.tight(childSize));
  //     var cellOffset = _createCellOffset(cell.position, childSize, childOffset);
  //     positionChild(cell, cellOffset);
  //   }
  // }

  void _layoutAndPositionDrawers(double lengthPerMeter) {
    Size? size;
    for (var drawer in area.drawers) {
      if (size == null) {
        var length = drawer.outSideLengthInMeters * lengthPerMeter;
        size = Size(length, length);
      }
      layoutChild(drawer, BoxConstraints.tight(size));
      var drawerOffset = _drawerOffset(drawer, lengthPerMeter);
      positionChild(drawer, drawerOffset);
    }
  }

  Offset _drawerOffset(GrandeDrawer drawer, double lengthPerMeter) =>
      (drawer.position.topLeft(area.layout)).toOffset() * lengthPerMeter;

  void _layoutAndPositionMarkers(lengthPerMeter) {
    Size size = const Size(1, 1);
    for (var marker in area.markers) {
      layoutChild(marker, BoxConstraints.tight(size));
      var position = (area.layout.positionOnSystem(
                  marker.system, marker.offsetFromSystemCenterWhenFacingNorth))
              .toOffset() *
          lengthPerMeter;
      positionChild(marker, position);
    }
  }

  // Offset _offsetForAllChildren(Size size, Size childSize) {
  //   var offSet = Offset(
  //     (size.width - (childSize.width * cashedCellRange.width)) / 2,
  //     (size.height - (childSize.height * cashedCellRange.height)) / 2,
  //   );
  //   return offSet;
  // }

  // Size _childSize(Size area) {
  //   var childWidth = area.width / cashedCellRange.width;
  //   var childHeight = area.height / cashedCellRange.height;
  //   var childSide = min(childWidth, childHeight);
  //   return Size(childSide, childSide);
  // }

  _lengthPerMeter(Size size) =>
      area.layout.size.xInMeters < area.layout.size.yInMeters
          ? size.height / area.layout.size.yInMeters
          : size.width / area.layout.size.xInMeters;

  final OffsetInMeters moduleGroupCenterToTopLeft =
      const OffsetInMeters(xInMeters: 0.63, yInMeters: -0.6);

  Offset _moduleGroupOffset(ModuleGroup moduleGroup, double lengthPerMeter) {
    var offsetInMeters =
        (moduleGroup.position).center(area.layout) + moduleGroupCenterToTopLeft;
    return offsetInMeters.toOffset() * lengthPerMeter;
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) => true;
}
