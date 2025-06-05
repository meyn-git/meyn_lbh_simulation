import 'dart:math';

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';

class VehicleRoute {
  final VehicleDirection vehicleDirection;
  CompassDirection _currentDirection;
  CompassDirection get lastDirection => _currentDirection;
  double _lengthInMeters = 0;
  double get lengthInMeters => _lengthInMeters;
  List<double> _cumulativeDistances = [];

  /// [points] from top left.
  late List<OffsetInMeters> points;

  VehicleRoute({
    required CompassDirection routeStartDirection,
    required OffsetInMeters startPoint,
    this.vehicleDirection = VehicleDirection.forward,
  }) : points = [startPoint],
       _currentDirection = routeStartDirection;

  late SizeInMeters size = _calculateSize();

  VehicleRoute addStraight(double distance) {
    if (distance < 0) {
      throw ArgumentError('must be positive', 'distance');
    }
    var radians = _currentDirection.toRadians();
    OffsetInMeters newPoint =
        points.last +
        OffsetInMeters(
          xInMeters: distance * sin(radians),
          yInMeters: distance * -cos(radians),
        );
    points.add(newPoint);
    updateCumulativeDistances();
    return this;
  }

  VehicleRoute addToPoint(OffsetInMeters destination) {
    points.add(destination);
    var directionInRadians =
        (points[points.length - 2] - points[points.length - 1])
            .directionInRadians;
    _currentDirection = CompassDirection(directionInRadians * 180 ~/ pi);
    updateCumulativeDistances();
    return this;
  }

  // e.g. [rotationInDegrees]: 45 = rotate 45 degrees to the right
  // e.g. [rotationInDegrees]:-90 = rotate 90 degrees to the left
  VehicleRoute addCurve(double radius, int rotationInDegrees) {
    double distanceFullCircle = pi * 2 * radius;
    double distance = distanceFullCircle * rotationInDegrees.abs() / 360;
    double distancePerDegree = distance / rotationInDegrees.abs();

    int direction = rotationInDegrees < 0 ? -1 : 1;
    // Generate points for each degree along the curve
    for (int i = 0; i < rotationInDegrees.abs(); i++) {
      _currentDirection = _currentDirection.rotate(direction);
      double endX = distancePerDegree * sin(_currentDirection.toRadians());
      double endY = distancePerDegree * -cos(_currentDirection.toRadians());

      // Add each calculated point to the list
      OffsetInMeters newPoint =
          points.last + OffsetInMeters(xInMeters: endX, yInMeters: endY);
      points.add(newPoint);
    }
    updateCumulativeDistances();
    return this;
  }

  OffsetInMeters pointAlongRoute(double traveledInMeters) {
    if (points.length == 1) {
      return points.first;
    }
    if (traveledInMeters < 0) {
      final startPoint = points[0];
      final endPoint = points[1];
      final direction = (endPoint - startPoint).directionInRadians;
      return startPoint +
          OffsetInMeters(
            xInMeters: traveledInMeters * sin(direction),
            yInMeters: traveledInMeters * -cos(direction),
          );
    }
    if (traveledInMeters > lengthInMeters) {
      final startPoint = points[points.length - 2];
      final endPoint = points[points.length - 1];
      final direction = (endPoint - startPoint).directionInRadians;
      final extraInMeters = traveledInMeters - lengthInMeters;
      return endPoint +
          OffsetInMeters(
            xInMeters: extraInMeters * sin(direction),
            yInMeters: extraInMeters * -cos(direction),
          );
    }

    // Find the segment the vehicle is on
    int index = _findSegmentIndex(traveledInMeters);

    // Get start and end points of the current segment
    final startPoint = points[index];
    final endPoint = points[index + 1];
    final segmentStartDist = _cumulativeDistances[index];
    final segmentEndDist = _cumulativeDistances[index + 1];

    // Calculate interpolation factor for the current segment
    final segmentFraction =
        (traveledInMeters - segmentStartDist) /
        (segmentEndDist - segmentStartDist);

    // Interpolate between startPoint and endPoint
    return OffsetInMeters(
      xInMeters:
          startPoint.xInMeters +
          (endPoint.xInMeters - startPoint.xInMeters) * segmentFraction,
      yInMeters:
          startPoint.yInMeters +
          (endPoint.yInMeters - startPoint.yInMeters) * segmentFraction,
    );
  }

  // Binary search function to find the segment index
  int _findSegmentIndex(double targetDistance) {
    int low = 0;
    int high = _cumulativeDistances.length - 2;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (_cumulativeDistances[mid] <= targetDistance &&
          targetDistance < _cumulativeDistances[mid + 1]) {
        return mid;
      } else if (_cumulativeDistances[mid] < targetDistance) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    // Fallback in case of an edge case, return the last segment
    return _cumulativeDistances.length - 2;
  }

  void updateCumulativeDistances() {
    _lengthInMeters = 0;
    _cumulativeDistances = [0];
    for (int i = 1; i < points.length; i++) {
      final distanceInMeters = (points[i] - points[i - 1]).lengthInMeters;
      _lengthInMeters = _lengthInMeters + distanceInMeters;
      _cumulativeDistances.add(_lengthInMeters);
    }
  }

  SizeInMeters _calculateSize() {
    var xPoints = points.map((point) => point.xInMeters);
    var xMin = xPoints.reduce(min);
    var xMax = xPoints.reduce(max);
    var yPoints = points.map((point) => point.yInMeters);
    var yMin = yPoints.reduce(min);
    var yMax = yPoints.reduce(max);
    return SizeInMeters(
      xInMeters: max((xMax - xMin), 0.01),
      yInMeters: max((yMax - yMin), 0.01),
    );
  }
}

enum VehicleDirection {
  forward(1),
  reverse(-1);

  final int sign;
  const VehicleDirection(this.sign);
}
