import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// An object that resolves to a [TextStyle] by [select]ing from a [TextTheme].
base mixin TextStyleSelector implements TextStyle {
  /// Selects a [TextStyle] using the provided [TextTheme].
  TextStyle select(TextTheme theme);

  /// Unlike [TextStyle.copyWith], the object returned by this method
  /// does not support stable equality checks.
  ///
  /// Prefer calling [resolve] and modifying the result, or changing
  /// the [TextTheme] directly (e.g. by creating a [Theme] widget
  /// with the desired configuration).
  @override
  TextStyle copyWith({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) {
    return _SelectorCallback(
      (theme) => select(theme).copyWith(
        inherit: inherit,
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        leadingDistribution: leadingDistribution,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        fontVariations: fontVariations,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        debugLabel: debugLabel,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        package: package,
        overflow: overflow,
      ),
    );
  }

  /// Unlike [TextStyle.merge], the object returned by this method
  /// does not support stable equality checks.
  ///
  /// Prefer calling [resolve] and modifying the result, or changing
  /// the [TextTheme] directly (e.g. by creating a [Theme] widget
  /// with the desired configuration).
  @override
  TextStyle merge(TextStyle? other) => switch (other) {
    null => this,
    TextStyleSelector() => _SelectorCallback((theme) => select(theme).merge(other.select(theme))),
    TextStyle() => _SelectorCallback((theme) => select(theme).merge(other)),
  };

  @override
  Never noSuchMethod(_) {
    throw UnsupportedError(
      '$MaterialTextStyle should only be passed to widgets '
      'that explicitly document support for it.',
    );
  }
}

base class _SelectorCallback with TextStyleSelector {
  const _SelectorCallback(this._select);

  final TextStyle Function(TextTheme theme) _select;

  @override
  TextStyle select(TextTheme theme) => _select(theme);

  @override
  String toString({DiagnosticLevel? minLevel}) => '[modified $MaterialTextStyle]';
}

/// Selects a [TextStyle] from the [ThemeData.textTheme].
enum MaterialTextStyle with TextStyleSelector {
  /// Selects [TextTheme.displayLarge].
  displayLarge,

  /// Selects [TextTheme.displayMedium].
  displayMedium,

  /// Selects [TextTheme.displaySmall].
  displaySmall,

  /// Selects [TextTheme.headlineLarge].
  headlineLarge,

  /// Selects [TextTheme.headlineMedium].
  headlineMedium,

  /// Selects [TextTheme.headlineSmall].
  headlineSmall,

  /// Selects [TextTheme.titleLarge].
  titleLarge,

  /// Selects [TextTheme.titleMedium].
  titleMedium,

  /// Selects [TextTheme.titleSmall].
  titleSmall,

  /// Selects [TextTheme.labelLarge].
  labelLarge,

  /// Selects [TextTheme.labelMedium].
  labelMedium,

  /// Selects [TextTheme.labelSmall].
  labelSmall,

  /// Selects [TextTheme.bodyLarge].
  bodyLarge,

  /// Selects [TextTheme.bodyMedium].
  bodyMedium,

  /// Selects [TextTheme.bodySmall].
  bodySmall;

  /// Selects a [TextStyle] from the [ThemeData.textTheme].
  @override
  TextStyle select(TextTheme theme) => switch (this) {
    // dart format off
    displayLarge   => theme.displayLarge!,
    displayMedium  => theme.displayMedium!,
    displaySmall   => theme.displaySmall!,
    headlineLarge  => theme.headlineLarge!,
    headlineMedium => theme.headlineMedium!,
    headlineSmall  => theme.headlineSmall!,
    titleLarge     => theme.titleLarge!,
    titleMedium    => theme.titleMedium!,
    titleSmall     => theme.titleSmall!,
    labelLarge     => theme.labelLarge!,
    labelMedium    => theme.labelMedium!,
    labelSmall     => theme.labelSmall!,
    bodyLarge      => theme.bodyLarge!,
    bodyMedium     => theme.bodyMedium!,
    bodySmall      => theme.bodySmall!,
    // dart format on
  };

  @override
  String toString({DiagnosticLevel? minLevel}) => '$MaterialTextStyle.$name';
}

/// A [RenderObjectWidget] that can display a [String] of text.
class RawText extends LeafRenderObjectWidget {
  /// Creates a [RenderObjectWidget] that can display a [String] of text.
  const RawText(
    this.text, {
    super.key,
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

  /// The text to display.
  final String text;

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
  RenderObject createRenderObject(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    DefaultTextStyle? inherited;
    TextStyle textStyle = style;
    if (textStyle is TextStyleSelector) {
      textStyle = textStyle.select(Theme.of(context).textTheme);
    }
    if (style.inherit) {
      inherited = DefaultTextStyle.of(context);
      textStyle = style.merge(inherited.style);
      if (MediaQuery.boldTextOf(context)) {
        textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
      }
    }
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);

    return RenderParagraph(
      TextSpan(text: text, style: textStyle),
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
    if (textStyle is TextStyleSelector) {
      textStyle = textStyle.select(Theme.of(context).textTheme);
    }
    if (style.inherit) {
      inherited = DefaultTextStyle.of(context);
      textStyle = style.merge(inherited.style);
      if (MediaQuery.boldTextOf(context)) {
        textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
      }
    }
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);

    renderObject
      ..text = TextSpan(text: text, style: textStyle)
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
}
