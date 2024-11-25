part of '../hooks.dart';

/// Subscribes to a [Listenable] and marks the widget as needing build
/// whenever the listener is called.
///
/// See also:
///   * [Listenable]
///   * [useValueListenable], [useAnimation]
L useListenable<L extends Listenable?>(L listenable, {bool watching = true}) {
  final Listenable? key = watching ? listenable : null;
  use(_ListenableHook.new, data: key, key: key, debugLabel: 'useListenable');
  return listenable;
}

class _ListenableHook extends Hook<void, Listenable?> {
  @override
  void initHook() => data?.addListener(setState);

  @override
  void dispose() => data?.removeListener(setState);

  @override
  void build() {}
}

/// Subscribes to a [ValueListenable] and returns its value.
///
/// See also:
///   * [ValueListenable], the created object
///   * [useListenable]
T useValueListenable<T>(ValueListenable<T> valueListenable, {bool watching = true}) {
  return use(
    _ValueListenableHook<T>.new,
    data: valueListenable,
    key: valueListenable,
    debugLabel: 'useValueListenable<$T>',
  );
}

/// [Animation]s are just [ValueListenable]s with an [AnimationStatus]!
const useAnimation = useValueListenable;

class _ValueListenableHook<T> extends Hook<T, ValueListenable<T>> {
  late T _value;

  void listener() {
    final T newValue = data.value;
    if (newValue != _value) {
      setState(() => _value = newValue);
    }
  }

  @override
  void initHook() {
    _value = data.value;
    data.addListener(listener);
  }

  @override
  void dispose() => data.removeListener(listener);

  @override
  T build() => _value;
}
