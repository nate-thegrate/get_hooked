/// @docImport '../../utils/proxy_notifier.dart';
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_hooked/src/ref.dart';

import '../get.dart';
import '_hooked.dart';

part 'renderer/paint.dart';
part 'renderer/decoration.dart';

mixin RenderHookElement on Element {
  T select<T>(Listenable listenable, ValueGetter<T> selector);

  void didResetListeners();

  final _disposers = <VoidCallback>{};
  void listen(Listenable listenable, VoidCallback listener) {
    listenable.addListener(listener);
    _disposers.add(() => listenable.removeListener(listener));
  }

  final _vsyncs = <Vsync>{};
  void vsync(Vsync vsync) {
    _vsyncs.add(vsync..context = Vsync.auto);
  }

  late bool _hasScope;
  bool get _hasScopeNow => getInheritedWidgetOfExactType<ScopeModel>()?.map.isNotEmpty ?? false;
  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _hasScope = _hasScopeNow;
  }

  void _resetListeners() {
    final bool hasScope = _hasScopeNow;
    if (_hasScope || hasScope) {
      for (final VoidCallback dispose in _disposers) {
        dispose();
      }
      didResetListeners();
      _hasScope = hasScope;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetListeners();
  }

  @override
  void activate() {
    super.activate();
    for (final Vsync(:context, :ticker) in _vsyncs) {
      if (context == Vsync.auto) {
        ticker?.updateNotifier(this);
      }
    }
    _resetListeners();
  }

  @override
  void unmount() {
    for (final VoidCallback dispose in _disposers) {
      dispose();
    }
    for (final Vsync vsync in _vsyncs) {
      if (vsync.context == Vsync.auto) {
        vsync.context = null;
      }
    }
    super.unmount();
  }
}
