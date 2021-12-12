import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/module.dart';

class ModuleGroupWidget extends StatelessWidget {
  final ModuleGroup moduleGroup;

  ModuleGroupWidget(this.moduleGroup): super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: AlwaysStoppedAnimation(moduleGroup.doorDirection.degrees / 360),
      child: CustomPaint(painter: ModuleGroupPainter(moduleGroup)),
    );
  }
}

class ModuleGroupPainter extends CustomPainter {
  final ModuleGroup moduleGroup;
  static final compartmentSize = 0.30;

  ModuleGroupPainter(this.moduleGroup);

  @override
  void paint(Canvas canvas, Size size) {
    if (moduleGroup.type.shape == ModuleShape.squareSideBySide) {
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
    switch (moduleGroup.contents) {
      case ModuleContents.noBirds:
        return Colors.black;
      case ModuleContents.stunnedBirds:
        return Colors.red;
      case ModuleContents.birdsBeingStunned:
        return Colors.orange;
      case ModuleContents.awakeBirds:
        return Colors.green; // awake birds
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
    var moduleOffset=0.015;
    var x1 = -size.width * moduleOffset;
    var y1 = -size.width * moduleOffset;
    _paintSingleRectangularModule(
      canvas,
      size,
      offset: Offset(x1, y1),
      paintTriangle: false,
    );
    var x2 = size.width * moduleOffset;
    var y2 = size.width * moduleOffset;
    _paintSingleRectangularModule(
      canvas,
      size,
      offset: Offset(x2, y2),
    );
  }
}
