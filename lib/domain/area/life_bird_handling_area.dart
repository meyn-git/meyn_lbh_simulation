import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_loader.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';

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
      throw Exception('Add a $ModuleCasStart to the systems '
          'when you have $ModuleCas systems.');
    }
  }

  void validateModuleCasAllocation() {
    if (systems.whereType<ModuleCas>().length > 1 &&
        systems.whereType<ModuleCasAllocation>().isEmpty) {
      throw Exception('Add a $ModuleCasAllocation to the timeProcessors '
          'when you have 1 or more $ModuleCas systems.');
    }
  }

  late String name = '$lineName-$productDefinition';

  /// Updates all the [PhysicalSystem]s, [ModuleGroup]s and [GrandeDrawer]s]
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
  final PhysicalSystem system;

  final OffsetInMeters offsetFromSystemCenterWhenFacingNorth;

  Marker(this.system, this.offsetFromSystemCenterWhenFacingNorth);
}

class ModuleGroups extends DelegatingList<ModuleGroup> {
  Map<ModuleGroupPlace, ModuleGroup> systemPositionsWithModules = {};

  ModuleGroups() : super(<ModuleGroup>[]) {
    updateSystemPositionsWithModuleGroups();
  }

  /// Creates a new [systemPositionsWithModules] map for all [ModuleGroup]s
  /// that are at a [PhysicalSystem] position.
  /// We only do this once per update cycle for performance.
  updateSystemPositionsWithModuleGroups() {
    systemPositionsWithModules.clear();
    for (var moduleGroup in this) {
      if (moduleGroup.position is AtModuleGroupPlace) {
        var position = (moduleGroup.position as AtModuleGroupPlace).place;
        systemPositionsWithModules[position] = moduleGroup;
      }
    }
  }

  /// returns the [ModuleGroup] that is at
  /// the given [system] and [positionIndex] or null
  /// Note that the [systemPositionsWithModules] are cached.
  /// See: [updateSystemPositionsWithModuleGroups]
  ModuleGroup? at(ModuleGroupPlace position) =>
      systemPositionsWithModules[position];

  bool anyAt(ModuleGroupPlace position) =>
      systemPositionsWithModules.containsKey(position);
}

@Deprecated('Remove!')
class CellRange {
  int? _minX;
  int? _maxX;
  int? _minY;
  int? _maxY;

  CellRange(List<ActiveCell> cells) {
    if (cells.isEmpty) {
      throw ('You must put cells in the area as part of the Area constructor');
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

@Deprecated('Remove!')
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

  Position neighbor(CardinalDirection relativePosition) {
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

@Deprecated('Use System instead')
abstract class Cell {
//FIXME: Cell should not have these methods because it could be empty or not handle Modules

  /// whether a given direction can feed out modules
  bool isFeedIn(CardinalDirection direction);

  /// waiting to feed in a [ModuleGroup] from the preceding transport system
  /// e.g.: when a [StateMachineCell] is in WaitToFeedIn
  bool waitingToFeedIn(CardinalDirection direction);

  /// whether a given direction can feed out modules
  bool isFeedOut(CardinalDirection direction);

  /// used to request to turn the turn table to this position in advance.
  bool almostWaitingToFeedOut(CardinalDirection direction);

  /// module(s) waiting to feed out to next transport system
  /// e.g. when a [StateMachineCell] is WaitToFeedOut
  bool waitingToFeedOut(CardinalDirection direction);

  /// to be increased with [nrOfModules] when the StateMachine has fed out
  /// TODO can we do without?: int nrOfModulesMoved = 0;

  ModuleGroup? get moduleGroup;
}

@Deprecated('Use System instead')
class EmptyCell implements Cell {
  static final EmptyCell _emptyCell = EmptyCell._();

  EmptyCell._();

  factory EmptyCell() => _emptyCell;

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

abstract class TimeProcessor {
  /// method to change the state of the object to the next point in time
  void onUpdateToNextPointInTime(Duration jump);
}

@Deprecated('Use System instead')
abstract class ActiveCell
    implements Cell, TimeProcessor, Commandable, Detailable {
  late LiveBirdHandlingArea area;
  late Position position;

  @override
  String toString() => objectDetails.toString();
}

// /// A list of [StateMachineCell]s to get to a [ModuleCas] within a [LiveBirdHandlingArea]
// @Deprecated('Use ModuleGroupRoute')
// class CellRoute extends DelegatingList<StateMachineCell> {
//   CellRoute(
//     super.cellRoute,
//   );

//   const CellRoute.empty() : super(const []);

//   // /// [ModuleCas] score for getting a new, un-stunned [ModuleGroup].
//   // /// =0 when [ModuleCas] is NOT waiting for a new un-stunned [ModuleGroup]
//   // ///    or there is already a new un-stunned [ModuleGroup].
//   // /// >0 the higher the score the higher the priority (e.g. when more [CellRoute]s are competing
//   // ///    - the longest route has the highest score (send stacks to furthest units first)
//   // ///    - the [ModuleCas] that is most ready to receive a module will get the highest
//   // ///      score when routes of equal length are competing.
//   // double get casNewStackScore {
//   //   if (_moduleGroupGoingTo(cas)) {
//   //     return 0;
//   //   }
//   //   var score = _casReadinessScore * 3 +
//   //       _troughPutScore * 2 +
//   //       _distanceToTravelScore * 1;
//   //   return score;
//   // }

//   /// A score between 1 (=100%) and 0 (=0%)
//   /// high (1) = when no modules are on route, otherwise
//   /// lower for each module that is blocking the route
//   double get _troughPutScore => 1 / (1 + numberOfModulesGroupsOnRoute);

//   /// A score between 1 (=100%) and 0 (=0%)
//   /// high (near 1) = longest route
//   /// low (towards 0) = shortest route
//   double get _distanceToTravelScore => 1 - (1 / length);

//   // /// A score between 1 (=100%) and 0 (=0%)
//   // /// 1= waiting to feed in
//   // /// 0.7= waiting to feed out
//   // /// 0.4= almost waiting to feed in
//   // double get _casReadinessScore {
//   //   if (casIsOkToFeedIn) {
//   //     return 1;
//   //   } else if (casIsOkToFeedOut) {
//   //     return 0.7;
//   //   } else if (casIsAlmostOkToFeedOut) {
//   //     return 0.4;
//   //   } else {
//   //     return 0;
//   //   }
//   // }

//   int get numberOfModulesGroupsOnRoute {
//     int total = 0;
//     for (StateMachineCell stateMachine in this) {
//       if (stateMachine.moduleGroup != null &&
//           stateMachine != first &&
//           stateMachine != last) {
//         total++;
//       }
//     }
//     return total;
//   }

//   bool _moduleGroupGoingTo(ModuleCas cas) =>
//       cas.area.moduleGroups.any((moduleGroup) =>
//           (moduleGroup.position as ModulePositionDeprecated).source != first &&
//           moduleGroup.destination == cas);

//   // bool get casIsOkToFeedIn => cas.waitingToFeedIn(cas.inAndOutFeedDirection);

//   // bool get casIsOkToFeedOut => cas.waitingToFeedOut(cas.inAndOutFeedDirection);

//   // bool get casIsAlmostOkToFeedOut =>
//   //     cas.almostWaitingToFeedOut(cas.inAndOutFeedDirection);

//   // ModuleCas get cas {
//   //   var destination = last;
//   //   if (destination is ModuleCas) {
//   //     return destination;
//   //   } else {
//   //     throw Exception('The last cell in the route is not a $ModuleCas');
//   //   }
//   // }
// }

class ProductDefinition {
  final String birdType; //TODO should be obtained from moduleGroupCapacities
  final int lineSpeedInShacklesPerHour;
  final int lineShacklePitchInInches;
  final ModuleFamily
      moduleFamily; //TODO should be obtained from moduleGroupCapacities
  final List<ModuleGroupCapacity>
      moduleGroupCapacities; // verify if module groups are identical (family dimensions, bird type)
  final CasRecipe? casRecipe;
  final ModuleSystem
      moduleSystem; //TODO should be obtained from moduleGroupCapacities
  final List<LiveBirdHandlingArea> Function(ProductDefinition)
      areaFactory; //TODO does this have to be a list?

  ProductDefinition({
    required this.areaFactory,
    required this.moduleSystem,
    required this.birdType,
    required this.lineSpeedInShacklesPerHour,
    required this.lineShacklePitchInInches,
    required this.moduleFamily,
    required this.moduleGroupCapacities,
    required this.casRecipe,
  }) {
    _verifyModuleGroupCapacities();
  }

  List<LiveBirdHandlingArea> get areas => areaFactory(this);

  double get averageProductsPerModuleGroup {
    var totalBirds = 0;
    var totalOccurrence = 0.0;
    for (var moduleGroupCapacity in moduleGroupCapacities) {
      totalBirds += moduleGroupCapacity.numberOfBirds;
      totalOccurrence += moduleGroupCapacity.occurrence;
    }
    return totalBirds / totalOccurrence;
  }

  @override
  String toString() {
    return '$birdType-${lineSpeedInShacklesPerHour}b/h-${moduleGroupCapacities.join(' ')}';
  }

  void _verifyModuleGroupCapacities() {
    if (moduleGroupCapacities.isEmpty) {
      throw ArgumentError('May not be empty', 'moduleGroupCapacities');
    }
  }
}

enum LoadFactor { minimum, average, max }

/// Calculates the [_topLefts], [_centers], [_rotations] and [_drawerPaths] of
/// all machines and caches the values for performance, because we only need
/// to calculate this once per [Scenario]
class SystemLayout {
  final Map<PhysicalSystem, OffsetInMeters> _topLefts = {};
  final Map<PhysicalSystem, OffsetInMeters> _centers = {};
  final Map<PhysicalSystem, CompassDirection> _rotations = {};
  final Map<DrawerConveyor, DrawerPath> _drawerPaths = {};
  final Map<DrawerConveyor, OffsetInMeters> _drawerStarts = {};
  late final SizeInMeters size;

  final Iterable<PhysicalSystem> physicalSystems;

  late final aspectRatio = size.xInMeters / size.yInMeters;

  SystemLayout(Systems systems) : physicalSystems = systems.physicalSystems {
    _placeSystems(systems.startDirection);
  }

  void _placeSystems(
    CompassDirection startDirection,
  ) {
    if (physicalSystems.isEmpty) {
      return;
    }

    var system = physicalSystems.first;
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
      Map<PhysicalSystem, OffsetInMeters> map, OffsetInMeters correction) {
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
    PhysicalSystem system,
    OffsetInMeters topLeft,
    CompassDirection rotation,
  ) {
    _topLefts[system] = topLeft;
    _rotations[system] = rotation;
    _centers[system] =
        topLeft + system.sizeWhenFacingNorth.toOffsetInMeters() * 0.5;
    if (system is DrawerConveyor) {
      var toCenter = _centers[system]!;
      var centerToStart =
          system.drawerIn.offsetFromCenterWhenFacingNorth.rotate(rotation);
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
        var system2Rotation = rotation +
            link.directionToOtherLink -
            link.linkedTo!.directionToOtherLink.opposite;
        var system1TopLeftToCenter =
            system1.sizeWhenFacingNorth.toOffsetInMeters() * 0.5;
        var system1CenterToLink =
            link.offsetFromCenterWhenFacingNorth.rotate(system1Rotation);
        var system2LinkToCenter = link.linkedTo!.offsetFromCenterWhenFacingNorth
                .rotate(system2Rotation) *
            -1;
        var system2CenterToTopLeft =
            system2.sizeWhenFacingNorth.toOffsetInMeters() * -0.5;
        var system2TopLeft = system1TopLeft +
            system1TopLeftToCenter +
            system1CenterToLink +
            system2LinkToCenter +
            system2CenterToTopLeft;
        _placeLinkedSystem(system2, system2TopLeft, system2Rotation);
      }
    }
  }

  /// Returns the cached offset from the top left of the [LiveBirdHandlingArea]
  /// to the top left of the [PhysicalSystem]
  OffsetInMeters topLeftWhenFacingNorthOf(PhysicalSystem system) =>
      _topLefts[system]!;

  OffsetInMeters positionOnSystem(PhysicalSystem system,
          OffsetInMeters offsetFromSystemCenterWhenFacingNorth) =>
      centerOf(system) +
      offsetFromSystemCenterWhenFacingNorth.rotate(rotationOf(system));

  /// Returns the cached offset from the top left of the [LiveBirdHandlingArea]
  /// to the center of the [PhysicalSystem]
  OffsetInMeters centerOf(PhysicalSystem system) => _centers[system]!;

  /// Returns the cached rotation off a [PhysicalSystem] and
  /// adds an additional rotation if the [PhysicalSystem] can rotate it self
  CompassDirection rotationOf(PhysicalSystem system) => system
          is AdditionalRotation
      ? _rotations[system]! + (system as AdditionalRotation).additionalRotation
      : _rotations[system]!;

  /// Returns the cached [DrawerPath] of a [PhysicalSystem]
  DrawerPath drawerPathOf(DrawerConveyor drawerConveyor) =>
      _drawerPaths[drawerConveyor]!;

  /// Returns the cached offset from the top left of the [LiveBirdHandlingArea]
  /// to the start of the [DrawerPath]
  OffsetInMeters drawerStartOf(DrawerConveyor drawerConveyor) =>
      _drawerStarts[drawerConveyor]!;

  String offsetString(OffsetInMeters offset) =>
      '${offset.yInMeters.toStringAsFixed(1)},${offset.xInMeters.toStringAsFixed(1)}';

  bool _unknownPosition(PhysicalSystem system) =>
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
    for (var system in physicalSystems) {
      if (_unknownPosition(system)) {
        throw Exception('${system.name} is not linked to other machines');
      }
    }
  }

  bool skip(PhysicalSystem system1, PhysicalSystem system2) =>
      system1 is DrawerLoaderLift && system2 is ModuleDrawerLoader ||
      system2 is DrawerLoaderLift && system1 is ModuleDrawerLoader;
}
