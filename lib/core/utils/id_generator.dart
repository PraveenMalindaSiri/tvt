import 'dart:math';

class IdGenerator {
  IdGenerator._();

  static final Random _random = Random();

  static String create() {
    final int now = DateTime.now().microsecondsSinceEpoch;

    final int randomPart = _random.nextInt(999999999);

    return 'id-$now-$randomPart';
  }
}