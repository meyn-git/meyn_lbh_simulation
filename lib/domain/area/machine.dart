// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';

abstract class Machine implements HasCommands {
  /// See [DefaultOrientation]
  late SizeInMeters sizeWhenFacingNorth;

  /// all links to other [Machine]s
  late List<Link> links;

  // late int sequenceNumber;
  // late String name;
}

class Machines extends DelegatingList<Machine> {
  Machines() : super([]);

  // @override
  // // ignore: avoid_renaming_method_parameters
  // void add(Machine machine) {
  //   int sequenceNumber =
  //       where((m) => m.runtimeType == machine.runtimeType).length;
  //   machine.sequenceNumber = sequenceNumber;
  //   super.add(machine);
  // }

  void link(Link link1, Link link2) {
    link1.linkedTo = link2;
    link2.linkedTo = link1;
  }
}

/// By convention: The [DefaultOrientation] of a [Machine] is,
/// when looking from the top, the product carrier starts to travel
/// North bound (starting in the south)
///
/// [Machine]s can have a rotation (see [MachineLayout])
/// This means that a rotation of
/// * 0 degrees: product carrier starts traveling North bound
///   (= starts in the South of the machine)
/// * 90 degrees: product carrier starts traveling East bound
///   (= starts in the West of the machine)
/// * 180 degrees: product carrier starts traveling South bound
///   (= starts in the North of the machine)
/// * 270 degrees: product carrier starts traveling West bound
///   (= starts in the East of the machine)
abstract class DefaultOrientation {}

/// Outer size in meters
class SizeInMeters {
  /// [widthInMeters] when in the [DefaultOrientation]
  final double widthInMeters;

  /// [heightInMeters] when in the [DefaultOrientation]
  final double heightInMeters;

  const SizeInMeters({
    required this.widthInMeters,
    required this.heightInMeters,
  });

  static const zero = SizeInMeters(widthInMeters: 0, heightInMeters: 0);

  SizeInMeters rotate(CompassDirection compassDirection) => SizeInMeters(
      widthInMeters: widthInMeters * cos(compassDirection.toRadians()),
      heightInMeters: heightInMeters * sin(compassDirection.toRadians()));

  Size toSize() => Size(widthInMeters, heightInMeters);

  OffsetInMeters toOffset() => OffsetInMeters(
      metersFromLeft: widthInMeters, metersFromTop: heightInMeters);
}

abstract class Link<OWNER extends Machine,
    LINKED_TO extends Link<Machine, dynamic>> {
  /// the [Machine] that owns the [Link]
  final OWNER owner;
  final OffsetInMeters offsetFromCenter;

  final CompassDirection directionFromCenter;

  /// the [linkedTo] is filled in by the [Machines.link] method
  late LINKED_TO linkedTo;

  Link({
    required this.owner,
    required this.offsetFromCenter,
    required this.directionFromCenter,
  });
}

/// The relative position from the top left
/// when looking from to top of the [Machine] in [DefaultOrientation]
class OffsetInMeters {
  ///
  final double metersFromTop;
  final double metersFromLeft;

  const OffsetInMeters({
    required this.metersFromLeft,
    required this.metersFromTop,
  });

  static const zero = OffsetInMeters(metersFromTop: 0, metersFromLeft: 0);

  OffsetInMeters operator +(OffsetInMeters other) => OffsetInMeters(
      metersFromLeft: metersFromLeft + other.metersFromLeft,
      metersFromTop: metersFromTop + other.metersFromTop);

  OffsetInMeters operator -(OffsetInMeters other) => OffsetInMeters(
      metersFromLeft: metersFromLeft - other.metersFromLeft,
      metersFromTop: metersFromTop - other.metersFromTop);

  OffsetInMeters operator *(double factor) => OffsetInMeters(
      metersFromLeft: metersFromLeft * factor,
      metersFromTop: metersFromTop * factor);

  Offset toOffset() => Offset(metersFromLeft, metersFromTop);

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
    sum = metersFromLeft * metersFromLeft;
    sum += metersFromTop * metersFromTop;
    return sqrt(sum);
  }

  /// The [directionInRadians] of the offset in radians relative to Y-axis,
  /// using the Flutter coordinate system:
  /// y<0 and x=0 = [CardinalDirection.north] = 0
  /// y=0 and x>0 = [CardinalDirection.east] = 0.5*pi
  /// y>0 and x=0 = [CardinalDirection.south] = 1*pi
  /// y=0 and x<0 = [CardinalDirection.west] = 1.5*pi
  double get directionInRadians =>
      atan2(metersFromLeft, -metersFromTop) % (2 * pi);

  OffsetInMeters rotate(CompassDirection rotationToAdd) {
    if (rotationToAdd.degrees == 0) {
      return this;
    }
    var rotation = (directionInRadians + rotationToAdd.toRadians()) % (2 * pi);
    var length = lengthInMeters;
    var fromTop = -cos(rotation) * length;
    var fromLeft = sin(rotation) * length;
    return OffsetInMeters(metersFromLeft: fromLeft, metersFromTop: fromTop);
  }

  @override
  bool operator ==(Object other) =>
      other is OffsetInMeters &&
      other.runtimeType == runtimeType &&
      other.metersFromLeft == metersFromLeft &&
      other.metersFromTop == metersFromTop;

  @override
  int get hashCode => Object.hash(metersFromLeft, metersFromTop);

  @override
  String toString() =>
      'OffsetInMeters(metersFromLeft:$metersFromLeft,metersFromTop:$metersFromTop)';
}

class OffsetInMetersFromTopLeft extends OffsetInMeters {
  OffsetInMetersFromTopLeft(
      {required super.metersFromTop, required super.metersFromLeft});
}

class DrawerInLink<OWNER extends Machine> extends Link<OWNER, DrawerOutLink> {
  DrawerInLink(
      {required super.owner,
      required super.offsetFromCenter,
      required super.directionFromCenter});
}

class DrawerOutLink<OWNER extends Machine> extends Link<OWNER, DrawerInLink> {
  DrawerOutLink(
      {required super.owner,
      required super.offsetFromCenter,
      required super.directionFromCenter});
}

class DrawersInLink<OWNER extends Machine> extends Link<OWNER, DrawersOutLink> {
  DrawersInLink(
      {required super.owner,
      required super.offsetFromCenter,
      required super.directionFromCenter});
}

class DrawersOutLink<OWNER extends Machine> extends Link<OWNER, DrawersInLink> {
  DrawersOutLink(
      {required super.owner,
      required super.offsetFromCenter,
      required super.directionFromCenter});
}

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
