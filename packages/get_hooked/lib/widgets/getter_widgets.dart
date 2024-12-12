import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../ref/ref.dart';
import 'render_get.dart';

/// A widget displaying a string representation of a [Get] object's value.
abstract class TextGetter<T> extends RenderScopedGetBase<T> {
  /// Creates a widget displaying a string representation of a [Get] object's value.
  const factory TextGetter(
    GetT<T> get, {
    Key? key,
    String Function(T value) describe,
    TextStyle style,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
    bool softWrap,
    StrutStyle? strutStyle,
    TextHeightBehavior? textHeightBehavior,
    TextScaler? textScaler,
    TextWidthBasis? textWidthBasis,
  }) = _TextGetter<T>;

  /// Creates a widget displaying a string representation of a [Get] object's value.
  // TODO(nate-thegrate): ComputeRef here, so we don't need both a get getter & describe callback
  const factory TextGetter.ref(
    ValueGetter<GetT<T>> get, {
    Key? key,
    String Function(T value) describe,
    TextStyle style,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
    bool softWrap,
    StrutStyle? strutStyle,
    TextHeightBehavior? textHeightBehavior,
    TextScaler? textScaler,
    TextWidthBasis? textWidthBasis,
  }) = _TextRef<T>;

  /// Initializes fields for subclasses.
  const TextGetter.construct({
    super.key,
    this.describe = _describe,
    this.style = const TextStyle(),
    this.align,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.strutStyle,
    this.textHeightBehavior,
    this.textScaler,
    this.textWidthBasis,
  });

  /// The [Get] object to display in text form.
  @override
  GetT<T> get get;

  /// Optionally turns the [Get] object's value into a [String] description.
  ///
  /// Defaults to using the value's [Object.toString] result.
  final String Function(T value) describe;
  static String _describe(Object? value) => value.toString();

  /// The [TextStyle] to apply to this text.
  final TextStyle style;

  /// How the text should be aligned horizontally.
  final TextAlign? align;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool? softWrap;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// {@macro flutter.painting.textPainter.textScaler}
  final TextScaler? textScaler;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int? maxLines;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis? textWidthBasis;

  /// {@macro dart.ui.textHeightBehavior}
  final ui.TextHeightBehavior? textHeightBehavior;

  @override
  RenderObject render(BuildContext context, T value) {
    assert(debugCheckHasDirectionality(context));
    DefaultTextStyle? inherited;
    TextStyle textStyle = style;
    if (style.inherit) {
      inherited = DefaultTextStyle.of(context);
      textStyle = style.merge(inherited.style);
      if (MediaQuery.boldTextOf(context)) {
        textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
      }
    }
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);

    return RenderParagraph(
      TextSpan(text: describe(value), style: textStyle),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: maxLines ?? inherited?.maxLines,
      selectionColor: registrar != null ? DefaultSelectionStyle.of(context).selectionColor : null,
      overflow: overflow ?? inherited?.overflow ?? TextOverflow.clip,
      softWrap: softWrap ?? inherited?.softWrap ?? true,
      strutStyle: strutStyle,
      textScaler: textScaler ?? MediaQuery.textScalerOf(context),
      textHeightBehavior: textHeightBehavior ?? inherited?.textHeightBehavior,
      textAlign: align ?? inherited?.textAlign ?? TextAlign.start,
      textWidthBasis: textWidthBasis ?? inherited?.textWidthBasis ?? TextWidthBasis.parent,
      textDirection: Directionality.of(context),
      registrar: registrar,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderParagraph renderObject) {
    assert(debugCheckHasDirectionality(context));
    DefaultTextStyle? inherited;
    TextStyle textStyle = style;
    if (style.inherit) {
      inherited = DefaultTextStyle.of(context);
      textStyle = style.merge(inherited.style);
      if (MediaQuery.boldTextOf(context)) {
        textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
      }
    }
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);

    renderObject
      ..text = TextSpan(text: describe(GetScope.of(context, get).value), style: textStyle)
      ..locale = Localizations.maybeLocaleOf(context)
      ..maxLines = maxLines ?? inherited?.maxLines
      ..selectionColor =
          registrar != null ? DefaultSelectionStyle.of(context).selectionColor : null
      ..overflow = overflow ?? inherited?.overflow ?? TextOverflow.clip
      ..softWrap = softWrap ?? inherited?.softWrap ?? true
      ..strutStyle = strutStyle
      ..textScaler = textScaler ?? MediaQuery.textScalerOf(context)
      ..textHeightBehavior = textHeightBehavior ?? inherited?.textHeightBehavior
      ..textAlign = align ?? inherited?.textAlign ?? TextAlign.start
      ..textWidthBasis = textWidthBasis ?? inherited?.textWidthBasis ?? TextWidthBasis.parent
      ..textDirection = Directionality.of(context)
      ..registrar = registrar;
  }

  @override
  void listen(RenderParagraph renderObject, T value) {
    final TextStyle? style = renderObject.text.style;
    renderObject.text = TextSpan(text: describe(value), style: style);
  }
}

class _TextGetter<T> extends TextGetter<T> {
  const _TextGetter(
    this.get, {
    super.key,
    super.describe,
    super.style,
    super.align,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.strutStyle,
    super.textHeightBehavior,
    super.textScaler,
    super.textWidthBasis,
  }) : super.construct();

  @override
  final GetT<T> get;
}

class _TextRef<T> extends TextGetter<T> {
  const _TextRef(
    this.getter, {
    super.key,
    super.describe,
    super.style,
    super.align,
    super.maxLines,
    super.overflow,
    super.softWrap,
    super.strutStyle,
    super.textHeightBehavior,
    super.textScaler,
    super.textWidthBasis,
  }) : super.construct();

  final ValueGetter<GetT<T>> getter;

  @override
  GetT<T> get get => getter();
}
