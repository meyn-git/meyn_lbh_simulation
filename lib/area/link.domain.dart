import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';

abstract class Link<
  OWNER extends LinkedSystem,
  LINKED_TO extends Link<LinkedSystem, dynamic>
> {
  /// the [LinkedSystem] that owns the [Link]
  final OWNER system;
  final OffsetInMeters offsetFromCenterWhenFacingNorth;

  final CompassDirection directionToOtherLink;

  /// the [linkedTo] is filled in by the [Systems.link] method
  LINKED_TO? linkedTo;

  Link({
    required this.system,
    required this.offsetFromCenterWhenFacingNorth,
    required this.directionToOtherLink,
  });
}

class DrawerInLink<OWNER extends LinkedSystem>
    extends Link<OWNER, DrawerOutLink> {
  DrawerInLink({
    required super.system,
    required super.offsetFromCenterWhenFacingNorth,
    required super.directionToOtherLink,
  });
}

class DrawerOutLink<OWNER extends LinkedSystem>
    extends Link<OWNER, DrawerInLink> {
  final bool visibleAndMutable;
  DrawerOutLink({
    required super.system,
    required super.offsetFromCenterWhenFacingNorth,
    required super.directionToOtherLink,
    this.visibleAndMutable = true,
  });
}

class DrawersInLink<OWNER extends LinkedSystem>
    extends Link<OWNER, DrawersOutLink> {
  /// returns 0 if it can not receive drawers
  /// or returns the number of drawers that can be received in one go.
  /// This is read and checked by [linkedTo.owner]
  /// before a transfer of drawer started
  final int Function() numberOfDrawersToFeedIn;

  // /// Called by [linkedTo.owner] when a transfer of drawers has started
  // /// Note that [linkedTo.owner] will change the position of the drawers
  // final void Function() onFeedInStarted;

  // /// Called by [linkedTo.owner] when a transfer of drawers is completed
  // final void Function(List<GrandeDrawer> transferredDrawers) onFeedInCompleted;

  DrawersInLink({
    required super.system,
    required super.offsetFromCenterWhenFacingNorth,
    required super.directionToOtherLink,
    required this.numberOfDrawersToFeedIn,
    // required this.onFeedInStarted,
    // required this.onFeedInCompleted,
  });
}

class DrawersOutLink<OWNER extends LinkedSystem>
    extends Link<OWNER, DrawersInLink> {
  DrawersOutLink({
    required super.system,
    required super.offsetFromCenterWhenFacingNorth,
    required super.directionToOtherLink,
  });
}

Duration moduleTransportDuration(
  ModuleGroupInLink<LinkedSystem> inLink,
  SpeedProfile conveyorSpeedProfile,
) {
  var source = inLink.linkedTo!;
  var destination = inLink;
  var distanceInMeters =
      source.distanceToFeedOutInMeters + destination.distanceToFeedInInMeters;
  var duration = conveyorSpeedProfile.durationOfDistance(distanceInMeters);
  // print(
  //   '${source.system.name}-${destination.system.name}: '
  //   '${source.distanceToFeedOutInMeters} + '
  //   '${destination.distanceToFeedInInMeters} ='
  //   ' $distanceInMeters m = ${(duration.inMilliseconds / 1000)} s',
  // );

  return duration;
}

class ModuleGroupInLink<OWNER extends LinkedSystem>
    extends Link<OWNER, ModuleGroupOutLink> {
  /// A function that calculates the ModuleGroup transport time
  /// between [ModuleGroupOutLink] and [ModuleGroupInLink]
  final Duration Function(ModuleGroupInLink<OWNER>) transportDuration;
  final bool feedInSingleStack;
  final bool Function() canFeedIn;
  final ModuleGroupPlace place;

  late double distanceToFeedInInMeters = _distanceToFeedInInMeters();

  double _distanceToFeedInInMeters() {
    var linkOffset = offsetFromCenterWhenFacingNorth;
    var modulePlaceOffset = place.offsetFromCenterWhenSystemFacingNorth;
    var lengthInMeters = (modulePlaceOffset - linkOffset).lengthInMeters.abs();
    return lengthInMeters;
  }

  ModuleGroupInLink({
    required this.place,
    required super.offsetFromCenterWhenFacingNorth,
    required super.directionToOtherLink,
    this.feedInSingleStack = false,
    required this.transportDuration,
    required this.canFeedIn,
  }) : super(system: (place.system as OWNER));

  @override
  String toString() =>
      "ModuleGroupInLink from: ${system.name} ${linkedTo?.system.name ?? ''}'}";
}

class ModuleGroupOutLink<OWNER extends LinkedSystem>
    extends Link<OWNER, ModuleGroupInLink> {
  /// * [Duration.zero] = The [LinkedSystem] can feed out now
  /// * [Duration] = Time until the [LinkedSystem] can feed out a module
  /// * [unknownDuration] = Unknown when the [LinkedSystem] can feed out a module
  final Duration Function() durationUntilCanFeedOut;
  final ModuleGroupPlace place;

  late double distanceToFeedOutInMeters = _distanceToFeedOutInMeters();

  double _distanceToFeedOutInMeters() {
    var linkOffset = offsetFromCenterWhenFacingNorth;
    var modulePlaceOffset = place.offsetFromCenterWhenSystemFacingNorth;
    var lengthInMeters = (modulePlaceOffset - linkOffset).lengthInMeters.abs();
    return lengthInMeters;
  }

  ModuleGroupOutLink({
    required this.place,
    required super.offsetFromCenterWhenFacingNorth,
    required super.directionToOtherLink,
    required this.durationUntilCanFeedOut,
  }) : super(system: (place.system as OWNER));

  ModuleGroupRoute? findRoute({
    required LinkedSystem destination,
    ModuleGroupRoute? routeSoFar,
  }) {
    routeSoFar ??= ModuleGroupRoute([]);
    routeSoFar.add(this);

    if (linkedTo?.system == destination) {
      // found it!
      return routeSoFar;
    }
    var neighbor = linkedTo?.system;
    if (neighbor == null) {
      // failed: no neighbor
      return null;
    }
    var outLinks = neighbor.links.whereType<ModuleGroupOutLink>().where(
      (outLink) => outLink.linkedTo != null,
    );
    for (var outLink in outLinks) {
      if (hasNoRoundTrips(routeSoFar, outLink)) {
        // recursive call
        var foundRoute = outLink.findRoute(
          destination: destination,
          routeSoFar: ModuleGroupRoute(List.from(routeSoFar)),
        );
        if (foundRoute != null) {
          return foundRoute;
        }
      } //try other outLinks
    }

    //failed: tried all links on this neighbor
    return null;
  }

  bool hasNoRoundTrips(
    ModuleGroupRoute route,
    ModuleGroupOutLink<LinkedSystem> linkToAdd,
  ) =>
      //    !route.systems.contains(linkToAdd.system) &&
      !route.systems.contains(linkToAdd.linkedTo!.system);

  @override
  String toString() =>
      "ModuleGroupOutLink(${system.name} ${linkedTo?.system.name ?? ''})";
}

//TODO make this an extension on Duration
/// Arbitrary duration to indicate an unknown duration
const Duration unknownDuration = Duration(days: 999);

class BirdsInLink<OWNER extends LinkedSystem>
    extends Link<OWNER, BirdsOutLink> {
  BirdsInLink({
    required super.system,
    required super.offsetFromCenterWhenFacingNorth,
    required super.directionToOtherLink,
  });

  @override
  String toString() =>
      "BirdsInLink from: ${system.name} ${linkedTo?.system.name ?? ''}";
}

class BirdsOutLink<OWNER extends LinkedSystem>
    extends Link<OWNER, BirdsInLink> {
  final int Function() availableBirds;
  final void Function(int numberOfBirds) transferBirds;

  BirdsOutLink({
    required super.system,
    required super.offsetFromCenterWhenFacingNorth,
    required super.directionToOtherLink,
    required this.availableBirds,
    required this.transferBirds,
  });

  @override
  String toString() =>
      "BirdsOutLink from: ${system.name} ${linkedTo?.system.name ?? ''}'}";
}
