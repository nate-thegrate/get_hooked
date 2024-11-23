// ignore_for_file: public_member_api_docs, pro crastinate

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

abstract interface class EqualityFilter {
  abstract final Equality<Object?> equality;
}

abstract class EqualityNotifier<T>
    with ChangeNotifier
    implements EqualityFilter, ValueNotifier<T> {
  factory EqualityNotifier(T initialValue, {Equality<Object?>? equality}) = _EqualityNotifier<T>;

  EqualityNotifier.constructor(T initialValue) : _value = initialValue {
    // ignore: prefer_asserts_in_initializer_lists, false positive
    assert(
      equality.isValidKey(_value),
      'invalid key passed to EqualityNotifier<$T> constructor: $_value',
    );
  }

  @override
  T get value => _value;
  T _value;
  @override
  set value(T newValue) {
    assert(
      equality.isValidKey(newValue),
      'invalid key set for EqualityNotifier<$T> value: $newValue',
    );

    if (!equality.equals(_value, newValue)) {
      _value = newValue;
      notifyListeners();
    }
  }
}

class _EqualityNotifier<T> extends EqualityNotifier<T> {
  _EqualityNotifier(super.initialValue, {Equality<Object?>? equality}) : super.constructor() {
    equality = switch (equality) {
      _? => equality,
      null => switch (value) {
        Set() => const SetEquality<Object?>(),
        List() => const ListEquality<Object?>(),
        Map() => const MapEquality<Object?, Object?>(),
        Iterable() => const IterableEquality<Object?>(),
        _ => const DefaultEquality(),
      },
    };
  }
  @override
  late final Equality<Object?> equality;
}
