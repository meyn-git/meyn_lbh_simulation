import 'dart:math';

enum CardinalDirection {
  north,
  east,
  south,
  west;

  CompassDirection toCompassDirection() {
    switch (this) {
      case CardinalDirection.north:
        return CompassDirection(0);
      case CardinalDirection.east:
        return CompassDirection(90);
      case CardinalDirection.south:
        return CompassDirection(180);
      case CardinalDirection.west:
        return CompassDirection(270);
    }
  }

  CardinalDirection get opposite {
    switch (this) {
      case CardinalDirection.north:
        return CardinalDirection.south;
      case CardinalDirection.east:
        return CardinalDirection.west;
      case CardinalDirection.south:
        return CardinalDirection.north;
      case CardinalDirection.west:
        return CardinalDirection.east;
    }
  }

  bool isParallelTo(CardinalDirection otherDirection) =>
      this == otherDirection || this == otherDirection.opposite;

  bool isPerpendicularTo(CardinalDirection otherDirection) =>
      !isParallelTo(otherDirection);
}

class CompassDirection {
  final int degrees;
  static const int max = 360;

  CompassDirection(int degrees) : degrees = degrees % max;

  CompassDirection rotate(int rotationInDegrees) {
    return CompassDirection(degrees + rotationInDegrees);
  }

  CardinalDirection? toCardinalDirection() {
    for (var cardinalDirection in CardinalDirection.values) {
      if (cardinalDirection.toCompassDirection().degrees == degrees) {
        return cardinalDirection;
      }
    }
    return null;
  }

  int clockWiseDistanceInDegrees(CompassDirection destination) {
    if (degrees < destination.degrees) {
      return destination.degrees - degrees;
    } else {
      return max - degrees + destination.degrees;
    }
  }

  int counterClockWiseDistanceInDegrees(CompassDirection destination) {
    if (degrees > destination.degrees) {
      return degrees - destination.degrees;
    } else {
      return degrees + max - destination.degrees;
    }
  }

  double get radians => degrees / 360 * 2 * pi;

  @override
  String toString() => degrees.toString();
}
