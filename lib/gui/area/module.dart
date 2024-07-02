import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleGroupWidget extends StatelessWidget {
  final ModuleGroup moduleGroup;

  ModuleGroupWidget(this.moduleGroup) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return RotationTransition(
      turns: AlwaysStoppedAnimation(moduleGroup.direction.toFraction()),
      child: CustomPaint(painter: ModuleGroupPainter(moduleGroup, theme)),
    );
  }
}

class ModuleGroupPainter extends CustomPainter {
  final ModuleGroup moduleGroup;
  final LiveBirdsHandlingTheme theme;

  /// 5% of module group length
  static const gabBetweenModulesFraction = 0.05;
  ModuleGroupPainter(this.moduleGroup, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    if (moduleGroup.moduleFamily.shape == ModuleShape.squareSideBySide) {
      _paintSquareModules(canvas, size);
    } else {
      _paintRectangleModules(canvas, size);
    }
  }

  /// paints a square scalable module compartment with doors facing west
  void _paintModuleCompartment({
    required Canvas canvas,
    required Size compartmentSize,
    required Offset topLeft,
    required bool paintTriangle,
  }) {
    var paint = Paint();
    paint.color = _colorFor(moduleGroup);
    paint.style = PaintingStyle.stroke;

    var path = Path();
    //rectangle starting bottom left
    var left = topLeft.dx;
    var right = topLeft.dx + compartmentSize.width;
    var top = topLeft.dy;
    var triangleMiddle = topLeft.dy + compartmentSize.height * 0.5;
    var bottom = topLeft.dy + compartmentSize.height;

    // paint square
    path.moveTo(right, bottom);
    path.lineTo(left, bottom);
    path.lineTo(left, top);
    path.lineTo(right, top);
    path.lineTo(right, bottom);

    if (paintTriangle) {
      //paint triangle pointing west
      path.lineTo(left, triangleMiddle);
      path.lineTo(right, top);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  Color _colorFor(ModuleGroup moduleGroup) {
    switch (moduleGroup.contents) {
      case BirdContents.noBirds:
        return theme.withoutBirdsColor;
      case BirdContents.stunnedBirds:
        return theme.withStunnedBirdsColor;
      case BirdContents.birdsBeingStunned:
        return theme.withBirdsBeingStunnedColor;
      case BirdContents.awakeBirds:
        return theme.withAwakeBirdsColor;
    }
  }

  void _paintSquareModules(Canvas canvas, Size size) {
    if (moduleGroup.numberOfModules == 1) {
      _paintSingleSquareModule(canvas, size);
    } else {
      _paintDoubleSquareModuleSideBySide(canvas, size);
    }
  }

  void _paintSingleSquareModule(Canvas canvas, Size groupSize) {
    var gabBetween = groupSize.height * gabBetweenModulesFraction;
    var moduleSize = Size(groupSize.width, (groupSize.height - gabBetween) / 2);
    _paintModuleCompartment(
      canvas: canvas,
      compartmentSize: moduleSize,
      topLeft: Offset(0, (groupSize.height - moduleSize.height) / 2),
      paintTriangle:
          moduleGroup.moduleFamily.compartmentType.birdsExitOnOneSide,
    );
  }

  // paints 2 modules side by side (note not 4 modules!)
  void _paintDoubleSquareModuleSideBySide(Canvas canvas, Size groupSize) {
    var gabBetween = groupSize.height * gabBetweenModulesFraction;
    var compartmentSize =
        Size(groupSize.width, (groupSize.height - gabBetween) / 2);
    _paintModuleCompartment(
      canvas: canvas,
      compartmentSize: compartmentSize,
      topLeft: Offset.zero,
      paintTriangle: moduleGroup.moduleFamily.compartmentType ==
          CompartmentType.doorOnOneSide,
    );
    _paintModuleCompartment(
      canvas: canvas,
      compartmentSize: compartmentSize,
      topLeft: Offset(0, compartmentSize.height + gabBetween),
      paintTriangle:
          moduleGroup.moduleFamily.compartmentType.birdsExitOnOneSide,
    );
  }

  void _paintRectangleModules(Canvas canvas, Size size) {
    if (moduleGroup.numberOfModules == 1) {
      _paintSingleRectangularModule(
        canvas: canvas,
        moduleSize: size,
        paintTriangle:
            moduleGroup.moduleFamily.compartmentType.birdsExitOnOneSide,
      );
    } else {
      _paintStackedRectangularModules(
        canvas: canvas,
        groupSize: size,
        paintTriangle:
            moduleGroup.moduleFamily.compartmentType.birdsExitOnOneSide,
      );
    }
  }

  void _paintSingleRectangularModule({
    required Canvas canvas,
    required Size moduleSize,
    Offset topLeft = Offset.zero,
    required bool paintTriangle,
  }) {
    var compartmentSize = Size(moduleSize.width, moduleSize.height * 0.5);
    _paintModuleCompartment(
      canvas: canvas,
      compartmentSize: compartmentSize,
      topLeft: topLeft,
      paintTriangle: paintTriangle,
    );
    _paintModuleCompartment(
      canvas: canvas,
      compartmentSize: compartmentSize,
      topLeft: Offset(topLeft.dx, topLeft.dy + moduleSize.height * 0.5),
      paintTriangle: paintTriangle,
    );
  }

  void _paintStackedRectangularModules({
    required Canvas canvas,
    required Size groupSize,
    required bool paintTriangle,
  }) {
    const moduleOffsetFactor = 0.05;
    var moduleOffset = groupSize.width * moduleOffsetFactor;
    var moduleSize = groupSize * (1 - moduleOffsetFactor);
    _paintSingleRectangularModule(
      canvas: canvas,
      moduleSize: moduleSize,
      topLeft: Offset(0, moduleOffset),
      paintTriangle: false,
    );
    _paintSingleRectangularModule(
      canvas: canvas,
      moduleSize: moduleSize,
      topLeft: Offset(moduleOffset, 0),
      paintTriangle: paintTriangle,
    );
  }
}
