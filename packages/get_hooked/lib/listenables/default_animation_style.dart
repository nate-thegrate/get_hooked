/// @docImport 'value_animation.dart';
library;

// ignore_for_file: public_member_api_docs, pro crastinate!

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

sealed class DefaultAnimationStyle implements Widget {
  const factory DefaultAnimationStyle({
    Key? key,
    required AnimationStyle style,
    bool mergeWithAncestor,
    required Widget child,
  }) = _DefaultAnimationStyle;

  /// A fallback [Duration] to use for [AnimationController]
  /// and [ValueAnimation] objects.
  static const fallbackDuration = Duration(milliseconds: 300);

  /// A fallback [Curve] to use for [AnimationController]
  /// and [ValueAnimation] objects.
  static const fallbackCurve = Curves.linear;

  static AnimationStyle of(BuildContext context, {bool createDependency = true}) {
    final _InheritedAnimationStyle? inherited =
        createDependency
            ? context.dependOnInheritedWidgetOfExactType()
            : context.getInheritedWidgetOfExactType();

    return inherited?.style ?? AnimationStyle();
  }

  static Duration? durationOf(BuildContext context) {
    return _AnimationStyleAspect.duration._of(context);
  }

  static Duration? reverseDurationOf(BuildContext context) {
    return _AnimationStyleAspect.reverseDuration._of(context);
  }

  static Curve? curveOf(BuildContext context) {
    return _AnimationStyleAspect.curve._of(context);
  }

  static Curve? reverseCurveOf(BuildContext context) {
    return _AnimationStyleAspect.reverseCurve._of(context);
  }

  static ValueListenable<AnimationStyle> getNotifier(BuildContext context) {
    final _InheritedAnimationStyle? inheritedWidget = context.getInheritedWidgetOfExactType();
    return inheritedWidget?.notifier ?? const _FallbackAnimationStyleListenable();
  }
}

class _FallbackAnimationStyleListenable implements ValueListenable<AnimationStyle> {
  const _FallbackAnimationStyleListenable();
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  static final _value = AnimationStyle();

  @override
  AnimationStyle get value => _value;
}

enum _AnimationStyleAspect<T> {
  duration<Duration?>(),
  curve<Curve?>(),
  reverseDuration<Duration?>(),
  reverseCurve<Curve?>();

  T? _of(BuildContext context) {
    final _InheritedAnimationStyle? model = InheritedModel.inheritFrom<_InheritedAnimationStyle>(
      context,
      aspect: this,
    );
    if (model == null) {
      return null;
    }
    return _select(model.style);
  }

  // dart format off
  T _select(AnimationStyle style) => switch (this) {
    duration        => style.duration,
    curve           => style.curve,
    reverseDuration => style.reverseDuration,
    reverseCurve    => style.reverseCurve,
  } as T;
  // dart format on
}

class _InheritedAnimationStyle extends InheritedModel<_AnimationStyleAspect<Object?>>
    implements DefaultAnimationStyle, InheritedTheme {
  _InheritedAnimationStyle({required this.notifier, required super.child})
    : style = notifier.value;

  final ValueListenable<AnimationStyle> notifier;
  final AnimationStyle style;

  @override
  bool updateShouldNotify(_InheritedAnimationStyle oldWidget) => style != oldWidget.style;

  @override
  bool updateShouldNotifyDependent(
    _InheritedAnimationStyle oldWidget,
    Set<_AnimationStyleAspect<Object?>> dependencies,
  ) {
    return dependencies.any((aspect) => aspect._select(style) != aspect._select(oldWidget.style));
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return _InheritedAnimationStyle(notifier: notifier, child: child);
  }
}

class _DefaultAnimationStyle extends StatefulWidget implements DefaultAnimationStyle {
  const _DefaultAnimationStyle({
    super.key,
    required this.style,
    this.mergeWithAncestor = true,
    required this.child,
  });

  final AnimationStyle style;
  final bool mergeWithAncestor;
  final Widget child;

  @override
  State<_DefaultAnimationStyle> createState() => _DefaultAnimationStyleState();
}

class _DefaultAnimationStyleState extends State<_DefaultAnimationStyle> {
  late final notifier = ValueNotifier(widget.style)..addListener(() => setState(() {}));

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AnimationStyle style = widget.style;
    if (widget.mergeWithAncestor) {
      final AnimationStyle ancestorStyle = DefaultAnimationStyle.of(context);
      if (ancestorStyle != AnimationStyle()) {
        style = ancestorStyle.copyWith(
          duration: style.duration,
          curve: style.curve,
          reverseDuration: style.reverseDuration,
          reverseCurve: style.reverseCurve,
        );
      }
    }
    return _InheritedAnimationStyle(notifier: notifier..value = style, child: widget.child);
  }
}
