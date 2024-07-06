// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:user_command/user_command.dart';

abstract class DrawerConveyor implements PhysicalSystem {
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
  late double systemProtrudesInMeters;

  late DrawerInLink drawerIn;

  late DrawerOutLink drawerOut;

  @override
  List<Link> get links => [drawerIn, drawerOut];
}

class DrawerConveyorStraight implements DrawerConveyor {
  @override
  late double systemProtrudesInMeters;

  /// the path to travel (in meters) for the drawer in [DefaultOrientation]
  @override
  late DrawerPath drawerPath;
  @override
  late double metersPerSecond;
  @override
  late String name = 'DrawerConveyorStraight';
  @override
  late List<Command> commands = [
    RemoveFromMonitorPanel(this),
  ];
  late double lengthInMeters;

  DrawerConveyorStraight({
    required this.lengthInMeters,
    required this.metersPerSecond,
    this.systemProtrudesInMeters = 0,
  }) : drawerPath = DrawerPath.straight(lengthInMeters);

  @override
  late SizeInMeters sizeWhenFacingNorth = SizeInMeters(
      xInMeters:
          DrawerConveyor.chainWidthInMeters + systemProtrudesInMeters * 2,
      yInMeters: lengthInMeters);

  @override
  late DrawerInLink drawerIn = DrawerInLink<DrawerConveyorStraight>(
      system: this,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: 0, yInMeters: sizeWhenFacingNorth.yInMeters / 2),
      directionToOtherLink: const CompassDirection.south());

  @override
  late DrawerOutLink drawerOut = DrawerOutLink(
      system: this,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: 0, yInMeters: -sizeWhenFacingNorth.yInMeters / 2),
      directionToOtherLink: const CompassDirection.north());

  @override
  late List<Link> links = [drawerIn, drawerOut];

  @override
  ObjectDetails get objectDetails => ObjectDetails(name);
}

class DrawerConveyor90Degrees implements DrawerConveyor {
  @override
  late double systemProtrudesInMeters;
  @override
  late DrawerPath drawerPath;
  @override
  late double metersPerSecond;
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];
  @override
  late String name = 'DrawerConveyor90Degrees';

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
      xInMeters: drawerPath.outWard.widthInMeters +
          DrawerConveyor.chainWidthInMeters / 2,
      yInMeters: drawerPath.outWard.heightInMeters +
          DrawerConveyor.chainWidthInMeters / 2);

  @override
  late DrawerInLink drawerIn = DrawerInLink(
      system: this,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: clockwise
              ? -sizeWhenFacingNorth.xInMeters / 2 +
                  DrawerConveyor.chainWidthInMeters / 2
              : sizeWhenFacingNorth.xInMeters / 2 -
                  DrawerConveyor.chainWidthInMeters / 2,
          yInMeters: sizeWhenFacingNorth.yInMeters / 2),
      directionToOtherLink: const CompassDirection.south());

  @override
  late DrawerOutLink drawerOut = DrawerOutLink(
      system: this,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: clockwise
              ? sizeWhenFacingNorth.xInMeters / 2
              : -sizeWhenFacingNorth.xInMeters / 2,
          yInMeters: -sizeWhenFacingNorth.yInMeters / 2 +
              DrawerConveyor.chainWidthInMeters / 2),
      directionToOtherLink: clockwise
          ? const CompassDirection.east()
          : const CompassDirection.west());

  @override
  late List<Link> links = [drawerIn, drawerOut];

  @override
  ObjectDetails get objectDetails => ObjectDetails(name);
}

/// A [DrawerConveyorStraight] that magically removes drawers
/// when they are at the end. E.g. manual processing or incomplete layouts
class DrawerRemover extends DrawerConveyorStraight implements TimeProcessor {
  LiveBirdHandlingArea area;

  DrawerRemover({required this.area, required super.metersPerSecond})
      : super(
          lengthInMeters: 2,
        );

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    var drawers = area.drawers;
    var drawersAtEnd = drawers
        .where((drawer) =>
            drawer.position is OnConveyorPosition &&
            (drawer.position as OnConveyorPosition).atEnd)
        .toList();
    for (var drawerAtEnd in drawersAtEnd) {
      drawerAtEnd.position = RemovedPosition();
      drawers.remove(drawerAtEnd);
    }
  }
}

class DrawerHangingConveyor extends DrawerConveyorStraight
    implements TimeProcessor {
  bool stopped = false;
  final ProductDefinition productDefinition;
  final List<GrandeDrawer> allDrawers;
  List<GrandeDrawer> drawersOnConveyor = [];

  /// the last conveyor of the [DrawerHangingConveyor] is speed controlled:
  /// * for optimal hanging performance (all hangers have birds available)
  /// * it runs slower than [firstConveyorInMeters] so that drawers are adjacent.
  ///
  /// The speed is controlled by the [OnConveyorPosition.conveyorSpeed] and
  /// [metersPerSecondOfEndConveyor].
  static const lastConveyorInMeters =
      GrandeDrawerModuleType.drawerOutSideLengthInMeters;

  /// the first conveyor of the [DrawerHangingConveyor] runs a continuous speed:
  /// * it runs faster than [lastConveyorInMeters] so that drawers are adjacent.
  late double firstConveyorInMeters =
      drawerPath.totalLengthInMeters - lastConveyorInMeters;

  DrawerHangingConveyor({
    required this.productDefinition,
    required int hangers,
    required double metersPerSecondOfFirstConveyor,
    super.systemProtrudesInMeters = 1,
    required this.allDrawers,
  }) : super(
          metersPerSecond: metersPerSecondOfFirstConveyor,
          //TODO
          lengthInMeters: max((hangers / 2).ceil() * 1, lastConveyorInMeters),
        );

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    drawersOnConveyor = findDrawersOnConveyor();
    if (drawersOnConveyor.length > 5) {
      //TODO: improve
      stopped = false;
    }
  }

  List<GrandeDrawer> findDrawersOnConveyor() => allDrawers
      .where((drawer) =>
          drawer.position is OnConveyorPosition &&
          (drawer.position as OnConveyorPosition).conveyor == this)
      .toList();

  late double secondsPerDrawer = 3600 /
      (productDefinition.lineSpeedInShacklesPerHour /
          productDefinition
              .moduleGroupCapacities.first.firstModule.birdsPerCompartment);
  late double lastConveyorSpeed =
      GrandeDrawerModuleType.drawerOutSideLengthInMeters / secondsPerDrawer;

  double get metersPerSecondOfLastConveyor => stopped ? 0 : lastConveyorSpeed;

  /// The last conveyor of the [DrawerHangingConveyor] is speed controlled:
  /// * for optimal hanging performance (all hangers have birds available)
  /// * it runs slower than [firstConveyorInMeters] so that drawers are adjacent.
  ///
  /// The speed is controlled by the [OnConveyorPosition.conveyorSpeed] and
  /// [metersPerSecondOfEndConveyor].
  bool isOnLastConveyor(double traveledMetersOnVector) =>
      traveledMetersOnVector > firstConveyorInMeters;

  ///
}

class DrawerSoakingConveyor extends DrawerConveyorStraight {
  DrawerSoakingConveyor({
    required super.metersPerSecond,
    super.systemProtrudesInMeters =
        (1.47 - DrawerConveyor.chainWidthInMeters) / 2,
  }) : super(
            lengthInMeters:
                10.5 // includes up towards washer TODO fixed length or min residence time?
            );
}

class DrawerWashingConveyor extends DrawerConveyorStraight {
  DrawerWashingConveyor({
    required super.metersPerSecond,
    super.systemProtrudesInMeters =
        (1.7 - DrawerConveyor.chainWidthInMeters) / 2,
  }) : super(lengthInMeters: 8.5 //TODO fixed length or min residence time?
            );
}

class DrawerWeighingConveyor extends DrawerConveyorStraight {
  DrawerWeighingConveyor({
    required super.metersPerSecond,
    super.systemProtrudesInMeters = 0.2,
  }) : super(lengthInMeters: 1.4 //TODO verify
            );
}

class DrawerTurningConveyor extends DrawerConveyorStraight {
  DrawerTurningConveyor({
    double diameter = 1 //TODO verify
    ,
    super.metersPerSecond = 2,
    super.systemProtrudesInMeters = 0.2,
  }) : super(
          lengthInMeters: diameter,
        );

  @override
  // ignore: overridden_fields
  late DrawerOutLink drawerOut = DrawerOutLink(
      system: this,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: 0, yInMeters: sizeWhenFacingNorth.yInMeters / 2),
      directionToOtherLink: const CompassDirection.south());
}

class DrawerPath extends DelegatingList<OffsetInMeters> {
  DrawerPath(super.base);

  factory DrawerPath.straight(double meters) =>
      DrawerPath([OffsetInMeters(xInMeters: 0, yInMeters: -meters)]);

  factory DrawerPath.ninetyDegreeCorner(bool clockwise, double lengthInMeters) {
    const steps = 12; //preferably a multitude of 3 (360 degrees)
    var vectors = DrawerPath([]);
    var angle = const CompassDirection.north();
    for (int i = 0; i < steps; i++) {
      var stepRotationInDegrees =
          (90 / (steps + 1)).round() * (clockwise ? 1 : -1);
      angle = angle.rotate(stepRotationInDegrees);
      var vector =
          OffsetInMeters(xInMeters: 0, yInMeters: lengthInMeters / steps * -1)
              .rotate(angle);
      vectors.add(vector);
    }
    return DrawerPath(vectors);
  }

  late Outward outWard = Outward.forVectors(this);

  double get totalLengthInMeters =>
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
      if (point.yInMeters < 0) {
        leftInMeters = min(leftInMeters, point.yInMeters);
      }
      if (point.yInMeters > 0) {
        rightInMeters = max(rightInMeters, point.yInMeters);
      }
      if (point.xInMeters < 0) {
        upInMeters = min(upInMeters, point.xInMeters);
      }
      if (point.xInMeters > 0) {
        downInMeters = max(downInMeters, point.xInMeters);
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
  double outSideLengthInMeters =
      GrandeDrawerModuleType.drawerOutSideLengthInMeters;
  BirdContents contents;
  DrawerPosition position;
  Duration? sinceEndStun;

  /// Distance traveled in meters from [startPosition]
  Offset traveledPath = Offset.zero;

  GrandeDrawer({
    //required this.startPosition,
    required int nrOfBirds,
    required this.contents,
    required this.position,
    required this.sinceEndStun,
  }) : _nrOfBirds = nrOfBirds;

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
    if (sinceEndStun != null) {
      sinceEndStun = sinceEndStun! + jump;
    }
  }
}

abstract class DrawerPosition {
  /// returns the center front position of the [GrandeDrawer]
  /// relative to the center position of a [DrawerConveyor]
  /// when the DrawerConveyor is in [DefaultOrientation]
  OffsetInMeters topLeft(SystemLayout layout);

  /// 0..1: 0=north, 0.25=east, 0.5=south, 0.75=west
  double rotationInFraction(SystemLayout layout);
}

/// Removed from [LiveBirdHandlingArea]
/// Needed because an other drawer may still look
/// at the position of the preceding (removed) drawer
class RemovedPosition extends DrawerPosition {
  @override
  double rotationInFraction(SystemLayout layout) => 0;

  @override
  OffsetInMeters topLeft(SystemLayout layout) => OffsetInMeters.zero;
}

abstract class DrawerPositionAndSize extends DrawerPosition {
  /// value for the size of the drawer:
  /// 1=normal drawer size
  /// 0.5=half the normal drawer size
  /// etc...
  double get scale;
}

class OnConveyorPosition extends DrawerPosition implements TimeProcessor {
  /// the conveyor where the drawer is on currently
  DrawerConveyor conveyor;

  /// the vector of the [drawerPath] where the drawer is on currently
  int vectorIndex;

  /// the traveled distance in meters on [vector] where the drawer is on currently
  double traveledMetersOnVector;

  final GrandeDrawer? precedingDrawer;

  double metersTraveledOnDrawerConveyors = 0;

  bool atEnd = false;

  OnConveyorPosition(
    this.conveyor, {
    this.traveledMetersOnVector = 0.0,
    required this.precedingDrawer,
  }) : vectorIndex = 0;

  /// calculates the next position of a drawer on a conveyor
  @override
  void onUpdateToNextPointInTime(Duration jump) {
    /// note that the drawerPath of the conveyor is not rotated,
    /// because this is done in the [SystemLayout]
    /// This should not matter because we needs its length only here
    var drawerPath = conveyor.drawerPath;
    var metersPerSecond = conveyorSpeed;
    var metersToTravel = _metersToTravel(metersPerSecond, jump);
    var remainingMetersOnVector =
        drawerPath[vectorIndex].lengthInMeters - traveledMetersOnVector;
    if (metersToTravel <= remainingMetersOnVector) {
      /// move on vector
      traveledMetersOnVector += metersToTravel;
      metersTraveledOnDrawerConveyors += metersToTravel;
    } else {
      metersTraveledOnDrawerConveyors += remainingMetersOnVector;
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
        var nextSystem = conveyor.drawerOut.linkedTo?.system;
        if (nextSystem != null && nextSystem is DrawerConveyor) {
          conveyor = nextSystem;
          vectorIndex = 0;
          traveledMetersOnVector = 0;
          //recursive call for next vector for the remaining time
          onUpdateToNextPointInTime(remainingJump);
        } else {
          // keep the drawer at the end.
          var lastVector = drawerPath.last;
          vectorIndex = drawerPath.length - 1;
          traveledMetersOnVector = lastVector.lengthInMeters;
          atEnd = true;
        }
      }
    }
  }

  double get conveyorSpeed {
    if (conveyor is DrawerHangingConveyor &&
        (conveyor as DrawerHangingConveyor)
            .isOnLastConveyor(traveledMetersOnVector)) {
      return (conveyor as DrawerHangingConveyor).metersPerSecondOfLastConveyor;
    } else {
      return conveyor.metersPerSecond;
    }
  }

  double _metersToTravel(double metersPerSecond, Duration jump) {
    var secondsOfTravel = jump.inMicroseconds / 1000000;
    var metersToTravel = metersPerSecond * secondsOfTravel;
    if (precedingDrawer == null ||
        precedingDrawer!.position is! OnConveyorPosition) {
      return metersToTravel;
    }

    /// ensure we are not overlapping drawers
    var metersInBetween = metersBetweenThisAndPrecedingDrawer();
    return min(metersToTravel, metersInBetween);
  }

  /// calculates the current position (offset) of a drawer on a conveyor
  @override
  OffsetInMeters topLeft(SystemLayout layout) =>
      layout.drawerStartOf(conveyor) +
      drawerStartToTopLeftDrawer(layout) +
      traveledOnConveyor(layout);

  OffsetInMeters traveledOnConveyor(SystemLayout layout) {
    var drawerPath = layout.drawerPathOf(conveyor);
    var vector = drawerPath[vectorIndex];
    var completedFraction = traveledMetersOnVector / vector.lengthInMeters;
    var traveled =
        (_sumOfCompletedVectors(drawerPath) + vector * completedFraction);
    return traveled;
  }

  /// The drawer start is the middle of the leading edge of the drawer
  /// Here we calculate the offset from drawer start to
  /// the top left of the drawer.
  /// This depends on the start rotation.
  OffsetInMeters drawerStartToTopLeftDrawer(SystemLayout layout) {
    double halveDrawerLength =
        GrandeDrawerModuleType.drawerOutSideLengthInMeters / 2;
    var startRotation = rotationInRadians(layout, 0);
    double xInMeters =
        -halveDrawerLength + -sin(startRotation) * halveDrawerLength;
    double yInMeters =
        -halveDrawerLength + cos(startRotation) * halveDrawerLength;
    var centerToTopLeft =
        OffsetInMeters(xInMeters: xInMeters, yInMeters: yInMeters);
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
  double rotationInFraction(SystemLayout layout) =>
      rotationInRadians(layout, vectorIndex) / (2 * pi);

  double rotationInRadians(SystemLayout layout, int index) =>
      layout.drawerPathOf(conveyor)[vectorIndex].directionInRadians;

  double metersBetweenThisAndPrecedingDrawer() {
    var preceding = (precedingDrawer!.position as OnConveyorPosition)
        .metersTraveledOnDrawerConveyors;
    var inBetween = preceding -
        metersTraveledOnDrawerConveyors -
        GrandeDrawerModuleType.drawerOutSideLengthInMeters;
    return inBetween;
  }
}
