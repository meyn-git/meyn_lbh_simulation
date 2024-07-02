import 'package:meyn_lbh_simulation/domain/area/module_stacker.dart';
import 'package:meyn_lbh_simulation/gui/area/module_de_stacker.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleStackerPainter extends ShapePainter {
  ModuleStackerPainter(ModuleStacker stacker, LiveBirdsHandlingTheme theme)
      : super(shape: stacker.shape, theme: theme);
}

class ModuleStackerShape extends ModuleDeStackerShape {}
