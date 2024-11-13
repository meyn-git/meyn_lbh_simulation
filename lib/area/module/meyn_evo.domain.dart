import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module_variant_builder.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';

class EvoBuilder extends ModuleVariantBuilder {
  late final standard = EvoStandardBuilder(parent: this);
  late final usa = EvoUsaBuilder(parent: this);
  //late final storkCopy=EvoStorkCopyBuilder(parent:this);

  @override
  late final List<ModuleVariantBuilder> children = [
    standard,
    usa,
  ];

  EvoBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
                family: 'Evo',
                footprint: const SizeInMeters(
                  xInMeters: 1.2,
                  yInMeters: 2.4,
                ),
                compartment:
                    CompartmentWithDoor(birdFloorSpaceInSquareMeters: 1.311),
                camHeightInMeters: 0.065,
                compartmentsPerLevel: 2,
                frameMaterial: ModuleFrameMaterial.stainlessSteel,
                headSpaceInMeters: 0.245,
                birdType: BirdType.chicken));
}

class EvoStandardBuilder extends ModuleVariantBuilder {
  late final l4 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 4,
        totalHeightInMeters: 1.23,
        weightWithoutBirdsInKiloGram: 340,
      ));
  late final l5 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 5,
        totalHeightInMeters: 1.483,
        weightWithoutBirdsInKiloGram: 395,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [l4, l5];

  EvoStandardBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
                version: ModuleVersion(
                    name: 'standard', description: 'Most commonly used')));
}

class EvoUsaBuilder extends ModuleVariantBuilder {
  late final l5 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 5,
        totalHeightInMeters: 1.356,
        //weightWithoutBirdsInKiloGram: TODO,
      ));
  late final l6 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 6,
        totalHeightInMeters: 1.609,
        //weightWithoutBirdsInKiloGram: TODO,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [l5, l6];

  EvoUsaBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
                version: ModuleVersion(
                    name: 'usa',
                    description: 'These containers:\n'
                        '* Are a little lower\n'
                        '* Have different cams (so that you can only stack them one way around)\n'
                        '* Are only available in 5 and 6 levels\n'
                        'These containers where only sold to:\n'
                        '* 7113-Tyson Union City-TN-USA\n'
                        '* 9149-Bachoco Celaya - Mexico\n')));
}
