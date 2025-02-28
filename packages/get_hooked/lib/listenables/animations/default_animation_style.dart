/// @docImport 'value_animation.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Designates an [AnimationStyle] for descendant widgets to fall back to.
sealed class DefaultAnimationStyle implements Widget {
  /// Creates a default [AnimationStyle] widget.
  ///
  /// [mergeWithAncestor] defaults to `true`.
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

  /// Returns the [AnimationStyle] corresponding to the nearest ancestor
  /// [DefaultAnimationStyle] widget.
  ///
  /// If [createDependency] is true, the provided [context] is notified to rebuild
  /// when the animation style changes.
  static AnimationStyle of(BuildContext context, {bool createDependency = true}) {
    final _InheritedAnimationStyle? inherited =
        createDependency
            ? context.dependOnInheritedWidgetOfExactType()
            : context.getInheritedWidgetOfExactType();

    return inherited?.style ?? const AnimationStyle();
  }

  /// Returns an object that sends a notification when the default style of the corresponding
  /// [context] changes.
  ///
  /// This allows an animation's configuration to stay up-to-date
  /// without triggering unnecessary rebuilds.
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

  @override
  AnimationStyle get value => const AnimationStyle();
}

enum _AnimationStyleAspect<T> {
  duration<Duration?>(),
  curve<Curve?>(),
  reverseDuration<Duration?>(),
  reverseCurve<Curve?>();

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
      if (ancestorStyle != const AnimationStyle()) {
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
