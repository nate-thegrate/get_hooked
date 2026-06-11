/// @docImport 'package:get_hooked/widgets.dart';
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:get_hooked/listenables.dart';
import 'package:get_hooked/src/substitution/substitution.dart';

/// A variant of [IgnorePointer] or [AbsorbPointer] that evaluates based on a [RefComputer<bool>].
///
/// `RefPointer`'s performance impact is much smaller than other widgets, since hit testing
/// happens between frames and nothing needs to be built, laid out, or rendered.
/// Thus, `RefPointer` won't actively subscribe to any listenable notifications.
/// It also does not automatically register animations with a [Vsync].
class RefPointer extends SingleChildRenderObjectWidget {
  /// Creates an [IgnorePointer] widget using the provided [RefComputer] callback.
  const RefPointer(
    this.interactable, {
    this.absorb = false,
    super.key,
    required Widget super.child,
  });

  /// Whether the [child] and its descendants should be exposed to pointer events.
  ///
  /// Returning `false` will cause pointer events to be ignored.
  final RefComputer<bool> interactable;

  /// Whether to absorb hit tests when [interactable] evaulates as `false`.
  ///
  /// Typically this distinction only comes into play when a [Stack] or [RefLayout]
  /// situates a [RefPointer] on top of another widget.
  ///
  /// When this value is `true`, the behavior matches [AbsorbPointer],
  /// and when `false` it matches [IgnorePointer].
  final bool absorb;

  @override
  RenderObject createRenderObject(BuildContext context) {
    context as _RefPointerElement;
    return _RenderRefPointer(interactable: context._interactable, absorbing: context._absorbing);
  }

  @override
  SingleChildRenderObjectElement createElement() => _RefPointerElement(this);
}

class _RefPointerElement extends SingleChildRenderObjectElement implements Ref {
  _RefPointerElement(super.widget);

  bool _interactable() => (widget as RefPointer).interactable(this);

  bool _absorbing() => (widget as RefPointer).absorb;

  @override
  T watch<T>(ValueListenable<T> get, {bool autoVsync = true, bool useScope = true}) {
    final ValueListenable<T> scoped = useScope ? read(get) : get;
    return scoped.value;
  }

  @override
  Result select<Result, T>(
    ValueListenable<T> get,
    Result Function(T value) selector, {
    bool autoVsync = true,
    bool useScope = true,
  }) {
    final ValueListenable<T> scoped = useScope ? read(get) : get;
    return selector(scoped.value);
  }
}

class _RenderRefPointer extends RenderProxyBox {
  _RenderRefPointer({required this.interactable, required this.absorbing});

  final ValueGetter<bool> interactable;
  final ValueGetter<bool> absorbing;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return interactable()
        ? super.hitTest(result, position: position)
        : absorbing() && size.contains(position);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isBlockingUserActions = !interactable();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing()));
    properties.add(DiagnosticsProperty<bool>('interactable', interactable()));
  }
}
