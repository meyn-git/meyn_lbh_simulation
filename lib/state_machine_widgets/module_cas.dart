import 'package:flutter/material.dart' as material;
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

import 'layout.dart';

class ModuleCas extends StateMachineCell {
  /// the [CardinalDirection] the in and out feed is pointed towards
  final CardinalDirection inAndOutFeedDirection;
  final CasRecipe recipe;
  final Duration closeSlideDoorDuration;
  final Duration openSlideDoorDuration;
  final Position moduleDestinationAfterStunning;

  ModuleCas({
    required Layout layout,
    required Position position,
    int? seqNr,
    required this.inAndOutFeedDirection,
    this.recipe = const CasRecipe([
      Duration(seconds: 60),
      Duration(seconds: 60),
      Duration(seconds: 60),
      Duration(seconds: 60),
      Duration(seconds: 120)
    ], Duration(seconds: 30)),
    this.closeSlideDoorDuration = const Duration(seconds: 3),
    this.openSlideDoorDuration = const Duration(seconds: 3),
    Duration inFeedDuration = const Duration(seconds: 14),
    Duration outFeedDuration = const Duration(seconds: 14),
    required this.moduleDestinationAfterStunning,
  }) : super(
          layout: layout,
          position: position,
          seqNr: seqNr,
          initialState: WaitingToFeedIn(),
          inFeedDuration: inFeedDuration,
          outFeedDuration: outFeedDuration,
        );

  @override
  bool isFeedIn(CardinalDirection direction) =>
      direction == inAndOutFeedDirection;

  @override
  bool okToFeedIn(CardinalDirection direction) =>
      direction == inAndOutFeedDirection &&
      (currentState is WaitingToFeedIn || currentState is FeedingIn);

  @override
  bool isFeedOut(CardinalDirection direction) =>
      direction == inAndOutFeedDirection;

  @override
  bool almostOkToFeedOut(CardinalDirection direction) =>
      currentState is ExhaustStage;

  @override
  bool okToFeedOut(CardinalDirection direction) =>
      direction == inAndOutFeedDirection &&
      (currentState is WaitingToFeedOut || currentState is FeedingOut);

  @override
  material.Widget get widget =>  material.Tooltip(
    message: toolTipText(),
    child: material.RotationTransition(
      turns: material.AlwaysStoppedAnimation(inAndOutFeedDirection.toCompassDirection().degrees/360),
      child: material.CustomPaint(painter: ModuleCasPainter()),
    ),
  );
}

class ModuleCasPainter extends material.CustomPainter {
  @override
  void paint(material.Canvas canvas, material.Size size) {
    drawRectangle(canvas, size);
    drawInFeedTriangle( canvas, size);
    drawOutFeedTriangle(canvas, size);
    drawAirIntakes(canvas, size);
  }

  void drawInFeedTriangle( material.Canvas canvas,material.Size size) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.fill;
    var path=material.Path();
    path.moveTo(size.width*0.45, size.height *0.55);
    path.lineTo(size.width*0.55, size.height *0.55);
    path.lineTo(size.width*0.50, size.height *0.6);
    path.close();
    canvas.drawPath(path, paint);
  }
  void drawOutFeedTriangle( material.Canvas canvas, material.Size size) {
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

  material.Paint drawAirIntakes(material.Canvas canvas, material.Size size) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.stroke;
    canvas.drawRect(
        material.Rect.fromLTWH(size.width * 0.2, size.height * 0.2,size.width * 0.1, size.height * 0.2),
        paint);
    canvas.drawRect(
        material.Rect.fromLTWH(size.width * 0.2, size.height * 0.6,size.width * 0.1, size.height * 0.2),
        paint);
    return paint;
  }

  @override
  bool shouldRepaint(covariant material.CustomPainter oldDelegate) => true;
}

class CasRecipe {
  final List<Duration> stunStageDurations;
  final Duration exhaustDuration;

  const CasRecipe(this.stunStageDurations, this.exhaustDuration);
}

class WaitingToFeedIn extends State<ModuleCas> {
  @override
  State? process(ModuleCas cas) {
    var inFeedNeighbouringCell =
        cas.layout.neighbouringCell(cas, cas.inAndOutFeedDirection);
    bool neighbourCanFeedOut =
        inFeedNeighbouringCell.okToFeedOut(cas.inAndOutFeedDirection.opposite);
    if (neighbourCanFeedOut) {
      return FeedingIn();
    }
  }
}

class FeedingIn extends DurationState<ModuleCas> {
  int nrOfModulesBeingTransported = 0;

  static ModuleGroup? stackBeingTransferred;

  FeedingIn()
      : super(
          duration: (cas) => cas.inFeedDuration,
          onStart: (cas) {
            var inFeedNeighbouringCell =
                cas.layout.neighbouringCell(cas, cas.inAndOutFeedDirection);
            stackBeingTransferred = inFeedNeighbouringCell.moduleGroup!;
          },
          onCompleted: (moduleConveyor) {
            stackBeingTransferred!.position =
                ModulePosition.forCel(moduleConveyor);
          },
          nextState: (moduleConveyor) => WaitingForStart(),
        );
}

class WaitingForStart extends State<ModuleCas> {
  @override
  State? process(ModuleCas cas) {
    //TODO wait for start from
    return CloseSlideDoor();
  }
}

class CloseSlideDoor extends DurationState<ModuleCas> {
  CloseSlideDoor()
      : super(
          duration: (cas) => cas.closeSlideDoorDuration,
          nextState: (cas) => StunStage(1),
        );
}

class StunStage extends DurationState<ModuleCas> {
  final int stageNumber;

  StunStage(this.stageNumber)
      : super(
            duration: (cas) => findDuration(cas),
            nextState: (cas) => findNextStage(cas, stageNumber));

  static State findNextStage(ModuleCas cas, int currentStageNumber) {
    if (currentStageNumber >= numberOfStages(cas)) {
      return ExhaustStage();
    } else {
      return StunStage(++currentStageNumber);
    }
  }

  @override
  String get name => '${super.name}$stageNumber';

  static int numberOfStages(ModuleCas cas) =>
      cas.recipe.stunStageDurations.length;

  static findDuration(ModuleCas cas) {
    var currentState = cas.currentState;
    if (currentState is StunStage) {
      var currentStageNumber = currentState.stageNumber;
      return cas.recipe.stunStageDurations[currentStageNumber - 1];
    }
    throw Exception('Unknown StunStage duration');
  }
}

class ExhaustStage extends DurationState<ModuleCas> {
  ExhaustStage()
      : super(
            duration: (cas) => cas.recipe.exhaustDuration,
            onCompleted: (cas) {
              cas.moduleGroup!.destination = cas.moduleDestinationAfterStunning;
            },
            nextState: (cas) => OpenSlideDoor());

  static int numberOfStages(ModuleCas cas) =>
      cas.recipe.stunStageDurations.length;
}

class OpenSlideDoor extends DurationState<ModuleCas> {
  OpenSlideDoor()
      : super(
          duration: (cas) => cas.openSlideDoorDuration,
          nextState: (cas) => WaitingToFeedOut(),
        );
}

class WaitingToFeedOut extends State<ModuleCas> {
  @override
  State? process(ModuleCas cas) {
    var outFeedNeighbouringCell =
        cas.layout.neighbouringCell(cas, cas.inAndOutFeedDirection.opposite);
    bool neighbourCanFeedIn =
        outFeedNeighbouringCell.okToFeedIn(cas.inAndOutFeedDirection);
    if (neighbourCanFeedIn) {
      return FeedingOut();
    }
  }
}

class FeedingOut extends DurationState<ModuleCas> {
  FeedingOut()
      : super(
            duration: (cas) => cas.outFeedDuration,
            nextState: (cas) => WaitingToFeedIn());
}
