// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:user_command/user_command.dart';

import 'state_machine.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class UnLoadingForkLiftTruck extends StateMachine
    implements PhysicalSystem, AdditionalRotation {
  final LiveBirdHandlingArea area;
  final Duration putModuleGroupOnTruckDuration;
  final Duration getModuleGroupFromConveyorDuration;

  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  UnLoadingForkLiftTruck({
    required this.area,
    this.putModuleGroupOnTruckDuration = const Duration(seconds: 5), //TODO 30s?
    this.getModuleGroupFromConveyorDuration =
        const Duration(seconds: 5), //TODO 15s?
  }) : super(initialState: WaitingForFullConveyor());

  late ModuleGroupInLink modulesIn = ModuleGroupInLink(
      position: moduleGroupPosition,
      offsetFromCenterWhenFacingNorth: OffsetInMeters(
          xInMeters: 0, yInMeters: sizeWhenFacingNorth.yInMeters * -0.5),
      directionToOtherLink: const CompassDirection.north(),
      inFeedDuration: getModuleGroupFromConveyorDuration,
      canFeedIn: () => currentState is WaitingForFullConveyor);

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    modulesIn
  ];

  @override
  String name = 'UnLoadingForkLiftTruck';

  @override
  late SizeInMeters sizeWhenFacingNorth =
      const SizeInMeters(xInMeters: 1.5, yInMeters: 5);

  @override
  CompassDirection get additionalRotation =>
      currentState is PutModuleGroupOnTruck
          ? const CompassDirection(180)
          : const CompassDirection(0);

  late ModuleGroupPlace moduleGroupPosition = ModuleGroupPlace(
    system: this,
    moduleGroups: area.moduleGroups,
    offsetFromCenterWhenSystemFacingNorth:
        const OffsetInMeters(xInMeters: 0, yInMeters: -1.4),
  );
}

class WaitingForFullConveyor extends State<UnLoadingForkLiftTruck>
    implements ModuleTransportStartedListener {
  bool transportStarted = false;

  @override
  String get name => 'WaitingForFullConveyor';

  @override
  State<UnLoadingForkLiftTruck>? nextState(
      UnLoadingForkLiftTruck forkLiftTruck) {
    if (transportStarted) {
      return GetModuleGroupFromConveyor();
    }
    return null;
  }

  /// Called by [BetweenModuleGroupPlaces]
  @override
  void onModuleTransportStarted() {
    transportStarted = true;
  }
}

class GetModuleGroupFromConveyor extends State<UnLoadingForkLiftTruck>
    implements ModuleTransportCompletedListener {
  bool transportCompleted = false;

  @override
  String get name => 'GetModuleGroupFromConveyor';

  @override
  State<UnLoadingForkLiftTruck>? nextState(
      UnLoadingForkLiftTruck forkLiftTruck) {
    if (transportCompleted) {
      return PutModuleGroupOnTruck();
    }
    return null;
  }

  /// Called by [BetweenModuleGroupPlaces]
  @override
  void onModuleTransportCompleted() {
    transportCompleted = true;
  }
}

class PutModuleGroupOnTruck extends DurationState<UnLoadingForkLiftTruck> {
  @override
  String get name => 'PutModuleGroupOnTruck';

  PutModuleGroupOnTruck()
      : super(
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.putModuleGroupOnTruckDuration,
            nextStateFunction: (forkLiftTruck) => WaitingForFullConveyor());

  @override
  void onCompleted(UnLoadingForkLiftTruck forkLiftTruck) {
    //TODO keep track of trough put
    var moduleGroup = forkLiftTruck.moduleGroupPosition.moduleGroup!;
    forkLiftTruck.area.moduleGroups.remove(moduleGroup);
  }
}
