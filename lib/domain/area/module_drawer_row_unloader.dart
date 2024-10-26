// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer.dart';
import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/module/drawer.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module_variant_builder.dart';
import 'package:meyn_lbh_simulation/domain/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/speed_profile.dart';
import 'package:meyn_lbh_simulation/domain/area/state_machine.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_drawer_row_unloader.dart';
import 'package:user_command/user_command.dart';

class ModuleDrawerRowUnloader extends StateMachine implements PhysicalSystem {
  final LiveBirdHandlingArea area;
  final Duration pusherPushDuration;
  final Duration pusherBackDuration;
  final Duration liftUpToTopDuration;
  final Duration liftOneLevelDownDuration;
  final Direction drawerOutDirection;
  final SpeedProfile conveyorSpeedProfile;

  @override
  late final List<Command> commands = [
    RemoveFromMonitorPanel(this),
  ];

  Duration? durationPerModule;
  Durations durationsPerModule = Durations(maxSize: 8);
  LiftLevel liftLevel = LiftLevel.bottom;

  late final List<DrawerPlace> drawerPlaces = shape
      .centerToLiftConveyorDrawerCenters
      .map((offset) => DrawerPlace(
          system: this, centerToDrawerCenterWhenSystemFacesNorth: offset))
      .toList();

  late final Duration drawerReceivingConveyorFeedOutDuration;

  GrandeDrawer? previousDrawerFedOut;

  late final drawersOut = DrawersOutLink(
      system: this,
      offsetFromCenterWhenFacingNorth: shape.centerToDrawersOutLink,
      directionToOtherLink: shape.drawersOutLinkDirectionToOtherLink);

  late final CompassDirection drawerFeedOutDirection = drawersOut
      .directionToOtherLink
      .rotate(area.layout.rotationOf(this).degrees);

  ModuleDrawerRowUnloader({
    required this.area,
    required this.drawerOutDirection,
    this.pusherPushDuration = const Duration(
        milliseconds: 3400), // Based on "4339-Vinnitsa-tack-timesv3.xlsx"
    this.pusherBackDuration = const Duration(
        milliseconds: 3400), // Based on "4339-Vinnitsa-tack-timesv3.xlsx"
    this.liftUpToTopDuration = const Duration(
        milliseconds: 7400), // Based on "4339-Vinnitsa-tack-timesv3.xlsx"
    this.liftOneLevelDownDuration = const Duration(
        milliseconds: 1600), // Based on "4339-Vinnitsa-tack-timesv3.xlsx"
    SpeedProfile? conveyorSpeedProfile,
  })  : conveyorSpeedProfile = conveyorSpeedProfile ??
            area.productDefinition.speedProfiles.moduleConveyor,
        super(
          initialState: CheckIfEmpty(),
        );

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late final ModuleDrawerRowUnloaderShape shape =
      ModuleDrawerRowUnloaderShape(this);

  final int drawersPerRow = 2;

  late ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorCenter,
  );

  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupInLink,
    directionToOtherLink: const CompassDirection.south(),
    transportDuration: (inLink) =>
        moduleTransportDuration(inLink, conveyorSpeedProfile),
    canFeedIn: () =>
        SimultaneousFeedOutFeedInModuleGroup.canFeedIn(currentState),
  );

  late ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleGroupOutLink,
    directionToOtherLink: const CompassDirection.north(),
    durationUntilCanFeedOut: () =>
        SimultaneousFeedOutFeedInModuleGroup.durationUntilCanFeedOut(
            currentState),
  );

  @override
  late List<Link> links = [modulesIn, drawersOut, modulesOut];

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    super.onUpdateToNextPointInTime(jump);
    if (durationPerModule != null) {
      durationPerModule = durationPerModule! + jump;
    }
  }

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('currentState', currentState)
      .appendProperty('speed',
          '${durationsPerModule.averagePerHour.toStringAsFixed(1)} modules/hour')
      .appendProperty('liftLevel', liftLevel);

  void onEndOfCycle() {
    durationsPerModule.add(durationPerModule);
    durationPerModule = Duration.zero;
  }

  @override
  late final String name = 'ModuleDrawerUnloader$seqNr';

  late final int seqNr = area.systems.seqNrOf(this);
}

class CheckIfEmpty extends DurationState<ModuleDrawerRowUnloader> {
  @override
  String get name => 'CheckIfEmpty';

  CheckIfEmpty()
      : super(
            durationFunction: (unloader) => unloader.conveyorSpeedProfile
                .durationOfDistance(unloader.shape.yInMeters),
            nextStateFunction: (unloader) =>
                SimultaneousFeedOutFeedInModuleGroup<ModuleDrawerRowUnloader>(
                    modulesIn: unloader.modulesIn,
                    modulesOut: unloader.modulesOut,
                    stateWhenCompleted:
                        AfterSimultaneousFeedOutFeedInModuleGroup(),
                    inFeedDelay: Duration.zero));
}

class AfterSimultaneousFeedOutFeedInModuleGroup
    extends State<ModuleDrawerRowUnloader> {
  @override
  String get name => 'AfterSimultaneousFeedOutFeedInModuleGroup';

  @override
  State<ModuleDrawerRowUnloader>? nextState(ModuleDrawerRowUnloader unloader) {
    if (moduleGroupIsEmpty(unloader) || sendToModuleDrawerUnloader(unloader)) {
      return SimultaneousFeedOutFeedInModuleGroup<ModuleDrawerRowUnloader>(
        modulesIn: unloader.modulesIn,
        modulesOut: unloader.modulesOut,
        stateWhenCompleted: AfterSimultaneousFeedOutFeedInModuleGroup(),
        inFeedDelay: Duration.zero,
      );
    } else {
      return MoveLift(LiftLevel.top);
    }
  }

  bool moduleGroupIsEmpty(ModuleDrawerRowUnloader unloader) {
    var moduleGroup = unloader.moduleGroupPlace.moduleGroup;
    return moduleGroup?.contents == BirdContents.noBirds;
  }

  bool sendToModuleDrawerUnloader(ModuleDrawerRowUnloader unloader) {
    var nextSystem = unloader.modulesOut.linkedTo?.system;
    if (nextSystem is ModuleDrawerRowUnloader) {
      var moduleGroup = nextSystem.moduleGroupPlace.moduleGroup;
      return moduleGroup == null;
    }
    return false;
  }
}

class MoveLift extends DurationState<ModuleDrawerRowUnloader> {
  final LiftLevel goToPosition;
  MoveLift(this.goToPosition)
      : super(
            durationFunction: (ModuleDrawerRowUnloader unloader) =>
                goToPosition == LiftLevel.top
                    ? unloader.liftUpToTopDuration
                    : unloader.liftOneLevelDownDuration,
            nextStateFunction: (ModuleDrawerRowUnloader unloader) =>
                nextStateWhenCompleted(unloader, goToPosition));

  static State<ModuleDrawerRowUnloader> nextStateWhenCompleted(
      ModuleDrawerRowUnloader unloader, LiftLevel newLevel) {
    unloader.liftLevel = newLevel;
    if (liftAtBottom(unloader) && moduleGroupIsEmpty(unloader)) {
      return SimultaneousFeedOutFeedInModuleGroup<ModuleDrawerRowUnloader>(
          modulesIn: unloader.modulesIn,
          modulesOut: unloader.modulesOut,
          stateWhenCompleted: AfterSimultaneousFeedOutFeedInModuleGroup(),
          inFeedDelay: Duration.zero);
    } else {
      return WaitToPushOutRow();
    }
  }

  static bool moduleGroupIsEmpty(ModuleDrawerRowUnloader unloader) =>
      unloader.moduleGroupPlace.moduleGroup!.contents == BirdContents.noBirds;

  static bool liftAtBottom(ModuleDrawerRowUnloader unloader) =>
      unloader.liftLevel == LiftLevel.bottom;

  @override
  final String name = 'MoveLift';

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('goToPosition',
          goToPosition.toString().replaceFirst('$LiftLevel.', ''))
      .appendProperty('remaining', '${remainingDuration.inSeconds}sec');
}

enum LiftLevel {
  pushOutLevel1(1),
  pushOutLevel2(2),
  pushOutLevel3(3),

  /// only for modules that have at least 4 levels,
  pushOutLevel4(4),

  /// all the way down
  /// only for modules that have at least 5 levels,
  pushOutLevel5(5);

  final int level;

  const LiftLevel(this.level);

  static LiftLevel get top => LiftLevel.pushOutLevel1;
  static LiftLevel get bottom => LiftLevel.pushOutLevel5;
  LiftLevel get oneLevelDown =>
      LiftLevel.values[LiftLevel.values.indexOf(this) + 1];
}

class WaitToPushOutRow extends State<ModuleDrawerRowUnloader> {
  @override
  String get name => 'WaitToPushOutRow';

  @override
  State<ModuleDrawerRowUnloader>? nextState(ModuleDrawerRowUnloader unloader) =>
      receiverCanFeedIn(unloader) ? PushOutRow() : null;

  bool receiverCanFeedIn(ModuleDrawerRowUnloader unloader) =>
      unloader.drawersOut.linkedTo!.numberOfDrawersToFeedIn() > 0;
}

class PushOutRow extends State<ModuleDrawerRowUnloader>
    implements DrawerTransportCompletedListener {
  ModuleDrawerRowUnloaderReceiver? _receiver;

  bool transportCompleted = false;

  @override
  String get name => 'PushOutRow';

  @override
  void onStart(ModuleDrawerRowUnloader unloader) {
    super.onStart(unloader);
    var drawers = unloader.area.drawers;
    var newDrawers = createDrawers(unloader);
    drawers.addAll(newDrawers);
    _verifyModuleGroup(unloader);
  }

  void _verifyModuleGroup(ModuleDrawerRowUnloader unloader) {
    var moduleGroup = (unloader.moduleGroupPlace.moduleGroup)!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('${unloader.name}:  can not handle stacked modules');
    }
    if (moduleGroup.compartment.birdsExitOnOneSide &&
        moduleGroup.direction.rotate(-90) != unloader.drawerFeedOutDirection) {
      if (moduleGroup.compartment is CompartmentWithDoor) {
        throw ('${unloader.name}: Can not process containers');
      } else {
        throw ('${unloader.name}: Incorrect drawer out feed direction '
            'of: $ModuleGroup');
      }
    }
  }

  List<GrandeDrawer> createDrawers(ModuleDrawerRowUnloader unloader) {
    var moduleGroup = unloader.moduleGroupPlace.moduleGroup!;
    if (moduleGroup.numberOfModules > 2) {
      throw Exception('Unloader can not handle stacked containers');
    }
    var module = moduleGroup.modules.first;
    var levels = module.variant.levels;
    var nrOfBirdsPerDrawer =
        module.nrOfBirds / unloader.drawersPerRow ~/ levels;
    var contents = moduleGroup.contents;

    var drawerRotation = unloader.area.layout.rotationOf(unloader);
    List<GrandeDrawer> drawers = [];

    for (int i = 0; i < unloader.drawersPerRow; i++) {
      var newDrawer = GrandeDrawer(
        nrOfBirds: nrOfBirdsPerDrawer,
        contents: contents,
        position: AtDrawerPlace(unloader.drawerPlaces[i]),
        sinceEndStun: moduleGroup.sinceEndStun,
      );

      drawers.add(newDrawer);
      unloader.drawerPlaces[i].drawer = newDrawer;
      var destination = receiver(unloader).receivingConveyors.drawerPlaces[i];
      newDrawer.position = BetweenDrawerPlaces(
          drawerRotation: drawerRotation,
          duration: unloader.pusherPushDuration,
          startPlace: unloader.drawerPlaces[i],
          destinationPlace: destination);
    }
    return drawers;
  }

  ModuleDrawerRowUnloaderReceiver receiver(ModuleDrawerRowUnloader unloader) {
    _receiver ??=
        unloader.drawersOut.linkedTo!.system as ModuleDrawerRowUnloaderReceiver;
    return _receiver!;
  }

  @override
  State<ModuleDrawerRowUnloader>? nextState(ModuleDrawerRowUnloader unloader) =>
      transportCompleted ? PusherBack() : null;

  @override
  onDrawerTransportCompleted(BetweenDrawerPlaces betweenDrawerPlaces) {
    transportCompleted = true;
  }

  @override
  void onCompleted(ModuleDrawerRowUnloader unloader) {
    var moduleGroup = unloader.moduleGroupPlace.moduleGroup!;
    var module = moduleGroup.modules.first;
    var moduleEmpty = unloader.liftLevel.level == module.variant.levels;
    if (moduleEmpty) {
      moduleGroup.unloadBirds();
    }
  }
}

class PusherBack extends DurationState<ModuleDrawerRowUnloader> {
  @override
  String get name => 'PusherBack';

  PusherBack()
      : super(
            durationFunction: (unloader) => unloader.pusherBackDuration,
            nextStateFunction: (unloader) => unloader.liftLevel ==
                    LiftLevel.bottom
                ? SimultaneousFeedOutFeedInModuleGroup<ModuleDrawerRowUnloader>(
                    modulesIn: unloader.modulesIn,
                    modulesOut: unloader.modulesOut,
                    stateWhenCompleted:
                        AfterSimultaneousFeedOutFeedInModuleGroup(),
                    inFeedDelay: Duration.zero)
                : MoveLift(unloader.liftLevel.oneLevelDown));
}

class ModuleDrawerRowUnloaderReceiver implements PhysicalSystem, TimeProcessor {
  final LiveBirdHandlingArea area;
  late final DrawerReceivingConveyors receivingConveyors =
      DrawerReceivingConveyors(this);
  late final CrossOver crossOver = CrossOver(this);
  late final shape = ModuleDrawerRowUnloaderReceiverShape(this);
  final Direction drawerOutDirection;
  final drawersPerRow = 2;
  final Duration receivingConveyorsFeedOutDuration;
  final Duration receivingConveyorsStopperDownDuration;
  final Duration receivingConveyorsStopperUpDuration;
  final Duration crossOverDownDuration;
  final Duration crossOverUpDuration;
  final bool weighing;
  final Duration crossOverWeighingDuration;

  final double crossOverFeedOutMetersPerSecond;

  Duration drawerFeedOutCycle = Duration.zero;
  Durations drawerFeedOutCycles = Durations(maxSize: 20);

  ModuleDrawerRowUnloaderReceiver({
    required this.area,
    required this.drawerOutDirection,
    this.receivingConveyorsFeedOutDuration = const Duration(milliseconds: 2500),
    this.receivingConveyorsStopperDownDuration =
        const Duration(milliseconds: 500),
    this.receivingConveyorsStopperUpDuration =
        const Duration(milliseconds: 500),
    this.crossOverDownDuration = const Duration(milliseconds: 700),
    this.crossOverUpDuration = const Duration(milliseconds: 600),
    required this.crossOverFeedOutMetersPerSecond,
    this.weighing = true,
    this.crossOverWeighingDuration = const Duration(milliseconds: 1600),
  });

  @override
  late final List<Command> commands = [
    RemoveFromMonitorPanel(this),
  ];

  late final drawersIn = DrawersInLink(
      system: this,
      numberOfDrawersToFeedIn: () =>
          receivingConveyors.currentState is DrawerReceivingConveyorFeedingIn
              ? drawersPerRow
              : 0,
      offsetFromCenterWhenFacingNorth: shape.centerToDrawersInLink,
      directionToOtherLink: shape.drawersInLinkDirectionToOtherLink);

  late final drawerOut = crossOver.feedOutConveyor.drawerOut;

  @override
  late final List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    drawersIn,
    //[crossOver.drawerOutLink] for positioning of [crossOver.feedOutConveyor]:
    crossOver.drawerOutLink,
    crossOver.feedOutConveyor.drawerOut,
    drawerOut
  ];

  @override
  late final String name = 'ModuleDrawerRowUnloaderReceiver$seqNr';

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty(
          'receivingConveyors', receivingConveyors.currentState.name)
      .appendProperty('crossOverConveyor', crossOver.currentState.name)
      .appendProperty('speed',
          '${drawerFeedOutCycles.averagePerHour.toStringAsFixed(1)} drawers/hour');

  @override
  late final SizeInMeters sizeWhenFacingNorth = shape.size;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    receivingConveyors.onUpdateToNextPointInTime(jump);
    crossOver.onUpdateToNextPointInTime(jump);
    drawerFeedOutCycle += jump;
  }

  //Called when drawers ar fed out of cross over so we can calculate the average speed
  void onFeedOutDrawers() {
    var durationPerDrawer = Duration(
        microseconds: (drawerFeedOutCycle.inMicroseconds ~/ drawersPerRow));
    for (int i = 0; i < drawersPerRow; i++) {
      drawerFeedOutCycles.add(durationPerDrawer);
    }
    drawerFeedOutCycle = Duration.zero;
  }
}

class DrawerReceivingConveyors extends StateMachine {
  final ModuleDrawerRowUnloaderReceiver receiver;

  late final Duration feedOutDuration =
      receiver.receivingConveyorsFeedOutDuration;

  late final Duration stopperDownDuration =
      receiver.receivingConveyorsStopperDownDuration;

  late final Duration stopperUpDuration =
      receiver.receivingConveyorsStopperUpDuration;

  DrawerReceivingConveyors(this.receiver)
      : super(initialState: DrawerReceivingConveyorFeedingIn());

  @override
  final String name = 'DrawerReceivingConveyor';

  bool get isEmpty => currentState is DrawerReceivingConveyorFeedingIn;

  late final List<DrawerPlace> drawerPlaces =
      receiver.shape.centerToReceivingConveyorDrawerCenters
          .map((offset) => DrawerPlace(
                system: receiver,
                centerToDrawerCenterWhenSystemFacesNorth: offset,
                stateMachine: this,
              ))
          .toList();

  late final CrossOver crossOverConveyor = receiver.crossOver;
}

class DrawerReceivingConveyorFeedingIn extends State<DrawerReceivingConveyors> {
  @override
  final String name = 'DrawerReceivingConveyorFeedingIn';

  @override
  State<DrawerReceivingConveyors>? nextState(
      DrawerReceivingConveyors receivingConveyors) {
    if (receivingConveyors.drawerPlaces[0].drawer != null) {
      return DrawerReceivingConveyorStopperDown();
    }
    return null;
  }
}

class DrawerReceivingConveyorStopperDown
    extends DurationState<DrawerReceivingConveyors> {
  DrawerReceivingConveyorStopperDown()
      : super(
          durationFunction: (DrawerReceivingConveyors receivingConveyors) =>
              receivingConveyors.stopperDownDuration,
          nextStateFunction: (_) => DrawerReceivingConveyorWaitingToFeedOut(),
        );

  @override
  final String name = 'DrawerReceivingConveyorStopperDown';
}

class DrawerReceivingConveyorWaitingToFeedOut
    extends State<DrawerReceivingConveyors> {
  @override
  final String name = 'DrawerReceivingConveyorWaitingToFeedOut';

  DrawerReceivingConveyorWaitingToFeedOut();

  @override
  State<DrawerReceivingConveyors>? nextState(
      DrawerReceivingConveyors receivingConveyors) {
    var crossOverConveyor = receivingConveyors.receiver.crossOver;
    if (crossOverConveyor.canFeedIn) {
      return DrawerReceivingConveyorFeedingOut();
    }
    return null;
  }
}

class DrawerReceivingConveyorFeedingOut extends State<DrawerReceivingConveyors>
    implements DrawerTransportCompletedListener {
  @override
  final String name = 'DrawerReceivingConveyorFeedingOut';

  bool transportCompleted = false;

  @override
  void onStart(DrawerReceivingConveyors receivingConveyors) {
    var receiver = receivingConveyors.receiver;
    var layout = receiver.area.layout;
    var drawerRotation = layout.rotationOf(receiver);
    for (int i = 0; i < receivingConveyors.drawerPlaces.length; i++) {
      var startPlace = receivingConveyors.drawerPlaces[i];
      var destinationPlace =
          receivingConveyors.receiver.crossOver.drawerPlaces[i];
      var drawer = startPlace.drawer!;
      drawer.position = BetweenDrawerPlaces(
        drawerRotation: drawerRotation,
        duration: receivingConveyors.feedOutDuration,
        startPlace: startPlace,
        destinationPlace: destinationPlace,
      );
    }
  }

  @override
  State<DrawerReceivingConveyors>? nextState(
          DrawerReceivingConveyors receivingConveyors) =>
      transportCompleted ? DrawerReceivingConveyorStopperUp() : null;

  @override
  onDrawerTransportCompleted(BetweenDrawerPlaces betweenDrawerPlaces) {
    transportCompleted = true;
  }
}

class DrawerReceivingConveyorStopperUp
    extends DurationState<DrawerReceivingConveyors> {
  DrawerReceivingConveyorStopperUp()
      : super(
          durationFunction: (DrawerReceivingConveyors receivingConveyors) =>
              receivingConveyors.stopperUpDuration,
          nextStateFunction: (_) => DrawerReceivingConveyorFeedingIn(),
        );

  @override
  final String name = 'DrawerReceivingConveyorStopperUp';
}

class CrossOver extends StateMachine {
  final ModuleDrawerRowUnloaderReceiver receiver;
  late final DrawerConveyorStraight feedOutConveyor;

  late final drawerOutLink = DrawerOutLink(
      system: feedOutConveyor,
      offsetFromCenterWhenFacingNorth:
          receiver.shape.centerToFeedOutConveyorInLink,
      directionToOtherLink: receiver.shape.drawerOutLinkDirectionToOtherLink,

      /// Internal link for positioning only.
      /// Link should not be visible or mutable by user when editing the layout
      visibleAndMutable: false);

  GrandeDrawer? lastAddedDrawer;

  late final Duration downDuration = receiver.crossOverDownDuration;
  late final Duration weighingDuration = receiver.crossOverWeighingDuration;
  late final Duration upDuration = receiver.crossOverUpDuration;
  late final double crossOverFeedOutMetersPerSecond =
      receiver.crossOverFeedOutMetersPerSecond;
  late final bool weighing = receiver.weighing;

  CrossOver(this.receiver) : super(initialState: CrossOverConveyorFeedingIn()) {
    feedOutConveyor = DrawerConveyorStraight(
        lengthInMeters: receiver.shape.feedOutConveyorLengthInMeters,
        metersPerSecond: crossOverFeedOutMetersPerSecond,
        systemProtrudesInMeters: 0);

    /// for positioning of the [feedOutConveyor]
    receiver.area.systems.link(drawerOutLink, feedOutConveyor.drawerIn);
  }

  @override
  final String name = 'CrossOverConveyor';

  late final List<DrawerPlace> drawerPlaces =
      receiver.shape.centerToCrossOverConveyorDrawerCenters
          .map((offset) => DrawerPlace(
                system: receiver,
                centerToDrawerCenterWhenSystemFacesNorth: offset,
                stateMachine: this,
              ))
          .toList();

  bool get canFeedIn => currentState is CrossOverConveyorFeedingIn;
}

class CrossOverConveyorFeedingIn extends State<CrossOver>
    implements DrawerTransportCompletedListener {
  @override
  final String name = 'CrossOverConveyorFeedingIn';

  bool transportCompleted = false;

  @override
  State<CrossOver>? nextState(CrossOver stateMachine) =>
      transportCompleted ? CrossOverConveyorDown() : null;

  @override
  onDrawerTransportCompleted(BetweenDrawerPlaces betweenDrawerPlaces) {
    transportCompleted = true;
  }
}

class CrossOverConveyorDown extends DurationState<CrossOver> {
  CrossOverConveyorDown()
      : super(
            durationFunction: (CrossOver crossOver) => crossOver.downDuration,
            nextStateFunction: (CrossOver crossOver) => crossOver.weighing
                ? CrossOverConveyorWeighing()
                : CrossOverConveyorFeedingOut());

  @override
  final String name = 'CrossOverConveyorDown';
}

class CrossOverConveyorWeighing extends DurationState<CrossOver> {
  CrossOverConveyorWeighing()
      : super(
            durationFunction: (CrossOver crossOver) =>
                crossOver.weighingDuration,
            nextStateFunction: (CrossOver crossOver) =>
                CrossOverConveyorFeedingOut());

  @override
  final String name = 'CrossOverConveyorWeighing';
}

class CrossOverConveyorFeedingOut extends State<CrossOver> {
  @override
  final String name = 'CrossOverConveyorFeedingOut';

  int drawerIndex = 0;

  bool transportCompleted = false;

  @override
  void onStart(CrossOver crossOverConveyor) {
    super.onStart(crossOverConveyor);
    var conveyor = crossOverConveyor.feedOutConveyor;
    var receiver = crossOverConveyor.receiver;
    for (int i = 0; i < receiver.drawersPerRow; i++) {
      var drawerPlace = crossOverConveyor.drawerPlaces[i];
      var drawer = drawerPlace.drawer!;
      var conveyorStartToCenter = receiver.shape.centerToFeedOutConveyorInLink;
      var centerToDrawerPlace =
          drawerPlace.centerToDrawerCenterWhenSystemFacesNorth;
      var distanceTraveled =
          (conveyorStartToCenter.xInMeters - centerToDrawerPlace.xInMeters)
                  .abs() +
              DrawerVariant.lengthInMeters / 2;
      if (crossOverConveyor.receiver.drawerOutDirection ==
          Direction.clockWise) {
        distanceTraveled += DrawerVariant.lengthInMeters;
      }
      if (i > 0) {
        distanceTraveled += DrawerVariant.lengthInMeters;
      }
      drawer.position = OnConveyorPosition(conveyor,
          precedingDrawer: crossOverConveyor.lastAddedDrawer,
          traveledMetersOnVector: distanceTraveled);
      (drawer.position as OnConveyorPosition).metersTraveledOnDrawerConveyors =
          distanceTraveled;
      crossOverConveyor.drawerPlaces[i].drawer = null;
      crossOverConveyor.lastAddedDrawer = drawer;
    }
  }

  @override
  State<CrossOver>? nextState(CrossOver crossOver) =>
      feedOutConveyorIsEmpty(crossOver) ? CrossOverConveyorUp() : null;

  bool feedOutConveyorIsEmpty(CrossOver crossOver) {
    var lastAddedDrawer = crossOver.lastAddedDrawer;
    if (lastAddedDrawer == null) {
      return true;
    }
    if (lastAddedDrawer.position is! OnConveyorPosition) {
      return true;
    }
    return (lastAddedDrawer.position as OnConveyorPosition).conveyor !=
        crossOver.feedOutConveyor;
  }

  @override
  void onCompleted(CrossOver crossOver) {
    crossOver.receiver.onFeedOutDrawers();
    super.onCompleted(crossOver);
  }
}

class CrossOverConveyorUp extends DurationState<CrossOver> {
  CrossOverConveyorUp()
      : super(
            durationFunction: (CrossOver crossOver) => crossOver.upDuration,
            nextStateFunction: (_) => CrossOverConveyorFeedingIn());

  @override
  final String name = 'CrossOverConveyorUp';
}
