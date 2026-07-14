## 0.1.1
- add documentation & analysis rules

## 0.1.0
- Initial release!
- `Stored<T>`: persistent `GetValue` backed by `SharedPreferences`
  - Built-in support for `bool`, `int`, `double`, `String`, `List<String>`, `Color`, and nullables
  - `Stored.enumValue` for enums
  - `Stored.custom` for arbitrary encode/decode
  - `Stored.init()` to load prefs before use
  - `save()` to await the write before notifying listeners
