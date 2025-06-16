import 'dart:math';

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/system/drawer_conveyor/drawer_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module_variant_builder.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_drawer_loader/module_drawer_loader.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_shuttle/module_shuttle.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_allocation.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_start.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/vehicle/vehicle.domain.dart';

abstract class LiveBirdHandlingArea implements TimeProcessor {
  final String lineName;
  final ProductDefinition productDefinition;
  final ModuleGroups moduleGroups = ModuleGroups();
  final List<GrandeDrawer> drawers = [];
  final Systems systems = Systems();
  late final SystemLayout layout = SystemLayout(systems);
  Duration durationSinceStart = Duration.zero;
  int moduleSequenceNumber = 0;

  final List<Marker> markers = [];

  LiveBirdHandlingArea({
    required this.lineName,
    required this.productDefinition,
  }) {
    createSystemsAndLinks();
    validate();
  }

  void validate() {
    validateModuleCasStart();
    validateModuleCasAllocation();
  }

  void validateModuleCasStart() {
    if (systems.whereType<ModuleCas>().isNotEmpty &&
        systems.whereType<ModuleCasStart>().isEmpty) {
      throw Exception(
        'Add a $ModuleCasStart to the systems '
        'when you have $ModuleCas systems.',
      );
    }
  }

  void validateModuleCasAllocation() {
    if (systems.whereType<ModuleCas>().length > 1 &&
        systems.whereType<ModuleCasAllocation>().isEmpty) {
      throw Exception(
        'Add a $ModuleCasAllocation to the timeProcessors '
        'when you have 1 or more $ModuleCas systems.',
      );
    }
  }

  late String name = '$lineName-$productDefinition';

  late final int modulesPerCasUnitCycle = _modulesPerCasUnitCycle();

  int _modulesPerCasUnitCycle() {
    var casUnits = systems.whereType<ModuleCas>();
    if (casUnits.isEmpty) {
      throw Exception('No $ModuleCas units found');
    }
    var levelsOfModules = casUnits
        .map((casUnit) => casUnit.levelsOfModules)
        .toSet();
    if (levelsOfModules.length > 1) {
      throw Exception(
        'All $ModuleCas units must have the same number of module levels',
      );
    }
    var levelOfModules = levelsOfModules.first;
    var truckRow = productDefinition.truckRows.first;
    return levelOfModules * truckRow.numberOfStacks;
  }

  /// Updates all the [LinkedSystem]s, [ModuleGroup]s and [GrandeDrawer]s]
  @override
  onUpdateToNextPointInTime(Duration jump) {
    durationSinceStart = durationSinceStart + jump;
    for (var system in systems.whereType<TimeProcessor>().toList()) {
      system.onUpdateToNextPointInTime(jump);
    }
    //TODO test if we can move the following lines to the top of this method
    for (var moduleGroup in moduleGroups) {
      moduleGroup.onUpdateToNextPointInTime(jump);
    }
    moduleGroups.updateSystemPositionsWithModuleGroups();
    for (var drawer in drawers) {
      drawer.onUpdateToNextPointInTime(jump);
    }
  }

  @override
  String toString() {
    return '$lineName-$productDefinition';
  }

  void createSystemsAndLinks();
}

/// a red dot for debugging the position
class Marker {
  final LinkedSystem system;

  final OffsetInMeters offsetFromSystemCenterWhenFacingNorth;

  Marker(this.system, this.offsetFromSystemCenterWhenFacingNorth);
}

abstract class TimeProcessor {
  /// method to change the state of the object to the next point in time
  void onUpdateToNextPointInTime(Duration jump);
}

class ProductDefinition {
  final String birdType;
  final int lineSpeedInShacklesPerHour;
  final int lineShacklePitchInInches;
  final List<TruckRow> truckRows;
  final CasRecipe? casRecipe;

  late final SpeedProfiles speedProfiles = SpeedProfiles.ofVariantBase(
    truckRows.first.templates.first.variant as ModuleVariantBase,
  );

  final List<LiveBirdHandlingArea> Function(ProductDefinition)
  areaFactory; //TODO does this have to be a list?

  ProductDefinition({
    required this.areaFactory,
    required this.birdType,
    required this.lineSpeedInShacklesPerHour,
    required this.lineShacklePitchInInches,
    required this.truckRows,
    required this.casRecipe,
  }) {
    _verifyTruckRowsAreNotEmpty();
    _verifyTruckRowModulesHaveSameBase();
  }

  List<LiveBirdHandlingArea> get areas => areaFactory(this);

  double get averageNumberOfBirdsPerModule {
    var totalBirdsPerModule = 0.0;
    var totalTruckRowOccurrence = 0.0;
    for (var truckRow in truckRows) {
      totalBirdsPerModule += truckRow.numberOfBirds / truckRow.numberOfModules;
      totalTruckRowOccurrence += truckRow.occurrence;
    }
    return totalBirdsPerModule / totalTruckRowOccurrence;
  }

  @override
  String toString() {
    return '$birdType-${lineSpeedInShacklesPerHour}b/h-${truckRows.join(' ')}';
  }

  void _verifyTruckRowsAreNotEmpty() {
    if (truckRows.isEmpty) {
      throw ArgumentError('May not be empty', 'truckRows');
    }
    for (var truckRow in truckRows) {
      truckRow.validateIsNotEmpty();
    }
  }

  void _verifyTruckRowModulesHaveSameBase() {
    var firstVariant = truckRows.first.templates.first.variant;
    for (var truckRow in truckRows) {
      var variants = truckRow.templates.map((template) => template.variant);
      for (var variant in variants) {
        if (!firstVariant.hasShameBaseAs(variant)) {
          throw ArgumentError('All templates must have the same module base');
        }
      }
    }
  }
}

enum LoadFactor { minimum, average, max }

/// Calculates the [_topLefts], [_centers], [_rotations] and [_drawerPaths] of
/// all systems and caches the values for performance, because we only need
/// to calculate this once per [Scenario]
class SystemLayout {
  final Map<LinkedSystem, OffsetInMeters> _topLefts = {};
  final Map<LinkedSystem, OffsetInMeters> _centers = {};
  final Map<LinkedSystem, CompassDirection> _rotations = {};
  final Map<DrawerConveyor, DrawerPath> _drawerPaths = {};
  final Map<DrawerConveyor, OffsetInMeters> _drawerStarts = {};
  late final SizeInMeters size;

  final Iterable<LinkedSystem> linkedSystems;

  late final aspectRatio = size.xInMeters / size.yInMeters;

  SystemLayout(Systems systems) : linkedSystems = systems.linkedSystems {
    _placeSystems(systems.startDirection);
  }

  void _placeSystems(CompassDirection startDirection) {
    if (linkedSystems.isEmpty) {
      return;
    }
    var system = linkedSystems.first;
    var topLeft = OffsetInMeters.zero;
    var rotation = startDirection;
    //place all machines recursively (assuming they are all linked)
    _placeLinkedSystem(system, topLeft, rotation);
    _validateAllMachinesArePlaced();
    var correction = offsetCorrection();
    _correctOffsets(_topLefts, correction);
    _correctOffsets(_centers, correction);
    _correctOffsets(_drawerStarts, correction);
    size = _size();
  }

  void _correctOffsets(
    Map<LinkedSystem, OffsetInMeters> map,
    OffsetInMeters correction,
  ) {
    for (var entry in map.entries) {
      map[entry.key] = entry.value + correction;
    }
  }

  /// Correction for all [OffsetInMeters] so that there are no negative values
  OffsetInMeters offsetCorrection() {
    var minX = 0.0;
    var minY = 0.0;
    for (var centerEntry in _centers.entries) {
      var system = centerEntry.key;
      var center = centerEntry.value;
      var centerToCorner =
          (system.sizeWhenFacingNorth.toOffsetInMeters() * 0.5);
      var cornerRotation = rotationOf(system);
      for (int corner = 0; corner < 3; corner++) {
        var corner = center + centerToCorner.rotate(cornerRotation);
        minX = min(minX, corner.xInMeters);
        minY = min(minY, corner.yInMeters);
        cornerRotation = cornerRotation.rotate(90);
      }
    }

    // var minX = _topLefts.values.map((pos) => pos.xInMeters).reduce(min);
    // var minY = _topLefts.values.map((pos) => pos.yInMeters).reduce(min);
    var correction = OffsetInMeters(xInMeters: minX, yInMeters: minY) * -1;
    return correction;
  }

  void _placeLinkedSystem(
    LinkedSystem system,
    OffsetInMeters topLeft,
    CompassDirection rotation,
  ) {
    _topLefts[system] = topLeft;
    _rotations[system] = rotation;
    _centers[system] =
        topLeft + system.sizeWhenFacingNorth.toOffsetInMeters() * 0.5;
    if (system is DrawerConveyor) {
      var toCenter = _centers[system]!;
      var centerToStart = system.drawerIn.offsetFromCenterWhenFacingNorth
          .rotate(rotation);
      _drawerStarts[system] = toCenter + centerToStart;
      var originalDrawerPath = system.drawerPath;
      var rotatedDrawerPath = originalDrawerPath.rotate(rotation);
      _drawerPaths[system] = rotatedDrawerPath;
    }
    for (var link in system.links) {
      var system1 = system;
      var system1TopLeft = topLeft;
      var system1Rotation = rotation;
      var system2 = link.linkedTo?.system;
      if (system2 != null &&
          _unknownPosition(system2) &&
          !skip(system1, system2)) {
        var system2Rotation =
            rotation +
            link.directionToOtherLink -
            link.linkedTo!.directionToOtherLink.opposite;
        var system1TopLeftToCenter =
            system1.sizeWhenFacingNorth.toOffsetInMeters() * 0.5;
        var system1CenterToLink = link.offsetFromCenterWhenFacingNorth.rotate(
          system1Rotation,
        );
        var system2LinkToCenter =
            link.linkedTo!.offsetFromCenterWhenFacingNorth.rotate(
              system2Rotation,
            ) *
            -1;
        var system2CenterToTopLeft =
            system2.sizeWhenFacingNorth.toOffsetInMeters() * -0.5;
        var system2TopLeft =
            system1TopLeft +
            system1TopLeftToCenter +
            system1CenterToLink +
            system2LinkToCenter +
            system2CenterToTopLeft;
        _placeLinkedSystem(system2, system2TopLeft, system2Rotation);
      }
    }
  }

  /// Returns the cached offset from the top left of the [LiveBirdHandlingArea]
  /// to the top left of the [LinkedSystem]
  OffsetInMeters topLeftWhenFacingNorthOf(LinkedSystem system) =>
      _topLefts[system]!;

  OffsetInMeters positionOnSystem(
    VisibleSystem system,
    OffsetInMeters offsetFromSystemCenterWhenFacingNorth,
  ) =>
      centerOf(system) +
      offsetFromSystemCenterWhenFacingNorth.rotate(rotationOf(system));

  /// Returns the cached offset from the top left of the [LiveBirdHandlingArea]
  /// to the center of the [VisibleSystem]
  OffsetInMeters centerOf(VisibleSystem system) =>
      system is Vehicle ? system.position.center(this) : _centers[system]!;

  /// Returns the cached rotation off a [LinkedSystem] and
  /// adds an additional rotation if the [LinkedSystem] can rotate it self
  CompassDirection rotationOf(VisibleSystem system) => system is Vehicle
      ? system.direction
      : system is AdditionalRotation
      ? _rotations[system]! + (system as AdditionalRotation).additionalRotation
      : _rotations[system]!;

  /// Returns the cached [DrawerPath] of a [LinkedSystem]
  DrawerPath drawerPathOf(DrawerConveyor drawerConveyor) =>
      _drawerPaths[drawerConveyor]!;

  /// Returns the cached offset from the top left of the [LiveBirdHandlingArea]
  /// to the start of the [DrawerPath]
  OffsetInMeters drawerStartOf(DrawerConveyor drawerConveyor) =>
      _drawerStarts[drawerConveyor]!;

  String offsetString(OffsetInMeters offset) =>
      '${offset.yInMeters.toStringAsFixed(1)},${offset.xInMeters.toStringAsFixed(1)}';

  bool _unknownPosition(LinkedSystem system) =>
      !_topLefts.keys.contains(system);

  SizeInMeters _size() {
    if (_topLefts.isEmpty) {
      return SizeInMeters.zero;
    }
    var maxX = 0.0;
    var maxY = 0.0;
    for (var centerEntry in _centers.entries) {
      var system = centerEntry.key;
      var center = centerEntry.value;
      var centerToCorner =
          (system.sizeWhenFacingNorth.toOffsetInMeters() * 0.5);
      var cornerRotation = rotationOf(system);
      for (int corner = 0; corner < 3; corner++) {
        var corner = center + centerToCorner.rotate(cornerRotation);
        maxX = max(maxX, corner.xInMeters);
        maxY = max(maxY, corner.yInMeters);
        cornerRotation = cornerRotation.rotate(90);
      }
    }
    return SizeInMeters(xInMeters: maxX, yInMeters: maxY);
  }

  void _validateAllMachinesArePlaced() {
    for (var system in linkedSystems) {
      // ModuleShuttleCarrier is added later
      if (_unknownPosition(system) && system is! ModuleShuttleCarrier) {
        throw Exception('${system.name} is not linked to other machines');
      }
    }
  }

  bool skip(LinkedSystem system1, LinkedSystem system2) =>
      system1 is DrawerLoaderLift && system2 is ModuleDrawerLoader ||
      system2 is DrawerLoaderLift && system1 is ModuleDrawerLoader;
}
