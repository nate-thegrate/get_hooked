import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'signal_element.dart';

/// Signature for the callback passed to [SignalClip.path] / [SignalClip.shape].
///
/// The [size] is the widget's current size. Signals read via `.value` during
/// this callback are tracked automatically.
typedef SignalClipCallback<T> = T Function(BuildContext context, Size size);

/// Clips the [child] based on a [SignalClipCallback].
abstract class SignalClip extends SingleChildRenderObjectWidget {
  /// Clips the [child] based on the [Path] returned by the callback.
  ///
  /// The callback can return `null`, in which case no clipping takes place.
  const factory SignalClip.path(
    SignalClipCallback<Path?> clip, {
    Key? key,
    Clip clipBehavior,
    Widget? child,
  }) = _Path;

  /// Clips the [child] based on the [ShapeBorder] returned by the callback.
  ///
  /// The callback can return `null`, in which case no clipping takes place.
  const factory SignalClip.shape(
    SignalClipCallback<ShapeBorder?> clip, {
    Key? key,
    Clip clipBehavior,
    Widget? child,
  }) = _Shape;

  /// Initializes fields for subclasses.
  const SignalClip._({super.key, required this.clipBehavior, super.child});

  /// Controls how to clip, including whether to apply anti-aliasing.
  final Clip clipBehavior;
}

sealed class _SignalClip<T extends Object> extends SignalClip {
  const _SignalClip(this.clip, {super.key, required super.clipBehavior, super.child}) : super._();

  final SignalClipCallback<T?> clip;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSignalClip(
      clipBehavior: clipBehavior,
      newSize: (context as _ClipElement)._newSize,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSignalClip).clipBehavior = clipBehavior;
  }
}

sealed class _ClipElement extends SingleChildSignalElement<_RenderSignalClip> {
  _ClipElement(_SignalClip<Object> super.widget);

  Size get _clipSize => renderer.hasSize ? renderer.size : Size.zero;

  void _newSize(Size size) => trackAndRecompute();
}

class _Path extends _SignalClip<Path> {
  const _Path(super.clip, {super.key, super.clipBehavior = Clip.hardEdge, super.child});

  @override
  SingleChildRenderObjectElement createElement() => _PathElement(this);
}

class _PathElement extends _ClipElement {
  _PathElement(super.widget);

  @override
  void recompute() {
    renderer.path = (widget as _Path).clip(this, _clipSize);
  }
}

class _Shape extends _SignalClip<ShapeBorder> {
  const _Shape(super.clip, {super.key, super.clipBehavior = Clip.hardEdge, super.child});

  @override
  SingleChildRenderObjectElement createElement() => _ShapeElement(this);
}

class _ShapeElement extends _ClipElement {
  _ShapeElement(super.widget);

  ShapeBorder? shape;

  @override
  void recompute() {
    final Size size = _clipSize;
    final ShapeBorder? newShape = (widget as _Shape).clip(this, size);
    shape = newShape;
    // Always rebuild the path: size may have changed even when [shape] is equal.
    renderer.path = newShape?.getOuterPath(Offset.zero & size);
  }
}

class _RenderSignalClip extends RenderProxyBox {
  _RenderSignalClip({this._clipBehavior = Clip.antiAlias, required this.newSize}) : super(null);

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
          _path?.shift(offset) ??
              (Path()..addRect(offset & size)),
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
