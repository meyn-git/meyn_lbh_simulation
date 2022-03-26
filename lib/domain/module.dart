import 'dart:math';

import 'life_bird_handling_area.dart';
import 'state_machine.dart';
import 'title_builder.dart';

/// A [ModuleGroup] can be one or 2 modules that are transported together
/// E.g. a stack of 2 modules, or 2 modules side by side
class ModuleGroup extends TimeProcessor {
  final Module firstModule;
  Module? secondModule;
  final ModuleType type;
  CompassDirection doorDirection;
  StateMachineCell destination;
  ModulePosition position;

  ModuleGroup({
    required this.type,
    required this.firstModule,
    this.secondModule,
    required this.doorDirection,
    required this.destination,
    required this.position,
  });

  ModuleGroup copyWith(
          {ModuleType? type,
          Module? firstModule,
          Module? secondModule,
          CompassDirection? doorDirection,
          StateMachineCell? destination,
          ModulePosition? position}) =>
      ModuleGroup(
          type: type ?? this.type,
          firstModule: firstModule ?? this.firstModule,
          doorDirection: doorDirection ?? this.doorDirection,
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
      .appendProperty('doorDirection', doorDirection)
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

class MeynTurkeyModule extends ModuleType {
  MeynTurkeyModule()
      : super(
            name: '$MeynTurkeyModule',
            shape: ModuleShape.rectangularStacked,
            birdType: BirdType.turkey,
            maxKgPerCompartment: 300,
            numberOfCompartments: 3);
}

class StorkSquare4LayerChickenModule extends ModuleType {
  StorkSquare4LayerChickenModule()
      : super(
            name: '$StorkSquare4LayerChickenModule',
            shape: ModuleShape.squareSideBySide,
            birdType: BirdType.chicken,
            maxKgPerCompartment: 99999,
            //unknown
            numberOfCompartments: 4);
}

class StorkSquare5LayerChickenModule extends ModuleType {
  StorkSquare5LayerChickenModule()
      : super(
            name: '$StorkSquare5LayerChickenModule',
            shape: ModuleShape.squareSideBySide,
            birdType: BirdType.chicken,
            maxKgPerCompartment: 99999,
            //unknown
            numberOfCompartments: 5);
}

class AngliaAutoFlow4LayerChickenModule extends ModuleType {
  AngliaAutoFlow4LayerChickenModule()
      : super(
            name: '$AngliaAutoFlow4LayerChickenModule',
            shape: ModuleShape.rectangularStacked,
            birdType: BirdType.chicken,
            maxKgPerCompartment: 99999,
            //unknown
            numberOfCompartments: 4);
}

class AngliaAutoFlow5LayerChickenModule extends ModuleType {
  AngliaAutoFlow5LayerChickenModule()
      : super(
            name: '$AngliaAutoFlow5LayerChickenModule',
            shape: ModuleShape.rectangularStacked,
            birdType: BirdType.chicken,
            maxKgPerCompartment: 99999,
            //unknown
            numberOfCompartments: 5);
}

class ModuleType {
  final String name;
  final ModuleShape shape;
  final BirdType birdType;
  final int numberOfCompartments;
  final double maxKgPerCompartment;

  ModuleType({
    required this.name,
    required this.shape,
    required this.birdType,
    required this.numberOfCompartments,
    required this.maxKgPerCompartment,
  });
}

enum ModuleShape { squareSideBySide, rectangularStacked }
enum BirdType { chicken, turkey }
