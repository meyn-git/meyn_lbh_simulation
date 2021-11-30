import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/module_cas_start.dart';

class ModuleCasStartWidget extends StatelessWidget {
  final ModuleCasStart moduleCasStart;


  ModuleCasStartWidget(this.moduleCasStart);

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.fitWidth,
        child: Text(moduleCasStart.toString()));


}