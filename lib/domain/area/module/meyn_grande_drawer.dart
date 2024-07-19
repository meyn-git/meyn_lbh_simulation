import 'package:meyn_lbh_simulation/domain/area/module/drawer.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module_variant_builder.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';

class GrandeDrawerBuilder extends ModuleVariantBuilder {
  late final m1 = GrandeDrawerM1Builder(parent: this);
  late final m2 = GrandeDrawerM2Builder(parent: this);
  late final m3 = GrandeDrawerM3Builder(parent: this);
  late final m4 = GrandeDrawerM4Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [m1, m2, m3, m4];

  GrandeDrawerBuilder({required super.parent})
      : super(
            values: ModuleVariantValues(
          family: 'Grande Drawer',
          footprint: const SizeInMeters(
            xInMeters: 1.18,
            yInMeters: 2.43,
          ),
          compartment: MeynDrawers.grande,
          birdType: BirdType.chicken,
        ));
}

/// For GrandeDrawer modules version M1
class GrandeDrawerM1Builder extends ModuleVariantBuilder {
  late final c2 = GrandeDrawerM1C2Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [
    c2,
  ];

  GrandeDrawerM1Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          version: ModuleVersion(
              name: 'M1',
              description: 'This is the first version of the Grande Module.\n'
                  'This module version is currently in use at the following customers\n'
                  '* 4339 - Mironovsky Vinnitsa – Ukraine\n'
                  '* 8219 - Société Agricole DICK – Tunisia\n'
                  'The M1 version cannot be sold to other customers.'),
          headSpaceInMeters: 0.255,
          camHeightInMeters: 0.03,
        ));
}

/// For modules with 2 compartments per level
class GrandeDrawerM1C2Builder extends ModuleVariantBuilder {
  late final l4 = GrandeDrawerM1C2L4Builder(parent: this);
  late final l5 = GrandeDrawerM1C2L5Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [l4, l5];

  GrandeDrawerM1C2Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          compartmentsPerLevel: 2,
        ));
}

/// For modules with 2 compartments and 4 levels
class GrandeDrawerM1C2L4Builder extends ModuleVariantBuilder {
  late final gs = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        weightWithoutBirdsInKiloGram: 338.6,
      ));

  late final ss = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.stainlessSteel,
        weightWithoutBirdsInKiloGram: 326.6,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [gs, ss];

  GrandeDrawerM1C2L4Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          levels: 4,
          totalHeightInMeters: 1.307,
        ));
}

/// For modules with 2 compartments and 4 levels
class GrandeDrawerM1C2L5Builder extends ModuleVariantBuilder {
  late final gs = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        weightWithoutBirdsInKiloGram: 392,
      ));

  late final ss = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.stainlessSteel,
        weightWithoutBirdsInKiloGram: 379,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [gs, ss];

  GrandeDrawerM1C2L5Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          levels: 5,
          totalHeightInMeters: 1.590,
        ));
}

/// For GrandeDrawer modules version M2
class GrandeDrawerM2Builder extends ModuleVariantBuilder {
  late final c2 = GrandeDrawerM2C2Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [
    c2,
  ];

  GrandeDrawerM2Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          version: ModuleVersion(
              name: 'M2',
              description: 'This is second version was introduced after the '
                  'evidence that the first version was too weak to withstand '
                  'normal continued operation at the 2 launching customers.\n'
                  'This module version is currently in use at the following customers\n'
                  '* 8595 - Hadco Al-Marai Poultry Processing Plant 4 - Saudi Arabia\n'
                  '* 9075 - Hadco Al-Marai Poultry Processing Plant 5 - Saudi Arabia\n'
                  '* 9075 - Hadco Al-Marai Poultry Processing Plant 6 - Saudi Arabia\n'
                  '* 5056 - Golden Chicken Farms – Saudi Arabia\n'
                  '* 8167 - Arasco - Hungary\n'
                  'The M2 version cannot be sold to other customers.\n'),
          headSpaceInMeters: 0.265,
          camHeightInMeters: 0.056,
        ));
}

/// For modules with 2 compartments per level
class GrandeDrawerM2C2Builder extends ModuleVariantBuilder {
  late final l4 = GrandeDrawerM2C2L4Builder(parent: this);
  late final l5 = GrandeDrawerM2C2L5Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [l4, l5];

  GrandeDrawerM2C2Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          compartmentsPerLevel: 2,
        ));
}

/// For modules with 2 compartments and 4 levels
class GrandeDrawerM2C2L4Builder extends ModuleVariantBuilder {
  late final gs = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        weightWithoutBirdsInKiloGram: 358.6,
      ));

  late final ss = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.stainlessSteel,
        weightWithoutBirdsInKiloGram: 345.6,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [gs, ss];

  GrandeDrawerM2C2L4Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          levels: 4,
          totalHeightInMeters: 1.349,
        ));
}

/// For modules with 2 compartments and 4 levels
class GrandeDrawerM2C2L5Builder extends ModuleVariantBuilder {
  late final gs = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        weightWithoutBirdsInKiloGram: 417,
      ));

  late final ss = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.stainlessSteel,
        weightWithoutBirdsInKiloGram: 403,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [gs, ss];

  GrandeDrawerM2C2L5Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          levels: 5,
          totalHeightInMeters: 1.641,
        ));
}

/// For GrandeDrawer modules version M2
class GrandeDrawerM3Builder extends ModuleVariantBuilder {
  late final c2 = GrandeDrawerM2C2Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [
    c2,
  ];

  GrandeDrawerM3Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          version: ModuleVersion(
              name: 'M3',
              description: 'This special version was introduced for Taravis '
                  'customer specifically to fulfill contract agreements '
                  'regarding the height of the modules that were sold. All '
                  'are 4 Layer modules made in galvanized steel with a 20mm '
                  'lower base and a centering cam of 48mm, compared to the '
                  'M2 version. \n'
                  'This module version is currently in use at the following '
                  'customer\n'
                  '* 4054 - Taravis Kft – Hungary\n'
                  'The M3 version cannot be sold to other customers.'),
          headSpaceInMeters: 0.260,
          camHeightInMeters: 0.048,
        ));
}

/// For modules with 2 compartments per level
class GrandeDrawerM3C2Builder extends ModuleVariantBuilder {
  late final l4 = GrandeDrawerM2C2L4Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [
    l4,
  ];

  GrandeDrawerM3C2Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          compartmentsPerLevel: 2,
        ));
}

/// For modules with 2 compartments and 4 levels
class GrandeDrawerM3C2L4Builder extends ModuleVariantBuilder {
  late final gs = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        weightWithoutBirdsInKiloGram: 354.6,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [gs];

  GrandeDrawerM3C2L4Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          levels: 4,
          totalHeightInMeters: 1.321,
        ));
}

/// For GrandeDrawer modules version M2
class GrandeDrawerM4Builder extends ModuleVariantBuilder {
  late final c1 = GrandeDrawerM4C1Builder(parent: this);
  late final c2 = GrandeDrawerM4C2Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [
    c2,
  ];

  GrandeDrawerM4Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          version: ModuleVersion(
              name: 'M4',
              description: 'This is the latest version developed with the goal '
                  'of making the module more attractive for customers within '
                  'Europe, given the lower stack height. The plastic tarps are '
                  'replaced with a steel sliding roof. Further improvements '
                  'ensure easier use of automatic catching machines.\n'
                  'It is likely that all new projects will get this version '
                  'starting 2024. Please contact the product manager when '
                  'selling new projects.\n'),
          headSpaceInMeters: 0.250,
          camHeightInMeters: 0.056,
        ));
}

/// For modules with 2 compartments per level
class GrandeDrawerM4C1Builder extends ModuleVariantBuilder {
  late final l4 = GrandeDrawerM4C1L4Builder(parent: this);
  late final l5 = GrandeDrawerM4C1L5Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [l4, l5];

  GrandeDrawerM4C1Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          compartmentsPerLevel: 1,
        ));
}

/// For modules with 1 compartment and 4 levels
class GrandeDrawerM4C1L4Builder extends ModuleVariantBuilder {
  late final gs = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        weightWithoutBirdsInKiloGram: 202,
      ));

  late final ss = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.stainlessSteel,
        weightWithoutBirdsInKiloGram: 195,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [gs, ss];

  GrandeDrawerM4C1L4Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          levels: 4,
          totalHeightInMeters: 1.299,
        ));
}

/// For modules with 1 compartment and 4 levels
class GrandeDrawerM4C1L5Builder extends ModuleVariantBuilder {
  late final gs = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        weightWithoutBirdsInKiloGram: 231,
      ));

  late final ss = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.stainlessSteel,
        weightWithoutBirdsInKiloGram: 223,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [gs, ss];

  GrandeDrawerM4C1L5Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          levels: 5,
          totalHeightInMeters: 1.581,
        ));
}

/// For modules with 2 compartments per level
class GrandeDrawerM4C2Builder extends ModuleVariantBuilder {
  late final l4 = GrandeDrawerM4C2L4Builder(parent: this);
  late final l5 = GrandeDrawerM4C2L5Builder(parent: this);

  @override
  late final List<ModuleVariantBuilder> children = [l4, l5];

  GrandeDrawerM4C2Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          compartmentsPerLevel: 2,
        ));
}

/// For modules with 2 compartments and 4 levels
class GrandeDrawerM4C2L4Builder extends ModuleVariantBuilder {
  late final gs = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        weightWithoutBirdsInKiloGram: 363.6,
      ));

  late final ss = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.stainlessSteel,
        weightWithoutBirdsInKiloGram: 350.6,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [gs, ss];

  GrandeDrawerM4C2L4Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          levels: 4,
          totalHeightInMeters: 1.299,
        ));
}

/// For modules with 2 compartments and 4 levels
class GrandeDrawerM4C2L5Builder extends ModuleVariantBuilder {
  late final gs = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.galvanizedSteel,
        weightWithoutBirdsInKiloGram: 420,
      ));

  late final ss = ModuleVariantLeafBuilder(
      parent: this,
      values: ModuleVariantValues(
        frameMaterial: ModuleFrameMaterial.stainlessSteel,
        weightWithoutBirdsInKiloGram: 406,
      ));

  @override
  late final List<ModuleVariantBuilder> children = [gs, ss];

  GrandeDrawerM4C2L5Builder({required super.parent})
      : super(
            values: ModuleVariantValues(
          levels: 5,
          totalHeightInMeters: 1.581,
        ));
}
