/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/foundation.dart';

/// Similarly to [Get] objects, `ListenablePlaceholder` is intended to be declared with a
/// global scope and accessed via [Ref.watch] calls, but their [value] is seldom (or never)
/// accessed directly: instead a [Substitution] is added to an ancestor [GetScope] to redirect it
/// to another value.
sealed class ListenablePlaceholder<T> implements ValueListenable<T> {
  /// Creates an object that can be passed as a [ValueListenable] but never changes its [value]
  /// or sends any notifications.
  factory ListenablePlaceholder(T value) = _Placeholder<T>;

  /// Creates an object that can be passed as a [ValueListenable] but throws when any fields
  /// are accessed.
  factory ListenablePlaceholder.strict() = _StrictPlaceholder<T>;
}

class _Placeholder<T> implements ListenablePlaceholder<T> {
  _Placeholder(this.value);

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  final T value;

  @override
  String toString() => 'ListenablePlaceholder<$T>(value: $value)';
}

class _StrictPlaceholder<T> implements ListenablePlaceholder<T> {
  @override
  Never noSuchMethod(Invocation invocation) {
    throw UnsupportedError('Attempted to access ${invocation.memberName} on $this');
  }

  @override
  String toString() => 'ListenablePlaceholder<$T>.strict()';
}
