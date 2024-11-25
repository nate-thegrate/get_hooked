part of '../hooks.dart';

/// A class that stores a single value.
///
/// It is typically created by [useRef].
class ObjectRef<T> {
  /// A class that stores a single value.
  ///
  /// It is typically created by [useRef].
  ObjectRef(this.value);

  /// A mutable property that will be preserved across rebuilds.
  ///
  /// Updating this property will not cause widgets to rebuild.
  T value;
}

/// Creates an object containing a property which can be mutated
/// without triggering rebuilds.
ObjectRef<T> useRef<T>(T initialValue, {Object? key}) {
  return use(_ObjectRefHook<T>.new, key: key, data: initialValue, debugLabel: 'useRef<$T>');
}

class _ObjectRefHook<T> extends Hook<ObjectRef<T>, T> {
  late final ref = ObjectRef(data);

  @override
  ObjectRef<T> build() => ref;
}
