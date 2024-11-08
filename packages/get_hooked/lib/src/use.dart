part of '../get_hooked.dart';

abstract final class Use {
  /// Don't use it.
  static V it<T, V extends ValueListenable<T>>(
    Get<T, V> get, {
    bool listen = false,
    bool attach = true,
  }) {
    return use(_GetHook(get, listen, attach));
  }

  static T watch<T>(
    Get<T, ValueListenable<T>> get, {
    bool checkVsync = true,
  }) {
    return use(_WatchHook(get, checkVsync));
  }

  static Out select<In, Out>(
    Get<In, ValueListenable<In>> get,
    Out Function(In value) selector, {
    bool checkVsync = true,
  }) {
    return use(_SelectHook(get, selector, checkVsync));
  }
}

mixin _MarkNeedsBuild<R, H extends Hook<R>> on HookState<R, H> {
  late final VoidCallback rebuild = (context as Element).markNeedsBuild;
}

class _GetHook<T, V extends ValueListenable<T>> extends Hook<V> {
  const _GetHook(this.useIt, this.listen, this.attach);

  final Get<T, V> useIt;
  final bool listen, attach;

  @override
  _GetState<T, V> createState() => _GetState<T, V>();
}

class _GetState<T, V extends ValueListenable<T>> extends HookState<V, _GetHook<T, V>>
    with _MarkNeedsBuild {
  V get listenable => hook.useIt.it;

  Subscription? subscription;
  void subscribe() {
    if (hook case _GetHook(attach: true, useIt: final GetVsync getItVsync)) {
      getItVsync.attach(context);
    }
    subscription = Subscription(listenable, rebuild);
  }

  @override
  void initHook() {
    if (hook.listen) subscribe();
  }

  @override
  void didUpdateHook(_GetHook<T, V> oldHook) {
    if (hook.useIt != oldHook.useIt) {
      subscription?.close();
      initHook();
    } else if (hook.listen != oldHook.listen) {
      if (hook.listen) {
        subscribe();
      } else {
        subscription?.close();
      }
    }
  }

  @override
  void dispose() {
    subscription?.close();
    Vsync.detach(context);
  }

  @override
  V build(BuildContext context) => listenable;
}

class _WatchHook<T> extends Hook<T> {
  const _WatchHook(this.useIt, this.checkVsync);

  final Get<T, ValueListenable<T>> useIt;
  final bool checkVsync;

  @override
  _WatchState<T> createState() => _WatchState();
}

class _WatchState<T> extends HookState<T, _WatchHook<T>> with _MarkNeedsBuild {
  late Get<T, ValueListenable<T>> useIt = hook.useIt;

  @override
  void initHook() {
    assert(() {
      if (hook.checkVsync) _debugCheckVsync(useIt, 'watch');
      return true;
    }());

    useIt = hook.useIt..it.addListener(rebuild);
  }

  @override
  void didUpdateHook(_WatchHook<T> oldHook) {
    if (hook.useIt != useIt) {
      dispose();
      initHook();
    }
  }

  @override
  void dispose() => useIt.it.removeListener(rebuild);

  @override
  T build(BuildContext context) => useIt.it.value;
}

class _SelectHook<In, Out> extends Hook<Out> {
  const _SelectHook(this.useIt, this.selector, this.checkVsync);

  final Get<In, ValueListenable<In>> useIt;
  final Out Function(In value) selector;
  final bool checkVsync;

  @override
  _SelectState<In, Out> createState() => _SelectState();
}

class _SelectState<In, Out> extends HookState<Out, _SelectHook<In, Out>> with _MarkNeedsBuild {
  late Get<In, ValueListenable<In>> useIt;
  Out? previous;

  void listener() {
    final result = build();
    if (result != previous) rebuild();
    previous = result;
  }

  @override
  void initHook() {
    assert(() {
      if (hook.checkVsync) _debugCheckVsync(useIt, 'select');
      return true;
    }());

    useIt = hook.useIt..it.addListener(listener);
  }

  @override
  void didUpdateHook(_SelectHook<In, Out> oldHook) {
    if (hook.useIt != useIt) {
      dispose();
      initHook();
    }
  }

  @override
  void dispose() => useIt.it.removeListener(listener);

  @override
  Out build([BuildContext? context]) => hook.selector(useIt.it.value);
}

void _debugCheckVsync(Get useIt, String name) {
  assert(() {
    if (useIt case final GetVsync getItVsync when getItVsync._animation == null) {
      throw FlutterError.fromParts([
        ErrorSummary('UseIt.$name() called with an unconfigured GetItVsync.'),
        ErrorDescription(
          'UseIt.$name() is intended to listen to an existing value, '
          'but the $getItVsync has not been set up.',
        ),
        ErrorHint(
          'Consider setting up an ancestor widget to manage the $getItVsync, '
          'or calling useIt() instead of UseIt.$name().',
        ),
        ErrorHint(
          'Alternatively, call UseIt.$name(checkVsync: false) to ignore this warning.',
        ),
      ]);
    }

    return true;
  }());
}
