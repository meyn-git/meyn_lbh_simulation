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
            durationFunction: (forkLiftTruck) =>
                forkLiftTruck.inFeedDuration,
            nextStateFunction: (forkLiftTruck) =>
                WaitingForEmptyConveyor());

  @override
  void onCompleted(LoadingForkLiftTruck forkLiftTruck) {
    var newModuleGroup = forkLiftTruck.createModuleGroup();
    _verifyDirections(
      forkLiftTruck,
      forkLiftTruck.outFeedDirection,
      newModuleGroup.doorDirection.toCardinalDirection()!,
    );
    _verifyDestination(forkLiftTruck, newModuleGroup.destination);
    forkLiftTruck.layout.moduleGroups.add(newModuleGroup);
  }

  static _verifyDirections(
    LoadingForkLiftTruck forkLiftTruck,
    CardinalDirection direction1,
    CardinalDirection direction2,
  ) {
    if (direction1.isParallelTo(direction2)) {
      throw ArgumentError(
          "${forkLiftTruck.name}: outFeedDirection and moduleDoorDirection must be perpendicular in layout configuration.");
    }
  }

  static void _verifyDestination(
    LoadingForkLiftTruck forkLiftTruck,
    StateMachineCell destination,
  ) {
    var layout = forkLiftTruck.layout;
    if (destination is! StateMachineCell) {
      throw ArgumentError("stack.destination must point to a none empty cell");
    }
    var route = layout.findRoute(
        source: forkLiftTruck, destination: destination);
    if (route == null) {
      throw ArgumentError(
          "${forkLiftTruck.name} can not reach destination: $destination in layout configuration.");
    }
  }
}

class WaitingForEmptyConveyor extends State<LoadingForkLiftTruck> {
  @override
  State<LoadingForkLiftTruck>? nextState(
      LoadingForkLiftTruck forkLiftTruck) {
    if (_neighbourCanFeedIn(forkLiftTruck)) {
      return PutStackOnConveyor();
    }
  }

  bool _neighbourCanFeedIn(LoadingForkLiftTruck forkLiftTruck) {
    return forkLiftTruck.receivingNeighbour
        .waitingToFeedIn(forkLiftTruck.outFeedDirection.opposite);
  }
}

/// Drive module stack above in feed conveyor
/// lower stack on in feed conveyor and adjust when needed
/// drive backward to clear lifting spoons
/// push button to feed in
class PutStackOnConveyor extends State<LoadingForkLiftTruck> {

  @override
  void onStart(LoadingForkLiftTruck forkLiftTruck) {
    var moduleGroup = forkLiftTruck.moduleGroup!;
    moduleGroup.position = ModulePosition.betweenCells(
        source: forkLiftTruck,
        destination: forkLiftTruck.receivingNeighbour,
        duration: forkLiftTruck.outFeedDuration);
    moduleGroup.startedLoadingOnToSystem();
  }

  @override
  State<LoadingForkLiftTruck>? nextState(
      LoadingForkLiftTruck forkLiftTruck) {
    if (_transportCompleted(forkLiftTruck)) {
      return GettingStackFromTruck();
    }
  }

  bool _transportCompleted(LoadingForkLiftTruck forkLiftTruck) => forkLiftTruck.moduleGroup==null;
}
