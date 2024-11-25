/// @docImport '../../utils/proxy_notifier.dart';
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_hooked/src/ref.dart';
import 'package:meta/meta.dart';

import '../get.dart';
import '_hooked.dart';

part 'renderer/paint.dart';
part 'renderer/decoration.dart';

/// Allows any [RenderObjectElement] to manage [Vsync] objects and subscribe to [Listenable]s.
///
/// {@template get_hooked.RenderHookElement}
/// All of the static methods defined in [Ref] ([Ref.watch], [Ref.vsync], etc.) can
/// be called within a "render Hook" widget's callbacks. Similar to [HookWidget.build],
/// these methods must be called unconditionally—but unlike the former, the order
/// doesn't matter. Generally, a [RenderHookElement] subscribes to changes during the
/// first [RenderObject.paint] based on which [Ref] methods are called;
/// these subscriptions remain active until this widget is detached from the tree.
/// {@endtemplate}
base mixin RenderHookElement on RenderObjectElement {
  /// Subtypes implement this method to return the [selector]'s value
  /// and trigger a re-render when the value changes.
  ///
  /// It often triggers [RenderObject.markNeedsPaint], but might instead call
  /// [RenderObject.markNeedsLayout], [RenderObject.markNeedsSemanticsUpdate], etc.
  T select<T>(Listenable listenable, ValueGetter<T> selector);

  /// Called when [Listenable] notifications should trigger updates unconditionally.
  void watch(Listenable listenable);

  /// Subtypes implement this method to clear out any flags relating to [Listenable]
  /// subscriptions, in order to re-subscribe.
  void didResetListeners();

  final _disposers = <VoidCallback>{};

  /// A subtype can call this method within [select] to subscribe to a [Listenable]
  /// and automatically terminate the subscription when the widget is detached from
  /// the tree.
  void listen(Listenable listenable, VoidCallback listener) {
    listenable.addListener(listener);
    _disposers.add(() => listenable.removeListener(listener));
  }

  final _vsyncs = <Vsync>{};

  /// Allows [Ref.vsync] to be used inside a [RenderObjectWidget]'s method.
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
    _hasScope = true; // Ensures that subscriptions are re-collected after a Hot Reload.
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
  void reassemble() {
    super.reassemble();
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

mixin _RenderHookWidget on SingleChildRenderObjectWidget {
  @override
  RenderObject createRenderObject(covariant BuildContext context);

  @override
  SingleChildRenderHookElement createElement();
}

/// Typically, a [RenderHookElement] is used for single-child widgets, which can
/// extend this class (primarily to look fancy).
///
/// {@macro get_hooked.RenderHookElement}
///
/// Additionally, [useContext] can be called from within a [RenderHookWidget]
/// method; however, it should be used with care: after subscribing to
/// an [InheritedWidget] (such as [MediaQuery]), any time the widget's
/// [BuildContext] receives a notification, it is reset and repainted
/// to ensure that the update is received. This can lead to big performance
/// costs; it's better to avoid referencing [useContext] when possible.
abstract class RenderHookWidget = SingleChildRenderObjectWidget with _RenderHookWidget;

/// A [SingleChildRenderObjectElement] with the [RenderHookElement] mixin.
abstract base class SingleChildRenderHookElement = SingleChildRenderObjectElement
    with RenderHookElement;
