import 'dart:math';


class CompassDirection {
  final int degrees;
  static const int max = 360;

  const CompassDirection(int degrees) : degrees = degrees % max;

  const CompassDirection.unknown() : degrees = -1;
  const CompassDirection.north() : degrees = 0;
  const CompassDirection.east() : degrees = 90;
  const CompassDirection.south() : degrees = 180;
  const CompassDirection.west() : degrees = 270;

  CompassDirection get opposite => rotate(180);

  CompassDirection rotate(int rotationInDegrees) {
    return CompassDirection(degrees + rotationInDegrees);
  }

  CompassDirection operator +(CompassDirection other) =>
      CompassDirection(degrees + other.degrees);

  CompassDirection operator -(CompassDirection other) =>
      CompassDirection(degrees - other.degrees);

 

  double toRadians() => degrees * pi / 180;

  /// 0..1: 0=north, 0.25=east, 0.5=south, 0.75=west
  double toFraction() => degrees / max;

  int clockWiseDistanceInDegrees(CompassDirection destination) {
    if (degrees <= destination.degrees) {
      return destination.degrees - degrees;
    } else {
      return max - degrees + destination.degrees;
    }
  }

  int counterClockWiseDistanceInDegrees(CompassDirection destination) {
    if (degrees >= destination.degrees) {
      return degrees - destination.degrees;
    } else {
      return degrees + max - destination.degrees;
    }
  }

  @override
  String toString() => degrees.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompassDirection &&
          runtimeType == other.runtimeType &&
          degrees == other.degrees;

  @override
  int get hashCode => degrees.hashCode;
}
