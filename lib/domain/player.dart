import 'dart:async';


class Player {
  int speed=1;
  bool playing=true;
  Duration jump=Duration(milliseconds: 100);
  void Function(Timer t)? listener;
  Timer? timer;

  Player() {
    updateTimer();
  }

  void increaseSpeed() {
    speed++;
    updateTimer();
  }

  void decreaseSpeed() {
    if (speed>0) {
      speed--;
      updateTimer();
    }
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