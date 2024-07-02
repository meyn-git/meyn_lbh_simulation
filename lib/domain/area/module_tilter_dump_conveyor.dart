// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/life_bird_handling_area.dart';
import 'package:meyn_lbh_simulation/domain/area/link.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:meyn_lbh_simulation/gui/area/module_tilter_dump_conveyor.dart';
import 'package:user_command/user_command.dart';

class ModuleTilterDumpConveyor implements PhysicalSystem, TimeProcessor {
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];
  late final shape = ModuleTilterDumpConveyorShape(this);
  final LiveBirdHandlingArea area;

  int birdsOnDumpBelt = 0;
  late final int maxBirdsOnDumpBelt;

  ///Number of birds on dumping belt between module and hanger (a buffer).
  ///The tilter starts tilting when birdsOnDumpBelt<dumpBeltBufferSize
  ///Normally this number is between the number of birds in 1 or 2 modules
  final int minBirdsOnDumpBeltBuffer;
  final double lengthInMeters;

  ModuleTilterDumpConveyor({
    required this.area,
    int? minBirdsOnDumpBeltBuffer,
    int? maxBirdsOnDumpBeltBuffer,
    this.lengthInMeters = 3,
  })  : minBirdsOnDumpBeltBuffer = minBirdsOnDumpBeltBuffer ??
            (area.productDefinition.averageProductsPerModuleGroup * 0.5)
                .round(),
        maxBirdsOnDumpBelt = maxBirdsOnDumpBeltBuffer ??
            (area.productDefinition.averageProductsPerModuleGroup * 1.5)
                .round() {
    //TODO verify minBirdsOnDumpBeltBuffer
    if (lengthInMeters < 3) {
      throw ArgumentError('ModuleTilterDumpBelt must be at least 3 meters');
    }
  }

  bool get canReceiveBirds => birdsOnDumpBelt < minBirdsOnDumpBeltBuffer;

  void receiveBirds(int numberOfBirds) {
    birdsOnDumpBelt += numberOfBirds;
  }

  /// 1=dump belt full with birds
  /// 0=dump belt empty
  double get loadedFraction {
    if (birdsOnDumpBelt > maxBirdsOnDumpBelt) {
      birdsOnDumpBelt = maxBirdsOnDumpBelt;
    }
    return birdsOnDumpBelt / maxBirdsOnDumpBelt;
  }

  late final int seqNr = area.systems.seqNrOf(this);

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('maxBirdsOnDumpBelt', maxBirdsOnDumpBelt)
      .appendProperty('minBirdsOnDumpBeltBuffer', minBirdsOnDumpBeltBuffer)
      .appendProperty('birdsOnDumpBelt', birdsOnDumpBelt);

  @override
  late String name = 'ModuleTilterDumpBelt$seqNr';

  late final birdsIn = BirdsInLink(
      system: this,
      offsetFromCenterWhenFacingNorth: shape.centerToBirdsInLink,
      directionToOtherLink: const CompassDirection.south(),
      canReceiveBirds: () => canReceiveBirds,
      transferBirds: receiveBirds);

  late final birdOut = BirdOutLink(
    system: this,
    offsetFromCenterWhenFacingNorth: shape.centerToBirdOutLink,
    directionToOtherLink: const CompassDirection.north(),
  );

  @override
  late List<Link<PhysicalSystem, Link<PhysicalSystem, dynamic>>> links = [
    birdsIn,
    birdOut,
  ];

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (birdsOnDumpBelt > 0 && birdOut.linkedTo!.canReceiveBird()) {
      birdOut.linkedTo!.transferBird();
      birdsOnDumpBelt--;
    }
  }
}
