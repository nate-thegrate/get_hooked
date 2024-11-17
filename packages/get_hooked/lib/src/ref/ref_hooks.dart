// ignore_for_file: invalid_use_of_visible_for_testing_member, these hooks are meant to access internal stuff :)
// ignore_for_file: avoid_positional_boolean_parameters, private hook functions are more readable this way

part of '../ref.dart';

T _selectAll<T>(T value) => value;
void _emptyListener(AnimationStatus status) {}

abstract class _DataSelect<Result> extends HookData<Result> {
  const _DataSelect({super.key, required this.watching});

  final bool watching;

  Listenable get hooked;

  Result get result;

  @override
  _SelectHook<Result> createHook() => _SelectHook();
}

class _Select1<Result, T> extends _DataSelect<Result> {
  const _Select1(this.hooked, this.selector, {required super.watching}) : super(key: hooked);

  @override
  final ValueListenable<T> hooked;
  final Result Function(T value) selector;

  @override
  Result get result => selector(hooked.value);
}

class _Select2<Result, L1, L2> extends _DataSelect<Result> {
  const _Select2(this.l1, this.l2, this.selector, {required super.watching})
    : super(key: (l1, l2));

  final L1 l1;
  final L2 l2;

  final Result Function(L1 l1, L2 l2) selector;

  @override
  Listenable get hooked => ProxyListenable(l1, l2);

  @override
  Result get result => selector(l1, l2);
}

class _Select3<Result, L1, L2, L3> extends _DataSelect<Result> {
  const _Select3(this.l1, this.l2, this.l3, this.selector, {required super.watching})
    : super(key: (l1, l2, l3));

  final L1 l1;
  final L2 l2;
  final L3 l3;

  final Result Function(L1 l1, L2 l2, L3 l3) selector;

  @override
  Listenable get hooked => ProxyListenable(l1, l2, l3);

  @override
  Result get result => selector(l1, l2, l3);
}

class _Select4<Result, L1, L2, L3, L4> extends _DataSelect<Result> {
  const _Select4(this.l1, this.l2, this.l3, this.l4, this.selector, {required super.watching})
    : super(key: (l1, l2, l3, l4));

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;

  final Result Function(L1 l1, L2 l2, L3 l3, L4 l4) selector;

  @override
  Listenable get hooked => ProxyListenable(l1, l2, l3, l4);

  @override
  Result get result => selector(l1, l2, l3, l4);
}

class _Select5<Result, L1, L2, L3, L4, L5> extends _DataSelect<Result> {
  const _Select5(
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    this.l5,
    this.selector, {
    required super.watching,
  }) : super(key: (l1, l2, l3, l4, l5));

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;

  final Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5) selector;

  @override
  Listenable get hooked => ProxyListenable(l1, l2, l3, l4, l5);

  @override
  Result get result => selector(l1, l2, l3, l4, l5);
}

class _Select6<Result, L1, L2, L3, L4, L5, L6> extends _DataSelect<Result> {
  const _Select6(
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    this.l5,
    this.l6,
    this.selector, {
    required super.watching,
  }) : super(key: (l1, l2, l3, l4, l5, l6));

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;
  final L6 l6;

  final Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6) selector;

  @override
  Listenable get hooked => ProxyListenable(l1, l2, l3, l4, l5, l6);

  @override
  Result get result => selector(l1, l2, l3, l4, l5, l6);
}

class _Select7<Result, L1, L2, L3, L4, L5, L6, L7> extends _DataSelect<Result> {
  const _Select7(
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    this.l5,
    this.l6,
    this.l7,
    this.selector, {
    required super.watching,
  }) : super(key: (l1, l2, l3, l4, l5, l6, l7));

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;
  final L6 l6;
  final L7 l7;

  final Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7) selector;

  @override
  Listenable get hooked => ProxyListenable(l1, l2, l3, l4, l5, l6, l7);

  @override
  Result get result => selector(l1, l2, l3, l4, l5, l6, l7);
}

class _Select8<Result, L1, L2, L3, L4, L5, L6, L7, L8> extends _DataSelect<Result> {
  const _Select8(
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    this.l5,
    this.l6,
    this.l7,
    this.l8,
    this.selector, {
    required super.watching,
  }) : super(key: (l1, l2, l3, l4, l5, l6, l7, l8));

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;
  final L6 l6;
  final L7 l7;
  final L8 l8;

  final Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8) selector;

  @override
  Listenable get hooked => ProxyListenable(l1, l2, l3, l4, l5, l6, l7, l8);

  @override
  Result get result => selector(l1, l2, l3, l4, l5, l6, l7, l8);
}

class _Select9<Result, L1, L2, L3, L4, L5, L6, L7, L8, L9> extends _DataSelect<Result> {
  const _Select9(
    this.l1,
    this.l2,
    this.l3,
    this.l4,
    this.l5,
    this.l6,
    this.l7,
    this.l8,
    this.l9,
    this.selector, {
    required super.watching,
  }) : super(key: (l1, l2, l3, l4, l5, l6, l7, l8, l9));

  final L1 l1;
  final L2 l2;
  final L3 l3;
  final L4 l4;
  final L5 l5;
  final L6 l6;
  final L7 l7;
  final L8 l8;
  final L9 l9;

  final Result Function(L1 l1, L2 l2, L3 l3, L4 l4, L5 l5, L6 l6, L7 l7, L8 l8, L9 l9) selector;

  @override
  Listenable get hooked => ProxyListenable(l1, l2, l3, l4, l5, l6, l7, l8, l9);

  @override
  Result get result => selector(l1, l2, l3, l4, l5, l6, l7, l8, l9);
}

class _SelectHook<Result> extends Hook<Result, _DataSelect<Result>> {
  late final Listenable listenable = data.hooked;
  late bool watching = data.watching;

  late Result previous = data.result;

  @override
  void initHook() {
    if (watching) listenable.addListener(markMayNeedRebuild);
  }

  @override
  void didUpdate(_DataSelect<Result> oldData) {
    final bool newWatching = data.watching;
    if (!newWatching) {
      listenable.removeListener(markMayNeedRebuild);
    } else if (!watching) {
      listenable.addListener(markMayNeedRebuild);
    }
  }

  @override
  void dispose() => listenable.removeListener(markMayNeedRebuild);

  @override
  bool shouldRebuild() => data.watching && data.result != previous;

  @override
  Result build() => previous = data.result;
}

class _VsyncAttachHook<Controls extends GetVsyncAny> extends Hook<void, Controls> {
  late GetVsyncAny get = data;
  late Vsync vsync = get.vsync;

  @override
  void initHook() {
    vsync.context = Vsync.auto;
  }

  @override
  void didUpdate(Controls oldData) {
    final GetVsyncAny newGet = data;

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
  void build() {
    vsync.ticker?.updateNotifier(context);
  }
}

/// Calls the [statusListener] whenever the [Animation.status] changes.
///
/// If the listener has a returned value, it will be returned by this hook
/// and updated whenever the status changes.
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
  void initHook() {
    animation.addStatusListener(statusUpdate);
  }

  @override
  void dispose() {
    animation.removeStatusListener(statusUpdate);
  }

  @override
  T build() => _result;
}
