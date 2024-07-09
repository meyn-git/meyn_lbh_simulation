// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas.dart';
import 'package:meyn_lbh_simulation/domain/area/name.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';

abstract class System implements Namable, Commandable, Detailable {}

abstract class PhysicalSystem extends System {
  /// See [DefaultOrientation]
  /// TODO replace with Shape get shape;
  SizeInMeters get sizeWhenFacingNorth;

  /// all links to other [PhysicalSystem]s
  List<Link> get links;

  @override
  String toString() => objectDetails.toString();
}

/// an optional [PhysicalSystem] capability
abstract class AdditionalRotation {
  CompassDirection get additionalRotation;
}

/// A Physical place on a [System] that can contain a [ModuleGroup]
class ModuleGroupPlace {
  final PhysicalSystem system;
  ModuleGroup?
      moduleGroup; // TODO change to ModuleGroup? moduleGroup, to be updated by BetweenModuleGroup Places See DrawerPlace
  final OffsetInMeters offsetFromCenterWhenSystemFacingNorth;

  ModuleGroupPlace(
      {required this.system,
      required this.offsetFromCenterWhenSystemFacingNorth});
}

class Systems extends DelegatingList<System> {
  /// set [topLeftFirstMachine] when defining a [LiveBirdHandlingArea]

  CompassDirection startDirection = const CompassDirection.north();

  Systems() : super([]);

  late Iterable<PhysicalSystem> physicalSystems = whereType<PhysicalSystem>();

  late Iterable<TimeProcessor> timeProcessingSystems =
      whereType<TimeProcessor>();

  void link(Link link1, Link link2) {
    if (!contains(link1.system)) {
      add(link1.system);
    }
    if (!contains(link2.system)) {
      add(link2.system);
    }
    link1.linkedTo = link2;
    link2.linkedTo = link1;
  }

  int seqNrOf(System systemToFind) {
    int seqNr = 0;
    for (var system in this) {
      if (system.runtimeType == systemToFind.runtimeType) {
        seqNr++;
      }
      if (system == systemToFind) {
        return seqNr;
      }
    }
    return seqNr;
  }
}

class ModuleGroupRoute extends DelegatingList<ModuleGroupOutLink> {
  ModuleGroupRoute(
    super.moduleGroupOutLinks,
  );

  const ModuleGroupRoute.empty() : super(const []);

  /// [ModuleCas] score for getting a new, un-stunned [ModuleGroup].
  /// =0 when [ModuleCas] is NOT waiting for a new un-stunned [ModuleGroup]
  ///    or there is already a new un-stunned [ModuleGroup].
  /// >0 the higher the score the higher the priority (e.g. when more [CellRoute]s are competing
  ///    - the longest route has the highest score (send stacks to furthest units first)
  ///    - the [ModuleCas] that is most ready to receive a module will get the highest
  ///      score when routes of equal length are competing.
  double get casNewStackScore {
    if (_moduleGroupGoingTo(cas)) {
      return 0;
    }
    var score = _casReadinessScore * 3 +
        _troughPutScore * 2 +
        _distanceToTravelScore * 1;
    return score;
  }

  /// A score between 1 (=100%) and 0 (=0%)
  /// high (1) = when no modules are on route, otherwise
  /// lower for each module that is blocking the route
  double get _troughPutScore => 1 / (1 + numberOfModulesGroupsOnRoute);

  /// A score between 1 (=100%) and 0 (=0%)
  /// high (near 1) = longest route
  /// low (towards 0) = shortest route
  double get _distanceToTravelScore => 1 - (1 / length);

  /// A score between 1 (=100%) and 0 (=0%)
  /// 1= waiting to feed in
  /// 0.7= waiting to feed out
  /// 0.4= almost waiting to feed in
  double get _casReadinessScore {
    if (cas.canFeedIn) {
      return 1;
    } else if (cas.durationUntilCanFeedOut == Duration.zero) {
      return 0.7;
    } else if (cas.almostWaitingToFeedOut) {
      return 0.4;
    } else {
      return 0;
    }
  }

  int get numberOfModulesGroupsOnRoute {
    int total = 0;
    for (var moduleGroupOut in this) {
      if (moduleGroupOut.place.moduleGroup != null &&
          moduleGroupOut != first &&
          moduleGroupOut != last) {
        total++;
      }
    }
    return total;
  }

  bool get containsRoundTrips => systems.length != systems.toSet().length;

  bool _moduleGroupGoingTo(ModuleCas cas) =>
      cas.area.moduleGroups.any((moduleGroup) =>
          !moduleGroupAtAllocationPlace(moduleGroup) &&
          moduleGroup.destination == cas);

  ModuleCas get cas {
    var destination = last.linkedTo?.system;
    if (destination is ModuleCas) {
      return destination;
    } else {
      throw Exception('The last cell in the route is not a $ModuleCas');
    }
  }

  List<PhysicalSystem> get systems => [
        ...map((outLink) => outLink.system),
        if (last.linkedTo?.system != null) last.linkedTo!.system
      ];

  @override
  String toString() => systems.map((system) => system.name).join(' -> ');

  bool moduleGroupAtAllocationPlace(ModuleGroup moduleGroup) =>
      moduleGroupStartPlace(moduleGroup)?.system == first.system;

  ModuleGroupPlace? moduleGroupStartPlace(ModuleGroup moduleGroup) {
    if (moduleGroup.position is AtModuleGroupPlace) {
      return (moduleGroup.position as AtModuleGroupPlace).place;
    }
    if (moduleGroup.position is BetweenModuleGroupPlaces) {
      return (moduleGroup.position as BetweenModuleGroupPlaces).source;
    }
    return null;
  }
}

/// By convention: The [DefaultOrientation] of a [PhysicalSystem] is,
/// when looking from the top, the product carrier starts to travel
/// North bound (starting in the south)
///
/// [PhysicalSystem]s can have a rotation (see [MachineLayout])
/// This means that a rotation of
/// * 0 degrees: product carrier starts traveling North bound
///   (= starts in the South of the system)
/// * 90 degrees: product carrier starts traveling East bound
///   (= starts in the West of the system)
/// * 180 degrees: product carrier starts traveling South bound
///   (= starts in the North of the system)
/// * 270 degrees: product carrier starts traveling West bound
///   (= starts in the East of the system)
abstract class DefaultOrientation {}

/// Outer size in meters

/// Outer size in meters
class SizeInMeters {
  /// distance between furthest West and East points
  final double xInMeters;

  /// distance between furthest North and South points
  final double yInMeters;

  const SizeInMeters({
    required this.xInMeters,
    required this.yInMeters,
  });

  static const zero = SizeInMeters(xInMeters: 0, yInMeters: 0);

  SizeInMeters operator +(SizeInMeters other) => SizeInMeters(
      xInMeters: xInMeters + other.xInMeters,
      yInMeters: yInMeters + other.yInMeters);

  SizeInMeters operator -(SizeInMeters other) => SizeInMeters(
      xInMeters: xInMeters - other.xInMeters,
      yInMeters: yInMeters - other.yInMeters);
  SizeInMeters operator *(double factor) => SizeInMeters(
      xInMeters: xInMeters * factor, yInMeters: yInMeters * factor);

  Size toSize() => Size(xInMeters, yInMeters);

  OffsetInMeters toOffsetInMeters() =>
      OffsetInMeters(xInMeters: xInMeters, yInMeters: yInMeters);
}

/// The relative position from the top left
/// when looking from to top of the [PhysicalSystem] in [DefaultOrientation]
/// The relative position from the top left
/// when looking from to top of the [Machine] in [DefaultOrientation]
class OffsetInMeters {
  ///
  final double yInMeters;
  final double xInMeters;

  const OffsetInMeters({
    required this.xInMeters,
    required this.yInMeters,
  });

  static const zero = OffsetInMeters(xInMeters: 0, yInMeters: 0);

  OffsetInMeters operator +(OffsetInMeters other) => OffsetInMeters(
      xInMeters: xInMeters + other.xInMeters,
      yInMeters: yInMeters + other.yInMeters);

  OffsetInMeters operator -(OffsetInMeters other) => OffsetInMeters(
      xInMeters: xInMeters - other.xInMeters,
      yInMeters: yInMeters - other.yInMeters);

  OffsetInMeters operator *(double factor) => OffsetInMeters(
      xInMeters: xInMeters * factor, yInMeters: yInMeters * factor);

  bool operator >=(OffsetInMeters other) =>
      xInMeters >= other.xInMeters && yInMeters >= other.yInMeters;

  bool operator <=(OffsetInMeters other) =>
      xInMeters <= other.xInMeters && yInMeters <= other.yInMeters;

  Offset toOffset() => Offset(xInMeters, yInMeters);

  OffsetInMeters withLengthInMeters(double lengthInMeters) {
    if (lengthInMeters == 0.0) {
      return OffsetInMeters.zero;
    } else {
      var oldLengthInMeters = lengthInMeters;
      if (oldLengthInMeters == 0.0) {
        return this;
      }
      return this * (lengthInMeters / oldLengthInMeters);
    }
  }

  double get lengthInMeters {
    double sum;
    sum = xInMeters * xInMeters;
    sum += yInMeters * yInMeters;
    return sqrt(sum);
  }

  /// The [directionInRadians] of the offset in radians relative to Y-axis,
  /// using the Flutter coordinate system:
  /// y<0 and x=0 = [CompassDirection.north] = 0
  /// y=0 and x>0 = [CompassDirection.east] = 0.5*pi
  /// y>0 and x=0 = [CompassDirection.south] = 1*pi
  /// y=0 and x<0 = [CompassDirection.west] = 1.5*pi
  double get directionInRadians => atan2(xInMeters, -yInMeters) % (2 * pi);

  OffsetInMeters rotate(CompassDirection rotationToAdd) {
    if (rotationToAdd.degrees == 0) {
      return this;
    }
    var rotation = (directionInRadians + rotationToAdd.toRadians()) % (2 * pi);
    var length = lengthInMeters;
    return OffsetInMeters(
      xInMeters: sin(rotation) * length,
      yInMeters: -cos(rotation) * length,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OffsetInMeters &&
      other.runtimeType == runtimeType &&
      other.xInMeters == xInMeters &&
      other.yInMeters == yInMeters;

  @override
  int get hashCode => Object.hash(xInMeters, yInMeters);

  @override
  String toString() =>
      'OffsetInMeters(xInMeters:$xInMeters,yInMeters:$yInMeters)';

  OffsetInMeters addX(double xMetersToAdd) =>
      OffsetInMeters(xInMeters: xInMeters + xMetersToAdd, yInMeters: yInMeters);

  OffsetInMeters addY(double yMetersToAdd) =>
      OffsetInMeters(xInMeters: xInMeters, yInMeters: yInMeters + yMetersToAdd);
}

// class OffsetInMetersFromTopLeft extends OffsetInMeters {
//   OffsetInMetersFromTopLeft(
//       {required super.metersFromTop, required super.metersFromLeft});
// }

class Durations {
  List<Duration> durations = [];
  final int maxSize;

  Durations({required this.maxSize});

  add(Duration? duration) {
    if (duration == null) {
      return;
    }
    durations.insert(0, duration);
    if (durations.length > maxSize) {
      durations.length = maxSize;
    }
  }

  Duration get total => durations.reduce((a, b) => a + b);

  Duration get average => durations.isEmpty
      ? Duration.zero
      : Duration(
          milliseconds: (total.inMilliseconds / durations.length).round());

  double get averagePerHour =>
      durations.isEmpty ? 0 : 3600000 / average.inMilliseconds;
}

enum Direction {
  counterClockWise(-1),
  clockWise(1);

  final int sign;

  const Direction(this.sign);
}
