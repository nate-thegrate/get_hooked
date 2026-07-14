import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_hooked_storage/get_hooked_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Stored.init(clearExisting: true);
  });

  test('reads and writes primitive values', () async {
    final counter = Stored('counter', 0);
    expect(counter.value, 0);

    counter.value = 3;
    expect(counter.value, 3);

    // New instance with same key should load persisted value.
    final again = Stored('counter', 0);
    expect(again.value, 3);
  });

  test('save awaits the write and returns success', () async {
    final flag = Stored('flag', false);

    final result = await flag.save(true);
    expect(result, isTrue);
    expect(flag.value, isTrue);

    // Same value: no write, returns null.
    expect(await flag.save(true), isNull);
  });

  test('nullable values round-trip through null token', () async {
    final name = Stored<String?>('name', 'alice');
    expect(name.value, 'alice');

    name.value = null;
    expect(name.value, isNull);

    final again = Stored<String?>('name', 'fallback');
    expect(again.value, isNull);
  });

  test('enumValue persists by name', () async {
    final mode = Stored.enumValue(ThemeMode.values, ThemeMode.system);
    expect(mode.value, ThemeMode.system);

    mode.value = ThemeMode.dark;
    expect(mode.value, ThemeMode.dark);

    final again = Stored.enumValue(ThemeMode.values, ThemeMode.light, storageKey: 'ThemeMode');
    expect(again.value, ThemeMode.dark);
  });

  test('custom encode/decode', () async {
    final point = Stored.custom<Offset, String>(
      'point',
      Offset.zero,
      encode: (o) => '${o.dx},${o.dy}',
      decode: (s) {
        final parts = s.split(',');
        return Offset(double.parse(parts[0]), double.parse(parts[1]));
      },
    );

    point.value = const Offset(1.5, 2.5);
    expect(point.value, const Offset(1.5, 2.5));

    final again = Stored.custom<Offset, String>(
      'point',
      Offset.zero,
      encode: (o) => '${o.dx},${o.dy}',
      decode: (s) {
        final parts = s.split(',');
        return Offset(double.parse(parts[0]), double.parse(parts[1]));
      },
    );
    expect(again.value, const Offset(1.5, 2.5));
  });

  test('Color is supported by default constructor', () {
    final color = Stored('color', const Color(0xFF112233));
    color.value = const Color(0xFFAABBCC);
    expect(color.value, const Color(0xFFAABBCC));

    final again = Stored('color', const Color(0xFF000000));
    expect(again.value, const Color(0xFFAABBCC));
  });
}
