import 'package:flutter/material.dart' as material;
import 'package:meyn_lbh_simulation/state_machine_widgets/layout.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

import 'module.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class LoadingForkLiftTruck extends StateMachineCell {
  final CardinalDirection outFeedDirection;
  final ModuleGroup Function() createModuleGroup;

  LoadingForkLiftTruck({
    required Layout layout,
    required Position position,
    int? seqNr,
    required this.outFeedDirection,
    required this.createModuleGroup,
    Duration gettingStackFromTruckDuration =
        const Duration(seconds: 5), //TODO 30s?
    Duration putStackOnConveyorDuration =
        const Duration(seconds: 5), //TODO 15s?
  }) : super(
            layout: layout,
            position: position,
            seqNr: seqNr,
            initialState: GettingStackFromTruck(),
            inFeedDuration: gettingStackFromTruckDuration,
            outFeedDuration: putStackOnConveyorDuration);

  get receivingNeighbour =>
      layout.neighbouringCell(this, outFeedDirection) as StateMachineCell;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => false;

  @override
  bool waitingToFeedIn(CardinalDirection direction) => false;

  @override
  bool isFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) => currentState is WaitingForEmptyConveyor;

  @override
  material.Widget get widget => material.Tooltip(
        message: toString(),
        child: material.RotationTransition(
          turns: material.AlwaysStoppedAnimation(paintDirection.degrees / 360),
          child: material.CustomPaint(painter: LoadingForkLiftTruckPainter()),
        ),
      );

  CompassDirection get paintDirection {
    if (currentState is GettingStackFromTruck) {
      return outFeedDirection.opposite.toCompassDirection();
    } else {
      return outFeedDirection.toCompassDirection();
    }
  }
}

class LoadingForkLiftTruckPainter extends material.CustomPainter {
  @override
  void paint(material.Canvas canvas, material.Size size) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.stroke;
    var path = material.Path();

    path.moveTo(size.width * 0.30, size.height * 0.90);
    path.lineTo(size.width * 0.30, size.height * 0.50);
    path.lineTo(size.width * 0.35, size.height * 0.50);
    path.lineTo(size.width * 0.35, size.height * 0.10);
    path.lineTo(size.width * 0.40, size.height * 0.10);
    path.lineTo(size.width * 0.40, size.height * 0.50);
    path.lineTo(size.width * 0.60, size.height * 0.50);
    path.lineTo(size.width * 0.60, size.height * 0.10);
    path.lineTo(size.width * 0.65, size.height * 0.10);
    path.lineTo(size.width * 0.65, size.height * 0.50);
    path.lineTo(size.width * 0.70, size.height * 0.50);
    path.lineTo(size.width * 0.70, size.height * 0.90);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width * 0.3, size.height * 0.9);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant material.CustomPainter oldDelegate) => true;
}

/// driving to truck
/// unloading stack
/// driving to in feed conveyor
class GettingStackFromTruck extends DurationState<LoadingForkLiftTruck> {
  GettingStackFromTruck()
      : super(
            durationFunction: (loadingForkLiftTruck) =>
                loadingForkLiftTruck.inFeedDuration,
            nextStateFunction: (loadingForkLiftTruck) =>
                WaitingForEmptyConveyor());

  @override
  void onCompleted(LoadingForkLiftTruck loadingForkLiftTruck) {
    var newModuleGroup = loadingForkLiftTruck.createModuleGroup();
    _verifyDirections(
      loadingForkLiftTruck,
      loadingForkLiftTruck.outFeedDirection,
      newModuleGroup.doorDirection.toCardinalDirection()!,
    );
    _verifyDestination(loadingForkLiftTruck, newModuleGroup.destination);
    loadingForkLiftTruck.layout.moduleGroups.add(newModuleGroup);
  }

  static _verifyDirections(
    LoadingForkLiftTruck loadingForkLiftTruck,
    CardinalDirection direction1,
    CardinalDirection direction2,
  ) {
    if (direction1.isParallelTo(direction2)) {
      throw ArgumentError(
          "${loadingForkLiftTruck.name}: outFeedDirection and moduleDoorDirection must be perpendicular in layout configuration.");
    }
  }

  static void _verifyDestination(
    LoadingForkLiftTruck loadingForkLiftTruck,
    StateMachineCell destination,
  ) {
    var layout = loadingForkLiftTruck.layout;
    if (destination is! StateMachineCell) {
      throw ArgumentError("stack.destination must point to a none empty cell");
    }
    var route = layout.findRoute(
        source: loadingForkLiftTruck, destination: destination);
    if (route == null) {
      throw ArgumentError(
          "${loadingForkLiftTruck.name} can not reach destination: $destination in layout configuration.");
    }
  }
}

class WaitingForEmptyConveyor extends State<LoadingForkLiftTruck> {
  @override
  State<LoadingForkLiftTruck>? nextState(
      LoadingForkLiftTruck loadingForkLiftTruck) {
    if (_neighbourCanFeedIn(loadingForkLiftTruck)) {
      return PutStackOnConveyor();
    }
  }

  bool _neighbourCanFeedIn(LoadingForkLiftTruck loadingForkLiftTruck) {
    return loadingForkLiftTruck.receivingNeighbour
        .waitingToFeedIn(loadingForkLiftTruck.outFeedDirection.opposite);
  }
}

/// Drive module stack above in feed conveyor
/// lower stack on in feed conveyor and adjust when needed
/// drive backward to clear lifting spoons
/// push button to feed in
class PutStackOnConveyor extends State<LoadingForkLiftTruck> {
  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(LoadingForkLiftTruck loadingForkLiftTruck) {
    transportedModuleGroup = loadingForkLiftTruck.moduleGroup!;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: loadingForkLiftTruck,
        destination: loadingForkLiftTruck.receivingNeighbour,
        duration: loadingForkLiftTruck.outFeedDuration);
  }

  @override
  State<LoadingForkLiftTruck>? nextState(
      LoadingForkLiftTruck loadingForkLiftTruck) {
    if (_transportCompleted(loadingForkLiftTruck)) {
      return GettingStackFromTruck();
    }
  }

  bool _transportCompleted(LoadingForkLiftTruck loadingForkLiftTruck) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != loadingForkLiftTruck;
}
