import 'package:meyn_lbh_simulation/area/module/drawer.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module_variant_builder.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';

class AngliaAutoFlowBuilder extends ModuleVariantBuilder {
  AngliaAutoFlowBuilder({super.parent})
      : super(
            values: ModuleVariantValues(
          brand: Brand.angliaAutoFlow,
          footprint: const SizeInMeters(xInMeters: 1.165, yInMeters: 2.438),
          camHeightInMeters: 0.1,
          frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        ));

  late final chicken = AngliaAutoFlowChickenBuilder(parent: this);
  late final turkey = AngliaAutoFlowTurkeyBuilder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [
    chicken,
    turkey,
  ];
}

class AngliaAutoFlowChickenBuilder extends ModuleVariantBuilder {
  AngliaAutoFlowChickenBuilder({super.parent})
      : super(
            values: ModuleVariantValues(
          birdType: BirdType.chicken,
          compartmentsPerLevel: 3,
        ));

  late final smallBirds = AngliaAutoFlowSmallChickenBuilder(parent: this);

  late final normalBirds = AngliaAutoFlowNormalChickenBuilder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [
    smallBirds,
    normalBirds,
  ];
}

class AngliaAutoFlowSmallChickenBuilder extends ModuleVariantBuilder {
  late final l4 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 4,
        totalHeightInMeters: 1.252,
        weightWithoutBirdsInKiloGram: 330,
      ));

  late final l5 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 5,
        totalHeightInMeters: 1.497,
        weightWithoutBirdsInKiloGram: 390,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [
    l4,
    l5,
  ];

  AngliaAutoFlowSmallChickenBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
          family: 'Small Birds',
          compartment: AngliaAutoFlowDrawers.l1160w770h225,
          compartmentsPerLevel: 3,
          headSpaceInMeters: 0.225,
        ));
}

class AngliaAutoFlowNormalChickenBuilder extends ModuleVariantBuilder {
  late final l4 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 4,
        totalHeightInMeters: 1.392,
        weightWithoutBirdsInKiloGram: 350,
      ));

  late final l5 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 5,
        totalHeightInMeters: 1.672,
        weightWithoutBirdsInKiloGram: 410,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [
    l4,
    l5,
  ];

  AngliaAutoFlowNormalChickenBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
          family: 'Normal Birds',
          compartment: AngliaAutoFlowDrawers.l1160w770h255,
          compartmentsPerLevel: 3,
          headSpaceInMeters: 0.255,
        ));
}

class AngliaAutoFlowTurkeyBuilder extends ModuleVariantLeafBuilder {
  AngliaAutoFlowTurkeyBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
          family: 'Turkey',
          birdType: BirdType.turkey,
          compartment: AngliaAutoFlowDrawers.l1160w1160h255,
          levels: 3,
          compartmentsPerLevel: 2,
          headSpaceInMeters: 0.355,
          totalHeightInMeters: 1.239,
          weightWithoutBirdsInKiloGram: 340,
        ));
}
