import 'package:flutter/material.dart';
import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/util/title_builder.dart';
import 'package:meyn_lbh_simulation/gui/area/command.dart';
import 'package:user_command/user_command.dart';

import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_tilter.dart';

class BirdHangingConveyor implements ActiveCell {
  @override
  late LiveBirdHandlingArea area;
  @override
  late Position position;
  @override
  late String name = "BirdHangingConveyor${seqNr ?? ''}";
  @override
  late List<Command> commands=[RemoveFromMonitorPanel(this), _startCommand, _stopCommand];
  final int? seqNr;
  final CardinalDirection direction;
  final int shacklesPerHour;
  ShackleLine shackleLine = ShackleLine();
  Duration elapsedTime = Duration.zero;
  late BirdBuffer birdBuffer = _findBirdBuffer();
  static final int hourInMicroSeconds = const Duration(hours: 1).inMicroseconds;


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

  BirdHangingConveyor({
    required this.area,
    required this.position,
    required this.direction,
    this.seqNr,
  })  : shacklesPerHour = area.productDefinition.lineSpeedInShacklesPerHour,
        timePerBird = Duration(
            microseconds: (hourInMicroSeconds /
                    area.productDefinition.lineSpeedInShacklesPerHour)
                .round()) {
    running = true;
  }

  bool get running => _running;

  set running(bool running) {
    _running = running;
    if (running) {
      shackleLine.startLine();
    }
  }

  BirdBuffer _findBirdBuffer() {
    for (var neighborDirection in CardinalDirection.values) {
      var neighbor = area.neighboringCell(this, neighborDirection);
      if (neighbor is BirdBuffer &&
          (neighbor as BirdBuffer).birdDirection ==
              neighborDirection.opposite) {
        return neighbor as BirdBuffer;
      }
    }
    throw Exception(
        '$LiveBirdHandlingArea error: $name must connect to a $BirdBuffer (e.g. a $ModuleTilter)');
  }

  @override
  bool almostWaitingToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => false;

  @override
  bool isFeedOut(CardinalDirection direction) => false;

  @override
  ModuleGroup? get moduleGroup => null;

  @override
  onUpdateToNextPointInTime(Duration jump) {
    if (running) {
      shackleLine.addRunningTime(jump);
      elapsedTime += jump;

      while (elapsedTime > timePerBird) {
        bool hasBird = birdBuffer.removeBird();
        shackleLine.nextShackle(hasBird: hasBird);
        elapsedTime = elapsedTime - timePerBird; //remainder
      }
    }
  }

  @override
  bool waitingToFeedIn(CardinalDirection direction) => false;

  @override
  bool waitingToFeedOut(CardinalDirection direction) => false;

  @override
  String toString() {
    return TitleBuilder(name)
        .appendProperty('shacklesPerHour', shacklesPerHour)
        .appendProperty('shackleLine', shackleLine)
        .toString();
  }
}

class ShackleLine {
  static const int maxSize = 100;
  final List<bool> _shackles = []; // true if shackle has a bird, false if not
  int hangedBirdsSinceStart = 0;
  int emptyShacklesSinceStart = 0;
  bool _waitForFirstBird = true;
  Duration _runningTime = Duration.zero;

  nextShackle({required bool hasBird}) {
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
  String toString() {
    return TitleBuilder('ShackleLine')
        .appendProperty('runningTime', _runningTime)
        .appendProperty('hangedBirdsSinceStart', hangedBirdsSinceStart)
        .appendProperty(
            'hangedBirdsPerHourSinceStart', hangedBirdsPerHourSinceStart)
        .appendProperty('emptyShacklesSinceStart', emptyShacklesSinceStart)
        .appendProperty('lineEfficiency', lineEfficiency)
        .toString();
  }

  void startLine() {
    _shackles.clear();
    _waitForFirstBird = true;
  }

  void addRunningTime(Duration jump) {
    if (!_waitForFirstBird) {
      _runningTime = _runningTime + jump;
    }
  }
}
