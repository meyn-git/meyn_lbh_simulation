import 'package:fling_units/fling_units.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';

main() {
  group('class: $LoadDensity', () {
    group('class: $LoadDensities()[0]', () {
    var loadDensity = LoadDensities()[0];

    test('field: standardOwner', () {
      expect(loadDensity.standardOwner, Supplier.meyn);
    });
    test('field: standardOwner', () {
      expect(loadDensity.birdType, BirdType.chicken);
    });
    test('field: type', () {
      expect(loadDensity.type, LoadDensityType.max());
    });
    test('field: squareMeterPerKgLiveWeight', () {
      expect(loadDensity.squareMeterPerKgLiveWeight, 0.0016);
    });
    });

    group('class: $LoadDensities()[1]', () {
      var loadDensity = LoadDensities()[1];

      test('field: standardOwner', () {
        expect(loadDensity.standardOwner, Supplier.meyn);
      });
      test('field: standardOwner', () {
        expect(loadDensity.birdType, BirdType.chicken);
      });
      test('field: type', () {
        expect(loadDensity.type, LoadDensityType.summer(percentage: 90));
      });
      test('field: squareMeterPerKgLiveWeight', () {
        expect(loadDensity.squareMeterPerKgLiveWeight, 0.0016*(100/90));
      });
    });
  });
}

Area _createArea(int squareCentimeters) =>
    Area.of(centi.meters(squareCentimeters), centi.meters(1));
