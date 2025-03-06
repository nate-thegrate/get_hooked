part of '../hook_functions.dart';

/// A class that stores a single value.
///
/// This is similar to a [ValueNotifier] but does not send any notifications
/// when the value changes.
///
/// It is typically instantiated by [useRef].
class ObjectRef<T> {
  /// Stores a single value.
  ///
  /// This constructor is typically called by [useRef].
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
