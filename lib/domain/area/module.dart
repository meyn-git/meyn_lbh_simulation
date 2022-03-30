import 'dart:math';

import 'package:meyn_lbh_simulation/domain/util/title_builder.dart';

import 'life_bird_handling_area.dart';
import 'state_machine.dart';

/// A [ModuleGroup] can be one or 2 modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side
class ModuleGroup extends TimeProcessor {
  final Module firstModule;
  Module? secondModule;
  final ModuleType type;

  /// The direction (rotation) of the module group. This is the direction
  /// that the doors would be pointing towards (if it has any)
  CompassDirection direction;
  StateMachineCell destination;
  ModulePosition position;

  ModuleGroup({
    required this.type,
    required this.firstModule,
    this.secondModule,
    required this.direction,
    required this.destination,
    required this.position,
  });

  ModuleGroup copyWith(
          {ModuleType? type,
          Module? firstModule,
          Module? secondModule,
          CompassDirection? direction,
          StateMachineCell? destination,
          ModulePosition? position}) =>
      ModuleGroup(
          type: type ?? this.type,
          firstModule: firstModule ?? this.firstModule,
          direction: direction ?? this.direction,
          destination: destination ?? this.destination,
          position: position ?? this.position);

  int get numberOfModules => 1 + ((secondModule == null) ? 0 : 1);

  int get numberOfBirds =>
      firstModule.nrOfBirds +
      ((secondModule == null) ? 0 : secondModule!.nrOfBirds);

  @override
  onUpdateToNextPointInTime(Duration jump) {
    position.processNextTimeFrame(this, jump);
    if (sinceLoadedOnSystem != null) {
      sinceLoadedOnSystem = sinceLoadedOnSystem! + jump;
    }
    if (sinceStartStun != null) {
      sinceStartStun = sinceStartStun! + jump;
    }
    if (sinceBirdsUnloaded != null) {
      sinceBirdsUnloaded = sinceBirdsUnloaded! + jump;
    }
  }

  @override
  String toString() => TitleBuilder('ModuleGroup')
      .appendProperty('doorDirection', direction)
      .appendProperty('destination', destination.name)
      //.appendProperty('position', position) removed because its obvious
      .appendProperty('firstModule', firstModule)
      .appendProperty('secondModule', secondModule)
      .toString();

  Duration? get sinceLoadedOnSystem => firstModule.sinceLoadedOnSystem;

  set sinceLoadedOnSystem(Duration? duration) {
    firstModule.sinceLoadedOnSystem = duration;
    if (secondModule != null) {
      secondModule!.sinceLoadedOnSystem = duration;
    }
  }

  void loadedOnToSystem() {
    sinceLoadedOnSystem = Duration.zero;
  }

  Duration? get sinceStartStun => firstModule.sinceStartStun;

  set sinceStartStun(Duration? duration) {
    firstModule.sinceStartStun = duration;
    if (secondModule != null) {
      secondModule!.sinceStartStun = duration;
    }
  }

  void startStunning() {
    sinceStartStun = Duration.zero;
  }

  Duration? get sinceEndStun => firstModule.sinceEndStun;

  set sinceEndStun(Duration? duration) {
    firstModule.sinceEndStun = duration;
    if (secondModule != null) {
      secondModule!.sinceEndStun = duration;
    }
  }

  void endStunning() {
    sinceEndStun = Duration.zero;
  }

  Duration? get sinceBirdsUnloaded => firstModule.sinceBirdsUnloaded;

  set sinceBirdsUnloaded(Duration? duration) {
    firstModule.sinceBirdsUnloaded = duration;
    if (secondModule != null) {
      secondModule!.sinceBirdsUnloaded = duration;
    }
  }

  void unloadBirds() {
    sinceBirdsUnloaded = Duration.zero;
    firstModule.nrOfBirds = 0;
    if (secondModule != null) {
      secondModule!.nrOfBirds = 0;
    }
  }

  ModuleContents get contents {
    if (sinceBirdsUnloaded != null) {
      return ModuleContents.noBirds;
    } else if (sinceEndStun != null) {
      return ModuleContents.stunnedBirds;
    } else if (sinceStartStun != null) {
      return ModuleContents.birdsBeingStunned;
    } else {
      return ModuleContents.awakeBirds;
    }
  }

  /// Splits the [ModuleGroup] int 2 different [ModuleGroup]s:
  /// - The [ModuleGroup.secondModule] is removed from the existing [ModuleGroup]
  /// - returns a new copied [ModuleGroup] where [ModuleGroup.firstModule]=[ModuleGroup.secondModule]
  ModuleGroup? split() {
    if (secondModule == null) {
      throw Exception(
          'You can not split a $ModuleGroup that contains only one module');
    }
    var newModuleGroup =
        copyWith(firstModule: secondModule, secondModule: null);
    secondModule = null;
    return newModuleGroup;
  }
}

enum ModuleContents { awakeBirds, birdsBeingStunned, stunnedBirds, noBirds }

/// A module location is either at a given position or traveling between 2 positions
class ModulePosition {
  StateMachineCell source;
  StateMachineCell destination;
  late Duration duration;
  late Duration remainingDuration;

  ModulePosition.forCel(StateMachineCell cell)
      : source = cell,
        destination = cell,
        duration = Duration.zero,
        remainingDuration = Duration.zero;

  ModulePosition.betweenCells(
      {required this.source, required this.destination, Duration? duration}) {
    this.duration = duration ?? findLongestDuration(source, destination);
    remainingDuration = this.duration;
  }

  /// 0  =  0% of transportation is completed
  /// 0.5= 50% of transportation is completed
  /// 1  =100% of transportation is completed
  double get percentageCompleted => duration == Duration.zero
      ? 1
      : 1 - remainingDuration.inMilliseconds / duration.inMilliseconds;

  processNextTimeFrame(ModuleGroup moduleGroup, Duration jump) {
    if (remainingDuration > Duration.zero) {
      remainingDuration = remainingDuration - jump;
      if (remainingDuration <= Duration.zero) {
        source = destination;
      }
    } else {
      remainingDuration = Duration.zero;
    }
  }

  equals(StateMachineCell cell) =>
      source.position == cell.position &&
      destination.position == cell.position &&
      remainingDuration == Duration.zero;

  static Duration findLongestDuration(
    StateMachineCell source,
    StateMachineCell destination,
  ) {
    Duration outFeedDuration = source.outFeedDuration;
    Duration inFeedDuration = destination.inFeedDuration;
    return Duration(
        milliseconds:
            max(outFeedDuration.inMilliseconds, inFeedDuration.inMilliseconds));
  }

  bool get isMoving {
    return source != destination;
  }

  @override
  String toString() {
    if (isMoving) {
      return TitleBuilder('ModulePosition')
          .appendProperty('source', source.name)
          .appendProperty('destination', destination.name)
          .appendProperty('remainingDuration', remainingDuration)
          .toString();
    } else {
      return TitleBuilder('ModulePosition')
          .appendProperty('at', source.name)
          .toString();
    }
  }

  transportingFrom(StateMachineCell stateMachineCell) =>
      source == stateMachineCell && destination != stateMachineCell;
}

class Module {
  final int sequenceNumber;
  int nrOfBirds;
  Duration? sinceLoadedOnSystem;
  Duration? sinceStartStun;
  Duration? sinceEndStun;
  Duration? sinceBirdsUnloaded;

  Module({
    required this.sequenceNumber,
    required this.nrOfBirds,
  });

  @override
  String toString() => TitleBuilder('Module')
      .appendProperty('sequenceNumber', sequenceNumber)
      .appendProperty('nrOfBirds', nrOfBirds)
      .appendProperty('sinceLoadedOnSystem', sinceLoadedOnSystem)
      .appendProperty('sinceStartStun', sinceStartStun)
      .appendProperty('sinceEndStun', sinceEndStun)
      .appendProperty('sinceBirdsUnloaded', sinceBirdsUnloaded)
      .toString();
}

class MeynEvoContainer extends ModuleType {
  MeynEvoContainer()
      : super(
          shape: ModuleShape.rectangularStacked,
          birdType: BirdType.chicken,
          compartmentType: CompartmentType.door,

          //following durations are based on measurements at: 7113-Tyson Union city
          stackerInFeedDuration: const Duration(seconds: 14),
          conveyorTransportDuration: const Duration(seconds: 12),
          casTransportDuration: const Duration(seconds: 14),
          turnTableDegreesPerSecond: (90 / 6).round(),
        );
}

class MeynOmniTurkeyModule extends ModuleType {
  static const maxKgPerCompartment = 300;
  static const numberOfCompartments = 3;

  MeynOmniTurkeyModule()
      : super(
            shape: ModuleShape.rectangularStacked,
            birdType: BirdType.turkey,
            compartmentType: CompartmentType.door,
            //following durations are based on measurements at: 8052-Indrol Grodzisk
            conveyorTransportDuration: const Duration(seconds: 19),
            stackerInFeedDuration: const Duration(seconds: 19),
            casTransportDuration: const Duration(seconds: 19),
            turnTableDegreesPerSecond: (90 / 11.25).round());
}

class AngliaAutoFlowModule extends ModuleType {
  AngliaAutoFlowModule()
      : super(
          shape: ModuleShape.rectangularStacked,
          birdType: BirdType.chicken,
          compartmentType: CompartmentType.drawer,

          //following durations are based on measurements at: 7113-Tyson Union city
          stackerInFeedDuration: const Duration(seconds: 14),
          conveyorTransportDuration: const Duration(seconds: 12),
          casTransportDuration: const Duration(seconds: 14),
          turnTableDegreesPerSecond: (90 / 6).round(),
        );
}

class StorkSquareModule extends ModuleType {
  StorkSquareModule()
      : super(
          shape: ModuleShape.squareSideBySide,
          birdType: BirdType.chicken,
          compartmentType: CompartmentType.door,

          //following durations are based on measurements at: 7696-Dabe-Germanyk
          conveyorTransportDuration: const Duration(milliseconds: 13400),
          stackerInFeedDuration: const Duration(milliseconds: 18700),
          casTransportDuration: const Duration(milliseconds: 18700),
          turnTableDegreesPerSecond: (90 / 9).round(),
        );
}

// class StorkSquare4LayerChickenModule extends ModuleCapacity {
//   StorkSquare4LayerChickenModule()
//       : super(
//           name: '$StorkSquare4LayerChickenModule',
//           shape: ModuleShape.squareSideBySide,
//           birdType: BirdType.chicken,
//           maxKgPerCompartment: 99999,
//           //unknown
//           numberOfCompartments: 4,
//           compartmentType: CompartmentType.door,
//         );
// }
//
// class StorkSquare5LayerChickenModule extends ModuleCapacity {
//   StorkSquare5LayerChickenModule()
//       : super(
//           name: '$StorkSquare5LayerChickenModule',
//           shape: ModuleShape.squareSideBySide,
//           birdType: BirdType.chicken,
//           maxKgPerCompartment: 99999,
//           //unknown
//           numberOfCompartments: 5,
//           compartmentType: CompartmentType.door,
//         );
// }

// class AngliaAutoFlow4LayerChickenModule extends AngliaAutoFlowModuleType
//     implements ModuleCapacity {
//   @override
//   BirdType get birdType => BirdType.chicken;
//
//   @override
//   double get maxKgPerCompartment => 99999; // unknown
//
//   @override
//   int get numberOfCompartments => 4;
// }
//
// class AngliaAutoFlow5LayerChickenModule extends ModuleCapacity {
//   AngliaAutoFlow5LayerChickenModule()
//       : super(
//           name: '$AngliaAutoFlow5LayerChickenModule',
//           shape: ModuleShape.rectangularStacked,
//           birdType: BirdType.chicken,
//           maxKgPerCompartment: 99999,
//           //unknown
//           numberOfCompartments: 5,
//           compartmentType: CompartmentType.drawer,
//         );
// }

class ModuleType {
  final ModuleShape shape;
  final CompartmentType compartmentType;
  final BirdType birdType;
  final Duration conveyorTransportDuration;

  /// [stackerInFeedDuration] is also used for [ModuleDeStacker]
  final Duration stackerInFeedDuration;
  final Duration casTransportDuration;
  final int turnTableDegreesPerSecond;

  ModuleType({
    required this.shape,
    required this.compartmentType,
    required this.birdType,
    required this.conveyorTransportDuration, //= const Duration(seconds: 12),
    required this.stackerInFeedDuration, //= const Duration(seconds: 14),
    required this.casTransportDuration, //= const Duration(seconds: 14),
    required this.turnTableDegreesPerSecond, //= 15,
  });

  String get name => '$shape-$compartmentType-$birdType';
}

class ModuleCapacity {
  static const unknown = -1.0;

  final int numberOfCompartments;
  final int numberOfBirdsPerCompartment;
  final double maxKgPerCompartment;

  ModuleCapacity({
    required this.numberOfCompartments,
    required this.numberOfBirdsPerCompartment,
    this.maxKgPerCompartment = unknown,
  });

  int get numberOfBirds => numberOfCompartments * numberOfBirdsPerCompartment;

  @override
  String toString() {
    return "ModuleCapacity{numberOfCompartments: $numberOfCompartments, numberOfBirdsPerCompartment: $numberOfBirdsPerCompartment, ${maxKgPerCompartment == unknown ? '' : 'maxKgPerCompartment: $maxKgPerCompartment'}' }";
  }
}

class ModuleGroupCapacity {
  /// how often this Module Combination is loaded on to the system
  /// 1=100% of the time, 1/4=25% of the time
  final double occurrence;
  final ModuleCapacity firstModule;
  final ModuleCapacity? secondModule;

  ModuleGroupCapacity({
    this.occurrence = 1,
    required this.firstModule,
    this.secondModule,
  });

  int get numberOfBirds =>
      firstModule.numberOfBirds +
      (secondModule == null ? 0 : secondModule!.numberOfBirds);
}

enum ModuleShape { squareSideBySide, rectangularStacked }

enum CompartmentType { door, drawer }

enum BirdType { chicken, turkey }
