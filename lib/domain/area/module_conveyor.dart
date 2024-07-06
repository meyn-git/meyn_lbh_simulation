// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_conveyor.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'state_machine.dart';

class ModuleConveyor extends StateMachine implements PhysicalSystem {
  final Duration inFeedDuration;
  final Duration outFeedDuration;
  final Duration checkIfEmptyDuration;
  final double lengthInMeters;
  final LiveBirdHandlingArea area;
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  late final ModuleConveyorShape shape = ModuleConveyorShape(this);

  static const double defaultLengthInMeters = 2.75;

  ModuleConveyor({
    required this.area,
    this.checkIfEmptyDuration = const Duration(seconds: 18),
    Duration? inFeedDuration,
    Duration? outFeedDuration,
    this.lengthInMeters = defaultLengthInMeters,
  })  : inFeedDuration = inFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration *
                (lengthInMeters / defaultLengthInMeters),
        outFeedDuration = outFeedDuration ??
            area.productDefinition.moduleSystem.conveyorTransportDuration,
        super(
          initialState: CheckIfEmpty(),
        );

  late final ModuleGroupInLink modulesIn = ModuleGroupInLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleInLink,
    directionToOtherLink: const CompassDirection.south(),
    inFeedDuration: inFeedDuration,
    canFeedIn: () => currentState is WaitToFeedIn,
  );

  late final ModuleGroupOutLink modulesOut = ModuleGroupOutLink(
    place: moduleGroupPlace,
    offsetFromCenterWhenFacingNorth: shape.centerToModuleOutLink,
    directionToOtherLink: const CompassDirection.north(),
    outFeedDuration: outFeedDuration,
    durationUntilCanFeedOut: () =>
        currentState is WaitToFeedOut ? Duration.zero : unknownDuration,
  );

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn,
    modulesOut
  ];

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  late String name = 'ModuleConveyor$seqNr';

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  late final ModuleGroupPlace moduleGroupPlace = ModuleGroupPlace(
    system: this,
    offsetFromCenterWhenSystemFacingNorth: shape.centerToConveyorEnd,
  );
}

class CheckIfEmpty extends DurationState<ModuleConveyor> {
  CheckIfEmpty()
      : super(
            durationFunction: (moduleConveyor) =>
                moduleConveyor.checkIfEmptyDuration,
            nextStateFunction: (moduleConveyor) => WaitToFeedIn());

  @override
  String get name => 'CheckIfEmpty';
}

class WaitToFeedIn extends State<ModuleConveyor>
    implements ModuleTransportStartedListener {
  var transportStarted = false;

  @override
  String get name => 'WaitToFeedIn';

  @override
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (transportStarted) {
      return FeedIn();
    }
    return null;
  }

  /// Must be called by FeedOut state of the preceding [PhysicalSystem]
  @override
  void onModuleTransportStarted(_) {
    transportStarted = true;
  }
}

class FeedIn extends State<ModuleConveyor>
    implements ModuleTransportCompletedListener {
  @override
  String get name => 'FeedIn';
  bool transportCompleted = false;

  @override
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (transportCompleted) {
      return WaitToFeedOut();
    }
    return null;
  }

  /// called by [BetweenModuleGroupPlaces]
  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}

class WaitToFeedOut extends State<ModuleConveyor> {
  @override
  String get name => 'WaitToFeedOut';

  @override
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (neighborCanFeedIn(moduleConveyor) &&
        !_moduleGroupAtDestination(moduleConveyor)) {
      return FeedOut();
    }
    return null;
  }

  bool neighborCanFeedIn(ModuleConveyor moduleConveyor) =>
      moduleConveyor.modulesOut.linkedTo!.canFeedIn();

  bool _moduleGroupAtDestination(ModuleConveyor moduleConveyor) =>
      moduleConveyor.moduleGroupPlace.moduleGroup!.destination ==
      moduleConveyor;
}

class FeedOut extends State<ModuleConveyor>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'FeedOut';

  @override
  void onStart(ModuleConveyor moduleConveyor) {
    var transportedModuleGroup = moduleConveyor.moduleGroupPlace.moduleGroup!;
    transportedModuleGroup.position =
        BetweenModuleGroupPlaces.forModuleOutLink(moduleConveyor.modulesOut);
  }

  @override
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (transportCompleted) {
      return WaitToFeedIn();
    }
    return null;
  }

  /// This method is called by ModuleTransport when completed
  @override
  void onModuleTransportCompleted(_) {
    transportCompleted = true;
  }
}
