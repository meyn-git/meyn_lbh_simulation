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
  final ModuleType type;
  CompassDirection doorDirection;
  StateMachineCell destination;
  ModulePosition position;

  ModuleGroup({
    required this.type,
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
    if (sinceLoadedOnSystem != null) {
      sinceLoadedOnSystem = sinceLoadedOnSystem! + jump;
    }
    if (sinceStartStun != null) {
      sinceStartStun = sinceStartStun! + jump;
    }
    if (sinceBirdsUnloaded != null) {
      sinceBirdsUnloaded = sinceBirdsUnloaded! + jump;
    }
  }

  @override
  String toString() => TitleBuilder('ModuleGroup')
      .appendProperty('doorDirection', doorDirection)
      .appendProperty('destination', destination.name)
      //.appendProperty('position', position) removed because its obvious
      .appendProperty('firstModule', firstModule)
      .appendProperty('secondModule', secondModule)
      .toString();

  Duration? get sinceLoadedOnSystem => firstModule.sinceLoadedOnSystem;

  set sinceLoadedOnSystem(Duration? duration) {
    firstModule.sinceLoadedOnSystem = duration;
    if (secondModule != null) {
      secondModule!.sinceLoadedOnSystem = duration;
    }
  }

  void startedLoadingOnToSystem() {
    sinceLoadedOnSystem = Duration.zero;
  }

  Duration? get sinceStartStun => firstModule.sinceStartStun;

  set sinceStartStun(Duration? duration) {
    firstModule.sinceStartStun = duration;
    if (secondModule != null) {
      secondModule!.sinceStartStun = duration;
    }
  }

  void startedStunning() {
    sinceStartStun = Duration.zero;
  }

  Duration? get sinceBirdsUnloaded => firstModule.sinceBirdsUnloaded;

  set sinceBirdsUnloaded(Duration? duration) {
    firstModule.sinceBirdsUnloaded = duration;
    if (secondModule != null) {
      secondModule!.sinceBirdsUnloaded = duration;
    }
  }

  void startedUnloadingBirds() {
    sinceBirdsUnloaded = Duration.zero;
  }
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
    if (source == destination) {
      return TitleBuilder('ModulePosition')
          .appendProperty('at', source.name)
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
  Duration? sinceLoadedOnSystem;
  Duration? sinceStartStun;
  Duration? sinceBirdsUnloaded;

  Module({
    required this.sequenceNumber,
    required this.nrOfBirds,
  });

  @override
  String toString() => TitleBuilder('Module')
      .appendProperty('sequenceNumber', sequenceNumber)
      .appendProperty('nrOfBirds', nrOfBirds)
      .appendProperty('sinceLoadedOnSystem', sinceLoadedOnSystem)
      .appendProperty('sinceStartStun', sinceStartStun)
      .appendProperty('sinceBirdsUnloaded', sinceBirdsUnloaded)
      .toString();
}

class ModuleGroupWidget extends StatelessWidget {
  final ModuleGroup moduleGroup;

  ModuleGroupWidget(this.moduleGroup);

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: AlwaysStoppedAnimation(moduleGroup.doorDirection.degrees / 360),
      child: CustomPaint(painter: ModuleGroupWidgetPainter(moduleGroup)),
    );
  }
}

//TODO depending on type: SideBySide or Stacked
//TODO draw double with small offset when 2 modules
class ModuleGroupWidgetPainter extends CustomPainter {
  final ModuleGroup moduleGroup;
  static final compartmentSize = 0.30;

  ModuleGroupWidgetPainter(this.moduleGroup);

  @override
  void paint(Canvas canvas, Size size) {
    if (moduleGroup.type == ModuleType.square) {
      _paintSquareModules(canvas, size);
    } else {
      _paintRectangleModules(canvas, size);
    }
  }

  /// paints a square scalable module compartment with doors pointing north
  void _paintModuleCompartment(
      Canvas canvas, Size size, double factor, Offset offset,
      {bool paintTriangle = true}) {
    var paint = Paint();
    paint.color = _colorFor(moduleGroup);
    paint.style = PaintingStyle.stroke;

    var path = Path();
    //rectangle starting bottom left
    var left = offset.dx;
    var middle = (size.width * factor) / 2 + offset.dx;
    var right = size.width * factor + offset.dx;
    var top = offset.dy;
    var bottom = size.height * factor + offset.dy;

    // paint square
    path.moveTo(left, bottom);
    path.lineTo(left, top);
    path.lineTo(right, top);
    path.lineTo(right, bottom);
    path.lineTo(left, bottom);

    if (paintTriangle) {
      //paint triangle pointing north
      path.lineTo(middle, top);
      path.lineTo(right, bottom);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Color _colorFor(ModuleGroup moduleGroup) {
    if (moduleGroup.sinceBirdsUnloaded != null) {
      return Colors.black; //no birds
    } else if (moduleGroup.sinceStartStun != null) {
      return Colors.red; // stunned birds
    } else {
      return Colors.green;
    }
  }

  void _paintSquareModules(Canvas canvas, Size size) {
    if (moduleGroup.numberOfModules == 1) {
      _paintSingleSquareModule(canvas, size);
    } else {
      _paintDoubleSquareModuleSideBySide(canvas, size);
    }
  }

  void _paintSingleSquareModule(Canvas canvas, Size size) {
    var x1 = (size.width * (1 - compartmentSize)) / 2;
    var y1 = (size.height * (1 - compartmentSize)) / 2;
    _paintModuleCompartment(canvas, size, compartmentSize, Offset(x1, y1));
  }

  void _paintDoubleSquareModuleSideBySide(Canvas canvas, Size size) {
    var x1 = size.width * 0.15;
    var y1 = (size.width * (1 - compartmentSize)) / 2;
    _paintModuleCompartment(canvas, size, compartmentSize, Offset(x1, y1));
    var x2 = size.width * (0.15 + compartmentSize + 0.1);
    var y2 = y1;
    _paintModuleCompartment(canvas, size, compartmentSize, Offset(x2, y2));
  }

  void _paintRectangleModules(Canvas canvas, Size size) {
    if (moduleGroup.numberOfModules == 1) {
      _paintSingleRectangularModule(canvas, size);
    } else {
      _paintStackedRectangularModules(canvas, size);
    }
  }

  void _paintSingleRectangularModule(
    Canvas canvas,
    Size size, {
    Offset offset = Offset.zero,
    paintTriangle: true,
  }) {
    var x1 = size.width * 0.2 + offset.dx;
    var y1 = (size.width * (1 - compartmentSize)) / 2 + offset.dy;
    _paintModuleCompartment(
      canvas,
      size,
      compartmentSize,
      Offset(x1, y1),
      paintTriangle: paintTriangle,
    );
    var x2 = size.width * (0.2 + compartmentSize) + offset.dx;
    var y2 = y1;
    _paintModuleCompartment(
      canvas,
      size,
      compartmentSize,
      Offset(x2, y2),
      paintTriangle: paintTriangle,
    );
  }

  void _paintStackedRectangularModules(Canvas canvas, Size size) {
    var x1 = -size.width * 0.01;
    var y1 = -size.width * 0.01;
    _paintSingleRectangularModule(
      canvas,
      size,
      offset: Offset(x1, y1),
      paintTriangle: false,
    );
    var x2 = size.width * 0.01;
    var y2 = size.width * 0.01;
    _paintSingleRectangularModule(
      canvas,
      size,
      offset: Offset(x2, y2),
    );
  }
}

enum ModuleType { square, rectangular }
