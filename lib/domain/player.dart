import 'dart:async';


class Player {
  int _speed=1;
  bool playing=true;
  Duration jump=Duration(milliseconds: 100);
  void Function(Timer t)? listener;
  Timer? timer;

  Player() {
    updateTimer();
  }

  int get speed=> _speed;

  set speed(speed) {
    _speed=speed;
    updateTimer();
  }

  void pause() {
    playing=false;
    updateTimer();
  }

  void play() {
    playing=true;
    updateTimer();
  }

  Duration get interval => Duration(milliseconds: (jump.inMilliseconds/speed).round());

  void timerListener(void Function(Timer t) listener) {
    this.listener=listener;
    updateTimer();
  }

  void updateTimer() {
    if (playing) {
      if (listener!=null) {
        if (timer!=null) {
          timer!.cancel();
        }
        timer = Timer.periodic(interval, listener!);

      }
    } else {
      if (timer!=null) {
        timer!.cancel();
      }
    }
  }


}