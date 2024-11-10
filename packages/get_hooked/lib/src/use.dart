// ignore_for_file: avoid_positional_boolean_parameters, makes private hook classes less readable

part of '../get_hooked.dart';

/// A namespace for [Hook] functions.
abstract final class Use {
  /// Don't use it.
  static V it<T, V extends ValueListenable<T>>(Get<T, V> get, {bool watch = false}) {
    final V it = get.it;
    useListenable(watch ? it : null);
    return it;
  }

  /// Watches a [Get] object and triggers a rebuild when a notification is sent.
  static T watch<T>(Get<T, ValueListenable<T>> get, {bool checkVsync = true}) {
    assert(() {
      useEffect(() => checkVsync ? _debugCheckVsync(get, 'watch') : null, [get, checkVsync]);
      return true;
    }());

    return useValueListenable(get.it);
  }

  /// Selects a value from a complex [Get] object and triggers a rebuild when
  /// the selected value changes.
  static Out select<In, Out>(
    Get<In, ValueListenable<In>> get,
    Out Function(In value) selector, {
    bool checkVsync = true,
  }) {
    assert(() {
      useEffect(() => checkVsync ? _debugCheckVsync(get, 'watch') : null, [get, checkVsync]);
      return true;
    }());

    final ValueListenable<In> it = get.it;
    return useListenableSelector(it, () => selector(it.value));
  }

  /// Provides an interface for controlling a [GetVsync] animation,
  /// and optionally rebuilds when the animation sends a notification.
  ///
  ///  * If [watch] is true, each notification sent by the animation
  ///    triggers a rebuild.
  ///  * If [attach] is true, the animation will use the current
  ///    [BuildContext] to determine whether its [Ticker] should be active.
  static Controls vsync<Controls>(
    GetVsync<Object?, ValueListenable<Object?>, Controls> get, {
    bool watch = false,
    bool attach = true,
  }) {
    useListenable(watch ? get.it : null);
    use(_VsyncAttachHook(get, attach));
    return get.controls;
  }
}

typedef _GetVsync = GetVsync<Object?, ValueListenable<Object?>, Object?>;

class _VsyncAttachHook extends Hook<void> {
  const _VsyncAttachHook(this.get, this.attach);

  final _GetVsync get;
  final bool attach;

  @override
  _VsyncAttachState createState() => _VsyncAttachState();
}

class _VsyncAttachState extends HookState<void, _VsyncAttachHook> {
  late _GetVsync get = hook.get;
  late bool attach = hook.attach;

  void _attach() {
    if (attach) get.attach(context);
  }

  void _detach() {
    final Vsync vsync = get.vsync;
    if (vsync.context == context) vsync.context = null;
  }

  @override
  void initHook() => _attach();

  @override
  void didUpdateHook(_VsyncAttachHook oldHook) {
    final _GetVsync newGet = hook.get;
    final bool newAttach = hook.attach;
    if (newGet != get) {
      _detach();
      attach = newAttach;
      _attach();
    } else if (newAttach != attach) {
      attach = newAttach;
      attach ? _attach() : _detach();
    }
  }

  @override
  void dispose() => get.vsync.context = null;

  @override
  void build(BuildContext context) {}
}

// ignore: prefer_void_to_null, to make useEffect() happy
Null _debugCheckVsync(Get<Object?, ValueListenable<Object?>>? get, String name) {
  assert(() {
    // ignore: strict_raw_type, too verbose!
    if (get case final GetVsync getVsync when getVsync.vsync.context == null) {
      final method = 'Use.$name';
      throw FlutterError.fromParts([
        ErrorSummary('$method() called with a non-attached Vsync.'),
        ErrorDescription(
          '$method() is intended to listen to an existing value, '
          'but the $getVsync has not been set up.',
        ),
        ErrorHint(
          'Consider setting up an ancestor widget with Use.vsync(), '
          'or calling Use.vsync() here instead of $method().',
        ),
        ErrorHint('Alternatively, call $method(checkVsync: false) to ignore this warning.'),
      ]);
    }

    return true;
  }());
}
