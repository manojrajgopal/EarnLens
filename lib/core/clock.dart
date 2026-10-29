import 'package:uuid/uuid.dart';

/// Injectable time source so calculations and tests never depend on the real clock.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

class FixedClock implements Clock {
  FixedClock(this.value);
  DateTime value;

  @override
  DateTime now() => value;
}

abstract interface class IdGenerator {
  String newId();
}

class UuidGenerator implements IdGenerator {
  const UuidGenerator();
  static const _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}
