import 'dart:async';
import 'dart:collection';

import 'package:meyn_lbh_simulation/domain/area/drawer_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/area/object_details.dart';
import 'package:meyn_lbh_simulation/domain/area/shackle_conveyor.dart';
import 'package:meyn_lbh_simulation/domain/site/scenario.dart';

class Player {
  int _speed = 1;
  bool playing = true;
  Duration jump = _calculateJump(1);
  final List<UpdateListener> _updateListeners = [];
  Timer? timer;

  LinkedHashSet<Object> objectsToMonitor = LinkedHashSet<Object>();

  Player() {
    updateTimer();
  }

  static const maxSpeed = 64;
  static const maxJumpResolution = Duration(seconds: 1);
  static final timerInterval = Duration(
      microseconds: (1 / maxSpeed * maxJumpResolution.inMicroseconds).round());

  Scenario? _scenario;

  Scenario? get scenario => _scenario;

  set scenario(Scenario? scenario) {
    _scenario = scenario;
    if (scenario != null) {
      Iterable<Detailable> shackleConveyors =
          scenario.area.systems.whereType<ShackleConveyor>();
      if (shackleConveyors.isEmpty) {
        shackleConveyors =
            scenario.area.systems.whereType<DrawerHangingConveyor>();
      }
      objectsToMonitor.clear();
      objectsToMonitor.addAll(shackleConveyors);
    }
  }

  int get speed => _speed;

  set speed(speed) {
    if (_speed <= maxSpeed) {
      _speed = speed;
      updateTimer();
    }
  }

  void pause() {
    playing = false;
    updateTimer();
  }

  void play() {
    playing = true;
    updateTimer();
  }

  void addUpdateListener(UpdateListener updateListener) {
    _updateListeners.add(updateListener);

    /// start timer if not started yet
    updateTimer();
  }

  void removeUpdateListener(UpdateListener updateListener) {
    _updateListeners.remove(updateListener);
  }

  void updateTimer() {
    if (playing) {
      if (_updateListeners.isNotEmpty) {
        if (timer != null) {
          timer!.cancel();
        }
        jump = _calculateJump(speed);
        timer = Timer.periodic(timerInterval, (timer) {
          _callListeners(timer);
        });
      }
    } else {
      if (timer != null) {
        timer!.cancel();
      }
    }
  }

  static Duration _calculateJump(int speed) => Duration(
      microseconds:
          (speed / maxSpeed * maxJumpResolution.inMicroseconds).round());

  void restart() {
    if (scenario != null) {
      scenario = scenario!.withNewArea();
    }
  }

  void start(Scenario scenario) {
    this.scenario = scenario;
  }

  void _callListeners(Timer timer) {
    for (var updateListener in _updateListeners) {
      updateListener.onUpdate();
    }
  }
}

abstract class UpdateListener {
  void onUpdate();
}
