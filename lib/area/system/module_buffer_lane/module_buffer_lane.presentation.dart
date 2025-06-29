import 'package:meyn_lbh_simulation/area/system/module_buffer_lane/module_buffer_lane.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class ModuleBufferSectionPainter extends ShapePainter {
  ModuleBufferSectionPainter(
    ModuleBufferSection system,
    LiveBirdsHandlingTheme theme,
  ) : super(shape: system.shape, theme: theme);
}
