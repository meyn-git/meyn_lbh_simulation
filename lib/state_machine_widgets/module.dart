import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

import 'layout.dart';

/// A [ModuleGroup] can be one or 2 modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side
class ModuleGroup extends TimeProcessor {
  final Module firstModule;
  final Module? secondModule;
  CompassDirection doorDirection;
  Position destination;
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
  processNextTimeFrame(Duration jump) {
    position.processNextTimeFrame(this, jump);
  }

  @override
  String toString() {
    return 'ModuleGroup{\n  firstModule: $firstModule, \n  secondModule: $secondModule,\n   doorDirection: $doorDirection,\n   destination: $destination,\n   position: $position}';
  }
}

/// A module location is either at a given position or traveling between 2 positions
class ModulePosition {
  StateMachineCell source;
  StateMachineCell destination;
  Duration remainingDuration;

  ModulePosition.forCel(StateMachineCell cell)
      : source = cell,
        destination = cell,
        remainingDuration = Duration.zero;

  ModulePosition.betweenCells({
    required this.source,
    required this.destination,
  }) : remainingDuration = findLongestDuration(source, destination);

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
    return "ModulePosition{source: $source${source == destination ? '' : ' , destination: $destination, remainingDuration: $remainingDuration'}}";
  }
}

class Module {
  final int sequenceNumber;
  final int nrOfBirds;
  DateTime? startStun;

  Module({
    required this.sequenceNumber,
    required this.nrOfBirds,
  });

  // Module get clone => Module(
  //       sequenceNumber: sequenceNumber,
  //       nrOfBirds: nrOfBirds,
  //     );

  @override
  String toString() {
    return 'Module{sequenceNumber: $sequenceNumber, nrOfBirds: $nrOfBirds}';
  }
}

class ModuleGroupWidget extends StatelessWidget {
  final ModuleGroup moduleGroup;

  ModuleGroupWidget(this.moduleGroup);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: moduleGroup.toString(),
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(moduleGroup.doorDirection.degrees / 360),
        child: CustomPaint(painter: ModuleConveyorPainter()),
      ),
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
