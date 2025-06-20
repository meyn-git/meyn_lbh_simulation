import 'dart:ui';

import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter_dump_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class ModuleTilterDumpConveyorPainter extends ShapePainter {
  ModuleTilterDumpConveyorPainter(
    ModuleTilterDumpConveyor dumpConveyor,
    LiveBirdsHandlingTheme theme,
  ) : super(shape: dumpConveyor.shape, theme: theme);
}

class ModuleTilterDumpConveyorShape extends Shape {
  final ModuleTilterDumpConveyor dumpConveyor;
  ModuleTilterDumpConveyorShape(this.dumpConveyor);

  /// repaint nr of birds on conveyor
  @override
  bool get shouldRepaint => true;

  @override
  void paint(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  ) {
    _paintReceivingConveyor(canvas, theme, offset, sizePerMeter);
    _paintBirdsOnReceivingConveyor(canvas, theme, offset, sizePerMeter);
  }

  void _paintReceivingConveyor(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  ) {
    var conveyorPaint = Paint();
    conveyorPaint.color = theme.machineColor;
    conveyorPaint.style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(
        offset.xInMeters * sizePerMeter,
        offset.yInMeters * sizePerMeter,
        xInMeters * sizePerMeter,
        yInMeters * sizePerMeter,
      ),
      conveyorPaint,
    );
  }

  void _paintBirdsOnReceivingConveyor(
    Canvas canvas,
    LiveBirdsHandlingTheme theme,
    OffsetInMeters offset,
    double sizePerMeter,
  ) {
    var birdPaint = Paint();
    birdPaint.color = theme.machineColor.withAlpha((255.0 * 0.5).round());
    birdPaint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(
        offset.xInMeters * sizePerMeter,
        offset.yInMeters * sizePerMeter,
        xInMeters * sizePerMeter,
        yInMeters * sizePerMeter * dumpConveyor.loadedFraction,
      ),
      birdPaint,
    );
  }

  @override
  double get xInMeters => 2.6;

  @override
  double get yInMeters => dumpConveyor.lengthInMeters;

  late final OffsetInMeters centerToBirdOutLink = OffsetInMeters(
    xInMeters: 0,
    yInMeters: yInMeters * -0.5,
  );

  late final OffsetInMeters centerToBirdsInLink = OffsetInMeters(
    xInMeters: 0,
    yInMeters: yInMeters * 0.5,
  );
}
