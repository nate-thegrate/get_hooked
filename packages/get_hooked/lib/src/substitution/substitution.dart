/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:collection_notifiers/collection_notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/bug_report.dart';
import 'package:get_hooked/src/computed_notifier.dart';
import 'package:get_hooked/src/vsync_mixin.dart';

part 'src/scope.dart';

typedef _V = ValueListenable<Object?>;

/// An immutable description of how one [ValueListenable] object can be used in place of another.
///
/// Most commonly used to create a [GetScope].
///
/// See also: [HookRef.sub], which creates a substitution via a [Hook] function.
abstract final class Substitution<T> with Diagnosticable {
  factory Substitution(
    ValueListenable<T> placeholder,
    ValueListenable<T> replacement, {
    bool autoDispose,
  }) = _SubReplacement<T>;

  factory Substitution.factory(
    ValueListenable<T> placeholder,
    ValueGetter<ValueListenable<T>> factory, {
    bool autoDispose,
  }) = _SubFactory<T>;

  /// Create a [Substitution] using a `value` of the matching type.\
  /// This redirects methods like [Ref.watch] to the provided value.
  factory Substitution.value(ValueListenable<T> placeholder, T value) = _SubValue;

  Substitution._(this.placeholder, {this.autoDispose = true});

  /// The original [ValueListenable] object (i.e. the listenable encapsulated in
  /// a [Get] object).
  final ValueListenable<T> placeholder;

  /// A [ValueListenable] of the same type as the [placeholder] which will be referenced
  /// in its place by methods like [HookRef.watch] called from descendant widgets.
  ValueListenable<T> get replacement;

  /// Whether to automatically call [ChangeNotifier.dispose] when the substitution
  /// is no longer part of an active [GetScope].
  ///
  /// Defaults to `true`, but this value is ignored if the notifier is identified
  /// as a [DisposeGuard] instance.
  final bool autoDispose;

  /// If a [Substitution] was made, returns the widget that made it.
  ///
  /// The result could be:
  ///
  /// - A [GetScope], if the substitution was made there
  /// - A [HookWidget] that called [HookRef.sub]
  /// - Any other widget that used [GetScope.add]
  /// - `null`, if no substitution was made
  ///
  /// The result is always `null` in profile & release mode.
  static Widget? debugSubWidget<T>(BuildContext context, ValueListenable<T> placeholder) {
    if (!kDebugMode) return null;

    final ValueListenable<T>? scopedGet = GetScope.maybeOf(context, placeholder);
    if (scopedGet == null) return null;

    final _GetScopeState state = context.findAncestorStateOfType()!;
    final GetScope scope = state.widget;
    for (final Substitution<Object?> sub in scope.substitutes) {
      if (sub.placeholder == placeholder) return scope;
    }

    for (final MapEntry(key: context, value: map) in state.clientSubstitutes.entries) {
      for (final _V key in map.keys) {
        if (key == placeholder) return context.widget;
      }
    }

    throw StateError(
      'The object $placeholder was substituted with $scopedGet, '
      'but the substitution was not found.\n'
      '$bugReport',
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ValueListenable<T>>('placeholder', placeholder));
    properties.add(FlagProperty('autoDispose', value: autoDispose));
  }
}

final class _SubReplacement<T> extends Substitution<T> {
  _SubReplacement(super.placeholder, this.replacement, {super.autoDispose}) : super._();

  @override
  final ValueListenable<T> replacement;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

final class _SubFactory<T> extends Substitution<T> {
  _SubFactory(super.placeholder, this.factory, {super.autoDispose}) : super._();

  final ValueGetter<ValueListenable<T>> factory;

  @override
  ValueListenable<T> get replacement => factory();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty.lazy('factory', factory));
  }
}

final class _SubValue<T> with Diagnosticable implements Substitution<T> {
  _SubValue(this.placeholder, this.value);

  @override
  final ValueListenable<T> placeholder;

  final T value;

  @override
  late final ValueListenable<T> replacement = _DummyListenable<T>(value);

  @override
  bool get autoDispose => false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

class _DummyListenable<T> implements ValueListenable<T> {
  _DummyListenable(this.value);

  @override
  final T value;

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
