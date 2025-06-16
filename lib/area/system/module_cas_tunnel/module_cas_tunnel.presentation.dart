import 'package:meyn_lbh_simulation/area/system/module_cas_tunnel/module_cas_tunnel.domain.dart';
import 'package:meyn_lbh_simulation/area/system/shape.presentation.dart';
import 'package:meyn_lbh_simulation/theme.presentation.dart';

class ModuleCasTunnelSectionPainter extends ShapePainter {
  ModuleCasTunnelSectionPainter(
    ModuleCasTunnelSection system,
    LiveBirdsHandlingTheme theme,
  ) : super(shape: system.shape, theme: theme);
}
