import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_start.dart';

class ModuleCasStartWidget extends StatelessWidget {
  final ModuleCasStart moduleCasStart;

  const ModuleCasStartWidget(this.moduleCasStart, {super.key});

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.fitWidth, child: Text(moduleCasStart.toString()));
}
