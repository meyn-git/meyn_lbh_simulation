import 'package:meyn_lbh_simulation/area/module/anglia_auto_flow.domain.dart';
import 'package:meyn_lbh_simulation/area/module/marel.domain.dart';
import 'package:meyn_lbh_simulation/area/module/meyn_classic_drawer.domain.dart';
import 'package:meyn_lbh_simulation/area/module/meyn_evo.domain.dart';
import 'package:meyn_lbh_simulation/area/module/meyn_grande_drawer.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module.domain.dart';
import 'package:meyn_lbh_simulation/area/module/module_variant_builder.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';

class BrandBuilder extends ModuleVariantBuilder {
  BrandBuilder() : super(values: ModuleVariantValues());
  late final meyn = MeynBuilder(parent: this);
  late final angliaAutoFlow = AngliaAutoFlowBuilder(parent: this);
  late final marel = MarelBuilder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [
    meyn,
    angliaAutoFlow,
    marel,
  ];

  List<ModuleVariant> buildAll() {
    var variants = <ModuleVariant>[];
    for (var leafBuilder in leafBuilders) {
      var variant = leafBuilder.build();
      variants.add(variant);
    }
    return variants;
  }
}

class MeynBuilder extends ModuleVariantBuilder {
  MeynBuilder({super.parent})
    : super(values: ModuleVariantValues(brand: Brand.meyn));

  late final grandeDrawer = GrandeDrawerBuilder(parent: this);
  late final classicDrawer = ClassicDrawerBuilder(parent: this);
  late final evo = EvoBuilder(parent: this);
  late final omnia = ModuleVariantLeafBuilder(
    parent: this,
    values: ModuleVariantValues(
      family: 'Omnia',
      birdType: BirdType.turkey,
      footprint: const SizeInMeters(xInMeters: 1.35, yInMeters: 2.43),
      compartment: CompartmentWithDoor(birdFloorSpaceInSquareMeters: 2.1),
      levels: 3,
      compartmentsPerLevel: 2,
      headSpaceInMeters: 0.38,
      totalHeightInMeters: 1.404,
      camHeightInMeters: 0.059,
      frameMaterial: ModuleFrameMaterial.stainlessSteel,
      weightWithoutBirdsInKiloGram: 420,
    ),
  );

  /// TODO MaxiloadTwin

  @override
  late final List<ModuleVariantBuilder> children = [
    grandeDrawer,
    classicDrawer,
    evo,
    omnia,
  ];
}
