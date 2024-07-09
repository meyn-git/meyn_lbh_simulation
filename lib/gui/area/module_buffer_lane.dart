import 'package:meyn_lbh_simulation/domain/area/module_buffer_lane.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleBufferSystemPainter extends ShapePainter {
  ModuleBufferSystemPainter(
      ModuleBufferSystem system, LiveBirdsHandlingTheme theme)
      : super(shape: system.shape, theme: theme);
}
