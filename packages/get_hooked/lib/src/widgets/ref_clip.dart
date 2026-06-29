import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/ref_element.dart';

/// Signature for the callback passed to [RefClip].
typedef RefClipCallback<T> = T Function(ClipRef ref);

/// Interface used in the [RefClipCallback].
abstract interface class ClipRef implements Ref {
  /// The widget's size.
  abstract final Size size;
}

/// Clips the [child] based on a [RefClipCallback].
abstract class RefClip extends SingleChildRenderObjectWidget {
  /// Clips the [child] based on the [Path] returned by the [RefClipCallback].
  ///
  /// The callback can return `null`, in which case no clipping takes place.
  const factory RefClip.path(
    RefClipCallback<Path?> clip, {
    Key? key,
    Clip clipBehavior,
    Widget? child,
  }) = _Path;

  /// Clips the [child] based on the [ShapeBorder] returned by the [RefClipCallback].
  ///
  /// The callback can return `null`, in which case no clipping takes place.
  const factory RefClip.shape(
    RefClipCallback<ShapeBorder?> clip, {
    Key? key,
    Clip clipBehavior,
    Widget? child,
  }) = _Shape;

  /// Initializes fields for subclasses.
  const RefClip._({super.key, required this.clipBehavior, super.child});

  /// Controls how to clip, including whether to apply anti-aliasing.
  final Clip clipBehavior;
}

sealed class _RefClip<T extends Object> extends RefClip {
  const _RefClip(this.clip, {super.key, required super.clipBehavior, super.child}) : super._();

  final RefClipCallback<T?> clip;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRefClip(
      clipBehavior: clipBehavior,
      newSize: (context as _ClipElement)._newSize,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRefClip).clipBehavior = clipBehavior;
  }
}

sealed class _ClipElement extends SingleChildComputeElement<_RenderRefClip> implements ClipRef {
  _ClipElement(_RefClip<Object> super.widget);

  @override
  Size size = Size.zero;

  void _newSize(Size size) {
    this.size = size;
    recompute();
  }
}

class _Path extends _RefClip<Path> {
  const _Path(super.clip, {super.key, super.clipBehavior = Clip.hardEdge, super.child});

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderRefClip).clipBehavior = clipBehavior;
  }

  @override
  SingleChildRenderObjectElement createElement() => _PathElement(this);
}

class _PathElement extends _ClipElement {
  _PathElement(super.widget);

  @override
  void recompute() {
    renderer.path = (widget as _Path).clip(this);
  }
}

class _Shape extends _RefClip<ShapeBorder> {
  const _Shape(super.clip, {super.key, super.clipBehavior = Clip.hardEdge, super.child});

  @override
  RenderClipRect createRenderObject(BuildContext context) {
    return RenderClipRect(clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipRect renderObject) {
    renderObject.clipBehavior = clipBehavior;
  }

  @override
  SingleChildRenderObjectElement createElement() => _ShapeElement(this);
}

class _ShapeElement extends _ClipElement {
  _ShapeElement(super.widget);

  ShapeBorder? shape;

  @override
  void recompute() {
    final ShapeBorder? newShape = (widget as _Shape).clip(this);
    if (newShape != shape) {
      renderer.path = (shape = newShape)?.getOuterPath(Offset.zero & size);
    }
  }
}

class _RenderRefClip extends RenderProxyBox {
  _RenderRefClip({Clip clipBehavior = Clip.antiAlias, required this.newSize})
    : _clipBehavior = clipBehavior,
      super(null);

  Path? get path => _path;
  Path? _path;
  set path(Path? newValue) {
    _path = newValue;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  final ValueChanged<Size> newSize;

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    final Size? oldSize = hasSize ? size : null;
    super.performLayout();
    if (oldSize != size) {
      newSize(size);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return (_path?.contains(position) ?? true) && super.hitTest(result, position: position);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    return clipBehavior == Clip.none ? null : _path?.getBounds();
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    if (_path case final path? when clipBehavior != Clip.none && child != null) {
      layer = context.pushClipPath(
        needsCompositing,
        offset,
        Offset.zero & size,
        path,
        super.paint,
        clipBehavior: clipBehavior,
        oldLayer: layer as ClipPathLayer?,
      );
      return;
    }

    super.paint(context, offset);
    layer = null;
  }

  Paint? _debugPaint;
  TextPainter? _debugText;
  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    if (kDebugMode && child != null) {
      super.debugPaintSize(context, offset);
      if (clipBehavior != Clip.none) {
        context.canvas.drawPath(
          _path?.shift(offset) ?? Path()
            ..addRect(offset & size),
          _debugPaint ??= Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              const Offset(10.0, 10.0),
              <Color>[
                const Color(0x00000000),
                const Color(0xFFFF00FF),
                const Color(0xFFFF00FF),
                const Color(0x00000000),
              ],
              <double>[0.25, 0.25, 0.75, 0.75],
              TileMode.repeated,
            )
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
        (_debugText ??= TextPainter(
          text: const TextSpan(
            text: '✂',
            style: TextStyle(color: Color(0xFFFF00FF), fontSize: 14.0),
          ),
          textDirection: TextDirection.rtl, // doesn't matter, it's one character
        )..layout()).paint(context.canvas, offset);
      }
    }
  }

  @override
  void dispose() {
    _debugText?.dispose();
    _debugText = null;
    super.dispose();
  }
}
