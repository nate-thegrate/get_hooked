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
  Get<T, ValueListenable<T>> get get;

  /// Creates a [RenderObject] (which is then passed to [createRenderObject]).
  RenderObject render(BuildContext context, T value);

  /// Used to make a closure for [Listenable.addListener].
  void listen(covariant RenderObject renderObject, T value);

  @override
  RenderObject createRenderObject(BuildContext context) {
    final RenderObject renderObject = render(
      context as _RenderScopedGetElement<T>,
      context.scopedGet.value,
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
    required Get<T, ValueListenable<T>> get,
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
  final Get<T, ValueListenable<T>> get;

  final void Function(Render render, T value) _listen;

  @override
  void listen(Render renderObject, T value) => _listen(renderObject, value);

  final Render Function(BuildContext context, T value) _render;
  @override
  Render render(BuildContext context, T value) => _render(context, value);
}

class _RenderGetElement extends SingleChildRenderObjectElement {
  _RenderGetElement(super.widget, this.get) : vsync = get is GetVsyncAny ? get.vsync : null;

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

  final Get<T, ValueListenable<T>> get;
  late Get<T, ValueListenable<T>> scopedGet;

  Vsync? vsync;

  /// The callback passed to [Listenable.addListener].
  late final VoidCallback listener;

  @override
  void mount(Element? parent, Object? newSlot) {
    scopedGet = GetScope.of(this, get);
    super.mount(parent, newSlot);
    scopedGet.hooked.addListener(listener);
  }

  void resync() {
    if (scopedGet case GetVsyncAny(:final Vsync vsync)) {
      this.vsync =
          vsync
            ..context = Vsync.auto
            ..ticker?.updateNotifier(this);
    }
  }

  @override
  void activate() {
    super.activate();
    vsync?.ticker?.updateNotifier(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Get<T, ValueListenable<T>> newGet = GetScope.of(this, get);
    if (newGet == scopedGet) return;

    scopedGet.hooked.removeListener(listener);
    scopedGet = newGet..hooked.addListener(listener);
    resync();
  }

  @override
  void unmount() {
    vsync?.context = null;
    scopedGet.hooked.removeListener(listener);
    super.unmount();
  }
}
