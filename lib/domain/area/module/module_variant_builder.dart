import 'package:fling_units/fling_units.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';

abstract class ModuleVariantBuilder {
  final ModuleVariantBuilder? parent;

  late final ModuleVariantBuilder root = parent == null ? this : parent!.root;

  Iterable<ModuleVariantLeafBuilder> get leafBuilders {
    var leafBuilders = <ModuleVariantLeafBuilder>[];
    if (this is ModuleVariantLeafBuilder) {
      leafBuilders.add(this as ModuleVariantLeafBuilder);
    } else {
      for (var child in children) {
        leafBuilders.addAll(child.leafBuilders);
      }
    }
    return leafBuilders;
  }

  final ModuleVariantValues values;

  List<ModuleVariantBuilder> get children;

  ModuleVariantBuilder({this.parent, required this.values});

  List<ModuleVariantBuilder> builderHierarchy() {
    var builders = <ModuleVariantBuilder>[];
    ModuleVariantBuilder? builder = this;
    do {
      builders.insert(0, builder!);
      builder = builder.parent;
    } while (builder != null);
    return builders;
  }
}

/// last [ModuleVariantBuilder] in a tree
class ModuleVariantLeafBuilder extends ModuleVariantBuilder {
  ModuleVariantLeafBuilder({required super.parent, required super.values});

  /// last [ModuleVariantBuilder] in a tree so no children
  @override
  List<ModuleVariantBuilder> get children => [];

  ModuleVariant build() {
    var values = populateValues();
    return ModuleVariant(
      brand: values.brand!,
      family: values.family!,
      version: values.version,
      birdType: values.birdType!,
      footprint: values.footprint!,
      compartment: values.compartment!,
      levels: values.levels!,
      compartmentsPerLevel: values.compartmentsPerLevel!,
      headSpaceInMeters: values.headSpaceInMeters,
      totalHeightInMeters: values.totalHeightInMeters!,
      camHeightInMeters: values.camHeightInMeters!,
      frameMaterial: values.frameMaterial!,
      weightWithoutBirdsInKiloGram: values.weightWithoutBirdsInKiloGram,
    );
  }

  ModuleVariantValues populateValues() {
    var populatedValues = ModuleVariantValues();
    for (var builder in builderHierarchy()) {
      populatedValues = populatedValues.merge(builder.values);
    }
    return populatedValues;
  }
}

class ModuleVariant {
  final Brand brand;
  final String family;
  final ModuleVersion? version;
  final SizeInMeters footprint;
  final Compartment compartment;
  final int levels;
  final BirdType birdType;
  final int compartmentsPerLevel;
  final double? headSpaceInMeters;
  // [totalHeightInMeters] is with cam
  final double totalHeightInMeters;
  final double camHeightInMeters;
  final ModuleFrameMaterial frameMaterial;
// [weightWithoutBirdsInKiloGram] is with drawers (if any)
  final double? weightWithoutBirdsInKiloGram;

  ModuleVariant({
    required this.brand,
    required this.family,
    this.version,
    required this.birdType,
    required this.footprint,
    required this.compartment,
    required this.levels,
    required this.compartmentsPerLevel,
    this.headSpaceInMeters,
    required this.totalHeightInMeters,
    required this.camHeightInMeters,
    required this.frameMaterial,
    this.weightWithoutBirdsInKiloGram,
  });

  ModuleCapacity withBirdsPerCompartment(int birdsPerCompartment) =>
      ModuleCapacity(
          compartmentsPerLevel: compartmentsPerLevel,
          levels: levels,
          birdsPerCompartment: birdsPerCompartment);

  ModuleCapacity withLoadDensity(
          LoadDensity loadDensity, Mass averageNormalBirdWeight) =>
      ModuleCapacity(
          compartmentsPerLevel: compartmentsPerLevel,
          levels: levels,
          birdsPerCompartment: birdsPerCompartment(
              loadDensity: loadDensity,
              averageBirdWeightOfHeaviestFlock: averageNormalBirdWeight));

  Mass maxWeightPerCompartment(LoadDensity loadDensity) =>
      kilo.grams(compartment.birdFloorSpaceInSquareMeters /
          loadDensity.squareMeterPerKgLiveWeight);

  int birdsPerCompartment({
    required LoadDensity loadDensity,
    required Mass averageBirdWeightOfHeaviestFlock,
  }) =>
      (maxWeightPerCompartment(loadDensity).as(grams) /
              averageBirdWeightOfHeaviestFlock.as(grams))
          .truncate();
}

abstract class Compartment {
  bool get birdsExitOnOneSide;
  double get birdFloorSpaceInSquareMeters;
}

class CompartmentWithDoor implements Compartment {
  @override
  final double birdFloorSpaceInSquareMeters;

  @override
  final bool birdsExitOnOneSide = true;

  CompartmentWithDoor({required this.birdFloorSpaceInSquareMeters});
}

/// Copy of ModuleVariant where all fields can be nullable
class ModuleVariantValues {
  final Brand? brand;
  final String? family;
  final ModuleVersion? version;
  final BirdType? birdType;
  final SizeInMeters? footprint;
  final Compartment? compartment;
  final int? levels;
  final int? compartmentsPerLevel;
  final double? headSpaceInMeters;
  // [totalHeightInMeters] is with cam
  final double? totalHeightInMeters;
  final double? camHeightInMeters;
  final ModuleFrameMaterial? frameMaterial;
  // [weightWithoutBirdsInKiloGram] is with drawers (if any)
  final double? weightWithoutBirdsInKiloGram;

  ModuleVariantValues({
    this.brand,
    this.family,
    this.version,
    this.birdType,
    this.footprint,
    this.compartment,
    this.levels,
    this.compartmentsPerLevel,
    this.headSpaceInMeters,
    this.totalHeightInMeters,
    this.camHeightInMeters,
    this.frameMaterial,
    this.weightWithoutBirdsInKiloGram,
  });

  ModuleVariantValues merge(ModuleVariantValues toMerge) => ModuleVariantValues(
        brand: toMerge.brand ?? brand,
        family: toMerge.family ?? family,
        version: toMerge.version ?? version,
        birdType: toMerge.birdType ?? birdType,
        footprint: toMerge.footprint ?? footprint,
        compartment: toMerge.compartment ?? compartment,
        levels: toMerge.levels ?? levels,
        compartmentsPerLevel:
            toMerge.compartmentsPerLevel ?? compartmentsPerLevel,
        headSpaceInMeters: toMerge.headSpaceInMeters ?? headSpaceInMeters,
        totalHeightInMeters: toMerge.totalHeightInMeters ?? totalHeightInMeters,
        camHeightInMeters: toMerge.camHeightInMeters ?? camHeightInMeters,
        frameMaterial: toMerge.frameMaterial ?? frameMaterial,
        weightWithoutBirdsInKiloGram: toMerge.weightWithoutBirdsInKiloGram ??
            weightWithoutBirdsInKiloGram,
      );

  @override
  String toString() {
    return 'ModuleVariantValues(\n'
        'ModuleVariantValues(\n'
        '  brand: $brand\n'
        '  family: $family\n'
        '  version: $version\n'
        '  birdType: $birdType\n'
        '  footprint: $footprint\n'
        '  compartment: $compartment\n'
        '  levels: $levels\n'
        '  compartmentsPerLevel: $compartmentsPerLevel\n'
        '  headSpaceInMeters: $headSpaceInMeters\n'
        '  totalHeightInMeters: $totalHeightInMeters\n'
        '  camHeightInMeters: $camHeightInMeters\n'
        '  frameMaterial: $frameMaterial\n'
        '  weightWithoutBirdsInKiloGram: $weightWithoutBirdsInKiloGram\n'
        ')';
  }
}

class ModuleVersion {
  final String name;
  final String description;

  ModuleVersion({required this.name, required this.description});
}
