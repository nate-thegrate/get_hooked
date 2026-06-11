import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A variation of [DecoratedBox] that allows specifying a [clipBehavior].
class ClippedDecoration extends SingleChildRenderObjectWidget {
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
       _configuration = configuration {
    _imagePainter = switch (decoration) {
      BoxDecoration(:final image?) ||
      ShapeDecoration(:final image?) => image.createPainter(markNeedsPaint),
      _ => null,
    };
  }

  /// What decoration to paint.
  ///
  /// Must be a [BoxDecoration] or [ShapeDecoration].
  Decoration get decoration => _decoration;
  Decoration _decoration;
  set decoration(Decoration value) {
    if (value == _decoration) {
      return;
    }
    if (value case BoxDecoration(:final image) || ShapeDecoration(:final image)) {
      if (_decoration
          case BoxDecoration(image: final oldImage) || ShapeDecoration(image: final oldImage)
          when image != oldImage) {
        _imagePainter?.dispose();
        _imagePainter = image?.createPainter(markNeedsPaint);
      }
      _decoration = value;
      markNeedsPaint();
    } else {
      assert(
        throw FlutterError.fromParts([
          ErrorSummary('Invalid decoration: ${value.runtimeType}'),
          ErrorHint('Consider using a BoxDecoration or ShapeDecoration instead.'),
        ]),
      );
    }
  }

  Paint? _backgroundFill;
  Rect? _backgroundFillRect;
  (Color?, Gradient?, BlendMode?) _fillData = const (null, null, null);

  /// Generates a [Paint] object to use in this render object's [paint] method.
  Paint? backgroundFill(Rect rect) {
    final paint = Paint();
    final (Color? color, Gradient? gradient, BlendMode? blendMode) = _fillData;

    if (gradient != null) {
      paint.shader = gradient.createShader(rect);
    } else if (color != null) {
      paint.color = color;
    } else {
      return null;
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

  DecorationImagePainter? _imagePainter;

  @override
  void detach() {
    super.detach();
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) {
    return _decoration.hitTest(size, position, textDirection: configuration.textDirection);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(() {
      if (decoration case BoxDecoration() || ShapeDecoration()) {
        return true;
      }
      throw FlutterError.fromParts([
        ErrorSummary('Invalid decoration: ${decoration.runtimeType}'),
        ErrorHint('Consider using a BoxDecoration or ShapeDecoration instead.'),
      ]);
    }());

    final ImageConfiguration filledConfiguration = configuration.copyWith(size: size);

    final (Color?, Gradient?, BlendMode?) fillData = switch (decoration) {
      ShapeDecoration(:final Color? color, :final Gradient? gradient)
          when (color ?? gradient) != null =>
        (color, gradient, null),
      BoxDecoration(
        :final Color? color,
        :final Gradient? gradient,
        :final BlendMode? backgroundBlendMode,
      )
          when (color ?? gradient) != null =>
        (color, gradient, backgroundBlendMode),
      _ => const (null, null, null),
    };

    Rect rect = Offset.zero & size;

    if (fillData == const (null, null, null)) {
      _backgroundFill = null;
    } else if (rect != _backgroundFillRect || fillData != _fillData) {
      _backgroundFillRect = rect;
      _fillData = fillData;
      _backgroundFill = backgroundFill(rect);
    }

    if (clipBehavior == .antiAliasWithSaveLayer) {
      // Deflating here prevents bleeding-edge artifacts on the sides of the child.
      rect = rect.deflate(0.5);
    }

    final Paint? paint = _backgroundFill;
    final Path clipPath = decoration.getClipPath(rect, filledConfiguration.textDirection ?? .ltr);

    // Paint shadows before clipping, so that shadows can extend beyond the clip boundary.
    switch (decoration) {
      case ShapeDecoration(:final ShapeBorder shape, :final List<BoxShadow> shadows)
          when shadows.isNotEmpty:
        for (final BoxShadow boxShadow in shadows) {
          final Paint paint = boxShadow.toPaint();
          final Rect bounds = (offset & size)
              .shift(boxShadow.offset)
              .inflate(boxShadow.spreadRadius);

          if (kDebugMode && debugDisableShadows && boxShadow.blurStyle == .outer) {
            context.canvas
              ..save()
              ..clipRect(bounds);
          }

          bool debugHandleDisabledShadowStart(BoxShadow boxShadow, Path path) {
            if (kDebugMode && debugDisableShadows && boxShadow.blurStyle == .outer) {
              context.canvas
                ..save()
                ..clipPath(
                  Path()
                    ..fillType = PathFillType.evenOdd
                    ..addRect(Rect.largest)
                    ..addPath(path, Offset.zero),
                );
            }
            return true;
          }

          bool debugHandleDisabledShadowEnd(BoxShadow boxShadow) {
            if (kDebugMode && debugDisableShadows && boxShadow.blurStyle == .outer) {
              context.canvas.restore();
            }
            return true;
          }

          if (shape.preferPaintInterior) {
            for (final BoxShadow shadow in shadows) {
              final Rect bounds = (offset & size)
                  .shift(shadow.offset)
                  .inflate(shadow.spreadRadius);
              assert(
                debugHandleDisabledShadowStart(
                  shadow,
                  shape.getOuterPath(bounds, textDirection: configuration.textDirection),
                ),
              );
              shape.paintInterior(
                context.canvas,
                bounds,
                paint,
                textDirection: configuration.textDirection,
              );
              assert(debugHandleDisabledShadowEnd(shadow));
            }
          } else {
            for (final BoxShadow shadow in shadows) {
              final Path path = shape.getOuterPath(
                (offset & size).shift(shadow.offset).inflate(shadow.spreadRadius),
                textDirection: configuration.textDirection,
              );
              assert(debugHandleDisabledShadowStart(shadow, path));
              context.canvas.drawPath(path, paint);
              assert(debugHandleDisabledShadowEnd(shadow));
            }
          }

          if (kDebugMode && debugDisableShadows && boxShadow.blurStyle == .outer) {
            context.canvas.restore();
          }
        }
      case BoxDecoration(
            :final BoxShape shape,
            :final BorderRadiusGeometry? borderRadius,
            boxShadow: final List<BoxShadow> shadows?,
          )
          when shadows.isNotEmpty:
        for (final BoxShadow boxShadow in shadows) {
          final Paint paint = boxShadow.toPaint();
          final Rect bounds = (offset & size)
              .shift(boxShadow.offset)
              .inflate(boxShadow.spreadRadius);
          if (kDebugMode && debugDisableShadows && boxShadow.blurStyle == .outer) {
            context.canvas
              ..save()
              ..clipRect(bounds);
          }

          switch (shape) {
            case BoxShape.circle:
              assert(borderRadius == null);
              final Offset center = bounds.center;
              final double radius = bounds.shortestSide / 2.0;
              context.canvas.drawCircle(center, radius, paint);
            case BoxShape.rectangle:
              if (borderRadius case null || BorderRadius.zero) {
                context.canvas.drawRect(bounds, paint);
              } else {
                context.canvas.drawRRect(
                  borderRadius.resolve(configuration.textDirection).toRRect(bounds),
                  paint,
                );
              }
          }
          if (kDebugMode && debugDisableShadows && boxShadow.blurStyle == .outer) {
            context.canvas.restore();
          }
        }
    }

    switch (clipBehavior) {
      case .hardEdge || .antiAlias || .antiAliasWithSaveLayer:
        layer = context.pushClipPath(
          needsCompositing,
          offset,
          rect,
          clipPath,
          (PaintingContext context, Offset offset) {
            if (position == .background) {
              if (paint != null) context.canvas.drawPaint(paint);
              _imagePainter?.paint(context.canvas, offset & size, null, configuration);
            }
            super.paint(context, offset);
            if (position == .foreground) {
              if (paint != null) context.canvas.drawPaint(paint);
              _imagePainter?.paint(context.canvas, offset & size, null, configuration);
            }
          },
          oldLayer: layer as ClipPathLayer?,
          clipBehavior: clipBehavior,
        );

      case .none:
        final Path path = clipPath.shift(offset);
        if (position == .background) {
          if (paint != null) context.canvas.drawPath(path, paint);
          _imagePainter?.paint(context.canvas, offset & size, path, configuration);
        }
        super.paint(context, offset);
        if (position == .foreground) {
          if (paint != null) context.canvas.drawPath(path, paint);
          _imagePainter?.paint(context.canvas, offset & size, path, configuration);
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
