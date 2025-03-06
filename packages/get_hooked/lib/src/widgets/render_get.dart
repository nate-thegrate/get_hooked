// dart format width=108

// ignore_for_file: use_to_and_as_if_applicable, we're overriding methods lol

import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/element_vsync_mixin.dart';

import '../hook_ref/hook_ref.dart';

/// Extend this class to create a widget with a single child.
abstract class RenderGetBase extends SingleChildRenderObjectWidget {
  /// `const` constructor for subclasses :)
  const RenderGetBase({super.key, super.child});

  /// The [Get] object attached to this widget.
  ///
  /// This getter should always return the same object.
  Listenable get get;

  /// Creates a [RenderObject] (which is then passed to [createRenderObject]).
  RenderObject render(VsyncContext context);

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
  ValueListenable<T> get get;

  /// Creates a [RenderObject] (which is then passed to [createRenderObject]).
  RenderObject render(VsyncContext context, T value);

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
    required Listenable get,
    required Render Function(VsyncContext context) render,
    required void Function(Render render) listen,
    Widget? child,
  }) = _RenderGet<Render>;

  /// A simple widget that subscribes to a [Get] object and updates a [RenderObject] accordingly.
  ///
  /// This constructor ensures that the appropriate object from an ancestor [SubScope] is used,
  /// if applicable.
  @factory
  static RenderGet<Render> scoped<Render extends RenderObject, T>({
    Key? key,
    required ValueListenable<T> get,
    required Render Function(VsyncContext context, T value) render,
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
    required Render Function(VsyncContext context) render,
    required void Function(Render render) listen,
    super.child,
  }) : _render = render,
       _listen = listen;

  @override
  final Listenable get;

  final Render Function(VsyncContext context) _render;

  @override
  Render render(VsyncContext context) => _render(context);

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
    required Render Function(VsyncContext context, T value) render,
    super.child,
  }) : _listen = listen,
       _render = render;

  @override
  final ValueListenable<T> get;

  final void Function(Render render, T value) _listen;

  @override
  void listen(Render renderObject, T value) => _listen(renderObject, value);

  final Render Function(VsyncContext context, T value) _render;
  @override
  Render render(VsyncContext context, T value) => _render(context, value);
}

typedef _Animation = VsyncValue<Object?>;

class _RenderGetElement extends SingleChildRenderObjectElement with ElementVsync {
  _RenderGetElement(super.widget, this.get);

  final Listenable get;

  /// The callback passed to [Listenable.addListener].
  late final VoidCallback listener;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    get.addListener(listener);
    if (get case final _Animation animation) {
      registry.add(animation);
    }
  }

  @override
  void unmount() {
    if (get case final _Animation animation) {
      registry.remove(animation);
    }
    get.removeListener(listener);
    super.unmount();
  }
}

class _RenderScopedGetElement<T> extends SingleChildRenderObjectElement with ElementVsync {
  _RenderScopedGetElement(super.widget, this.get);

  final ValueListenable<T> get;
  late ValueListenable<T> scopedGet;

  /// The callback passed to [Listenable.addListener].
  late VoidCallback listener;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    scopedGet.addListener(listener);
    if (scopedGet case final _Animation animation) {
      registry.add(animation);
    }
  }

  @override
  void reassemble() {
    assert(() {
      scopedGet
        ..removeListener(listener)
        ..addListener(
          listener = () => (widget as RenderScopedGetBase<T>).listen(renderObject, scopedGet.value),
        );
      return true;
    }());
    super.reassemble();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ValueListenable<T> newGet = GetScope.of(this, get);
    if (newGet == scopedGet) return;

    scopedGet.removeListener(listener);
    scopedGet = newGet..addListener(listener);
  }

  @override
  void unmount() {
    scopedGet.removeListener(listener);
    super.unmount();
  }
}
