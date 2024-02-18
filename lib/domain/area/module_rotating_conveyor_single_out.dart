import 'package:collection/collection.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/module_tilter.dart' as tilter;
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_rotating_conveyor.dart';
import 'state_machine.dart';

/// Special for 7160 agricola, with a copy of the states + additional states: FeedOutFirst and FeedOutSecond
class ModuleRotatingConveyorSingleOut extends ModuleRotatingConveyor {
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];

  ModuleRotatingConveyorSingleOut({
    required super.area,
    required super.position,
    int? seqNr,
    int? degreesPerSecond,
    super.defaultPositionWhenIdle,
    super.oppositeInFeeds = const [],
    super.oppositeOutFeeds = const [],
    super.inFeedDuration,
    super.outFeedDuration,
  }) : super(initialState: TurnToInFeed2());

  ModuleGroup? waitingModuleGroup;

  /// needed override: When [waitingModuleGroup]!=null than
  /// there could be 2 [ModuleGroup]s in [LiveBirdHandlingArea.modelGroups] for this [StateMachineCell].
  /// In this case we do not want the [waitingModuleGroup] but the other one
  /// That is why we need to override the default behavior.
  @override
  ModuleGroup? get moduleGroup =>
      area.moduleGroups.firstWhereOrNull((moduleGroup) =>
          moduleGroup != waitingModuleGroup &&
          moduleGroup.position.equals(this));
}

class TurnToInFeed2 extends TurnToInFeed {
  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (rotatingConveyor.moduleGroupFeedingIn) {
      return FeedIn2();
    }
    return null;
  }
}

class FeedIn2 extends FeedIn {
  @override
  String get name => 'FeedIn';
  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (transportCompleted(rotatingConveyor)) {
      return TurnToFeedOut2();
    }
    return null;
  }
}

class TurnToFeedOut2 extends TurnToFeedOut {
  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (neighborOkToFeedIn(rotatingConveyor) &&
        doneRotating(rotatingConveyor) &&
        rotatingConveyor.moduleGroup!.destination != rotatingConveyor) {
      rotatingConveyor as ModuleRotatingConveyorSingleOut;
      if (_neighborIsTilter(rotatingConveyor)) {
        return FeedOutFirst();
      } else {
        return FeedOut2();
      }
    }
    return null;
  }

  bool _neighborIsTilter(ModuleRotatingConveyorSingleOut rotatingConveyor) {
    var currentDirection = rotatingConveyor.currentDirection;
    var direction = currentDirection.toCardinalDirection();
    if (direction == null) {
      return false;
    }
    var neighbor =
        rotatingConveyor.area.neighboringCell(rotatingConveyor, direction);
    return neighbor is tilter.ModuleTilter;
  }
}

class FeedOut2 extends FeedOut {
  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (transportCompleted(rotatingConveyor)) {
      return TurnToInFeed2();
    }
    return null;
  }
}

class FeedOutFirst extends FeedOut {
  @override
  String get name => 'FeedOutFirst';
  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleRotatingConveyor rotatingConveyor) {
    var area = rotatingConveyor.area;

    rotatingConveyor as ModuleRotatingConveyorSingleOut;
    transportedModuleGroup = rotatingConveyor.moduleGroup;

    rotatingConveyor.waitingModuleGroup = transportedModuleGroup!.split();
    area.moduleGroups.add(rotatingConveyor.waitingModuleGroup!);

    var neighborDirection = rotatingConveyor.bestOutFeedNeighbor;
    var receivingNeighbor = area.neighboringCell(
        rotatingConveyor, neighborDirection!) as StateMachineCell;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: rotatingConveyor, destination: receivingNeighbor);
  }

  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (neighborOkToFeedIn(rotatingConveyor) &&
        transportCompleted2(rotatingConveyor)) {
      rotatingConveyor as ModuleRotatingConveyorSingleOut;
      return FeedOutSecond();
    }
    return null;
  }

  bool neighborOkToFeedIn(ModuleRotatingConveyor rotatingConveyor) {
    // CardinalDirection? neighborPosition =
    //     rotatingConveyor.bestOutFeedNeighbor; TODO does not work
    CardinalDirection? neighborPosition =
        rotatingConveyor.currentDirection.toCardinalDirection();
    if (neighborPosition == null) {
      return false;
    }
    var receivingNeighbor = rotatingConveyor.area
        .neighboringCell(rotatingConveyor, neighborPosition);
    return receivingNeighbor.waitingToFeedIn(neighborPosition.opposite);
  }

  bool doneRotating(ModuleRotatingConveyor rotatingConveyor) {
    var goToDirection = rotatingConveyor.outFeedDirection;
    var currentDirection =
        rotatingConveyor.currentDirection.toCardinalDirection();
    var doneRotating =
        goToDirection != null && goToDirection == currentDirection;
    return doneRotating;
  }
  // void _putWaitingModuleGroupInPosition(
  //     ModuleRotatingConveyorSingleOut rotatingConveyor) {
  //   rotatingConveyor.waitingModuleGroup!.position =
  //       ModulePosition.forCel(rotatingConveyor);
  // }

  bool transportCompleted2(ModuleRotatingConveyor rotatingConveyor) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != rotatingConveyor;
}

class FeedOutSecond extends FeedOut {
  @override
  void onStart(ModuleRotatingConveyor rotatingConveyor) {
    rotatingConveyor as ModuleRotatingConveyorSingleOut;
    rotatingConveyor.waitingModuleGroup!.position =
        ModulePosition.forCel(rotatingConveyor);
    rotatingConveyor.waitingModuleGroup = null;
    var area = rotatingConveyor.area;
    //var neighborDirection = rotatingConveyor.bestOutFeedNeighbor; TODO DID not work???
    var neighborDirection =
        rotatingConveyor.currentDirection.toCardinalDirection();
    var receivingNeighbor = area.neighboringCell(
        rotatingConveyor, neighborDirection!) as StateMachineCell;
    rotatingConveyor.moduleGroup!.position = ModulePosition.betweenCells(
        source: rotatingConveyor, destination: receivingNeighbor);
  }

  @override
  String get name => 'FeedOutSecond';
  @override
  State<ModuleRotatingConveyor>? nextState(
      // ignore: avoid_renaming_method_parameters
      ModuleRotatingConveyor rotatingConveyor) {
    if (transportCompleted(rotatingConveyor)) {
      return TurnToInFeed2();
    }
    return null;
  }
}
