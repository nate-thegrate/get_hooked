import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A variation of [DecoratedBox] that allows specifying a [clipBehavior]
/// and re-renders without any need to rebuild a widget subtree.
abstract class ClippedDecoration extends SingleChildRenderObjectWidget {
  /// Initializes fields for subclasses.
  const ClippedDecoration({
    super.key,
    required this.decoration,
    this.position = DecorationPosition.background,
    this.clipBehavior = Clip.none,
    super.child,
  }) : assert(
         decoration is BoxDecoration || decoration is ShapeDecoration,
         '$decoration is not supported.\n'
         'Consider using a BoxDecoration or ShapeDecoration instead.',
       );

  /// What decoration to paint.
  ///
  /// Must be a [BoxDecoration] or [ShapeDecoration].
  final Decoration decoration;

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
      decoration: decoration,
      clipBehavior: clipBehavior,
      position: position,
      configuration: createLocalImageConfiguration(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderClippedDecoration renderObject) {
    renderObject
      ..decoration = decoration
      ..clipBehavior = clipBehavior
      ..position = position
      ..configuration = createLocalImageConfiguration(context);
  }
}

/// Paints a [Decoration].
class RenderClippedDecoration extends RenderProxyBox {
  /// Creates a decorated box.
  RenderClippedDecoration({
    required Decoration decoration,
    DecorationPosition position = DecorationPosition.background,
    ImageConfiguration configuration = ImageConfiguration.empty,
    Clip clipBehavior = Clip.none,
  }) : _decoration = decoration,
       _position = position,
       _clipBehavior = clipBehavior,
       _configuration = configuration;

  /// What decoration to paint.
  ///
  /// Must be a [BoxDecoration] or [ShapeDecoration].
  Decoration get decoration => _decoration;
  late Decoration _decoration;
  set decoration(Decoration value) {
    if (value == _decoration) {
      return;
    }
    _decoration = value;
    markNeedsPaint();
  }

  Paint? _backgroundFill;
  Rect? _backgroundFillRect;
  (Color?, Gradient?, BlendMode?) _currentData = const (null, null, null);

  /// Generates a [Paint] object to use in this render object's [paint] method.
  Paint backgroundFill(Rect rect) {
    final paint = Paint();
    final (Color? color, Gradient? gradient, BlendMode? blendMode) = _currentData;

    if (gradient != null) {
      paint.shader = gradient.createShader(rect);
    } else if (color != null) {
      paint.color = color;
    }
    if (blendMode != null) {
      paint.blendMode = blendMode;
    }
    return paint;
  }

  /// Whether to paint the decoration behind or in front of the child.
  DecorationPosition get position => _position;
  DecorationPosition _position;
  set position(DecorationPosition value) {
    if (value == _position) {
      return;
    }
    _position = value;
    markNeedsPaint();
  }

  /// The clipping to apply to descendant widgets.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    if (value == _clipBehavior) {
      return;
    }
    _clipBehavior = value;
    markNeedsPaint();
  }

  /// The settings to pass to the decoration when painting, so that it can
  /// resolve images appropriately. See [ImageProvider.resolve] and
  /// [BoxPainter.paint].
  ///
  /// The [ImageConfiguration.textDirection] field is also used by
  /// direction-sensitive [Decoration]s for painting and hit-testing.
  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    if (value == _configuration) {
      return;
    }
    _configuration = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    super.detach();
    // Since we're disposing of our painter, we won't receive change
    // notifications. We mark ourselves as needing paint so that we will
    // resubscribe to change notifications. If we didn't do this, then, for
    // example, animated GIFs would stop animating when a DecoratedBox gets
    // moved around the tree due to GlobalKey reparenting.
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) {
    return _decoration.hitTest(size, position, textDirection: configuration.textDirection);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(() {
      if (decoration case BoxDecoration(:final image) || ShapeDecoration(:final image)) {
        if (image == null) return true;
        throw UnsupportedError('Painting images is not yet supported.');
      }
      throw FlutterError.fromParts([
        ErrorSummary('Invalid HookDecoration: ${decoration.runtimeType}'),
        ErrorHint('Consider using a BoxDecoration or ShapeDecoration instead.'),
      ]);
    }());

    final ImageConfiguration filledConfiguration = configuration.copyWith(size: size);
    Rect rect = offset & size;

    final (Color?, Gradient?, BlendMode?) currentData = switch (decoration) {
      ShapeDecoration(:final Color? color, :final Gradient? gradient) => (color, gradient, null),
      BoxDecoration(
        :final Color? color,
        :final Gradient? gradient,
        :final BlendMode? backgroundBlendMode,
      ) =>
        (color, gradient, backgroundBlendMode),
      _ => (null, null, null),
    };

    if (rect != _backgroundFillRect || currentData != _currentData) {
      _backgroundFillRect = rect;
      _currentData = currentData;
      _backgroundFill = backgroundFill(rect);
    }
    final Paint paint = _backgroundFill ??= backgroundFill(rect);

    if (clipBehavior == Clip.antiAliasWithSaveLayer) {
      // Deflating here prevents bleeding-edge artifacts on the sides of the child.
      rect = (Offset.zero & size).deflate(0.5);
    }
    final Path clipPath = decoration.getClipPath(
      rect,
      filledConfiguration.textDirection ?? TextDirection.ltr,
    );

    switch (clipBehavior) {
      case Clip.antiAliasWithSaveLayer:
        layer = context.pushClipPath(
          needsCompositing,
          offset,
          rect,
          clipPath,
          (PaintingContext context, Offset offset) {
            if (position == DecorationPosition.background) {
              context.canvas.drawPaint(paint);
            }
            super.paint(context, offset);
            if (position == DecorationPosition.foreground) {
              context.canvas.drawPaint(paint);
            }
          },
          oldLayer: layer as ClipPathLayer?,
          clipBehavior: clipBehavior,
        );
      case Clip.antiAlias:
      case Clip.hardEdge:
        context.canvas
          ..save()
          ..clipPath(clipPath, doAntiAlias: clipBehavior == Clip.antiAlias);
        if (position == DecorationPosition.background) {
          context.canvas.drawPaint(paint);
        }
        super.paint(context, offset);
        if (position == DecorationPosition.foreground) {
          context.canvas.drawPaint(paint);
        }
        context.canvas.restore();
      case Clip.none:
        if (position == DecorationPosition.background) {
          context.canvas.drawPath(clipPath, paint);
        }
        super.paint(context, offset);
        if (position == DecorationPosition.foreground) {
          context.canvas.drawPath(clipPath, paint);
        }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(_decoration.toDiagnosticsNode(name: 'decoration'));
    properties.add(DiagnosticsProperty<ImageConfiguration>('configuration', configuration));
  }
}
