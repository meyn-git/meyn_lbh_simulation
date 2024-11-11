import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/module/module.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/system/vehicle/vehicle.presentation.dart';

abstract class Vehicle extends PhysicalSystem {
  AreaPosition get position;
  CompassDirection get direction;
  VehicleShape get shape;
}
