// ignore_for_file: invalid_use_of_visible_for_testing_member, these hooks are meant to access internal stuff :)
// ignore_for_file: avoid_positional_boolean_parameters, private hook functions are more readable this way

part of '../ref.dart';

T _selectAll<T>(T value) => value;
void _emptyListener(AnimationStatus status) {}

class _SelectHook<T, Result> extends Hook<Result> {
  const _SelectHook(this.listenable, this.selector, this.watching);

  final ValueListenable<T> listenable;
  final Result Function(T value) selector;
  final bool watching;

  @override
  _SelectState<T, Result> createState() => _SelectState<T, Result>();
}

class _SelectState<T, Result> extends HookState<Result, _SelectHook<T, Result>> {
  late ValueListenable<T> listenable = hook.listenable;
  late bool watching = hook.watching;
  late Result previous = result;
  Result get result => hook.selector(listenable.value);

  @override
  void initHook() {
    if (watching) listenable.addListener(markMayNeedRebuild);
  }

  @override
  void didUpdateHook(_SelectHook<T, Result> oldHook) {
    final ValueListenable<T> newListenable = hook.listenable;
    final bool newWatching = hook.watching;
    if (newListenable != listenable) {
      listenable.removeListener(markMayNeedRebuild);
      listenable = newListenable;
      if (newWatching) listenable.addListener(markMayNeedRebuild);
    } else if (!newWatching) {
      listenable.removeListener(markMayNeedRebuild);
    } else if (!watching) {
      listenable.addListener(markMayNeedRebuild);
    }
    watching = newWatching;
  }

  @override
  void dispose() => listenable.removeListener(markMayNeedRebuild);

  @override
  bool shouldRebuild() => hook.watching && result != previous;

  @override
  Result build(BuildContext context) => previous = result;
}

class _VsyncAttachHook extends Hook<void> {
  const _VsyncAttachHook(this.get);

  final GetVsyncAny get;

  @override
  _VsyncAttachState createState() => _VsyncAttachState();
}

class _VsyncAttachState extends HookState<void, _VsyncAttachHook> {
  late GetVsyncAny get = hook.get;
  late Vsync vsync = get.vsync;

  @override
  void initHook() {
    vsync.context = Vsync.auto;
  }

  @override
  void didUpdateHook(_VsyncAttachHook oldHook) {
    final GetVsyncAny newGet = hook.get;

    if (newGet != get) {
      dispose();
      get = newGet;
      vsync = get.vsync;
      initHook();
    }
  }

  @override
  void dispose() {
    if (vsync.context == context) vsync.context = null;
  }

  @override
  void build(BuildContext context) {
    vsync.ticker?.updateNotifier(context);
  }
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
