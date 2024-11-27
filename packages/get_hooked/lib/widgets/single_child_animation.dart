// dart format width=108

// ignore_for_file: use_to_and_as_if_applicable, we're overriding methods lol

import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';

import '../ref/ref.dart';

/// Extend this class to create a [RenderAnimationWidget] widget with a single child.
abstract class SingleChildAnimation<R extends RenderObject> extends SingleChildRenderObjectWidget
    with RenderAnimationWidget<R>, _SingleChildAnimation<R> {
  /// `const` constructor for subclasses :)
  const SingleChildAnimation({super.key, super.child});
}

class _SingleChildAnimationElement<R extends RenderObject> = SingleChildRenderObjectElement
    with AnimationElement<R>;

/// Configures a [RenderObjectWidget] for [Listenable] subscriptions.
mixin RenderAnimationWidget<Render extends RenderObject> on RenderObjectWidget {
  /// The [Listenable] attached to this widget.
  abstract final Listenable listenable;

  /// Used to make a closure for [Listenable.addListener].
  void listen(Render renderObject);

  /// Creates a [RenderObject] (which is then passed to [createRenderObject]).
  Render render(BuildContext context);

  @override
  Render createRenderObject(covariant AnimationElement<Render> context) {
    final Render render = this.render(context);
    context.listener = () => listen(render);
    return render;
  }

  @override
  void updateRenderObject(BuildContext context, Render renderObject) {}
}

mixin _SingleChildAnimation<Render extends RenderObject> on SingleChildRenderObjectWidget {
  @override
  SingleChildRenderObjectElement createElement() => _SingleChildAnimationElement(this);
}

/// Allows a [RenderObjectElement] to subscribe to a listenable.
mixin AnimationElement<Render extends RenderObject> on RenderObjectElement {
  /// The [Listenable] attached to the [RenderAnimationWidget].
  late final Listenable listenable = (widget as RenderAnimationWidget<Render>).listenable;

  /// The callback passed to [Listenable.addListener].
  late final VoidCallback listener;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    listenable.addListener(listener);
  }

  @override
  void unmount() {
    listenable.removeListener(listener);
    super.unmount();
  }
}

/// A [SingleChildRenderObjectWidget] that interfaces with a [Get] object.
abstract class RenderGetWidget<T, Render extends RenderObject> extends SingleChildAnimation<Render> {
  /// Creates a [SingleChildRenderObjectWidget] that interfaces with a [Get] object.
  const factory RenderGetWidget({
    Key? key,
    required Get<T, ValueListenable<T>> Function() getGetter,
    required Render Function(BuildContext context, T value) getRender,
    required void Function(Render renderObject, T value) updateRender,
    Widget? child,
  }) = _RenderGetWidget<T, Render>;

  /// Initializes fields for subclasses.
  const RenderGetWidget.constructor({super.key, super.child});

  /// The [Get] object associated with this widget.
  Get<T, ValueListenable<T>> get get;

  @override
  ValueListenable<T> get listenable => get.hooked;
}

class _RenderGetWidget<T, Render extends RenderObject> extends RenderGetWidget<T, Render> {
  const _RenderGetWidget({
    super.key,
    required this.getGetter,
    required this.getRender,
    required this.updateRender,
    super.child,
  }) : super.constructor();

  final ValueGetter<Get<T, ValueListenable<T>>> getGetter;

  final Render Function(BuildContext context, T value) getRender;

  @override
  Render render(BuildContext context) => getRender(context, get.value);

  final void Function(Render renderObject, T value) updateRender;

  @override
  void listen(Render renderObject) => updateRender(renderObject, get.value);

  @override
  Get<T, ValueListenable<T>> get get => getGetter();
}
