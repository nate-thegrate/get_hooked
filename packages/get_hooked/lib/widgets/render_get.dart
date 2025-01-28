// dart format width=108

// ignore_for_file: use_to_and_as_if_applicable, we're overriding methods lol

import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';

import '../ref/ref.dart';

/// Extend this class to create a widget with a single child.
abstract class RenderGetBase extends SingleChildRenderObjectWidget {
  /// `const` constructor for subclasses :)
  const RenderGetBase({super.key, super.child});

  /// The [Get] object attached to this widget.
  ///
  /// This getter should always return the same object.
  GetAny get get;

  /// Creates a [RenderObject] (which is then passed to [createRenderObject]).
  RenderObject render(BuildContext context);

  /// Used to make a closure for [Listenable.addListener].
  void listen(covariant RenderObject renderObject);

  @override
  RenderObject createRenderObject(BuildContext context) {
    final RenderObject renderObject = render(context as _RenderGetElement);
    context.listener = () => listen(renderObject);
    return renderObject;
  }

  @override
  SingleChildRenderObjectElement createElement() => _RenderGetElement(this, get);
}

/// Extend this class to create a widget with a single child.
abstract class RenderScopedGetBase<T> extends SingleChildRenderObjectWidget {
  /// `const` constructor for subclasses :)
  const RenderScopedGetBase({super.key, super.child});

  /// The [Get] object attached to this widget.
  ///
  /// This getter should always return the same object.
  GetT<T> get get;

  /// Creates a [RenderObject] (which is then passed to [createRenderObject]).
  RenderObject render(BuildContext context, T value);

  /// Used to make a closure for [Listenable.addListener].
  void listen(covariant RenderObject renderObject, T value);

  @override
  RenderObject createRenderObject(BuildContext context) {
    final RenderObject renderObject = render(
      context as _RenderScopedGetElement<T>,
      (context.scopedGet = GetScope.of(context, get)).value,
    );
    context.listener = () => listen(renderObject, context.scopedGet.value);
    return renderObject;
  }

  @override
  SingleChildRenderObjectElement createElement() => _RenderScopedGetElement(this, get);
}

/// A simple widget that subscribes to a [Get] object and updates a [RenderObject] accordingly.
abstract final class RenderGet<Render extends RenderObject> implements SingleChildRenderObjectWidget {
  /// A simple widget that subscribes to a [Get] object and updates a [RenderObject] accordingly.
  const factory RenderGet({
    Key? key,
    required GetAny get,
    required Render Function(BuildContext context) render,
    required void Function(Render render) listen,
    Widget? child,
  }) = _RenderGet<Render>;

  /// A simple widget that subscribes to a [Get] object and updates a [RenderObject] accordingly.
  ///
  /// This constructor ensures that the appropriate object from an ancestor [GetScope] is used,
  /// if applicable.
  @factory
  static RenderGet<Render> scoped<Render extends RenderObject, T>({
    Key? key,
    required GetT<T> get,
    required Render Function(BuildContext context, T value) render,
    required void Function(Render render, T value) listen,
    Widget? child,
  }) {
    return _RenderScopedGet<T, Render>(key: key, get: get, render: render, listen: listen, child: child);
  }
}

final class _RenderGet<Render extends RenderObject> extends RenderGetBase implements RenderGet<Render> {
  const _RenderGet({
    super.key,
    required this.get,
    required Render Function(BuildContext context) render,
    required void Function(Render render) listen,
    super.child,
  }) : _render = render,
       _listen = listen;

  @override
  final GetAny get;

  final Render Function(BuildContext context) _render;

  @override
  Render render(BuildContext context) => _render(context);

  final void Function(Render render) _listen;

  @override
  void listen(Render render) => _listen(render);
}

final class _RenderScopedGet<T, Render extends RenderObject> extends RenderScopedGetBase<T>
    implements RenderGet<Render> {
  const _RenderScopedGet({
    super.key,
    required this.get,
    required void Function(Render render, T value) listen,
    required Render Function(BuildContext context, T value) render,
    super.child,
  }) : _listen = listen,
       _render = render;

  @override
  final GetT<T> get;

  final void Function(Render render, T value) _listen;

  @override
  void listen(Render renderObject, T value) => _listen(renderObject, value);

  final Render Function(BuildContext context, T value) _render;
  @override
  Render render(BuildContext context, T value) => _render(context, value);
}

class _RenderGetElement extends SingleChildRenderObjectElement {
  _RenderGetElement(super.widget, this.get) : vsync = get is GetVsyncAny ? get.maybeVsync : null;

  final GetAny get;

  final Vsync? vsync;

  /// The callback passed to [Listenable.addListener].
  late final VoidCallback listener;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    get.hooked.addListener(listener);
  }

  @override
  void activate() {
    super.activate();
    vsync?.ticker?.updateNotifier(this);
  }

  @override
  void unmount() {
    vsync?.context = null;
    get.hooked.removeListener(listener);
    super.unmount();
  }
}

class _RenderScopedGetElement<T> extends SingleChildRenderObjectElement {
  _RenderScopedGetElement(super.widget, this.get);

  final GetT<T> get;
  late GetT<T> scopedGet;

  Vsync? vsync;

  /// The callback passed to [Listenable.addListener].
  late VoidCallback listener;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    scopedGet.hooked.addListener(listener);
  }

  void resync(GetAny get) {
    final Vsync? vsync = get is GetVsyncAny ? get.maybeVsync : null;
    if (vsync == this.vsync) return;

    if (this.vsync case final oldVsync? when oldVsync.context == this) {
      oldVsync.context = null;
    }
    if (vsync != null && (vsync.context == null || vsync.context == this)) {
      vsync
        ..context ??= this
        ..ticker?.updateNotifier(this)
        ..updateStyleNotifier(this);
    }
  }

  @override
  void activate() {
    final GetT<T> scoped = scopedGet;
    super.activate();
    if (GetScope.of(this, get) == scoped) {
      vsync
        ?..ticker?.updateNotifier(this)
        ..updateStyleNotifier(this);
    }
  }

  @override
  void reassemble() {
    scopedGet.hooked
      ..removeListener(listener)
      ..addListener(
        listener = () => (widget as RenderScopedGetBase<T>).listen(renderObject, scopedGet.value),
      );
    super.reassemble();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GetT<T> newGet = GetScope.of(this, get);
    if (newGet == scopedGet) return;

    scopedGet.hooked.removeListener(listener);
    scopedGet = newGet..hooked.addListener(listener);
    resync(scopedGet);
  }

  @override
  void unmount() {
    vsync?.context = null;
    scopedGet.hooked.removeListener(listener);
    super.unmount();
  }
}
