import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/area/direction.domain.dart';
import 'package:meyn_lbh_simulation/area/area.domain.dart';
import 'package:meyn_lbh_simulation/area/link.domain.dart';
import 'package:meyn_lbh_simulation/area/object_details.domain.dart';
import 'package:meyn_lbh_simulation/area/system/system.domain.dart';
import 'package:meyn_lbh_simulation/area/command.presentation.dart';
import 'package:meyn_lbh_simulation/area/system/shackle_conveyor/shackle_conveyor.presentation.dart';
import 'package:user_command/user_command.dart';

class ShackleConveyor implements LinkedSystem, TimeProcessor {
  final LiveBirdHandlingArea area;
  @override
  late String name = "ShackleConveyor$seqNr";
  @override
  late List<Command> commands = [
    RemoveFromMonitorPanel(this),
    _startCommand,
    _stopCommand,
  ];
  late final seqNr = area.systems.seqNrOf(this);

  final int shacklesPerHour;
  final int shacklePitchInInches;
  Duration elapsedTime = Duration.zero;
  static final int hourInMicroSeconds = const Duration(hours: 1).inMicroseconds;

  final Direction direction;

  Command get _startCommand => Command.dynamic(
    name: () => 'Start line',
    visible: () => !running,
    icon: () => Icons.play_arrow,
    action: () {
      running = true;
    },
  );

  Command get _stopCommand => Command.dynamic(
    name: () => 'Stop line',
    visible: () => running,
    icon: () => Icons.stop,
    action: () {
      running = false;
    },
  );

  Duration timePerBird;

  bool _running = false;

  ShackleConveyor({required this.area, required this.direction})
    : shacklesPerHour = area.productDefinition.lineSpeedInShacklesPerHour,
      shacklePitchInInches = area.productDefinition.lineShacklePitchInInches,
      timePerBird = Duration(
        microseconds:
            (hourInMicroSeconds /
                    area.productDefinition.lineSpeedInShacklesPerHour)
                .round(),
      ) {
    running = true;
  }

  bool get running => _running;

  set running(bool running) {
    _running = running;
    if (running) {
      startLine();
    }
  }

  late final ShackleConveyorShape shape = ShackleConveyorShape(this);

  late final birdsIn = BirdsInLink(
    system: this,
    offsetFromCenterWhenFacingNorth: shape.centerToBirdInLink,
    directionToOtherLink: direction == Direction.counterClockWise
        ? const CompassDirection.west()
        : const CompassDirection.east(),
  );

  @override
  late List<Link<LinkedSystem, Link<LinkedSystem, dynamic>>> links = [birdsIn];

  @override
  onUpdateToNextPointInTime(Duration jump) {
    if (running) {
      addRunningTime(jump);
      elapsedTime += jump;

      while (elapsedTime > timePerBird) {
        var hasBirdToHang = birdsIn.linkedTo!.availableBirds() > 0;
        nextShackle(hasBird: hasBirdToHang);
        if (hasBirdToHang) {
          birdsIn.linkedTo!.transferBirds(1);
        }
        elapsedTime = elapsedTime - timePerBird; //remainder
      }
    }
  }

  @override
  ObjectDetails get objectDetails => ObjectDetails(name)
      .appendProperty('shacklesPerHour', shacklesPerHour)
      .appendProperty('runningTime', _runningTime)
      .appendProperty('hangedBirdsSinceStart', hangedBirdsSinceStart)
      .appendProperty(
        'hangedBirdsPerHourSinceStart',
        hangedBirdsPerHourSinceStart,
      )
      .appendProperty('emptyShacklesSinceStart', emptyShacklesSinceStart)
      .appendProperty('lineEfficiency', lineEfficiency);

  static const int maxSize = 100;
  final List<bool> _shackles = []; // true if shackle has a bird, false if not
  int hangedBirdsSinceStart = 0;
  int emptyShacklesSinceStart = 0;
  bool _waitForFirstBird = true;
  Duration _runningTime = Duration.zero;

  void nextShackle({required bool hasBird}) {
    _shackles.insert(0, hasBird);
    if (_shackles.length > maxSize) {
      _shackles.removeAt(_shackles.length - 1);
    }
    if (hasBird) {
      hangedBirdsSinceStart++;
      _waitForFirstBird = false;
    } else if (!_waitForFirstBird) {
      emptyShacklesSinceStart++;
    }
  }

  int get numberOfShackles => _shackles.length;

  int get numberOfBirds => _shackles.where((shackle) => shackle == true).length;

  double get lineEfficiency =>
      numberOfShackles == 0 ? 0 : numberOfBirds / numberOfShackles;

  bool hasBirdInShackle(int shackleIndex) {
    if (shackleIndex < 0) {
      throw ArgumentError('must be >0', 'shackleIndex');
    }
    if (shackleIndex > maxSize) {
      throw ArgumentError('must be <$maxSize', 'shackleIndex');
    }
    if (shackleIndex >= _shackles.length) {
      return false;
    } else {
      return _shackles[shackleIndex];
    }
  }

  int get hangedBirdsPerHourSinceStart {
    try {
      return runningTimeInHours == 0
          ? 0
          : (hangedBirdsSinceStart / runningTimeInHours).round();
    } on Exception {
      return 0;
    }
  }

  double get runningTimeInHours =>
      _runningTime.inMilliseconds / const Duration(hours: 1).inMilliseconds;

  @override
  String toString() => objectDetails.toString();

  void startLine() {
    _shackles.clear();
    _waitForFirstBird = true;
  }

  void addRunningTime(Duration jump) {
    if (!_waitForFirstBird) {
      _runningTime = _runningTime + jump;
    }
  }

  @override
  late SizeInMeters sizeWhenFacingNorth = shape.size;
}
