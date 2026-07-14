// ignore_for_file: type_literal_in_constant_pattern, we're evaluating type literals

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:get_hooked/get_hooked.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bugReport = 'Please file a bug report at https://github.com/nate-thegrate/get_hooked/issues';

SharedPreferences? _storage;
const _nullToken = '_nullToken';
Future<bool> _save(String name, Object? newValue) => switch (newValue) {
  null => _storage!.setString(name, _nullToken),
  bool() => _storage!.setBool(name, newValue),
  int() => _storage!.setInt(name, newValue),
  double() => _storage!.setDouble(name, newValue),
  String() => _storage!.setString(name, newValue),
  List<String>() => _storage!.setStringList(name, newValue),
  _ => () {
    if (kDebugMode) {
      final argType = newValue.runtimeType.toString();
      final String an = switch (argType[0].toLowerCase()) {
        'a' || 'e' || 'i' || 'o' || 'u' => 'an',
        _ => 'a',
      };
      throw ArgumentError('Unable to save $an $argType: $newValue');
    }
    return SynchronousFuture(false);
  }(),
};

/// For some reason, the `?` works in a type argument but not when creating a [Type] object.
typedef _Maybe<T> = T?;

/// A [GetValue] that is automatically persisted to and restored from
/// [SharedPreferences].
///
/// Call [Stored.init] before reading or writing any values.
///
/// Supported types with the default constructor include `bool`, `int`, `double`,
/// `String`, `List<String>`, [Color], and their nullable variants. Use
/// [Stored.enumValue] for enums and [Stored.custom] for other types.
///
/// ```dart
/// final counter = Stored('counter', 0);
/// counter.value = 1; // persists automatically
/// ```
extension type Stored<T>._(_Stored<T, Object> _hooked) implements GetValue<T> {
  /// Creates a [Stored] value under [storageKey], using [initialValue] when no
  /// persisted value exists.
  ///
  /// Supported types: `bool`, `int`, `double`, `String`, `List<String>`, [Color],
  /// and their nullable variants.
  ///
  /// For enums, use [Stored.enumValue]. For other types, use [Stored.custom].
  factory Stored(String storageKey, T initialValue) {
    final _Stored<Object?, Object>? result = switch ((T, initialValue)) {
      (const (_Maybe<bool>), final bool? value) => _Stored.nullable<bool?>(storageKey, value),
      (const (_Maybe<int>), final int? value) => _Stored.nullable<int?>(storageKey, value),
      (const (_Maybe<double>), final double? value) => _Stored.nullable<double?>(storageKey, value),
      (const (_Maybe<String>), final String? value) => _Stored.nullable<String?>(storageKey, value),
      (const (_Maybe<List<String>>), final List<String>? value) => _Stored.nullable<List<String>?>(
        storageKey,
        value,
      ),
      (bool, final bool value) => _Stored.noEncoding<bool>(storageKey, value),
      (int, final int value) => _Stored.noEncoding<int>(storageKey, value),
      (double, final double value) => _Stored.noEncoding<double>(storageKey, value),
      (String, final String value) => _Stored.noEncoding<String>(storageKey, value),
      (const (List<String>), final List<String> value) => _Stored.noEncoding<List<String>>(
        storageKey,
        value,
      ),
      (const (_Maybe<Color>), final Color? value) => _Stored<Color?, Object>(
        storageKey,
        value,
        encode: _encodeMaybeColor,
        decode: _decodeMaybeColor,
      ),
      (Color, final Color value) => _Stored<Color, int>(
        storageKey,
        value,
        encode: _encodeColor,
        decode: _decodeColor,
      ),
      _ => null,
    };
    if (result case final Stored<T> stored) {
      return stored;
    } else if (result != null) {
      throw StateError(
        "Internal error: Stored('$storageKey', $initialValue) was parsed into "
        'a ${result.runtimeType}, which is not a Stored<$T>.\n$_bugReport',
      );
    }
    throw FlutterError.fromParts([
      ErrorSummary('Unable to create a Stored<$T> object using the default constructor.'),
      ErrorHint('Consider using Stored.custom()'),
    ]);
  }

  /// Creates a [Stored] enum value, persisted by the enum's `name`.
  ///
  /// Pass the enum's `values` list (e.g. `ThemeMode.values`) and an [initial]
  /// value used when nothing is stored yet. If [storageKey] is omitted, the
  /// runtime type of [initial] is used as the key.
  ///
  /// ```dart
  /// final themeMode = Stored.enumValue(ThemeMode.values, ThemeMode.system);
  /// ```
  static Stored<E> enumValue<E extends Enum?>(List<Enum> values, E initial, {String? storageKey}) {
    assert(values is List<E>, () {
      var type = '$E';
      if (type.endsWith('?')) type = type.substring(0, type.length - 1);
      return 'Stored<$E> expects a List<$type>; instead got a ${values.runtimeType}.\n'
          'Consider passing $type.values instead.';
    });

    return Stored._(
      _Stored<E, String>(
        storageKey ?? '${initial.runtimeType}',
        initial,
        encode: (value) => value?.name ?? _nullToken,
        decode: (name) => (name == _nullToken ? null : values.byName(name)) as E,
      ),
    );
  }

  /// Creates a [Stored] value with custom [encode] and [decode] for types not
  /// handled by the default constructor or [Stored.enumValue].
  ///
  /// [Encoded] must be a type that [SharedPreferences] can store natively
  /// (`bool`, `int`, `double`, `String`, or `List<String>`).
  ///
  /// ```dart
  /// final point = Stored.custom<Offset, String>(
  ///   'point',
  ///   Offset.zero,
  ///   encode: (o) => '${o.dx},${o.dy}',
  ///   decode: (s) {
  ///     final parts = s.split(',');
  ///     return Offset(double.parse(parts[0]), double.parse(parts[1]));
  ///   },
  /// );
  /// ```
  static Stored<T> custom<T, Encoded extends Object>(
    String storageKey,
    T initialValue, {
    required Encoded Function(T value) encode,
    required T Function(Encoded encoded) decode,
  }) {
    return Stored._(_Stored<T, Encoded>(storageKey, initialValue, encode: encode, decode: decode));
  }

  /// This method should be `await`ed before interacting with any stored values.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await Stored.init();
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// If `prefs` are provided, this function runs synchronously to register them
  /// with the [_Stored] API.
  ///
  /// If `clearExisting` is true, all existing preferences are cleared.
  static Future<void> init({SharedPreferences? prefs, bool clearExisting = false}) {
    void maybeClearStorage(SharedPreferences prefs) {
      _storage = prefs;
      if (clearExisting) prefs.clear();
    }

    if (prefs ?? _storage case final existing?) {
      maybeClearStorage(existing);
      return SynchronousFuture(null);
    }

    return SharedPreferences.getInstance().then(maybeClearStorage);
  }

  /// Saves a new value to local storage, and waits until the save completes
  /// before triggering any notifications.
  ///
  /// Returns a future that completes with the result of the relevant `SharedPreferences`
  /// API call, such as [SharedPreferences.setInt], or returns `null` if the new value
  /// matches the existing one.
  Future<bool>? save(T newValue) => _hooked.save(newValue);
}

int _encodeColor(Color color) => color.toARGB32();
Color _decodeColor(int value) => Color(value);

Object _encodeMaybeColor(Color? color) => color?.toARGB32() ?? _nullToken;
Color? _decodeMaybeColor(Object value) => value == _nullToken ? null : Color(value as int);

class _Stored<T, Encoded extends Object> with ChangeNotifier implements ValueNotifier<T> {
  _Stored(this.storageKey, T initialValue, {required this.encode, required this.decode})
    : _value = initialValue;

  @factory
  static _Stored<T, T> noEncoding<T extends Object>(String storageKey, T initialValue) {
    assert(switch (initialValue) {
      bool() || int() || double() || String() || List<String>() => true,
      _ => throw ArgumentError('Encoding & decoding must be specified for the type $T.'),
    });
    return _Stored(storageKey, initialValue, encode: _noEncoding, decode: _noEncoding);
  }

  @factory
  static _Stored<T, Object> nullable<T>(String storageKey, T initialValue) {
    assert(switch (initialValue) {
      bool() || int() || double() || String() || List<String>() || null => true,
      _ => throw ArgumentError('Encoding & decoding must be specified for the type $T.'),
    });
    T decodeNullable(Object encoded) {
      final Object? result = encoded == _nullToken ? null : encoded;
      if (result is T) return result;
      if (kDebugMode) {
        throw FlutterError.fromParts([
          ErrorSummary('Object obtained from local storage could not be parsed.'),
          ErrorDescription(
            'Expected an object of type $T from the storage key "$storageKey" '
            'but received a ${encoded.runtimeType}: $encoded',
          ),
          ErrorHint(
            'Consider using Stored.custom() to ensure values are encoded & decoded correctly.',
          ),
          ErrorHint(
            'Or if this value is outdated, '
            'run Stored.init(clearExisting: true) to clear the current prefs.',
          ),
        ]);
      }
      return null as T;
    }

    return _Stored(storageKey, initialValue, encode: _encodeNullable, decode: decodeNullable);
  }

  static T _noEncoding<T extends Object>(T value) => value;
  static Object _encodeNullable<T>(T value) => value ?? _nullToken;

  @override
  T get value {
    assert(
      _storage != null,
      'A Stored<$T> tried to access a value before Stored.init() was finished.\n'
      'Consider adding an `await Stored.init()` to the main() function (before calling `runApp`).',
    );
    return switch (_storage?.get(storageKey)) {
      final Encoded encoded => _value = decode(encoded),
      _ => _value,
    };
  }

  T _value;
  @override
  set value(T newValue) {
    if (newValue == value) return;

    _value = newValue;
    _save(storageKey, encode(newValue));
    notifyListeners();
  }

  Future<bool>? save(T newValue) {
    if (newValue == value) return null;

    return _save(storageKey, encode(newValue)).then((result) {
      _value = newValue;
      notifyListeners();
      return result;
    });
  }

  final String storageKey;

  final Encoded Function(T) encode;
  final T Function(Encoded) decode;
}
