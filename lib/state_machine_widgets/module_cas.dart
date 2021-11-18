import 'package:flutter/material.dart' as material;
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

import 'layout.dart';
import 'module.dart';

class ModuleCas extends StateMachineCell {
  /// the [CardinalDirection] the in and out feed is pointed towards
  final CardinalDirection inAndOutFeedDirection;
  final CasRecipe recipe;
  final Duration closeSlideDoorDuration;
  final Duration openSlideDoorDuration;
  final Position moduleDestinationPositionAfterStunning;

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
    required this.moduleDestinationPositionAfterStunning,
  }) : super(
    layout: layout,
    position: position,
    seqNr: seqNr,
    initialState: WaitToFeedIn(),
    inFeedDuration: inFeedDuration,
    outFeedDuration: outFeedDuration,
  );

  StateMachineCell get neighbour =>
      layout.neighbouringCell(this, inAndOutFeedDirection) as StateMachineCell;

  @override
  bool isFeedIn(CardinalDirection direction) =>
      direction == inAndOutFeedDirection;

  @override
  bool waitingToFeedIn(CardinalDirection direction) =>
      direction == inAndOutFeedDirection && currentState is WaitToFeedIn;

  @override
  bool isFeedOut(CardinalDirection direction) =>
      direction == inAndOutFeedDirection;

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) =>
      currentState is ExhaustStage;

  @override
  bool waitingToFeedOut(CardinalDirection direction) =>
      direction == inAndOutFeedDirection && currentState is WaitToFeedOut;

  StateMachineCell get moduleDestinationAfterStunning =>
      layout.cellForPosition(
          moduleDestinationPositionAfterStunning) as StateMachineCell;

  @override
  material.Widget get widget =>
      material.Tooltip(
        message: toString(),
        child: material.RotationTransition(
          turns: material.AlwaysStoppedAnimation(
              inAndOutFeedDirection
                  .toCompassDirection()
                  .degrees / 360),
          child: material.CustomPaint(painter: ModuleCasPainter()),
        ),
      );

}

class ModuleCasPainter extends material.CustomPainter {
  @override
  void paint(material.Canvas canvas, material.Size size) {
    drawRectangle(canvas, size);
    drawInFeedTriangle(canvas, size);
    drawOutFeedTriangle(canvas, size);
    drawAirIntakes(canvas, size);
  }

  void drawInFeedTriangle(material.Canvas canvas, material.Size size) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.fill;
    var path = material.Path();
    path.moveTo(size.width * 0.45, size.height * 0.55);
    path.lineTo(size.width * 0.55, size.height * 0.55);
    path.lineTo(size.width * 0.50, size.height * 0.6);
    path.close();
    canvas.drawPath(path, paint);
  }

  void drawOutFeedTriangle(material.Canvas canvas, material.Size size) {
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

  material.Paint drawAirIntakes(material.Canvas canvas, material.Size size) {
    var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.stroke;
    canvas.drawRect(
        material.Rect.fromLTWH(size.width * 0.2, size.height * 0.2,
            size.width * 0.1, size.height * 0.2),
        paint);
    canvas.drawRect(
        material.Rect.fromLTWH(size.width * 0.2, size.height * 0.6,
            size.width * 0.1, size.height * 0.2),
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

class WaitToFeedIn extends State<ModuleCas> {
  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_moduleGroupTransportedTo(cas)) {
      return FeedIn();
    }
  }

  bool _moduleGroupTransportedTo(ModuleCas cas) =>
      cas.layout.moduleGroups
          .any((moduleGroup) => moduleGroup.position.destination == cas);
}

class FeedIn extends State<ModuleCas> {
  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_transportCompleted(cas)) {
      return WaitForStart();
    }
  }

  bool _transportCompleted(ModuleCas cas) => cas.moduleGroup != null;
}

class WaitForStart extends State<ModuleCas> {
  @override
  State<ModuleCas>? nextState(ModuleCas moduleCas) {
    //TODO wait for start from
    return CloseSlideDoor();
  }
}

class CloseSlideDoor extends DurationState<ModuleCas> {
  CloseSlideDoor()
      : super(
    durationFunction: (cas) => cas.closeSlideDoorDuration,
    nextStateFunction: (cas) => StunStage(1),
  );
}

class StunStage extends DurationState<ModuleCas> {
  final int stageNumber;

  StunStage(this.stageNumber)
      : super(
      durationFunction: (cas) => findDuration(cas),
      nextStateFunction: (cas) => findNextStage(cas, stageNumber));

  static State<ModuleCas> findNextStage(ModuleCas cas, int currentStageNumber) {
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

  @override
  String toString() => '$name (remaining: ${remainingDuration.inSeconds}sec)';
}

class ExhaustStage extends DurationState<ModuleCas> {
  ExhaustStage()
      : super(
      durationFunction: (cas) => cas.recipe.exhaustDuration,
      nextStateFunction: (cas) => OpenSlideDoor());

  @override
  void onCompleted(ModuleCas cas) {
    cas.moduleGroup!.destination = cas.moduleDestinationAfterStunning;
  }
}

class OpenSlideDoor extends DurationState<ModuleCas> {
  OpenSlideDoor()
      : super(
    durationFunction: (cas) => cas.openSlideDoorDuration,
    nextStateFunction: (cas) => WaitToFeedOut(),
  );
}

class WaitToFeedOut extends State<ModuleCas> {
  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_neighbourOkToFeedIn(cas)) {
      return FeedOut();
    }
  }

  bool _neighbourOkToFeedIn(ModuleCas cas) =>
      cas.neighbour.waitingToFeedIn(cas.inAndOutFeedDirection.opposite);
}

class FeedOut extends State<ModuleCas> {
  ModuleGroup? transportedModuleGroup;

  @override
  void onStart(ModuleCas cas) {
    transportedModuleGroup = cas.moduleGroup;
    transportedModuleGroup!.position =
        ModulePosition.betweenCells(source: cas, destination: cas.neighbour);
  }

  @override
  State<ModuleCas>? nextState(ModuleCas cas) {
    if (_transportCompleted(cas)) {
      return WaitToFeedIn();
    }
  }

  bool _transportCompleted(ModuleCas cas) =>
      transportedModuleGroup != null &&
          transportedModuleGroup!.position.source != cas;
}
