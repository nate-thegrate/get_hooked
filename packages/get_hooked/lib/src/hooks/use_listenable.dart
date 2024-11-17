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
