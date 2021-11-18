import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/title_builder.dart';

import 'layout.dart';

/// A [ModuleGroup] can be one or 2 modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side
class ModuleGroup extends TimeProcessor {
  final Module firstModule;
  final Module? secondModule;
  CompassDirection doorDirection;
  StateMachineCell destination;
  ModulePosition position;

  ModuleGroup({
    required this.firstModule,
    this.secondModule,
    required this.doorDirection,
    required this.destination,
    required this.position,
  });

  int get numberOfModules => 1 + ((secondModule == null) ? 0 : 1);

  @override
  onUpdateToNextPointInTime(Duration jump) {
    position.processNextTimeFrame(this, jump);
  }

  @override
  String toString() => TitleBuilder('ModuleGroup')
      .appendProperty('doorDirection', doorDirection)
      .appendProperty('destination', destination.name)
      //.appendProperty('position', position) removed because its obvious
      .appendProperty('firstModule', firstModule)
      .appendProperty('secondModule', secondModule)
      .toString();
}

/// A module location is either at a given position or traveling between 2 positions
class ModulePosition {
  StateMachineCell source;
  StateMachineCell destination;
  late Duration duration;
  late Duration remainingDuration;

  ModulePosition.forCel(StateMachineCell cell)
      : source = cell,
        destination = cell,
        duration = Duration.zero,
        remainingDuration = Duration.zero;

  ModulePosition.betweenCells(
      {required this.source, required this.destination, Duration? duration}) {
    this.duration = duration ?? findLongestDuration(source, destination);
    remainingDuration = this.duration;
  }

  /// 0  =  0% of transportation is completed
  /// 0.5= 50% of transportation is completed
  /// 1  =100% of transportation is completed
  double get percentageCompleted => duration == Duration.zero
      ? 1
      : 1 - remainingDuration.inMilliseconds / duration.inMilliseconds;

  processNextTimeFrame(ModuleGroup moduleGroup, Duration jump) {
    if (remainingDuration > Duration.zero) {
      remainingDuration = remainingDuration - jump;
      if (remainingDuration <= Duration.zero) {
        source = destination;
      }
    } else {
      remainingDuration = Duration.zero;
    }
  }

  equals(StateMachineCell cell) =>
      source.position == cell.position &&
      destination.position == cell.position &&
      remainingDuration == Duration.zero;

  static Duration findLongestDuration(
    StateMachineCell source,
    StateMachineCell destination,
  ) {
    Duration outFeedDuration = source.outFeedDuration;
    Duration inFeedDuration = destination.inFeedDuration;
    return Duration(
        milliseconds:
            max(outFeedDuration.inMilliseconds, inFeedDuration.inMilliseconds));
  }

  @override
  String toString() {
    if (source == destination ) {
      return TitleBuilder('ModulePosition')
          .appendProperty('at',  source.name)
          .toString();
    } else {
      return TitleBuilder('ModulePosition')
          .appendProperty('source', source.name)
          .appendProperty('destination', destination.name)
          .appendProperty('remainingDuration', remainingDuration)
          .toString();
    }
  }
}

class Module {
  final int sequenceNumber;
  final int nrOfBirds;
  DateTime? loadedOnSystem;
  DateTime? startStun;
  DateTime? startUnloadBirds;

  Module({
    required this.sequenceNumber,
    required this.nrOfBirds,
  });

  @override
  String toString() => TitleBuilder('Module')
      .appendProperty('sequenceNumber', sequenceNumber)
      .appendProperty('nrOfBirds', nrOfBirds)
      .appendProperty('loadedOnSystem', loadedOnSystem)
      .appendProperty('startStun', startStun)
      .appendProperty('startUnloadBirds', startUnloadBirds)
      .toString();
}

class ModuleGroupWidget extends StatelessWidget {
  final ModuleGroup moduleGroup;

  ModuleGroupWidget(this.moduleGroup);

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: AlwaysStoppedAnimation(moduleGroup.doorDirection.degrees / 360),
      child: CustomPaint(painter: ModuleConveyorPainter()),
    );
  }
}

//TODO depending on type: SideBySide or Stacked
//TODO draw double with small offset when 2 modules
class ModuleConveyorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.green.withOpacity(0.5); //TODO red when stunned
    paint.style = PaintingStyle.stroke;

    var path = Path();
    //rectangle starting bottom left, doors north
    var x1 = 0.12;
    var x2 = 0.31;
    var x3 = 0.5;
    var x4 = 0.69;
    var x5 = 0.88;
    var y1 = 0.32;
    var y2 = 0.68;
    path.moveTo(size.width * x1, size.height * y2);
    path.lineTo(size.width * x1, size.height * y1);
    path.lineTo(size.width * x5, size.height * y1);
    path.lineTo(size.width * x5, size.height * y2);
    path.lineTo(size.width * x1, size.height * y2);

    //left compartment triangle
    path.lineTo(size.width * x2, size.height * y1);
    path.lineTo(size.width * x3, size.height * y2);

    //middle line
    path.lineTo(size.width * x3, size.height * y1);
    path.lineTo(size.width * x3, size.height * y2);

    //left compartment triangle
    path.lineTo(size.width * x4, size.height * y1);
    path.lineTo(size.width * x5, size.height * y2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
