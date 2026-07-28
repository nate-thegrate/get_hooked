import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'signal_element.dart';

/// A variant of [IgnorePointer] or [AbsorbPointer] driven by a [SignalComputer<bool>].
///
/// [SignalPointer]'s performance impact is much smaller than other widgets, since hit
/// testing happens between frames and nothing needs to be built, laid out, or rendered.
/// Thus, [SignalPointer] will not actively subscribe to signal changes — the
/// [interactable] callback is only evaluated during hit testing / semantics.
class SignalPointer extends SingleChildRenderObjectWidget {
  /// Creates an [IgnorePointer]-style widget using the provided [SignalComputer] callback.
  const SignalPointer(
    this.interactable, {
    this.absorb = false,
    super.key,
    required Widget super.child,
  });

  /// Whether the [child] and its descendants should be exposed to pointer events.
  ///
  /// Returning `false` will cause pointer events to be ignored.
  ///
  /// Prefer reading signal values with `.value` or `.peek()`; either works because
  /// this widget does not establish signal subscriptions.
  final SignalComputer<bool> interactable;

  /// Whether to absorb hit tests when [interactable] evaluates as `false`.
  ///
  /// Typically this distinction only comes into play when a [Stack] situates a
  /// [SignalPointer] on top of another widget.
  ///
  /// When this value is `true`, the behavior matches [AbsorbPointer],
  /// and when `false` it matches [IgnorePointer].
  final bool absorb;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSignalPointer(
      interactable: () => (context.widget as SignalPointer).interactable(context),
      absorbing: () => (context.widget as SignalPointer).absorb,
    );
  }
}

class _RenderSignalPointer extends RenderProxyBox {
  _RenderSignalPointer({required this.interactable, required this.absorbing});

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
