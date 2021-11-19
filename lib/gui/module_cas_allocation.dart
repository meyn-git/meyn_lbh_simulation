import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/module_cas_allocation.dart';

class ModuleCasAllocationWidget extends StatelessWidget {
  final ModuleCasAllocation moduleCasAllocation;


  ModuleCasAllocationWidget(this.moduleCasAllocation);

  @override
  Widget build(BuildContext context) {
    return Text(moduleCasAllocation.toString());
  }

}