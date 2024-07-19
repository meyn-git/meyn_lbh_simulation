import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/module/drawer.dart';
import 'package:meyn_lbh_simulation/domain/area/state_machine.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';

/// A place on a [system] where a [drawer] can be.
/// Note that a [drawer] can also be between [DrawerPlace]s
class DrawerPlace {
  final PhysicalSystem system;
  final OffsetInMeters centerToDrawerCenterWhenSystemFacesNorth;
  late final StateMachine? stateMachine;
  GrandeDrawer? drawer;

  DrawerPlace({
    required this.system,
    required this.centerToDrawerCenterWhenSystemFacesNorth,
    StateMachine? stateMachine,
  }) {
    this.stateMachine = stateMachine ??
        ((system is StateMachine) ? (system as StateMachine) : null);
  }
}

class DrawerLiftPlace extends DrawerPlace {
  /// level 0 = bottom level
  final int level;
  DrawerLiftPlace({
    required super.system,
    required super.centerToDrawerCenterWhenSystemFacesNorth,
    required this.level,
  });
}

class BetweenDrawerPlaces implements DrawerPositionAndSize, TimeProcessor {
  final CompassDirection drawerRotation;
  final DrawerPlace startPlace;
  final DrawerPlace destinationPlace;

  Duration elapsed = Duration.zero;

  final Duration duration;

  bool completed = false;

  final OffsetInMeters drawerCenterToTopLeft = const OffsetInMeters(
          xInMeters: DrawerVariant.lengthInMeters,
          yInMeters: DrawerVariant.lengthInMeters) *
      -0.5;

  late final GrandeDrawer transportedDrawer;

  /// cashed top left of [LiveBirdHandlingArea] to drawer center of the start place
  OffsetInMeters? _startPosition;

  /// cashed top left of [LiveBirdHandlingArea] to drawer center of the start place
  OffsetInMeters? _destinationPosition;

  /// route to travel from [_startPosition] to [_destinationPosition]
  OffsetInMeters? _vector;

  BetweenDrawerPlaces(
      {required this.drawerRotation,
      required this.duration,
      required this.startPlace,
      required this.destinationPlace});

  double get completedFraction =>
      elapsed.inMicroseconds / duration.inMicroseconds;

  @override
  double rotationInFraction(SystemLayout layout) => drawerRotation.toFraction();

  /// top left of [LiveBirdHandlingArea] to drawer center of the start place
  OffsetInMeters startPosition(SystemLayout layout) =>
      _startPosition ??
      layout.positionOnSystem(startPlace.system,
          startPlace.centerToDrawerCenterWhenSystemFacesNorth);

  /// top left of [LiveBirdHandlingArea] to drawer center of the destination place
  OffsetInMeters destinationPosition(SystemLayout layout) =>
      _destinationPosition ??
      layout.positionOnSystem(destinationPlace.system,
          destinationPlace.centerToDrawerCenterWhenSystemFacesNorth);

  /// route to travel from [_startPosition] to [_destinationPosition]
  OffsetInMeters vector(SystemLayout layout) =>
      _vector ?? destinationPosition(layout) - startPosition(layout);

  @override
  OffsetInMeters topLeft(SystemLayout layout) {
    return startPosition(layout) +
        vector(layout) * completedFraction +
        drawerCenterToTopLeft;
  }

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (!completed) {
      if (elapsed == Duration.zero) {
        onStart();
      }
      elapsed += jump;
      if (elapsed > duration) {
        elapsed = duration;
        completed = true;
        onCompleted();
      }
    }
  }

  void onStart() {
    if (startPlace.drawer == null) {
      throw ArgumentError(
          'is null', 'startPlace.drawer of ${startPlace.system.name}');
    }
    transportedDrawer = startPlace.drawer!;

    startPlace.drawer = null;

    if (startPlace.stateMachine?.currentState
        is DrawerTransportStartedListener) {
      (startPlace.stateMachine?.currentState as DrawerTransportStartedListener)
          .onDrawerTransportStarted(this);
    }

    if (destinationPlace.stateMachine?.currentState
        is DrawerTransportStartedListener) {
      (destinationPlace.stateMachine?.currentState
              as DrawerTransportStartedListener)
          .onDrawerTransportStarted(this);
    }
  }

  void onCompleted() {
    transportedDrawer.position = AtDrawerPlace(destinationPlace, scale: scale);
    destinationPlace.drawer = transportedDrawer;
    if (startPlace.stateMachine?.currentState
        is DrawerTransportCompletedListener) {
      (startPlace.stateMachine?.currentState
              as DrawerTransportCompletedListener)
          .onDrawerTransportCompleted(this);
    }

    if (destinationPlace.stateMachine?.currentState
        is DrawerTransportCompletedListener) {
      (destinationPlace.stateMachine?.currentState
              as DrawerTransportCompletedListener)
          .onDrawerTransportCompleted(this);
    }
  }

  @override
  final scale = 1.0;
}

abstract class DrawerTransportStartedListener {
  onDrawerTransportStarted(BetweenDrawerPlaces betweenDrawerPlaces);
}

abstract class DrawerTransportCompletedListener {
  onDrawerTransportCompleted(BetweenDrawerPlaces betweenDrawerPlaces);
}

class AtDrawerPlace implements DrawerPositionAndSize {
  final DrawerPlace drawerPlace;
  final OffsetInMeters drawerCenterToTopLeft = const OffsetInMeters(
          xInMeters: DrawerVariant.lengthInMeters,
          yInMeters: DrawerVariant.lengthInMeters) *
      -0.5;

  OffsetInMeters? _topLeft;
  double? _rotationInFraction;
  @override
  double scale;

  AtDrawerPlace(this.drawerPlace, {this.scale = 1});

  @override
  double rotationInFraction(SystemLayout layout) =>
      _rotationInFraction ?? layout.rotationOf(drawerPlace.system).toFraction();

  @override
  OffsetInMeters topLeft(SystemLayout layout) =>
      _topLeft ??
      layout.positionOnSystem(drawerPlace.system,
              drawerPlace.centerToDrawerCenterWhenSystemFacesNorth) +
          drawerCenterToTopLeft;
}
