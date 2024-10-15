import 'package:flutter_test/flutter_test.dart';
import 'package:meyn_lbh_simulation/domain/area/travel_speed.dart';
import 'package:shouldly/shouldly.dart';

void main() {
  group('$TravelSpeed', () {
    group('$TravelSpeed default constructor', () {
      test(
          'a travelspeed of 0.5 m/s without acceleration and desceleration over a distance of 0.5 meter should take 1 second',
          () {
        var travelSpeed = const TravelSpeed(
            maxSpeed: 0.5,
            acceleration: double.infinity,
            deceleration: double.infinity);
        travelSpeed
            .durationOfDistance(0.5)
            .should
            .be(const Duration(seconds: 1));
      });

      test(
          'a travelspeed of 0.5 m/s without acceleration and desceleration over a distance of 1 meter should take 2 seconds',
          () {
        var travelSpeed = const TravelSpeed(
            maxSpeed: 0.5,
            acceleration: double.infinity,
            deceleration: double.infinity);
        travelSpeed.durationOfDistance(1).should.be(const Duration(seconds: 2));
      });

      test(
          'a max speed of 10 m/s without 2m/s/s acceleration and 1m/s/s desceleration over a distance of 100 meter should take 17.5 seconds',
          () {
        var travelSpeed =
            const TravelSpeed(maxSpeed: 10, acceleration: 2, deceleration: 1);

        /// calculated:
        /// * acceleration = time = 10 m/s / 2m/s/s = 5s
        ///                  distance = 0.5 * 2 m/s/s * 5s ^ 2 = 25m
        /// * deceleration = time = 10 m/s / 1m/s/s = 10s
        ///                  distance = 0.5 * 1 m/s/s * 10s ^ 2 = 50m
        /// * constant speed = distance = 100m - 25m - 50m = 25m
        ///                    time = 100m / 10m/2 / 25m = 2.5s
        /// * duration = 5s + 2.5s + 10s = 17.5s
        travelSpeed
            .durationOfDistance(100)
            .should
            .be(const Duration(seconds: 17, milliseconds: 500));
      });
    });

    group('$TravelSpeed.total constructor', () {
      test(
          'a max speed of 10 m/s without 2m/s/s acceleration and 1m/s/s desceleration '
          'over a distance of 100 meter should take 17.5 seconds', () {
        var travelSpeed = TravelSpeed.total(
            totalDistance: 100,
            totalDurationInSeconds: 17.5,
            accelerationInSeconds: 5,
            decelerationInSeconds: 10);

        /// totalDistance=100m
        /// maxSpeed=10m/s
        /// acceleration=2m/s/s
        /// deceleration=1m/s/s
        ///
        /// calculated:
        /// * acceleration = time = 10 m/s / 2m/s/s = 5s
        ///                  distance = 0.5 * 2 m/s/s * 5s ^ 2 = 25m
        /// * deceleration = time = 10 m/s / 1m/s/s = 10s
        ///                  distance = 0.5 * 1 m/s/s * 10s ^ 2 = 50m
        /// * constant speed = distance = 100m - 25m - 50m = 25m
        ///                    time = 100m / 10m/2 / 25m = 2.5s

        travelSpeed.maxSpeed.should.be(10);
        travelSpeed.acceleration.should.be(2);
        travelSpeed.deceleration.should.be(1);
        travelSpeed
            .durationOfDistance(100)
            .should
            .be(const Duration(seconds: 17, milliseconds: 500));
      });
    });
  });

  group('$ElectricModuleLiftSpeed class', () {
    test(
        '$ElectricModuleLiftSpeed maxSpeed should be 2m / (0.5*3s + (10s-3s-3s) + 0.5*3s) = 0.2857 m/s',
        () {
      var travelSpeed = const ElectricModuleLiftSpeed();
      travelSpeed.maxSpeed.should.beCloseTo(0.2857, delta: 0.0001);
    });
    test(
        '$ElectricModuleLiftSpeed acceleration should be 0.2857 m/s / 3s = 0.0952m/s/s',
        () {
      var travelSpeed = const ElectricModuleLiftSpeed();
      travelSpeed.acceleration.should.beCloseTo(0.0952, delta: 0.0001);
    });
    test(
        '$ElectricModuleLiftSpeed deceleration should be 0.2857 m/s / 3s = 0.0952m/s/s',
        () {
      var travelSpeed = const ElectricModuleLiftSpeed();
      travelSpeed.deceleration.should.beCloseTo(0.0952, delta: 0.0001);
    });

    test('$ElectricModuleLiftSpeed should travel 2 meters in 10seconds', () {
      var travelSpeed = const ElectricModuleLiftSpeed();
      travelSpeed
          .durationOfDistance(ElectricModuleLiftSpeed.totalDistanceInMeters)
          .should
          .be(const Duration(
              seconds: ElectricModuleLiftSpeed.totalDurationInSeconds));
    });

    test('$ElectricModuleLiftSpeed should travel 0.5 meters in 5.292seconds',
        () {
      var travelSpeed = const ElectricModuleLiftSpeed();
      travelSpeed
          .durationOfDistance(0.5)
          .should
          .be(const Duration(seconds: 5, milliseconds: 292));
    });
  });
}
