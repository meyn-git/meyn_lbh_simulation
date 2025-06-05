import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas.domain.dart';
import 'package:meyn_lbh_simulation/area/system/module_cas/module_cas_start.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';

abstract class ModuleBirdUnloader extends LinkedSystem {
  /// average number of Module CAS loads that should be waiting before the unloader as a buffer
  ///
  /// Number of modules [ModuleCasStart] will try to keep waiting before the [ModuleBirdUnloader]
  /// = [waitingCasModuleLoadSetPoint] * Number of modules per CAS cycle
  ///
  /// Some examples:
  ///
  ///  Value of                       | Number of modules per | Number of modules [ModuleCasStart]
  ///  [waitingCasModuleLoadSetPoint] | [ModuleCas] cycle     | will try to keep waiting before the [ModuleBirdUnloader]
  ///  -------------------------------|-----------------------|---------------------------------------------------------
  ///              0.5                |          1            |     0.5
  ///              0.5                |          2            |     1
  ///              0.5                |          4            |     2
  ///               1                 |          1            |     1
  ///               1                 |          2            |     2
  ///               1                 |          4            |     4
  double get waitingCasModuleLoadSetPoint;
}
