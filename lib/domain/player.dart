import 'dart:async';

import 'package:meyn_lbh_simulation/domain/site_fileni.dart';
import 'package:meyn_lbh_simulation/domain/site_indrol.dart';

import 'life_bird_handling_area.dart';

class Player {
  int _speed = 1;
  bool playing = true;
  Duration jump = _calculateJump(1);
  void Function(Timer t)? listener;
  Timer? timer;
  LiveBirdHandlingArea area = IndrolLifeBirdHandlingArea(IndrolProductDefinitions()[0]);

  // Using a singleton here. A bit jucky, that for now cleaner than using get_it or provider.
  static final Player _singleton = Player._();

  factory Player() {
    return _singleton;
  }

  Player._() {
    updateTimer();
  }

  static final maxSpeed = 64;
  static final maxJumpResolution = Duration(seconds: 1);
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
    if (area is IndrolLifeBirdHandlingArea) {
      area = IndrolLifeBirdHandlingArea(
          IndrolProductDefinitions()[0]); // TODO be able to select others
    } else {
      area = FileniLiveBirdHandlingArea(
          FileniProductDefinitions()[0]); // TODO be able to select others
    }
  }

  void restartOtherArea() {
    if (area is IndrolLifeBirdHandlingArea) {
      area = FileniLiveBirdHandlingArea(
          FileniProductDefinitions()[0]); // TODO be able to select others
    } else {
      area = IndrolLifeBirdHandlingArea(
          IndrolProductDefinitions()[0]); // TODO be able to select others
    }
  }
}
