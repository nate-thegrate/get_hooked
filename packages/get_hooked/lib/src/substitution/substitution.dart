import 'package:collection_notifiers/collection_notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/bug_report.dart';

part 'src/scope.dart';

/// Causes the static [Ref] methods to reference a different [Get] object.
///
///
/// {@tool snippet}
///
/// A substitution is made by wrapping a [Get] object in a [Ref] constructor
/// and calling a `Ref` instance method, such as [Ref.subGet].
///
/// ```dart
/// GetScope(
///   substitutes: {Ref(getValue).sub(getOtherValue)},
///   child: widget.child,
/// );
/// ```
/// {@end-tool}
///
/// See also: [useSubstitute], to create a substitution via a [Hook] function.
abstract final class Substitution<V extends Object> with Diagnosticable {
  const factory Substitution(V ref, V replacement, {bool autoDispose}) = _SubValue<V>;
  const factory Substitution.factory(V ref, ValueGetter<V> factory, {bool autoDispose}) =
      _SubFactory<V>;

  const Substitution._(this.ref, {this.autoDispose = true});

  /// The original [ValueListenable] object (i.e. the listenable encapsulated in
  /// a [Get] object).
  final V ref;

  /// A [ValueListenable] of the same type as the [ref] which will be referenced
  /// in its place by methods like [Ref.watch] called from descendant widgets.
  V get replacement;

  /// Whether to automatically call [ChangeNotifier.dispose] when the substitution
  /// is no longer part of an active [SubScope].
  ///
  /// Defaults to `true`, but this value is ignored if the notifier is identified
  /// as a [DisposeGuard] instance.
  final bool autoDispose;

  /// If a [Substitution] was made, returns the widget that made it.
  ///
  /// The result could be:
  ///
  /// - A [SubScope], if the substitution was made there
  /// - A [HookWidget] that called [useSubstitute]
  /// - Another widget that used a `Ref` instance method such as [ref.sub]
  /// - `null`, if no substitution was made
  ///
  /// The result is always `null` in profile & release mode.
  static Widget? debugSubWidget<V extends Object, T>(BuildContext context, T placeholder) {
    Widget? result;
    assert(() {
      final T? scopedGet = SubScope.maybeOf(context, placeholder);
      if (scopedGet == null) return true;
      final SubScope scope = context.findAncestorStateOfType<_SubScopeState>()!.widget;
      for (final Substitution<Object> sub in scope.substitutes) {
        if (sub.ref == placeholder) {
          result = scope;
          return true;
        }
      }
      final container =
          context.getElementForInheritedWidgetOfExactType<_OverrideContainer<V>>()!
              as _OverrideContainerElement<V>;

      for (final MapEntry(key: context, value: map) in container.clientSubstitutes.entries) {
        for (final V key in map.keys) {
          if (key == placeholder) {
            result = context.widget;
            return true;
          }
        }
      }

      throw StateError(
        'The object $placeholder was substituted with $scopedGet, '
        'but the substitution was not found.\n'
        '$bugReport',
      );
    }());

    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<V>('ref', ref));
    properties.add(FlagProperty('autoDispose', value: autoDispose));
  }
}

final class _SubValue<V extends Object> extends Substitution<V> {
  const _SubValue(super.ref, this.replacement, {super.autoDispose}) : super._();

  @override
  final V replacement;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

final class _SubFactory<V extends Object> extends Substitution<V> {
  const _SubFactory(super.ref, this.factory, {super.autoDispose}) : super._();

  final ValueGetter<V> factory;

  @override
  V get replacement => factory();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty.lazy('factory', factory));
  }
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
