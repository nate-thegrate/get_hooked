part of '../renderer.dart';

/// A variation of [DecoratedBox] that allows specifying a [clipBehavior]
/// and re-renders without any need to rebuild a widget subtree.
abstract class HookDecoration extends RenderHookWidget {
  /// Initializes fields for subclasses.
  const HookDecoration({
    super.key,
    this.position = DecorationPosition.background,
    this.clipBehavior = Clip.none,
    super.child,
  });

  /// Creates a [HookDecoration] using the specified [ValueGetter] callback.
  ///
  /// The [decorate] callback allows this widget to subscribe to updates—it
  /// will repaint the widget while skipping the "build phase" entirely.
  ///
  /// {@macro get_hooked.RenderHookElement}
  const factory HookDecoration.compose({
    Key? key,
    required ValueGetter<Decoration> decorate,
    Clip clipBehavior,
    DecorationPosition position,
    Widget? child,
  }) = _HookDecoration;

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

  /// Configures the [Decoration] for this UI element.
  /// Unlike [DecoratedBox], this is a single
  ///
  /// Static [Ref] methods (e.g. [Ref.watch] and [Ref.read]) can be called from within
  /// [decorate].
  ///
  /// The returned value must be either a [BoxDecoration] or a [ShapeDecoration].
  Decoration decorate();

  @override
  SingleChildRenderHookElement createElement() => _HookDecorationElement(this);

  @internal
  @override
  // ignore: library_private_types_in_public_api, i don't care
  RenderHookDecoration createRenderObject(_HookDecorationElement context) {
    return RenderHookDecoration(
      decorator: context.decorator,
      clipBehavior: clipBehavior,
      position: position,
      configuration: createLocalImageConfiguration(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderHookDecoration renderObject) {
    renderObject
      ..clipBehavior = clipBehavior
      ..position = position
      ..configuration = createLocalImageConfiguration(context);
  }
}

class _HookDecoration extends HookDecoration {
  const _HookDecoration({
    super.key,
    required ValueGetter<Decoration> decorate,
    super.clipBehavior,
    super.position,
    super.child,
  }) : _decorate = decorate;
  final ValueGetter<Decoration> _decorate;

  @override
  Decoration decorate() => _decorate();
}

final class _HookDecorationElement extends SingleChildRenderHookElement {
  _HookDecorationElement(HookDecoration super.widget);

  @override
  void didResetListeners() {
    _handled = false;
    renderObject.markNeedsPaint();
  }

  bool _handled = false;

  Decoration decorator() {
    Hooked.renderer = this;
    final Decoration decoration = (widget as HookDecoration).decorate();
    Hooked.renderer = null;
    _handled = true;
    return decoration;
  }

  @override
  T select<T>(Listenable listenable, ValueGetter<T> selector) {
    T value = selector();
    if (_handled) return value;

    listen(listenable, () {
      final T newValue = selector();
      if (newValue != value) {
        value = newValue;
        renderObject.markNeedsPaint();
      }
    });
    return value;
  }
}

/// Paints a [Decoration].
class RenderHookDecoration extends RenderProxyBox {
  /// Creates a decorated box.
  RenderHookDecoration({
    required this.decorator,
    DecorationPosition position = DecorationPosition.background,
    ImageConfiguration configuration = ImageConfiguration.empty,
    Clip clipBehavior = Clip.none,
  })  : _position = position,
        _clipBehavior = clipBehavior,
        _configuration = configuration;

  /// This method is defined in the [RenderHookElement]
  /// and references [HookDecoration.decorate].
  final ValueGetter<Decoration> decorator;

  late Decoration _decoration;
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
    final Decoration decoration = _decoration = decorator();
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
      // For some reason, if we don't deflate here
      // there can be tiny clipping issues on the sides of the child.
      rect = (Offset.zero & size).deflate(0.5);
    }
    final Path clipPath = decoration.getClipPath(
      rect,
      filledConfiguration.textDirection ?? TextDirection.ltr,
    );

    void drawPaint([_, __]) {
      if (position == DecorationPosition.background) {
        context.canvas.drawPaint(paint);
      }
      super.paint(context, offset);
      if (position == DecorationPosition.foreground) {
        context.canvas.drawPaint(paint);
      }
    }

    switch (clipBehavior) {
      case Clip.antiAliasWithSaveLayer:
        layer = context.pushClipPath(
          needsCompositing,
          offset,
          rect,
          clipPath,
          drawPaint,
          oldLayer: layer as ClipPathLayer?,
          clipBehavior: clipBehavior,
        );
      case Clip.antiAlias:
      case Clip.hardEdge:
        context.canvas
          ..save()
          ..clipPath(clipPath, doAntiAlias: clipBehavior == Clip.antiAlias);
        drawPaint();
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
