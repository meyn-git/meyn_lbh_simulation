import 'package:meyn_lbh_simulation/area/system/module_stacker/module_stacker.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_de_stacker/module_de_stacker.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class ModuleStackerPainter extends ShapePainter {
  ModuleStackerPainter(ModuleStacker stacker, LiveBirdsHandlingTheme theme)
    : super(shape: stacker.shape, theme: theme);
}

class ModuleStackerShape extends ModuleDeStackerShape {}
