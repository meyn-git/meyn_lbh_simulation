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
  late DrawerPath drawerPath;
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
  late DrawerPath drawerPath;

  @override
  late double metersPerSecond;

  late double lengthInMeters;

  DrawerConveyorStraight({
    required this.lengthInMeters,
    required this.metersPerSecond,
    this.machineProtrudesInMeters = 0,
  }) : drawerPath = DrawerPath.straight(lengthInMeters);

  @override
  late SizeInMeters sizeWhenFacingNorth = SizeInMeters(
      widthInMeters:
          DrawerConveyor.chainWidthInMeters + machineProtrudesInMeters * 2,
      heightInMeters: lengthInMeters);

  @override
  late DrawerInLink drawerIn = DrawerInLink<DrawerConveyorStraight>(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: 0,
          metersFromTop: sizeWhenFacingNorth.heightInMeters / 2),
      directionFromCenter: CardinalDirection.south.toCompassDirection());

  @override
  late DrawerOutLink drawerOut = DrawerOutLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: 0,
          metersFromTop: -sizeWhenFacingNorth.heightInMeters / 2),
      directionFromCenter: CardinalDirection.north.toCompassDirection());

  @override
  late List<Link> links = [drawerIn, drawerOut];
}

class DrawerConveyor90Degrees implements DrawerConveyor {
  @override
  late double machineProtrudesInMeters;

  @override
  late DrawerPath drawerPath;

  @override
  late double metersPerSecond;

  final bool clockwise;

  DrawerConveyor90Degrees(
      {double lengthInMeters = 4.3,
      required this.clockwise,
      required this.metersPerSecond})
      : drawerPath = DrawerPath.ninetyDegreeCorner(
          clockwise,
          lengthInMeters,
        );

  @override
  late SizeInMeters sizeWhenFacingNorth = SizeInMeters(
      widthInMeters: drawerPath.outWard.widthInMeters +
          DrawerConveyor.chainWidthInMeters / 2,
      heightInMeters: drawerPath.outWard.heightInMeters +
          DrawerConveyor.chainWidthInMeters / 2);

  @override
  late DrawerInLink drawerIn = DrawerInLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: clockwise
              ? -sizeWhenFacingNorth.widthInMeters / 2 +
                  DrawerConveyor.chainWidthInMeters / 2
              : sizeWhenFacingNorth.widthInMeters / 2 -
                  DrawerConveyor.chainWidthInMeters / 2,
          metersFromTop: sizeWhenFacingNorth.heightInMeters / 2),
      directionFromCenter: CardinalDirection.south.toCompassDirection());

  @override
  late DrawerOutLink drawerOut = DrawerOutLink(
      owner: this,
      offsetFromCenter: OffsetInMeters(
          metersFromLeft: clockwise
              ? sizeWhenFacingNorth.widthInMeters / 2
              : -sizeWhenFacingNorth.widthInMeters / 2,
          metersFromTop: -sizeWhenFacingNorth.heightInMeters / 2 +
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
          metersFromTop: sizeWhenFacingNorth.heightInMeters / 2),
      directionFromCenter: CardinalDirection.south.toCompassDirection());
}

class DrawerPath extends DelegatingList<OffsetInMeters> {
  DrawerPath(super.base);

  factory DrawerPath.straight(double meters) =>
      DrawerPath([OffsetInMeters(metersFromLeft: 0, metersFromTop: -meters)]);

  factory DrawerPath.ninetyDegreeCorner(bool clockwise, double lengthInMeters) {
    const steps = 12; //preferably a multitude of 3 (360 degrees)
    var vectors = DrawerPath([]);
    var angle = CardinalDirection.north.toCompassDirection();
    for (int i = 0; i < steps; i++) {
      var stepRotationInDegrees =
          (90 / (steps + 1)).round() * (clockwise ? 1 : -1);
      angle = angle.rotate(stepRotationInDegrees);
      var x = sin(angle.toRadians()) * (lengthInMeters / steps);
      var y =
          -cos(angle.toRadians()) * (lengthInMeters / steps); //up is negative
      var vector = OffsetInMeters(metersFromLeft: x, metersFromTop: y);
      vectors.add(vector);
    }
    return DrawerPath(vectors);
  }

  late Outward outWard = Outward.forVectors(this);

  double get totalLength =>
      map((v) => v.lengthInMeters).reduce((a, b) => a + b);

  DrawerPath rotate(CompassDirection rotation) {
    var rotatedVectors = <OffsetInMeters>[];
    for (var vector in this) {
      rotatedVectors.add(vector.rotate(rotation));
    }
    return DrawerPath(rotatedVectors);
  }
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

  /// 0..1: 0=north, 0.25=east, 0.5=south, 0.75=west
  double rotationInFraction(MachineLayout layout);
}

class OnConveyorPosition extends DrawerPosition implements TimeProcessor {
  /// the conveyor where the drawer is on currently
  DrawerConveyor conveyor;

  /// the vector of the [drawerPath] where the drawer is on currently
  int vectorIndex;

  /// the traveled distance in meters on [vector] where the drawer is on currently
  double traveledMetersOnVector;

  OnConveyorPosition(this.conveyor)
      : vectorIndex = 0,
        traveledMetersOnVector = 0.0;

  /// calculates the next position of a drawer on a conveyor
  @override
  void onUpdateToNextPointInTime(Duration jump) {
    /// note that the drawerPath of the conveyor is not rotated,
    /// because this is done in the [MachineLayout]
    /// This should not matter because we needs its length only here
    var drawerPath = conveyor.drawerPath;
    var secondsOfTravel = jump.inMicroseconds / 1000000;
    var metersPerSecond = conveyor.metersPerSecond;
    var metersToTravel = metersPerSecond *
        secondsOfTravel; //TODO reduce [meterToTravel] when needed to not overlap other drawers!
    var remainingMetersOnVector =
        drawerPath[vectorIndex].lengthInMeters - traveledMetersOnVector;
    if (metersToTravel <= remainingMetersOnVector) {
      /// move on vector
      traveledMetersOnVector += metersToTravel;
    } else {
      // move on next vector
      var remainingJumpOnVector = Duration(
          microseconds: remainingMetersOnVector / metersPerSecond ~/ 1000000);
      var remainingJump = jump - remainingJumpOnVector;
      var nextVector = _nextVectorIndex();
      if (nextVector != null) {
        vectorIndex = nextVector;
        traveledMetersOnVector = 0;
        //recursive call for next vector for the remaining time
        onUpdateToNextPointInTime(remainingJump);
      } else {
        var nextMachine = conveyor.drawerOut.linkedTo.owner;
        if (nextMachine is DrawerConveyor) {
          conveyor = nextMachine;
          vectorIndex = 0;
          traveledMetersOnVector = 0;
          //recursive call for next vector for the remaining time
          onUpdateToNextPointInTime(remainingJump);
        } else {
          // keep the drawer at the end.
          var lastVector = drawerPath.last;
          vectorIndex = drawerPath.length - 1;
          traveledMetersOnVector = lastVector.lengthInMeters;
        }
      }
    }
  }

  /// calculates the current position (offset) of a drawer on a conveyor
  @override
  OffsetInMeters topLeft(MachineLayout layout) =>
      layout.drawerStartOf(conveyor) +
      drawerStartToTopLeftDrawer(layout) +
      traveledOnConveyor(layout);

  OffsetInMeters traveledOnConveyor(MachineLayout layout) {
    var drawerPath = layout.drawerPathOf(conveyor);
    var vector = drawerPath[vectorIndex];
    var completedFraction = traveledMetersOnVector / vector.lengthInMeters;
    var traveled =
        (_sumOfCompletedVectors(drawerPath) + vector * completedFraction);
    return traveled;
  }

  OffsetInMeters drawerStartToTopLeftDrawer(MachineLayout layout) {
    double halveDrawerLength =
        GrandeDrawerModuleType.drawerOutSideLength.as(meters) / 2;
    var startRotation = rotationInRadians(layout, 0);
    double metersFromLeft =
        -halveDrawerLength + -sin(startRotation) * halveDrawerLength;
    double metersFromTop =
        -halveDrawerLength + cos(startRotation) * halveDrawerLength;
    var centerToTopLeft = OffsetInMeters(
        metersFromLeft: metersFromLeft, metersFromTop: metersFromTop);
    return centerToTopLeft;
  }

  Iterable<OffsetInMeters> _completedVectors(DrawerPath drawerPath) {
    return drawerPath.getRange(0, vectorIndex);
  }

  OffsetInMeters _sumOfCompletedVectors(DrawerPath drawerPath) {
    var vectors = _completedVectors(drawerPath);
    if (vectors.isEmpty) {
      return OffsetInMeters.zero;
    }
    return vectors.reduce((a, b) => a + b);
  }

  /// returns the [drawerPath] index of the next vector.
  /// returns null if there is no next vector.
  int? _nextVectorIndex() {
    if (vectorIndex >= conveyor.drawerPath.length - 1) {
      return null;
    }
    return vectorIndex + 1;
  }

  @override
  double rotationInFraction(MachineLayout layout) =>
      rotationInRadians(layout, vectorIndex) / (2 * pi);

  double rotationInRadians(MachineLayout layout, int index) =>
      layout.drawerPathOf(conveyor)[vectorIndex].directionInRadians;
}
