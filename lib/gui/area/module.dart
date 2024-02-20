import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/gui/style.dart';

class ModuleGroupWidget extends StatelessWidget {
  final ModuleGroup moduleGroup;

  ModuleGroupWidget(this.moduleGroup) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    var style = LiveBirdsHandlingStyle.of(context);
    return RotationTransition(
      turns: AlwaysStoppedAnimation(moduleGroup.direction.toFraction()),
      child: CustomPaint(painter: ModuleGroupPainter(moduleGroup, style)),
    );
  }
}

class ModuleGroupPainter extends CustomPainter {
  final ModuleGroup moduleGroup;
  static const compartmentSize = 0.30;
  final LiveBirdsHandlingStyle style;
  ModuleGroupPainter(this.moduleGroup, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    if (moduleGroup.moduleFamily.shape == ModuleShape.squareSideBySide) {
      _paintSquareModules(canvas, size);
    } else {
      _paintRectangleModules(canvas, size);
    }
  }

  /// paints a square scalable module compartment with doors pointing north
  void _paintModuleCompartment({
    required Canvas canvas,
    required Size size,
    required double factor,
    required Offset offset,
    required bool paintTriangle,
  }) {
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
    switch (moduleGroup.contents) {
      case BirdContents.noBirds:
        return style.withoutBirdsColor;
      case BirdContents.stunnedBirds:
        return style.withStunnedBirdsColor;
      case BirdContents.birdsBeingStunned:
        return style.withBirdsBeingStunnedColor;
      case BirdContents.awakeBirds:
        return style.withAwakeBirdsColor;
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
    _paintModuleCompartment(
      canvas: canvas,
      size: size,
      factor: compartmentSize,
      offset: Offset(x1, y1),
      paintTriangle:
          moduleGroup.moduleFamily.compartmentType.birdsExitOnOneSide,
    );
  }

  void _paintDoubleSquareModuleSideBySide(Canvas canvas, Size size) {
    var x1 = size.width * 0.15;
    var y1 = (size.width * (1 - compartmentSize)) / 2;
    _paintModuleCompartment(
      canvas: canvas,
      size: size,
      factor: compartmentSize,
      offset: Offset(x1, y1),
      paintTriangle: moduleGroup.moduleFamily.compartmentType ==
          CompartmentType.doorOnOneSide,
    );
    var x2 = size.width * (0.15 + compartmentSize + 0.1);
    var y2 = y1;
    _paintModuleCompartment(
      canvas: canvas,
      size: size,
      factor: compartmentSize,
      offset: Offset(x2, y2),
      paintTriangle:
          moduleGroup.moduleFamily.compartmentType.birdsExitOnOneSide,
    );
  }

  void _paintRectangleModules(Canvas canvas, Size size) {
    if (moduleGroup.numberOfModules == 1) {
      _paintSingleRectangularModule(
        canvas: canvas,
        size: size,
        paintTriangle:
            moduleGroup.moduleFamily.compartmentType.birdsExitOnOneSide,
      );
    } else {
      _paintStackedRectangularModules(
        canvas: canvas,
        size: size,
        paintTriangle:
            moduleGroup.moduleFamily.compartmentType.birdsExitOnOneSide,
      );
    }
  }

  void _paintSingleRectangularModule({
    required Canvas canvas,
    required Size size,
    Offset offset = Offset.zero,
    required bool paintTriangle,
  }) {
    var x1 = size.width * 0.2 + offset.dx;
    var y1 = (size.width * (1 - compartmentSize)) / 2 + offset.dy;
    _paintModuleCompartment(
      canvas: canvas,
      size: size,
      factor: compartmentSize,
      offset: Offset(x1, y1),
      paintTriangle: paintTriangle,
    );
    var x2 = size.width * (0.2 + compartmentSize) + offset.dx;
    var y2 = y1;
    _paintModuleCompartment(
      canvas: canvas,
      size: size,
      factor: compartmentSize,
      offset: Offset(x2, y2),
      paintTriangle: paintTriangle,
    );
  }

  void _paintStackedRectangularModules({
    required Canvas canvas,
    required Size size,
    required bool paintTriangle,
  }) {
    var moduleOffset = 0.015;
    var x1 = -size.width * moduleOffset;
    var y1 = -size.width * moduleOffset;
    _paintSingleRectangularModule(
      canvas: canvas,
      size: size,
      offset: Offset(x1, y1),
      paintTriangle: false,
    );
    var x2 = size.width * moduleOffset;
    var y2 = size.width * moduleOffset;
    _paintSingleRectangularModule(
      canvas: canvas,
      size: size,
      offset: Offset(x2, y2),
      paintTriangle: paintTriangle,
    );
  }
}
