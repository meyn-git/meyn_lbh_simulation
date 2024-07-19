import 'package:meyn_lbh_simulation/domain/area/module/drawer.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module_variant_builder.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';

class ClassicDrawerBuilder extends ModuleVariantBuilder {
  late final l4 = ModuleVariantLeafBuilder(
    parent: this,
    values: ModuleVariantValues(
      levels: 4,
      totalHeightInMeters: 1.331,
      weightWithoutBirdsInKiloGram: 369,
    ),
  );

  late final l5 = ModuleVariantLeafBuilder(
    parent: this,
    values: ModuleVariantValues(
      levels: 5,
      totalHeightInMeters: 1.617,
      weightWithoutBirdsInKiloGram: 440,
    ),
  );

  @override
  late final List<ModuleVariantBuilder> children = [
    l4,
    l5,
  ];

  ClassicDrawerBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
          family: 'Classic Drawer',
          footprint: const SizeInMeters(
            xInMeters: 1.16,
            yInMeters: 2.43,
          ),
          compartment: MeynDrawers.classic,
          compartmentsPerLevel: 3,
          birdType: BirdType.chicken,
          headSpaceInMeters: 0.255,
          camHeightInMeters: 0.07,
          frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        ));
}
