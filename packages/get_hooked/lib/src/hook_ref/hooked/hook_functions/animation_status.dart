part of '../hook_functions.dart';

/// Calls the [statusListener] whenever the [Animation.status] changes.
///
/// If the listener returns a value, it will be returned by this hook function
/// and will trigger a rebuild when it changes.
@optionalTypeArgs
T useAnimationStatus<T>(
  Animation<Object?> animation,
  T Function(AnimationStatus status) statusListener,
) {
  return use(
    _AnimationStatusHook<T>.new,
    data: (animation: animation, statusListener: statusListener),
    key: animation,
    debugLabel: 'useAnimationStatus',
  );
}

typedef _AnimationStatusData<T> =
    ({Animation<Object?> animation, T Function(AnimationStatus status) statusListener});

class _AnimationStatusHook<T> extends Hook<T, _AnimationStatusData<T>> {
  late Animation<Object?> animation = data.animation;
  late T _result = data.statusListener(animation.status);

  void statusUpdate(AnimationStatus status) {
    final T result = data.statusListener(status);
    if (result != _result) {
      setState(() => _result = result);
    }
  }

  @override
  void initHook() => animation.addStatusListener(statusUpdate);

  @override
  void dispose() => animation.removeStatusListener(statusUpdate);

  @override
  T build() => _result;
}
