import 'package:flutter/material.dart' as material;
import 'package:meyn_lbh_simulation/state_machine_widgets/layout.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

import 'module.dart';

class ModuleConveyor extends StateMachineCell {
  final CardinalDirection inFeedDirection;

  int nrOfModulesFeedingIn = 0;

  final Duration checkIfEmptyDuration;

  ModuleConveyor({
    required Layout layout,
    required Position position,
    int? seqNr,
    required this.inFeedDirection,
    this.checkIfEmptyDuration = const Duration(seconds: 18),
    Duration inFeedDuration = const Duration(seconds: 12),
    Duration outFeedDuration = const Duration(seconds: 12),
  }) : super(
          layout: layout,
          position: position,
          seqNr: seqNr,
          initialState: CheckIfEmpty(),
          inFeedDuration: inFeedDuration,
          outFeedDuration: outFeedDuration,
        );

  Cell get receivingNeighbour =>
      layout.neighbouringCell(this, inFeedDirection.opposite);

  Cell get sendingNeighbour => layout.neighbouringCell(this, inFeedDirection);

  @override
  bool isFeedIn(CardinalDirection direction) => direction == inFeedDirection;

  @override
  bool waitingToFeedIn(CardinalDirection direction) =>
      direction == inFeedDirection && currentState is WaitToFeedIn;

  @override
  bool isFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite && currentState is WaitToFeedOut;

  @override
  material.Widget get widget => material.Tooltip(
        message: toString(),
        child: material.RotationTransition(
          turns: material.AlwaysStoppedAnimation(
              inFeedDirection.opposite.toCompassDirection().degrees / 360),
          child: material.CustomPaint(painter: ModuleConveyorPainter()),
        ),
      );
}

class ModuleConveyorPainter extends material.CustomPainter {
  @override
  void paint(material.Canvas canvas, material.Size size) {
    drawRectangle(canvas, size);
    drawDirectionTriangle(size, canvas);
  }

  void drawDirectionTriangle(material.Size size, material.Canvas canvas) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.fill;
    var path = material.Path();
    path.moveTo(size.width * 0.45, size.height * 0.45);
    path.lineTo(size.width * 0.55, size.height * 0.45);
    path.lineTo(size.width * 0.50, size.height * 0.4);
    path.close();
    canvas.drawPath(path, paint);
  }

  material.Paint drawRectangle(material.Canvas canvas, material.Size size) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.stroke;
    canvas.drawRect(
        material.Rect.fromCenter(
            center: material.Offset(size.width / 2, size.height / 2),
            width: size.width * 0.4,
            height: size.width * 0.8),
        paint);
    return paint;
  }

  @override
  bool shouldRepaint(covariant material.CustomPainter oldDelegate) => true;
}

class CheckIfEmpty extends DurationState<ModuleConveyor> {
  CheckIfEmpty()
      : super(
            durationFunction: (moduleConveyor) =>
                moduleConveyor.checkIfEmptyDuration,
            nextStateFunction: (moduleConveyor) => WaitToFeedIn());
}

class WaitToFeedIn extends State<ModuleConveyor> {
  @override
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (_moduleGroupTransportedTo(moduleConveyor)) {
      return FeedIn();
    }
  }

  bool _moduleGroupTransportedTo(ModuleConveyor moduleConveyor) {
    return moduleConveyor.layout.moduleGroups.any(
        (moduleGroup) => moduleGroup.position.destination == moduleConveyor);
  }
}

class FeedIn extends State<ModuleConveyor> {
  @override
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (_transportCompleted(moduleConveyor)) {
      return WaitToFeedOut();
    }
  }

  bool _transportCompleted(ModuleConveyor moduleConveyor) =>
      moduleConveyor.moduleGroup != null;
}

class WaitToFeedOut extends State<ModuleConveyor> {
  @override
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (_neighbourCanFeedIn(moduleConveyor) &&
        !_moduleGroupAtDestination(moduleConveyor)) {
      return FeedOut();
    }
  }

  bool _moduleGroupAtDestination(ModuleConveyor moduleConveyor) =>
      moduleConveyor.moduleGroup!.destination == moduleConveyor;

  _neighbourCanFeedIn(ModuleConveyor moduleConveyor) =>
      moduleConveyor.receivingNeighbour
          .waitingToFeedIn(moduleConveyor.inFeedDirection);
}

class FeedOut extends State<ModuleConveyor> {
  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleConveyor moduleConveyor) {
    transportedModuleGroup = moduleConveyor.moduleGroup;
    transportedModuleGroup!.position = ModulePosition.betweenCells(
        source: moduleConveyor,
        destination: moduleConveyor.receivingNeighbour as StateMachineCell);
  }

  @override
  State<ModuleConveyor>? nextState(ModuleConveyor moduleConveyor) {
    if (_transportCompleted(moduleConveyor)) {
      return WaitToFeedIn();
    }
  }

  bool _transportCompleted(ModuleConveyor moduleConveyor) =>
      transportedModuleGroup != null &&
      transportedModuleGroup!.position.source != moduleConveyor;
}
