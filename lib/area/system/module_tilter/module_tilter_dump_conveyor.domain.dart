// ignore_for_file: avoid_renaming_method_parameters

import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/module_tilter/module_tilter_dump_conveyor.presentation.dart';
import 'package:user_command/user_command.dart';

class ModuleTilterDumpConveyor implements LinkedSystem, TimeProcessor {
  @override
  late List<Command> commands = [RemoveFromMonitorPanel(this)];
  late final ModuleTilterDumpConveyorShape shape =
      ModuleTilterDumpConveyorShape(this);
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
  }) : minBirdsOnDumpBeltBuffer =
           minBirdsOnDumpBeltBuffer ??
           (area.productDefinition.averageNumberOfBirdsPerModule).round(),
       maxBirdsOnDumpBelt =
           maxBirdsOnDumpBeltBuffer ??
           (area.productDefinition.averageNumberOfBirdsPerModule * 2).round() {
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
  );

  late final birdOut = BirdsOutLink(
    system: this,
    offsetFromCenterWhenFacingNorth: shape.centerToBirdOutLink,
    directionToOtherLink: const CompassDirection.north(),
    availableBirds: () => birdsOnDumpBelt,
    transferBirds: (int numberOfBirdsTransferred) {
      birdsOnDumpBelt -= numberOfBirdsTransferred;
      if (birdsOnDumpBelt < 0) {
        throw Exception('$name: Transferred more birds than possible');
      }
    },
  );

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [
    birdsIn,
    birdOut,
  ];

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;

  @override
  void onUpdateToNextPointInTime(Duration jump) {
    if (!canReceiveBirds) {
      return;
    }
    var birdsToReceive = birdsIn.linkedTo!.availableBirds();
    if (birdsToReceive == 0) {
      return;
    }
    birdsIn.linkedTo!.transferBirds(birdsToReceive);
    birdsOnDumpBelt += birdsToReceive;
  }
}
