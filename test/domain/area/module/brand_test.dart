import 'package:flutter_test/flutter_test.dart';
import 'package:meyn_lbh_simulation/domain/area/module/brand.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module_variant_builder.dart';
import 'package:shouldly/shouldly.dart';

void main() {
  group('BrandBuilder', () {
    var leafBuilders = BrandBuilder().leafBuilders;
    test('leafBuilders should not be empty', () {
      leafBuilders.should.not.beEmpty();
    });

    var builderHierarchy = leafBuilders.first.builderHierarchy();
    test('builderHierarchy.length should not be >1', () {
      builderHierarchy.length.should.beAbove(1);
    });
    test('builderHierarchy should start with a BrandBuilder', () {
      builderHierarchy.first.should.beOfType<BrandBuilder>();
    });
    test('builderHierarchy should end with a ModuleVariantLeafBuilder', () {
      builderHierarchy.last.should.beOfType<ModuleVariantLeafBuilder>();
    });

    for (var leafBuilder in leafBuilders) {
      test('LeafBuilder.build() should not throw an exception', () {
        try {
          leafBuilder.build();
        } catch (e, trace) {
          var builderHierarchy = leafBuilder
              .builderHierarchy()
              .map((builder) => builder.runtimeType.toString())
              .join('.');
          Execute.assertion.forCondition(true).failWith('Exception: $e\n'
              'StackTrace: $trace\n'
              'BuilderHierarchy: $builderHierarchy\n'
              'Values: ${leafBuilder.populateValues()}');
        }
      });
    }
  });
}
