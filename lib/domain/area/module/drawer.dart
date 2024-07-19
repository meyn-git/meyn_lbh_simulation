import 'package:meyn_lbh_simulation/domain/area/module/module_variant_builder.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';

abstract class DrawerGroup {
  List<DrawerVariant> get variants;
}

/// Italian supplier
class GiordanoDrawers extends DrawerGroup {
  static const DrawerVariant l1160w770h225 = DrawerVariant(
      heightInMeters: 0.225,
      footprint: SizeInMeters(
        xInMeters: 0.77,
        yInMeters: 1.16,
      ),
      birdFloorSpaceInSquareMeters: 0.8,
      birdsExitOnOneSide: false,
      weightInKiloGrams: 8.6);

  static const DrawerVariant l1160w770h255 = DrawerVariant(
      heightInMeters: 0.255,
      footprint: SizeInMeters(
        xInMeters: 0.77,
        yInMeters: 1.16,
      ),
      birdFloorSpaceInSquareMeters: 0.8,
      birdsExitOnOneSide: false,
      weightInKiloGrams: 9.2);

  static const DrawerVariant l1160w770h355 = DrawerVariant(
      heightInMeters: 0.355,
      footprint: SizeInMeters(
        xInMeters: 0.77,
        yInMeters: 1.16,
      ),
      birdFloorSpaceInSquareMeters: 0.8,
      birdsExitOnOneSide: false,
      weightInKiloGrams: 10.75);

  /// TODO Maxiload drawers

  @override
  final List<DrawerVariant> variants = [
    l1160w770h225,
    l1160w770h255,
    l1160w770h355
  ];
}

/// Turkish supplier
class AytavDrawers extends DrawerGroup {
  static const l1160w1160h255 = DrawerVariant(
      heightInMeters: 0.255,
      footprint: const SizeInMeters(
        xInMeters: 1.16,
        yInMeters: 1.16,
      ),
      birdFloorSpaceInSquareMeters: 1.221,
      birdsExitOnOneSide: true,
      weightInKiloGrams: 18.7);

  @override
  List<DrawerVariant> get variants => [l1160w1160h255];
}

/// English supplier
class AngliaAutoFlowDrawers extends DrawerGroup {
  static const DrawerVariant l1160w770h225 = DrawerVariant(
      heightInMeters: 0.225,
      footprint: SizeInMeters(
        xInMeters: 0.77,
        yInMeters: 1.16,
      ),
      birdFloorSpaceInSquareMeters: 0.8,
      birdsExitOnOneSide: false,
      weightInKiloGrams: 8.6
      // not sure: copied from GiordanoDrawers
      );

  static const DrawerVariant l1160w770h255 = DrawerVariant(
      heightInMeters: 0.255,
      footprint: SizeInMeters(
        xInMeters: 0.77,
        yInMeters: 1.16,
      ),
      birdFloorSpaceInSquareMeters: 0.8,
      birdsExitOnOneSide: false,
      weightInKiloGrams: 9.2
      // not sure: copied from GiordanoDrawers
      );

  static const DrawerVariant l1160w770h355 = DrawerVariant(
      heightInMeters: 0.355,
      footprint: SizeInMeters(
        xInMeters: 0.77,
        yInMeters: 1.16,
      ),
      birdFloorSpaceInSquareMeters: 0.8,
      birdsExitOnOneSide: false,
      weightInKiloGrams: 10.75
      // not sure: copied from GiordanoDrawers
      );

  static const l1160w1160h255 = DrawerVariant(
      heightInMeters: 0.255,
      footprint: const SizeInMeters(
        xInMeters: 1.16,
        yInMeters: 1.16,
      ),
      birdFloorSpaceInSquareMeters: 1.221,
      birdsExitOnOneSide: true,
      weightInKiloGrams: 19.2);

  @override
  List<DrawerVariant> get variants =>
      [l1160w770h225, l1160w770h255, l1160w770h355, l1160w1160h255];
}

class MeynDrawers extends DrawerGroup {
  static const classic = GiordanoDrawers.l1160w770h255;
  static const grande = AytavDrawers.l1160w1160h255;

  /// Used to be from Anglia AutoFlow

  @override
  final List<DrawerVariant> variants = [classic, grande];
}

/// See also [DrawerGroup] implementations
class DrawerVariant implements Compartment {
  static const double lengthInMeters = 1.16;
  final double heightInMeters;
  final double weightInKiloGrams;
  final SizeInMeters footprint;

  @override
  final double birdFloorSpaceInSquareMeters;

  @override
  final bool birdsExitOnOneSide;

  const DrawerVariant({
    required this.heightInMeters,
    required this.footprint,
    required this.birdFloorSpaceInSquareMeters,
    required this.birdsExitOnOneSide,
    required this.weightInKiloGrams,
  });

  @override
  bool operator ==(Object other) =>
      other is DrawerVariant &&
      other.heightInMeters == heightInMeters &&
      other.footprint == footprint &&
      other.birdFloorSpaceInSquareMeters == birdFloorSpaceInSquareMeters &&
      other.birdsExitOnOneSide == birdsExitOnOneSide &&
      other.weightInKiloGrams == weightInKiloGrams;

  @override
  int get hashCode => Object.hash(
        heightInMeters,
        footprint,
        birdFloorSpaceInSquareMeters,
        birdsExitOnOneSide,
        weightInKiloGrams,
      );
}
