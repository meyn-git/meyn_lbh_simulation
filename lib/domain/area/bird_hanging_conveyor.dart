import 'life_bird_handling_area.dart';
import 'module.dart';
import 'module_tilter.dart';

class BirdHangingConveyor extends ActiveCell {
  final CardinalDirection direction;
  final int shacklesPerHour;
  ShackleLine shackleLine = ShackleLine();
  Duration elapsedTime = Duration.zero;
  BirdBuffer? _cashedBirdBuffer;
  static final int hourInMicroSeconds = const Duration(hours: 1).inMicroseconds;
  Duration timePerBird;

  bool running;

  BirdHangingConveyor({
    required LiveBirdHandlingArea area,
    required Position position,
    required this.direction,
  })  : running = true,
        shacklesPerHour = area.productDefinition.lineSpeedInShacklesPerHour,
        timePerBird = Duration(
            microseconds: (hourInMicroSeconds /
                    area.productDefinition.lineSpeedInShacklesPerHour)
                .round()),
        super(
          area,
          position,
        );

  BirdBuffer get birdBuffer {
    return _cashedBirdBuffer ?? _findBirdBuffer();
  }

  BirdBuffer _findBirdBuffer() {
    for (var neighbourDirection in CardinalDirection.values) {
      var neighbour = area.neighbouringCell(this, neighbourDirection);
      if (neighbour is BirdBuffer &&
          (neighbour as BirdBuffer).birdDirection ==
              neighbourDirection.opposite) {
        return neighbour as BirdBuffer;
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
  String get name => runtimeType.toString();

  @override
  onUpdateToNextPointInTime(Duration jump) {
    if (running) {
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
}

class ShackleLine {
  static const int maxSize = 100;
  final List<bool> _shackles = []; // true if shackle has a bird, false if not
  int hangedBirdsSinceStart = 0;
  int emptyShacklesSinceStart = 0;

  nextShackle({required bool hasBird}) {
    _shackles.insert(0, hasBird);
    if (_shackles.length > maxSize) {
      _shackles.removeAt(_shackles.length - 1);
    }
    if (hasBird) {
      hangedBirdsSinceStart++;
    } else {
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
}
