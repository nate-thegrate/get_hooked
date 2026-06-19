/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/computed_notifier.dart';
import 'package:get_hooked/src/vsync_mixin.dart';

part 'src/scope.dart';

typedef _V = ValueListenable<Object?>;

/// An immutable description of how one [ValueListenable] object can be used in place of another.
///
/// Most commonly used to create a [GetScope].
abstract final class Substitution with Diagnosticable {
  factory Substitution(
    ValueListenable<Object?> placeholder,
    ValueListenable<Object?> replacement, {
    bool autoDispose,
  }) = _SubReplacement;

  factory Substitution.factory(
    ValueListenable<Object?> placeholder,
    ValueGetter<ValueListenable<Object?>> factory, {
    bool autoDispose,
  }) = _SubFactory;

  /// Create a [Substitution] using a `value` of the matching type.\
  /// This redirects methods like [Ref.watch] to the provided value.
  factory Substitution.value(ValueListenable<Object?> placeholder, Object? value) = _SubValue;

  Substitution._(this.placeholder, {this.autoDispose = true});

  /// The original [ValueListenable] object (i.e. the listenable encapsulated in
  /// a [Get] object).
  final ValueListenable<Object?> placeholder;

  /// A [ValueListenable] of the same type as the [placeholder] which will be referenced
  /// in its place by methods like [HookRef.watch] called from descendant widgets.
  ValueListenable<Object?> get replacement;

  /// Whether to automatically call [ChangeNotifier.dispose] when the substitution
  /// is no longer part of an active [GetScope].
  ///
  /// Defaults to `true`, but this value is ignored if the notifier is identified
  /// as a [DisposeGuard] instance.
  final bool autoDispose;

  /// If a [Substitution] was made, returns the [GetScope] widget that made it.
  ///
  /// The result is always `null` in profile & release mode.
  static GetScope? debugSubWidget(BuildContext context, ValueListenable<Object?> placeholder) {
    return kDebugMode && GetScope.maybeOf(context, placeholder) != null
        ? context.findAncestorStateOfType<_GetScopeState>()?.widget
        : null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<_V>('placeholder', placeholder));
    properties.add(FlagProperty('autoDispose', value: autoDispose));
  }
}

final class _SubReplacement extends Substitution {
  _SubReplacement(super.placeholder, this.replacement, {super.autoDispose}) : super._();

  @override
  final _V replacement;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

final class _SubFactory extends Substitution {
  _SubFactory(super.placeholder, this.factory, {super.autoDispose}) : super._();

  final ValueGetter<_V> factory;

  @override
  _V get replacement => factory();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty.lazy('factory', factory));
  }
}

final class _SubValue with Diagnosticable implements Substitution {
  _SubValue(this.placeholder, this.value);

  @override
  final _V placeholder;

  final Object? value;

  @override
  late final _V replacement = _DummyListenable(value);

  @override
  bool get autoDispose => false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

class _DummyListenable implements ValueListenable<Object?> {
  _DummyListenable(this.value);

  @override
  final Object? value;

  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

/// A [Map] where each value is assumed to implement the same interface as the corresponding key.
extension type SubMap<T>._(Map<T, T> _map) implements Map<T, T> {
  /// Applies the [SubMap] interface to the provided [map].
  SubMap([Map<T, T>? map]) : _map = map ?? {};

  Error _notFound(Object? key) {
    if (_map.containsKey(key)) {
      return StateError('Unexpected map entry: (key: "$key", value: "${_map[key]}")');
    }
    return StateError('This map does not contain the key: $key');
  }

  /// Returns the [key]'s corresponding value.
  ///
  /// Throws an error if the map's value does not match the type argument's interface.
  G? maybeGet<G>(G key) => switch (_map[key]) {
    final G? g => g,
    _ => throw _notFound(key),
  };

  /// Returns the [key]'s corresponding value.
  ///
  /// Throws an error if the key is not present,
  /// or if map's value does not match the type argument's interface.
  G get<G>(G key) => switch (_map[key]) {
    final G g => g,
    _ => throw _notFound(key),
  };
}
