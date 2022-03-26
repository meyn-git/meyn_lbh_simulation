import 'package:flutter_test/flutter_test.dart';
import 'package:meyn_lbh_simulation/domain/bird_hanging_conveyor.dart';

main() {
  group('class ShackleLine', () {
    test('no shackles', () {
      var shackleLine = ShackleLine();
      expect(shackleLine.hasBirdInShackle(10), false);
    });
    test('first shackle with bird', () {
      var shackleLine = ShackleLine();
      shackleLine.nextShackle(hasBird: true);
      expect(shackleLine.numberOfShackles, 1);
      expect(shackleLine.hasBirdInShackle(0), true);
    });
    test('first shackle without bird', () {
      var shackleLine = ShackleLine();
      shackleLine.nextShackle(hasBird: false);
      expect(shackleLine.numberOfShackles, 1);
      expect(shackleLine.hasBirdInShackle(0), false);
    });
    test('first shackle with bird, second without', () {
      var shackleLine = ShackleLine();
      shackleLine.nextShackle(hasBird: true);
      shackleLine.nextShackle(hasBird: false);
      expect(shackleLine.numberOfShackles, 2);
      expect(shackleLine.hasBirdInShackle(0), false);
      expect(shackleLine.hasBirdInShackle(1), true);
    });
    test('More than 100 shackles', () {
      var shackleLine = ShackleLine();
      shackleLine.nextShackle(hasBird: false);
      for (int i = 1; i < 110; i++) {
        shackleLine.nextShackle(hasBird: true);
      }
      expect(shackleLine.numberOfShackles, 100);
      expect(shackleLine.hasBirdInShackle(0), true);
      expect(shackleLine.hasBirdInShackle(99), true);
    });
  });
}
