import 'package:flutter/material.dart' as material;
import 'package:meyn_lbh_simulation/state_machine_widgets/layout.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

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

  @override
  bool isFeedIn(CardinalDirection direction) => direction == inFeedDirection;

  @override
  bool okToFeedIn(CardinalDirection direction) =>
      direction == inFeedDirection &&
      (currentState is WaitingToFeedIn || currentState is FeedingIn);

  @override
  bool isFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite;

  @override
  bool almostOkToFeedOut(CardinalDirection direction) => false;

  @override
  bool okToFeedOut(CardinalDirection direction) =>
      direction == inFeedDirection.opposite &&
      (currentState is WaitingToFeedOut || currentState is FeedingOut);

  @override
  material.Widget get widget =>  material.Tooltip(
    message: toolTipText(),
    child: material.RotationTransition(
      turns: material.AlwaysStoppedAnimation(inFeedDirection.opposite.toCompassDirection().degrees/360),
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
    var path=material.Path();
    path.moveTo(size.width*0.45, size.height *0.45);
    path.lineTo(size.width*0.55, size.height *0.45);
    path.lineTo(size.width*0.50, size.height *0.4);
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
            duration: (moduleConveyor) => moduleConveyor.checkIfEmptyDuration,
            nextState: (moduleConveyor) => WaitingToFeedIn());
}

class WaitingToFeedIn extends State<ModuleConveyor> {
  @override
  State? process(ModuleConveyor moduleConveyor) {
    var inFeedNeighbouringCell = moduleConveyor.layout
        .neighbouringCell(moduleConveyor, moduleConveyor.inFeedDirection);
    bool neighbourCanFeedOut = inFeedNeighbouringCell
        .okToFeedOut(moduleConveyor.inFeedDirection.opposite);
    if (neighbourCanFeedOut) {
      return FeedingIn();
    }
    if (moduleConveyor.moduleGroup != null) {
      //e.g. LoadingForkLiftTruck put a stack on conveyor
      return WaitingToFeedOut();
    }
  }
}

class FeedingIn extends DurationState<ModuleConveyor> {
  int nrOfModulesBeingTransported = 0;

  static ModuleGroup? stackBeingTransferred;

  FeedingIn()
      : super(
          duration: (moduleConveyor) => moduleConveyor.inFeedDuration,
          onStart: (moduleConveyor) {
            var inFeedNeighbouringCell = moduleConveyor.layout.neighbouringCell(
                moduleConveyor, moduleConveyor.inFeedDirection);
            stackBeingTransferred = inFeedNeighbouringCell.moduleGroup!;
          },
          onCompleted: (moduleConveyor) {
            stackBeingTransferred!.position = ModulePosition.forCel(
                moduleConveyor); // TODO change to transition
          },
          nextState: (moduleConveyor) => WaitingToFeedOut(),
        );
}

class WaitingToFeedOut extends State<ModuleConveyor> {
  @override
  State? process(ModuleConveyor moduleConveyor) {
    var outFeedNeighbouringCell = moduleConveyor.layout.neighbouringCell(
        moduleConveyor, moduleConveyor.inFeedDirection.opposite);
    bool neighbourCanFeedIn =
        outFeedNeighbouringCell.okToFeedIn(moduleConveyor.inFeedDirection);
    if (neighbourCanFeedIn) {
      return FeedingOut();
    }
  }
}

class FeedingOut extends DurationState<ModuleConveyor> {
  FeedingOut()
      : super(
            duration: (moduleConveyor) => moduleConveyor.outFeedDuration,
            nextState: (moduleConveyor) => WaitingToFeedIn());
}
