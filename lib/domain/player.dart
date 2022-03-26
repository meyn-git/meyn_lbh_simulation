import 'dart:async';

import 'package:meyn_lbh_simulation/domain/scenario.dart';

class Player {
  int _speed = 1;
  bool playing = true;
  Duration jump = _calculateJump(1);
  void Function(Timer t)? listener;
  Timer? timer;
  Scenario scenario = Scenario.first();

  Player() {
    updateTimer();
  }

  static const maxSpeed = 64;
  static const maxJumpResolution = Duration(seconds: 1);
  static final timerInterval = Duration(
      microseconds: (1 / maxSpeed * maxJumpResolution.inMicroseconds).round());

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

  void timerListener(void Function(Timer t) listener) {
    this.listener = listener;
    updateTimer();
  }

  void updateTimer() {
    if (playing) {
      if (listener != null) {
        if (timer != null) {
          timer!.cancel();
        }
        jump = _calculateJump(speed);
        timer = Timer.periodic(timerInterval, listener!);
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
    scenario = scenario.withNewArea();
  }

  void start(Scenario scenario) {
    this.scenario = scenario;
  }
}
