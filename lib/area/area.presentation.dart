import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/player.domain.dart';
import 'package:meyn_lbh_simulation/site/scenario.domain.dart';
import 'package:meyn_lbh_simulation/area/drawer/drawer.presentation.dart';
import 'package:meyn_lbh_simulation/area/module/module.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/system.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.domain.dart';

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
                  child: Text(
                    scenarioTitle,
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: Align(
                      alignment: Alignment.center,
                      child: AspectRatio(
                        aspectRatio: areaWidgetDelegate.area.layout.aspectRatio,
                        child: CustomMultiChildLayout(
                          delegate: areaWidgetDelegate,
                          children: createChildren(player.scenario!),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  static List<Widget> createChildren(Scenario scenario) {
    List<Widget> children = [];
    var area = scenario.area;
    children.addAll(createSystemWidgets(area));
    children.addAll(createDrawerWidgets(area));
    children.addAll(createMarkerWidgets(area));
    children.addAll(createModuleGroupWidgets(area));
    return children;
  }

  static List<Widget> createModuleGroupWidgets(LiveBirdHandlingArea area) {
    var moduleGroupWidgets = area.moduleGroups
        .map<Widget>(
          (moduleGroup) =>
              LayoutId(id: moduleGroup, child: ModuleGroupWidget(moduleGroup)),
        )
        .toList();
    return moduleGroupWidgets;
  }

  static List<Widget> createMarkerWidgets(LiveBirdHandlingArea area) {
    var markerWidgets = area.markers
        .map<Widget>(
          (marker) => LayoutId(
            id: marker,
            child: Container(color: Colors.red),
          ),
        )
        .toList();
    return markerWidgets;
  }

  static List<Widget> createSystemWidgets(LiveBirdHandlingArea area) {
    List<Widget> widgets = [];
    for (var system in area.systems.visibleSystems) {
      widgets.add(
        LayoutId(id: system, child: SystemWidget(area.layout, system)),
      );
    }
    return widgets;
  }

  static List<Widget> createDrawerWidgets(LiveBirdHandlingArea area) {
    List<Widget> widgets = [];
    var drawers = area.drawers;
    for (var drawer in drawers) {
      widgets.add(
        LayoutId(id: drawer, child: GrandeDrawerWidget(area.layout, drawer)),
      );
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
    for (var system in area.systems.visibleSystems) {
      var size = sizeOfSystem(system).toSize() * lengthPerMeter;
      layoutChild(system, BoxConstraints.tight(size));

      var topLeft = topLeftOfSystem(system, lengthPerMeter);
      positionChild(system, topLeft);
    }
  }

  SizeInMeters sizeOfSystem(VisibleSystem system) => system is LinkedSystem
      ? sizeLinkedSystem(system)
      : sizeOfVehicle(system as Vehicle);

  SizeInMeters sizeLinkedSystem(LinkedSystem system) =>
      system.sizeWhenFacingNorth;

  SizeInMeters sizeOfVehicle(Vehicle vehicle) => vehicle.shape.size;

  Offset topLeftOfSystem(system, lengthPerMeter) => system is Vehicle
      ? topLeftOfVehicle(system, lengthPerMeter)
      : topLeftOfLinkedSystem(system, lengthPerMeter);

  Offset topLeftOfLinkedSystem(LinkedSystem system, double lengthPerMeter) =>
      area.layout.topLeftWhenFacingNorthOf(system).toOffset() * lengthPerMeter;

  Offset topLeftOfVehicle(Vehicle vehicle, double lengthPerMeter) =>
      (vehicle.position.center(area.layout) - vehicle.shape.centerCenter)
          .toOffset() *
      lengthPerMeter;

  void _layoutAndPositionModuleGroups(double lengthPerMeter) {
    // var moduleType =
    //     MeynGrandeDrawerChicken4Level(); //TODO get from modulegroup
    // var moduleDimensions = moduleType.dimensions;
    // var moduleSize = Size(moduleDimensions.widthShortSide.defaultValue,
    //         moduleDimensions.lengthLongSide.defaultValue) *
    //     lengthPerMeter;
    for (var moduleGroup in area.moduleGroups) {
      var moduleSize = moduleGroup.shape.size.toSize() * lengthPerMeter;
      layoutChild(moduleGroup, BoxConstraints.tight(moduleSize));
      var topLeft = _moduleGroupTopLeft(moduleGroup, lengthPerMeter);
      positionChild(moduleGroup, topLeft);
    }
  }

  void _layoutAndPositionDrawers(double lengthPerMeter) {
    Size? size;
    for (var drawer in area.drawers) {
      if (size == null) {
        //TODO get from drawer.variant.footprint.toSize() * lengthPerMeter;
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
      var position =
          (area.layout.positionOnSystem(
            marker.system,
            marker.offsetFromSystemCenterWhenFacingNorth,
          )).toOffset() *
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

  OffsetInMeters moduleGroupCenterToTopLeft(ModuleGroup moduleGroup) =>
      moduleGroup.shape.size.toOffsetInMeters() * -0.5;
  //const OffsetInMeters(xInMeters: 0.63, yInMeters: -0.6);

  Offset _moduleGroupTopLeft(ModuleGroup moduleGroup, double lengthPerMeter) {
    var topLeft =
        moduleGroup.position.center(area.layout) +
        moduleGroupCenterToTopLeft(moduleGroup);
    return topLeft.toOffset() * lengthPerMeter;
  }

  // TODO only when nessasary
  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) => true;
}
