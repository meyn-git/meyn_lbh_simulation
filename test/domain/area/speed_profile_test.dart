import 'package:flutter_test/flutter_test.dart';
import 'package:meyn_lbh_simulation/domain/area/speed_profile.dart';
import 'package:shouldly/shouldly.dart';

void main() {
  group('$SpeedProfile default constructor', () {
    test(
        'a speedProfile of 0.5 m/s without acceleration and desceleration over a distance of 0.5 meter should take 1 second',
        () {
      var speedProfile = const SpeedProfile(
          maxSpeed: 0.5,
          acceleration: double.infinity,
          deceleration: double.infinity);
      speedProfile
          .durationOfDistance(0.5)
          .should
          .be(const Duration(seconds: 1));
    });

    test(
        'a speedProfile of 0.5 m/s without acceleration and desceleration over a distance of -0.5 meter should take 1 second',
        () {
      var speedProfile = const SpeedProfile(
          maxSpeed: 0.5,
          acceleration: double.infinity,
          deceleration: double.infinity);
      speedProfile
          .durationOfDistance(-0.5)
          .should
          .be(const Duration(seconds: 1));
    });

    test(
        'a speedProfile of 0.5 m/s without acceleration and desceleration over a distance of 1 meter should take 2 seconds',
        () {
      var speedProfile = const SpeedProfile(
          maxSpeed: 0.5,
          acceleration: double.infinity,
          deceleration: double.infinity);
      speedProfile.durationOfDistance(1).should.be(const Duration(seconds: 2));
    });

    test(
        'a max speed of 10 m/s without 2m/s/s acceleration and 1m/s/s desceleration over a distance of 100 meter should take 17.5 seconds',
        () {
      var speedProfile =
          const SpeedProfile(maxSpeed: 10, acceleration: 2, deceleration: 1);

      /// calculated:
      /// * acceleration = time = 10 m/s / 2m/s/s = 5s
      ///                  distance = 0.5 * 2 m/s/s * 5s ^ 2 = 25m
      /// * deceleration = time = 10 m/s / 1m/s/s = 10s
      ///                  distance = 0.5 * 1 m/s/s * 10s ^ 2 = 50m
      /// * constant speed = distance = 100m - 25m - 50m = 25m
      ///                    time = 100m / 10m/2 / 25m = 2.5s
      /// * duration = 5s + 2.5s + 10s = 17.5s
      speedProfile
          .durationOfDistance(100)
          .should
          .be(const Duration(seconds: 17, milliseconds: 500));
    });
  });

  group('$SpeedProfile.total constructor', () {
    test(
        'a max speed of 10 m/s without 2m/s/s acceleration and 1m/s/s desceleration '
        'over a distance of 100 meter should take 17.5 seconds', () {
      var speedProfile = SpeedProfile.total(
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

      speedProfile.maxSpeed.should.be(10);
      speedProfile.acceleration.should.be(2);
      speedProfile.deceleration.should.be(1);
      speedProfile
          .durationOfDistance(100)
          .should
          .be(const Duration(seconds: 17, milliseconds: 500));
    });
  });

  group('$ElectricModuleLiftSpeedProfile class', () {
    var speedProfile = const ElectricModuleLiftSpeedProfile();
    test(
        '$ElectricModuleLiftSpeedProfile maxSpeed should be 2m / (0.5*3s + (10s-3s-3s) + 0.5*3s) = 0.2857 m/s',
        () {
      speedProfile.maxSpeed.should.beCloseTo(0.2857, delta: 0.0001);
    });
    test(
        '$ElectricModuleLiftSpeedProfile acceleration should be 0.2857 m/s / 3s = 0.0952m/s/s',
        () {
      speedProfile.acceleration.should.beCloseTo(0.0952, delta: 0.0001);
    });
    test(
        '$ElectricModuleLiftSpeedProfile deceleration should be 0.2857 m/s / 3s = 0.0952m/s/s',
        () {
      speedProfile.deceleration.should.beCloseTo(0.0952, delta: 0.0001);
    });

    test('$ElectricModuleLiftSpeedProfile should travel 2 meters in 10seconds',
        () {
      speedProfile
          .durationOfDistance(
              ElectricModuleLiftSpeedProfile.totalDistanceInMeters)
          .should
          .be(const Duration(
              seconds: ElectricModuleLiftSpeedProfile.totalDurationInSeconds));
    });

    test(
        '$ElectricModuleLiftSpeedProfile should travel 0.5 meters in 5.292seconds',
        () {
      var speedProfile = const ElectricModuleLiftSpeedProfile();
      speedProfile
          .durationOfDistance(0.5)
          .should
          .be(const Duration(seconds: 5, milliseconds: 292));
    });
  });

  group(
      '$TurnTableSpeedProfileForContainersOrModulesWith2OrMoreCompartmentsPerLevel class',
      () {
    var speedProfile =
        const TurnTableSpeedProfileForContainersOrModulesWith2OrMoreCompartmentsPerLevel();
    test(
        'MaxSpeed should be 90 degrees / (0.5*2s + (6s-2s-2s) + 0.5*2s) = 22,5 degrees/s',
        () {
      speedProfile.maxSpeed.should.beCloseTo(22.5, delta: 0.01);
    });
    test('Acceleration should be 22,5 degree/s / 2s = 11,25 degree/s/s', () {
      speedProfile.acceleration.should.beCloseTo(11.25, delta: 0.01);
    });
    test('Deceleration should be  22,5 degree/s / 2s = 11,25 degree/s/s', () {
      speedProfile.deceleration.should.beCloseTo(11.25, delta: 0.01);
    });

    test('Should travel 90 degrees in 6seconds', () {
      speedProfile.durationOfDistance(90).should.be(const Duration(seconds: 6));
    });

    test('Should travel 180 degrees in 10seconds', () {
      speedProfile
          .durationOfDistance(180)
          .should
          .be(const Duration(seconds: 10));
    });
  });

  group(
      '$TurnTableSpeedProfileForContainersOrModulesWith1CompartmentPerLevel class',
      () {
    var speedProfile =
        const TurnTableSpeedProfileForContainersOrModulesWith1CompartmentPerLevel();
    test(
        'MaxSpeed should be 90 degrees / (0.5*2s + (9s-2s-2s) + 0.5*2s) = 12.857 degrees/s',
        () {
      speedProfile.maxSpeed.should.beCloseTo(12.857, delta: 0.001);
    });
    test('Acceleration should be 12.857 degree/s / 2s = 6.428 degree/s/s', () {
      speedProfile.acceleration.should.beCloseTo(6.428, delta: 0.001);
    });
    test('Deceleration should be 12.857 degree/s / 2s = 6.428 degree/s/s', () {
      speedProfile.deceleration.should.beCloseTo(6.428, delta: 0.001);
    });

    test('Should travel 90 degrees in 9seconds', () {
      speedProfile.durationOfDistance(90).should.be(const Duration(seconds: 9));
    });

    test('Should travel 180 degrees in 16seconds', () {
      speedProfile
          .durationOfDistance(180)
          .should
          .be(const Duration(seconds: 16));
    });
  });

  group('$TurnTableSpeedProfileForOmniaContainers class', () {
    var speedProfile = const TurnTableSpeedProfileForOmniaContainers();
    test(
        'MaxSpeed should be 90 degrees / (0.5*2s + (11.5s-4s-4s) + 0.5*2s) = 12 degrees/s',
        () {
      speedProfile.maxSpeed.should.beCloseTo(12, delta: 0.001);
    });
    test('Acceleration should be 6 degree/s / 2s = 3 degree/s/s', () {
      speedProfile.acceleration.should.beCloseTo(3, delta: 0.001);
    });
    test('Deceleration should be 6 degree/s / 2s = 3 degree/s/s', () {
      speedProfile.deceleration.should.beCloseTo(3, delta: 0.001);
    });

    test('Should travel 90 degrees in 11.5seconds', () {
      speedProfile
          .durationOfDistance(90)
          .should
          .be(const Duration(milliseconds: 11500));
    });

    test('Should travel 180 degrees in 16seconds', () {
      speedProfile
          .durationOfDistance(180)
          .should
          .be(const Duration(seconds: 19));
    });
  });

  group('$SpeedProfiles enum', () {
    test(
        '$SpeedProfiles.containersOrModulesWith2OrMoreCompartmentsPerLevel should rotate 90 degrees in 6s',
        () {
      SpeedProfiles
          .containersOrModulesWith2OrMoreCompartmentsPerLevel.turnTableTurn
          .durationOfDistance(90)
          .should
          .be(const Duration(seconds: 6));
    });

    test(
        '$SpeedProfiles.containersOrModulesWith1CompartmentsPerLevel should rotate 90 degrees in 9s',
        () {
      SpeedProfiles.containersOrModulesWith1CompartmentsPerLevel.turnTableTurn
          .durationOfDistance(90)
          .should
          .be(const Duration(seconds: 9));
    });

    test('$SpeedProfiles.meynOmnia should rotate 90 degrees in 11.5s', () {
      SpeedProfiles.meynOmnia.turnTableTurn
          .durationOfDistance(90)
          .should
          .be(const Duration(milliseconds: 11500));
    });
  });
}
