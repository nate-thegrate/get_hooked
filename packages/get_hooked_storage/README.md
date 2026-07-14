# get_hooked_storage

Persistent [GetValue](https://pub.dev/packages/get_hooked) objects backed by
`SharedPreferences`.

Values created with `Stored<T>` can be used directly with `ref.watch()`, `Get.it`,
`RefPaint`, and the rest of the get_hooked ecosystem while being automatically
saved to and restored from local storage.

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:get_hooked/get_hooked.dart';
import 'package:get_hooked_storage/get_hooked_storage.dart';

// In main(), before runApp:
await Stored.init();

final counter = Stored('counter', 0);
final themeMode = Stored.enumValue(ThemeMode.values, ThemeMode.system);

class MyApp extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeMode);
    final count = ref.watch(counter);
    return MaterialApp(
      themeMode: mode,
      home: Text('count: $count'),
    );
  }
}

// Later:
counter.value = 1; // persists automatically
await themeMode.save(ThemeMode.dark); // or await the write
```

## Supported types

- `bool`, `int`, `double`, `String`, `List<String>`
- `Color` and `Color?`
- Nullable versions of the above
- Enums via `Stored.enumValue(values, initial)`
- Custom types via `Stored.custom(key, initial, encode: ..., decode: ...)`

## Initialization

`Stored.init()` must complete before any `Stored` value is read.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Stored.init();
  runApp(const MyApp());
}
```

See the library docs for `Stored.enumValue`, `Stored.custom`, and the `save` method.
