part of '../hook_functions.dart';

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

  @override
  Listenable? get debugResult => data;
}

/// Subscribes to a [ValueListenable] and returns its value.
///
/// See also:
///   * [ValueListenable], the created object
///   * [useListenable]
T useValueListenable<T>(ValueListenable<T> valueListenable, {bool watching = true}) {
  final Listenable? key = watching ? valueListenable : null;
  use(_ListenableHook.new, data: key, key: key, debugLabel: 'useValueListenable<$T>');
  return valueListenable.value;
}

/// [Animation]s are just [ValueListenable]s with an [AnimationStatus]!
const useAnimation = useValueListenable;
