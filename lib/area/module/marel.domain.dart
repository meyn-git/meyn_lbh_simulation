import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module_variant_builder.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';

class MarelBuilder extends ModuleVariantBuilder {
  late final gpl = MarelGplBuilder(parent: this);
  late final gps = MarelGpsBuilder(parent: this);
  late final gpsk = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
          birdType: BirdType.turkey,
          family: 'GP SK',
          levels: 6,
          compartment: CompartmentWithDoor(birdFloorSpaceInSquareMeters: 1.530),
          compartmentsPerLevel: 1,
          footprint: const SizeInMeters(xInMeters: 1.210, yInMeters: 1.420),
          totalHeightInMeters: 2.66,
          weightWithoutBirdsInKiloGram: 280));

  //TODO Atlas

  @override
  late final List<ModuleVariantBuilder> children = [gpl, gps, gpsk];

  MarelBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
                brand: Brand.marel,
                camHeightInMeters: 0.1,
                frameMaterial: ModuleFrameMaterial.galvanizedSteel,
                birdType: BirdType.chicken));
}

class MarelGplBuilder extends ModuleVariantBuilder {
  /// TODO add stainless steel versions
  late final l4 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 4,
        totalHeightInMeters: 1.36,
        weightWithoutBirdsInKiloGram: 399,
      ));
  late final l5 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 5,
        totalHeightInMeters: 1.465,
        weightWithoutBirdsInKiloGram: 440,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [l4, l5];

  MarelGplBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
          family: 'GP L',
          compartment:
              CompartmentWithDoor(birdFloorSpaceInSquareMeters: 2.55 / 2),
          compartmentsPerLevel: 2,
          footprint: const SizeInMeters(xInMeters: 1.2, yInMeters: 2.43),
        ));
}

class MarelGpsBuilder extends ModuleVariantBuilder {
  /// TODO add stainless steel versions
  late final l4 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 4,
        totalHeightInMeters: 1.36,
        weightWithoutBirdsInKiloGram: 399,
      ));
  late final l5 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 5,
        totalHeightInMeters: 1.465,
        weightWithoutBirdsInKiloGram: 440,
      ));
  late final l6 = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        levels: 6,
        totalHeightInMeters: 1.465,
        weightWithoutBirdsInKiloGram: 440,
      ));
  @override
  late final List<ModuleVariantBuilder> children = [l4, l5, l6];

  MarelGpsBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
          family: 'GP S',
          compartment: CompartmentWithDoor(birdFloorSpaceInSquareMeters: 1.53),
          compartmentsPerLevel: 1,
          footprint: const SizeInMeters(xInMeters: 1.2, yInMeters: 1.42),
        ));
}
