// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/system/module_conveyor/module_conveyor.domain.dart';
import 'package:meyn_lbh_simulation/area/system/speed_profile.domain.dart';
import 'package:meyn_lbh_simulation/area/system/state_machine.domain.dart';

class ModuleWeigingConveyor extends ModuleConveyor {
  final Duration stabelizeAndWeighDuration;

  static const double defaultLengthInMeters = 2.75;

  ModuleWeigingConveyor({
    required super.area,
    SpeedProfile? speedProfile,
    super.lengthInMeters = defaultLengthInMeters,
    this.stabelizeAndWeighDuration = const Duration(seconds: 3),
  }) : super(
          initialState: CheckIfEmpty(),
        );

  @override
  // ignore: overridden_fields
  late String name = 'ModuleWeighingConveyor$seqNr';
}

class CheckIfEmpty extends DurationState<ModuleWeigingConveyor> {
  CheckIfEmpty()
      : super(
            durationFunction: (moduleConveyor) => moduleConveyor.speedProfile
                .durationOfDistance(moduleConveyor.lengthInMeters * 1.5),
            nextStateFunction: (moduleConveyor) =>
                SimultaneousFeedOutFeedInModuleGroup(
                    modulesIn: moduleConveyor.modulesIn,
                    modulesOut: moduleConveyor.modulesOut,
                    stateWhenCompleted: StabillizeAndWeigh()));

  @override
  String get name => 'CheckIfEmpty';
}

class StabillizeAndWeigh extends DurationState<ModuleWeigingConveyor> {
  StabillizeAndWeigh()
      : super(
            durationFunction: (moduleConveyor) =>
                moduleConveyor.stabelizeAndWeighDuration,
            nextStateFunction: (moduleConveyor) =>
                SimultaneousFeedOutFeedInModuleGroup(
                    modulesIn: moduleConveyor.modulesIn,
                    modulesOut: moduleConveyor.modulesOut,
                    stateWhenCompleted: StabillizeAndWeigh()));

  @override
  String get name => 'StabillizeAndWeigh';
}
