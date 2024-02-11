import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/machine.dart';
import 'package:shouldly/shouldly.dart';

void main() {
  group('class OffsetInMeters', () {
    group('method OffsetInMeters.direction', () {
      test('method OffsetInMeters(0,-1).direction=0', () {
        const OffsetInMeters(metersFromLeft: 0, metersFromTop: -1)
            .direction
            .should
            .be(0);
      });
      test('method OffsetInMeters(1,0).direction=0.5*pi', () {
        const OffsetInMeters(metersFromLeft: 1, metersFromTop: 0)
            .direction
            .should
            .be(0.5 * pi);
      });
      test('method OffsetInMeters(0,1).direction=pi', () {
        const OffsetInMeters(metersFromLeft: 0, metersFromTop: 1)
            .direction
            .should
            .be(pi);
      });
      test('method OffsetInMeters(-1,0).direction=1.5*pi', () {
        const OffsetInMeters(metersFromLeft: -1, metersFromTop: 0)
            .direction
            .should
            .be(1.5 * pi);
      });

      group('method OffsetInMeters.rotate', () {
        var offset = const OffsetInMeters(metersFromLeft: 0, metersFromTop: -1);
        var precision = 0.0000000001;
        test('method OffsetInMeters(0,-1).rotate(0)=OffsetInMeters(0,-1)', () {
          offset
              .rotate(const CompassDirection(0))
              .metersFromLeft
              .should
              .beCloseTo(0, delta: precision);
          offset
              .rotate(const CompassDirection(0))
              .metersFromTop
              .should
              .beCloseTo(-1, delta: precision);
        });
        test('method OffsetInMeters(0,-1).rotate(90)=OffsetInMeters(1,0)', () {
          offset
              .rotate(const CompassDirection(90))
              .metersFromLeft
              .should
              .beCloseTo(1, delta: precision);
          offset
              .rotate(const CompassDirection(90))
              .metersFromTop
              .should
              .beCloseTo(0, delta: precision);
        });

        test('method OffsetInMeters(0,-1).rotate(180)=OffsetInMeters(0,1)', () {
          offset
              .rotate(const CompassDirection(180))
              .metersFromLeft
              .should
              .beCloseTo(0, delta: precision);
          offset
              .rotate(const CompassDirection(180))
              .metersFromTop
              .should
              .beCloseTo(1, delta: precision);
        });
        test('method OffsetInMeters(0,-1).rotate(270)=OffsetInMeters(-1,0)',
            () {
          offset
              .rotate(const CompassDirection(270))
              .metersFromLeft
              .should
              .beCloseTo(-1, delta: precision);
          offset
              .rotate(const CompassDirection(270))
              .metersFromTop
              .should
              .beCloseTo(0, delta: precision);
        });
      });
    });
  });
}
