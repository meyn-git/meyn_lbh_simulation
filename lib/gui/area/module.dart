import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleGroupWidget extends StatelessWidget {
  final ModuleGroup moduleGroup;

  ModuleGroupWidget(this.moduleGroup) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).liveBirdsHandling;
    return RotationTransition(
        turns: AlwaysStoppedAnimation(moduleGroup.direction.toFraction()),
        child: CustomPaint(
          painter: ModuleGroupPainter(moduleGroup, theme),
        ));
  }
}

class ModuleGroupPainter extends ShapePainter {
  ModuleGroupPainter(ModuleGroup moduleGroup, LiveBirdsHandlingTheme theme)
      : super(shape: moduleGroup.shape, theme: theme);
}

class ModuleGroupShape extends CompoundShape {
  static const double offsetPerLevel = 0.1;
  static const double offsetBetweenStacks = 0.2;
  ModuleGroupShape(ModuleGroup moduleGroup) {
    var positions = moduleGroup.keys;
    var topLevel = positions.map((p) => p.level).reduce(max);
    for (var position in positions) {
      bool showOutDirection = moduleGroup.compartment.birdsExitOnOneSide &&
          position.level == topLevel;
      var moduleShape = ModuleShape(moduleGroup, showOutDirection);
      var topLeft = OffsetInMeters.zero
          .addX(position.level * offsetPerLevel)
          .addY(position.level * offsetPerLevel +
              position.stack * (moduleShape.yInMeters + offsetBetweenStacks));
      add(topLeft, moduleShape);
    }
  }
}

class ModuleShape extends CompoundShape {
  ModuleShape(ModuleGroup moduleGroup, bool showOutDirection) {
    var topLeft = OffsetInMeters.zero;
    for (int i = 0; i < moduleGroup.compartmentsPerLevel; i++) {
      var compartment = ModuleCompartmentShape(moduleGroup, showOutDirection);
      add(topLeft, compartment);
      topLeft = topLeft.addY(moduleGroup.compartmentSize.yInMeters);
    }
  }
}

class ModuleCompartmentShape extends Shape {
  @override
  late final double xInMeters;
  @override
  late final double yInMeters;
  final ModuleGroup moduleGroup;
  final bool showOutDirection;
  ModuleCompartmentShape(this.moduleGroup, this.showOutDirection)
      : xInMeters = moduleGroup.compartmentSize.xInMeters,
        yInMeters = moduleGroup.compartmentSize.yInMeters;

  @override
  void paint(Canvas canvas, LiveBirdsHandlingTheme theme, OffsetInMeters offset,
      double sizePerMeter) {
    var paint = Paint();
    paint.color = color(theme);
    paint.style = PaintingStyle.stroke;
    var left = offset.xInMeters * sizePerMeter;
    var top = offset.yInMeters * sizePerMeter;
    var width = xInMeters * sizePerMeter;
    var height = yInMeters * sizePerMeter;
    canvas.drawRect(Rect.fromLTWH(left, top, width, height), paint);
    if (showOutDirection) {
      var topRight = Offset(left + width, top);
      var centerLeft = Offset(left, top + height * 0.5);
      var bottomRight = Offset(left + width, top + height);
      canvas.drawLine(topRight, centerLeft, paint);
      canvas.drawLine(centerLeft, bottomRight, paint);
    }
  }

  Color color(theme) {
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
}

// class ModuleGroupPainter extends CustomPainter {
//   final ModuleGroup moduleGroup;
//   final LiveBirdsHandlingTheme theme;

//   /// 5% of module group length
//   static const gabBetweenModulesFraction = 0.05;
//   ModuleGroupPainter(this.moduleGroup, this.theme);

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (moduleGroup.family.shape == ModuleShape.squareSideBySide) {
//       _paintCompartments(canvas, size, moduleGroup);
//     } else {
//       _paintRectangleModules(canvas, size);
//     }
//   }

//   /// paints a square scalable module compartment with doors facing west
//   void _paintModuleCompartment({
//     required Canvas canvas,
//     required Size compartmentSize,
//     required Offset topLeft,
//     required bool paintTriangle,
//   }) {
//     var paint = Paint();
//     paint.color = _colorFor(moduleGroup);
//     paint.style = PaintingStyle.stroke;

//     var path = Path();
//     //rectangle starting bottom left
//     var left = topLeft.dx;
//     var right = topLeft.dx + compartmentSize.width;
//     var top = topLeft.dy;
//     var triangleMiddle = topLeft.dy + compartmentSize.height * 0.5;
//     var bottom = topLeft.dy + compartmentSize.height;

//     // paint square
//     path.moveTo(right, bottom);
//     path.lineTo(left, bottom);
//     path.lineTo(left, top);
//     path.lineTo(right, top);
//     path.lineTo(right, bottom);

//     if (paintTriangle) {
//       //paint triangle pointing west
//       path.lineTo(left, triangleMiddle);
//       path.lineTo(right, top);
//     }

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

//   Color _colorFor(ModuleGroup moduleGroup) {
//     switch (moduleGroup.contents) {
//       case BirdContents.noBirds:
//         return theme.withoutBirdsColor;
//       case BirdContents.stunnedBirds:
//         return theme.withStunnedBirdsColor;
//       case BirdContents.birdsBeingStunned:
//         return theme.withBirdsBeingStunnedColor;
//       case BirdContents.awakeBirds:
//         return theme.withAwakeBirdsColor;
//     }
//   }

//   void _paintCompartments(Canvas canvas, Size size) {
//     if (moduleGroup.numberOfModules == 1) {
//       _paintSingleSquareModule(canvas, size);
//     } else {
//       _paintDoubleSquareModuleSideBySide(canvas, size);
//     }
//   }

//   void _paintSingleSquareModule(Canvas canvas, Size groupSize) {
//     var gabBetween = groupSize.height * gabBetweenModulesFraction;
//     var moduleSize = Size(groupSize.width, (groupSize.height - gabBetween) / 2);
//     _paintModuleCompartment(
//       canvas: canvas,
//       compartmentSize: moduleSize,
//       topLeft: Offset(0, (groupSize.height - moduleSize.height) / 2),
//       paintTriangle: moduleGroup.family.compartmentType.birdsExitOnOneSide,
//     );
//   }

//   // paints 2 modules side by side (note not 4 modules!)
//   void _paintDoubleSquareModuleSideBySide(Canvas canvas, Size groupSize) {
//     var gabBetween = groupSize.height * gabBetweenModulesFraction;
//     var compartmentSize =
//         Size(groupSize.width, (groupSize.height - gabBetween) / 2);
//     _paintModuleCompartment(
//       canvas: canvas,
//       compartmentSize: compartmentSize,
//       topLeft: Offset.zero,
//       paintTriangle:
//           moduleGroup.family.compartmentType == CompartmentType.doorOnOneSide,
//     );
//     _paintModuleCompartment(
//       canvas: canvas,
//       compartmentSize: compartmentSize,
//       topLeft: Offset(0, compartmentSize.height + gabBetween),
//       paintTriangle: moduleGroup.family.compartmentType.birdsExitOnOneSide,
//     );
//   }

//   void _paintRectangleModules(Canvas canvas, Size size) {
//     if (moduleGroup.numberOfModules == 1) {
//       _paintSingleRectangularModule(
//         canvas: canvas,
//         moduleSize: size,
//         paintTriangle: moduleGroup.family.compartmentType.birdsExitOnOneSide,
//       );
//     } else {
//       _paintStackedRectangularModules(
//         canvas: canvas,
//         groupSize: size,
//         paintTriangle: moduleGroup.family.compartmentType.birdsExitOnOneSide,
//       );
//     }
//   }

//   void _paintSingleRectangularModule({
//     required Canvas canvas,
//     required Size moduleSize,
//     Offset topLeft = Offset.zero,
//     required bool paintTriangle,
//   }) {
//     var compartmentSize = Size(moduleSize.width, moduleSize.height * 0.5);
//     _paintModuleCompartment(
//       canvas: canvas,
//       compartmentSize: compartmentSize,
//       topLeft: topLeft,
//       paintTriangle: paintTriangle,
//     );
//     _paintModuleCompartment(
//       canvas: canvas,
//       compartmentSize: compartmentSize,
//       topLeft: Offset(topLeft.dx, topLeft.dy + moduleSize.height * 0.5),
//       paintTriangle: paintTriangle,
//     );
//   }

//   void _paintStackedRectangularModules({
//     required Canvas canvas,
//     required Size groupSize,
//     required bool paintTriangle,
//   }) {
//     const moduleOffsetFactor = 0.05;
//     var moduleOffset = groupSize.width * moduleOffsetFactor;
//     var moduleSize = groupSize * (1 - moduleOffsetFactor);
//     _paintSingleRectangularModule(
//       canvas: canvas,
//       moduleSize: moduleSize,
//       topLeft: Offset(0, moduleOffset),
//       paintTriangle: false,
//     );
//     _paintSingleRectangularModule(
//       canvas: canvas,
//       moduleSize: moduleSize,
//       topLeft: Offset(moduleOffset, 0),
//       paintTriangle: paintTriangle,
//     );
//   }
// }
