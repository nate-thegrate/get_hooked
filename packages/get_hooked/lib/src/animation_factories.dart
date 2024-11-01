// ignore_for_file: deprecated_member_use

part of '../get_hooked.dart';

T _use<T extends Hooked>(
  T Function(BuildContext context) create,
  bool listen,
  bool autoDispose,
) {
  return use(_HookedHook<T>(create, listen, autoDispose));
}

class _HookedHook<T extends Hooked> extends Hook<T> {
  const _HookedHook(this.create, this.listen, this.autoDispose);

  final T Function(BuildContext context) create;
  final bool listen, autoDispose;

  @override
  _HookedState<T> createState() => _HookedState();
}

class _HookedState<T extends Hooked> extends HookState<T, _HookedHook<T>> {
  late final T hooked;

  void rebuild() => setState(() {});

  @override
  void initHook() {
    hooked = hook.create(context);
    animationMap.set(hooked, key: hooked.key);
    if (hook.listen) {
      hooked.addListener(rebuild);
    }
  }

  @override
  void didUpdateHook(_HookedHook<T> oldHook) {
    final shouldListen = hook.listen;
    if (shouldListen != oldHook.listen) {
      shouldListen ? hooked.addListener(rebuild) : hooked.removeListener(rebuild);
    }
  }

  @override
  void dispose() {
    if (hook.autoDispose) {
      hooked.dispose();
      animationMap.dispose(key: hooked.key);
    } else {
      hooked.removeListener(rebuild);
    }
  }

  @override
  T build(BuildContext context) => hooked;
}

class _AnimationController extends AnimationController with _HookedListeners<double> {
  _AnimationController({
    required this.vsync,
    required super.value,
    required super.duration,
    required super.reverseDuration,
    required super.lowerBound,
    required super.upperBound,
    required super.animationBehavior,
  }) : super(vsync: vsync);

  @override
  final Vsync vsync;

  @override
  void dispose() {
    _count = 0;
    super.dispose();
  }
}

class _ValueAnimation<T> extends ValueAnimation<T> with _HookedListeners<T> {
  _ValueAnimation({
    required this.vsync,
    required super.initialValue,
    required super.duration,
    required super.curve,
    required super.lerp,
    required super.animationBehavior,
  }) : super(vsync: vsync);

  @override
  final Vsync vsync;

  @override
  void dispose() {
    _count = 0;
    super.dispose();
  }
}

mixin _HookedListeners<T> on Animation<T> implements Hooked<T> {
  Vsync get vsync;

  @override
  Object get key => vsync.key;

  @override
  BuildContext? get context => vsync.context;

  int _count = 0;

  @override
  void addListener(VoidCallback listener) {
    _count++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _count--;
    super.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    _count++;
    super.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    _count--;
    super.removeStatusListener(listener);
  }

  @override
  bool get hasListeners => _count > 0;
}
