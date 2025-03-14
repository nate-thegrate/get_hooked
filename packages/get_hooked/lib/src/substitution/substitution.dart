/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:collection_notifiers/collection_notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/bug_report.dart';

part 'src/scope.dart';

/// Causes the static [Ref] methods to reference a different [Get] object.
///
/// ## Performance Consideration
///
/// [GlobalKey] re-parenting has a notable performance impact, and the same is true when a
/// substitution is made. Prefer making substitutions all at once, such as when the relevant
/// widget(s) are first created, to mitigate unnecessary updates.
///
/// See also: [HookRef.sub], to create a substitution via a [Hook] function.
abstract final class Substitution<V extends Object> with Diagnosticable {
  const factory Substitution(V placeholder, V replacement, {bool autoDispose}) = _SubValue<V>;
  const factory Substitution.factory(V placeholder, ValueGetter<V> factory, {bool autoDispose}) =
      _SubFactory<V>;

  const Substitution._(this.placeholder, {this.autoDispose = true});

  /// The original [ValueListenable] object (i.e. the listenable encapsulated in
  /// a [Get] object).
  final V placeholder;

  /// A [ValueListenable] of the same type as the [placeholder] which will be referenced
  /// in its place by methods like [HookRef.watch] called from descendant widgets.
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
  /// - A [HookWidget] that called [HookRef.sub]
  /// - Any other widget that used [SubScope.add]
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
        if (sub.placeholder == placeholder) {
          result = scope;
          return true;
        }
      }
      final container =
          context.getElementForInheritedWidgetOfExactType<_ClientSubContainer<V>>()!
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
    properties.add(DiagnosticsProperty<V>('placeholder', placeholder));
    properties.add(FlagProperty('autoDispose', value: autoDispose));
  }
}

final class _SubValue<V extends Object> extends Substitution<V> {
  const _SubValue(super.placeholder, this.replacement, {super.autoDispose}) : super._();

  @override
  final V replacement;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('replacement', replacement));
  }
}

final class _SubFactory<V extends Object> extends Substitution<V> {
  const _SubFactory(super.placeholder, this.factory, {super.autoDispose}) : super._();

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
