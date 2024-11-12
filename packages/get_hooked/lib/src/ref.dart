part of '../get_hooked.dart';

/// A namespace for [Hook] functions that reference a [Get] object.
abstract final class Ref {
  /// Reads a [Get] object's value without subscribing to receive notifications.
  ///
  /// It's safe to call this method outside of a [HookWidget].
  static T read<T>(Get<T, ValueListenable<T>> get) => get.it.value;

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
    AnimationStatusListener? onStatusChange,
  }) {
    final ValueListenable<Object?> animation = get.it;
    useListenable(watch ? animation : null);
    if (animation is Animation && onStatusChange != null) {
      useAnimationStatus<void>(animation, onStatusChange);
    } else {
      useAnimationStatus<void>(null, _emptyListener);
    }
    use(_VsyncAttachHook(get));
    return get.controls;
  }
}

void _emptyListener(AnimationStatus status) {}

typedef _GetVsync = GetVsync<Object?, ValueListenable<Object?>, Object?>;

class _VsyncAttachHook extends Hook<void> {
  const _VsyncAttachHook(this.get);

  final _GetVsync get;

  @override
  _VsyncAttachState createState() => _VsyncAttachState();
}

class _VsyncAttachState extends HookState<void, _VsyncAttachHook> {
  late _GetVsync get = hook.get;

  @override
  void didUpdateHook(_VsyncAttachHook oldHook) {
    final _GetVsync newGet = hook.get;

    if (newGet != get) {
      final Vsync vsync = get.vsync;
      if (vsync.context == context) vsync.context = null;
      get = newGet..vsync.context = context;
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
      final method = 'Ref.$name';
      throw FlutterError.fromParts([
        ErrorSummary('$method() called with a non-attached Vsync.'),
        ErrorDescription(
          '$method() is intended to listen to an existing value, '
          'but the $getVsync has not been set up.',
        ),
        ErrorHint(
          'Consider setting up an ancestor widget with Ref.vsync(), '
          'or calling Ref.vsync() here instead of $method().',
        ),
        ErrorHint('Alternatively, call $method(checkVsync: false) to ignore this warning.'),
      ]);
    }

    return true;
  }());
}

/// Calls the [statusListener] whenever the [Animation.status] changes.
///
/// If the listener has a returned value, it will be returned by this hook
/// and updated whenever the status changes.
///
/// If `null` is passed as the [animation], the hook will stop listening to
/// the status.
T useAnimationStatus<T>(
  Animation<Object?>? animation,
  T Function(AnimationStatus status) statusListener,
) {
  return use(_AnimationStatusHook(statusListener, animation));
}

class _AnimationStatusHook<T> extends Hook<T> {
  const _AnimationStatusHook(this.statusListener, this.animation);

  final Animation<Object?>? animation;
  final T Function(AnimationStatus) statusListener;

  @override
  _AnimationStatusHookState<T> createState() => _AnimationStatusHookState();
}

class _AnimationStatusHookState<T> extends HookState<T, _AnimationStatusHook<T>> {
  late Animation<Object?>? animation = hook.animation;
  late T _result = hook.statusListener(animation?.status ?? AnimationStatus.dismissed);

  void statusUpdate(AnimationStatus status) {
    final T result = hook.statusListener(status);
    if (result != _result) {
      setState(() => _result = result);
    }
  }

  @override
  void initHook() {
    animation?.addStatusListener(statusUpdate);
  }

  @override
  void didUpdateHook(_AnimationStatusHook<T> oldHook) {
    final Animation<Object?>? newAnimation = hook.animation;
    if (newAnimation != animation) {
      animation?.removeStatusListener(statusUpdate);
      animation = newAnimation?..addStatusListener(statusUpdate);
    }
  }

  @override
  void dispose() {
    animation?.removeStatusListener(statusUpdate);
  }

  @override
  T build(BuildContext context) => _result;
}
