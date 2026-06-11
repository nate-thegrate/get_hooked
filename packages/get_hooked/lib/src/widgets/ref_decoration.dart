import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/vsync_mixin.dart';

import 'clipped_decorated_box.dart';

/// A variant of [Transform] that evaluates based on a [RefComputer<Matrix4>].
class RefDecoration extends SingleChildRenderObjectWidget {
  /// Initializes fields for subclasses.
  const RefDecoration(
    this.decorate, {
    super.key,
    this.position = DecorationPosition.background,
    this.clipBehavior = Clip.none,
    super.child,
  });

  /// Returns the decoration to paint.
  ///
  /// Must be a [BoxDecoration] or [ShapeDecoration].
  final RefComputer<Decoration> decorate;

  /// Whether to paint this decoration in front of or behind the [child].
  final DecorationPosition position;

  /// Determines how the widget's [child] (and the child's descendants) are clipped.
  ///
  /// In order from cheapest to most expensive:
  /// - [Clip.none]: don't perform any clipping.
  /// - [Clip.hardEdge]: each pixel will either be fully visible or fully clipped.
  /// - [Clip.antiAlias]: boundary pixels might be made partially transparent,
  ///   in order to achieve a smoother appearance.
  /// - [Clip.antiAliasWithSaveLayer]: all clipped content is placed in its own layer
  ///   to prevent "bleeding-edge artifacts".
  final Clip clipBehavior;

  @override
  RenderClippedDecoration createRenderObject(BuildContext context) {
    return RenderClippedDecoration(
      decoration: const BoxDecoration(),
      clipBehavior: clipBehavior,
      position: position,
      configuration: createLocalImageConfiguration(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderClippedDecoration renderObject) {
    renderObject
      ..clipBehavior = clipBehavior
      ..position = position
      ..configuration = createLocalImageConfiguration(context);
  }

  @override
  SingleChildRenderObjectElement createElement() => _DecorationElement(this);
}

class _DecorationElement extends SingleChildComputeElement<RenderClippedDecoration> {
  _DecorationElement(super.widget);

  @override
  void recompute() {
    renderer.decoration = (widget as RefDecoration).decorate(this);
  }
}
