import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/module_cas_allocation.dart';

class ModuleCasAllocationWidget extends StatelessWidget {
  final ModuleCasAllocation moduleCasAllocation;

  const ModuleCasAllocationWidget(this.moduleCasAllocation, {super.key});

  @override
  Widget build(BuildContext context) => FittedBox(
      fit: BoxFit.fitWidth, child: Text(moduleCasAllocation.toString()));
}
