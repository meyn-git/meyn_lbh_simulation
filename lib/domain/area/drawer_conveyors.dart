// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fling_units/fling_units.dart';
import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/machine.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/gui/area/area.dart';

abstract class DrawerConveyor implements Machine {
  /// * y: number of meters in north/south direction, e.g.:
  ///   * -3 = 3 meters north
  ///   * +2 = 2 meters south
  /// * x: number of meters in west/east direction, e.g.:
  ///   * -3 = 3 meters west
  ///   * +2 = 2 meters east
  late ProductCarrierPath vectors;
  double metersPerSecond = 0;
  static const double chainWidthInMeters = 0.8;

  /// simple drawer conveyors protrude 0m
  /// drawer weighers, washers, rotators protrude 0,3m?
  /// hanging platform protrude 1m?
  late double machineProtrudesInMeters;

  late DrawerInLink drawerIn;

  late DrawerOutLink drawerOut;

  @override
  List<Link> get links => [drawerIn, drawerOut];
}

class DrawerConveyorStraight implements DrawerConveyor {
  @override
  late double machineProtrudesInMeters;

  /// the path to travel (in meters) for the drawer in [DefaultOrientation]
  @override
  late ProductCarrierPath vectors;

  @override
  late double metersPerSecond;

  late double lengthInMeters;

  DrawerConveyorStraight({
    required this.lengthInMeters,
    required this.metersPerSecond,
    this.machineProtrudesInMeters = 0,
  }) : vectors = ProductCarrierPath.straight(lengthInMeters);

  @override
  late SizeInMeters sizeWhenNorthBound = SizeInMeters(
      widthInMeters:
          DrawerConveyor.chainWidthInMeters + machineProtrudesInMeters * 2,
      heightInMeters: lengthInMeters);

  @override
  late DrawerInLink drawerIn = DrawerInLink<DrawerConveyorStraight>(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: 0,
          metersFromTop: sizeWhenNorthBound.heightInMeters / 2),
      directionFromCenter: CardinalDirection.south.toCompassDirection());

  @override
  late DrawerOutLink drawerOut = DrawerOutLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: 0,
          metersFromTop: -sizeWhenNorthBound.heightInMeters / 2),
      directionFromCenter: CardinalDirection.north.toCompassDirection());

  @override
  late List<Link> links = [drawerIn, drawerOut];
}

class DrawerConveyor90Degrees implements DrawerConveyor {
  @override
  late double machineProtrudesInMeters;

  @override
  late ProductCarrierPath vectors;

  @override
  late double metersPerSecond;

  final bool clockwise;

  DrawerConveyor90Degrees(
      {double lengthInMeters = 4.3,
      required this.clockwise,
      required this.metersPerSecond})
      : vectors = ProductCarrierPath.ninetyDegreeCorner(
          clockwise,
          lengthInMeters,
        );

  @override
  late SizeInMeters sizeWhenNorthBound = SizeInMeters(
      widthInMeters:
          vectors.outWard.widthInMeters + DrawerConveyor.chainWidthInMeters / 2,
      heightInMeters: vectors.outWard.heightInMeters +
          DrawerConveyor.chainWidthInMeters / 2);

  @override
  late DrawerInLink drawerIn = DrawerInLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: clockwise
              ? -sizeWhenNorthBound.widthInMeters / 2 +
                  DrawerConveyor.chainWidthInMeters / 2
              : sizeWhenNorthBound.widthInMeters / 2 -
                  DrawerConveyor.chainWidthInMeters / 2,
          metersFromTop: sizeWhenNorthBound.heightInMeters / 2),
      directionFromCenter: CardinalDirection.south.toCompassDirection());

  @override
  late DrawerOutLink drawerOut = DrawerOutLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: clockwise
              ? sizeWhenNorthBound.widthInMeters / 2
              : -sizeWhenNorthBound.widthInMeters / 2,
          metersFromTop: -sizeWhenNorthBound.heightInMeters / 2 +
              DrawerConveyor.chainWidthInMeters / 2),
      directionFromCenter: clockwise
          ? CardinalDirection.east.toCompassDirection()
          : CardinalDirection.west.toCompassDirection());

  @override
  late List<Link> links = [drawerIn, drawerOut];
}

class DrawerHangingConveyor extends DrawerConveyorStraight {
  DrawerHangingConveyor({
    required int hangers,
    required super.metersPerSecond,
    super.machineProtrudesInMeters = 1,
  }) : super(
          //TODO
          lengthInMeters: (hangers / 2).ceil() * 1,
        );
}

class DrawerSoakingConveyor extends DrawerConveyorStraight {
  DrawerSoakingConveyor({
    required super.metersPerSecond,
    super.machineProtrudesInMeters = 0.3,
  }) : super(
            lengthInMeters:
                10.5 // includes up towards washer TODO fixed length or min residence time?
            );
}

class DrawerWashingConveyor extends DrawerConveyorStraight {
  DrawerWashingConveyor({
    required super.metersPerSecond,
    super.machineProtrudesInMeters = 0.3,
  }) : super(lengthInMeters: 8.5 //TODO fixed length or min residence time?
            );
}

class DrawerWeighingConveyor extends DrawerConveyorStraight {
  DrawerWeighingConveyor({
    required super.metersPerSecond,
    super.machineProtrudesInMeters = 0.2,
  }) : super(lengthInMeters: 1.4 //TODO verify
            );
}

class DrawerTurningConveyor extends DrawerConveyorStraight {
  DrawerTurningConveyor({
    double diameter = 1 //TODO verify
    ,
    super.metersPerSecond = 2,
    super.machineProtrudesInMeters = 0.2,
  }) : super(
          lengthInMeters: diameter,
        );

  @override
  // ignore: overridden_fields
  late DrawerOutLink drawerOut = DrawerOutLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: 0,
          metersFromTop: sizeWhenNorthBound.heightInMeters / 2),
      directionFromCenter: CardinalDirection.south.toCompassDirection());
}

class ProductCarrierPath extends DelegatingList<OffsetInMeters> {
  ProductCarrierPath(super.base);

  factory ProductCarrierPath.straight(double meters) => ProductCarrierPath(
      [OffsetInMeters(metersFromLeft: 0, metersFromTop: -meters)]);

  factory ProductCarrierPath.ninetyDegreeCorner(
      bool clockwise, double lengthInMeters) {
    const steps = 6; //preferably a multitude of 3 (360 degrees)
    var vectors = ProductCarrierPath([]);
    var angle = CardinalDirection.north.toCompassDirection();
    for (int i = 0; i < steps; i++) {
      var stepRotationInDegrees =
          (90 / (steps + 1)).round() * (clockwise ? 1 : -1);
      angle = angle.rotate(stepRotationInDegrees);
      var x = sin(angle.toRadians());
      var y = -cos(angle.toRadians()); //up is negative
      var vector = OffsetInMeters(metersFromLeft: x, metersFromTop: y)
          .withLengthInMeters(lengthInMeters / steps);
      vectors.add(vector);
    }
    return ProductCarrierPath(vectors);
  }

  late Outward outWard = Outward.forVectors(this);

  double get totalLength =>
      map((v) => v.lengthInMeters).reduce((a, b) => a + b);
}

class Outward {
  final double upInMeters;
  final double rightInMeters;
  final double downInMeters;
  final double leftInMeters;

  Outward({
    required this.upInMeters,
    required this.rightInMeters,
    required this.downInMeters,
    required this.leftInMeters,
  });

  factory Outward.forVectors(List<OffsetInMeters> vectors) {
    var leftInMeters = 0.0;
    var rightInMeters = 0.0;
    var upInMeters = 0.0;
    var downInMeters = 0.0;
    var point = OffsetInMeters.zero;
    for (var vector in vectors) {
      point += vector;
      if (point.metersFromLeft < 0) {
        leftInMeters = min(leftInMeters, point.metersFromLeft);
      }
      if (point.metersFromLeft > 0) {
        rightInMeters = max(rightInMeters, point.metersFromLeft);
      }
      if (point.metersFromTop < 0) {
        upInMeters = min(upInMeters, point.metersFromTop);
      }
      if (point.metersFromTop > 0) {
        downInMeters = max(downInMeters, point.metersFromTop);
      }
    }
    return Outward(
        upInMeters: upInMeters,
        rightInMeters: rightInMeters,
        downInMeters: downInMeters,
        leftInMeters: leftInMeters);
  }

  late double widthInMeters = (leftInMeters - rightInMeters).abs();
  late double heightInMeters = (upInMeters - downInMeters).abs();
}

class GrandeDrawer implements TimeProcessor {
  int _nrOfBirds;
  Distance outSideLength = GrandeDrawerModuleType.drawerOutSideLength;
  double distanceTraveledInMeters = 0;
  BirdContents contents;
  DrawerPosition position;
  final Position startPosition;

  /// Distance traveled in meters from [startPosition]
  Offset traveledPath = Offset.zero;

  GrandeDrawer(
      {required this.startPosition,
      required int nrOfBirds,
      required this.contents,
      required this.position})
      : _nrOfBirds = nrOfBirds;

  CompassDirection get direction =>
      CardinalDirection.north.toCompassDirection(); //TODO get from vector;

  set nrOfBirds(int nrOfBirds) {
    if (nrOfBirds == 0) {
      contents = BirdContents.noBirds;
    }
    _nrOfBirds = nrOfBirds;
  }

  int get nrOfBirds => _nrOfBirds;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (position is TimeProcessor) {
      (position as TimeProcessor).onUpdateToNextPointInTime(jump);
    }
  }
}

abstract class DrawerPosition {
  /// returns the center front position of the [GrandeDrawer]
  /// relative to the center position of a [DrawerConveyor]
  /// when the DrawerConveyor is in [DefaultOrientation]
  /// in meters
  OffsetInMeters topLeft(MachineLayout layout);
}
