import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'signal_element.dart';

/// When using a [ParentDataWidget], the widget contains fields that translate
/// to [ParentData] properties, and its corresponding [ParentDataElement] updates the
/// render object using the widget instance each time it rebuilds.
///
/// Conversely, [SignalParentData] is designed to skip the build phase
/// and apply parent data updates directly when signals change.
abstract class SignalParentData<Data extends ParentData> extends ProxyWidget {
  /// Initializes fields for subclasses.
  const SignalParentData({super.key, this.debugTypicalAncestorWidgetClass, required super.child});

  /// Applies changes to the [ParentData] and returns a boolean value
  /// to determine whether a re-layout should take place.
  ///
  /// Signals read via `.value` during this method are tracked automatically.
  bool shouldLayout(BuildContext context, Data data);

  /// Describes the [RenderObjectWidget] that is typically used to set up the
  /// [ParentData] that this widget will write to.
  ///
  /// This is only used in error messages to tell users what widget typically
  /// wraps this [ParentDataWidget].
  final Type? debugTypicalAncestorWidgetClass;

  @override
  Element createElement() => _SignalParentDataElement(this);
}

class _SignalParentDataElement<P extends ParentData> extends ComponentElement with ElementSignal {
  _SignalParentDataElement(SignalParentData<P> super.widget) : child = widget.child;

  Widget child;

  @override
  Widget build() => child;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    trackAndRecompute();
  }

  @override
  void update(SignalParentData<P> newWidget) {
    super.update(newWidget);

    child = newWidget.child;
    rebuild(force: true);
    trackAndRecompute();
  }

  @override
  void reassemble() {
    super.reassemble();
    clearSignalWatches();
    trackAndRecompute();
  }

  @override
  void unmount() {
    clearSignalWatches();
    super.unmount();
  }

  void applyParentData(Element element) {
    switch (element) {
      case RenderObjectElement(
        renderObject: RenderObject(:final P parentData, :final RenderObject? parent),
      ):
        if ((widget as SignalParentData<P>).shouldLayout(this, parentData)) {
          parent?.markNeedsLayout();
        }

      case RenderObjectElement(:final RenderObject renderObject):
        assert(
          throw FlutterError.fromParts([
            ErrorSummary('Attempted to access an invalid parent data type.'),
            ErrorDescription(
              'The ${widget.runtimeType} expects "$P" '
              'but instead got "${renderObject.parentData.runtimeType}".',
            ),
            if (widget case SignalParentData(debugTypicalAncestorWidgetClass: final Type type))
              ErrorHint(
                'Ensure that there are no other RenderObjectWidgets in the tree '
                'between the ${widget.runtimeType} and the nearest ancestor $type.',
              ),
          ]),
        );

      case Element(renderObjectAttachingChild: final Element child):
        applyParentData(child);

      case Element(widget: final Widget problemWidget):
        assert(
          throw FlutterError.fromParts([
            ErrorSummary('No render object was found for this ${widget.runtimeType}.'),
            ErrorDescription(
              'The renderObjectAttachingChild chain ended abruptly at the following widget:',
            ),
            problemWidget.toDiagnosticsNode(style: DiagnosticsTreeStyle.error),
          ]),
        );
    }
  }

  @override
  @pragma('vm:notify-debugger-on-exception')
  void recompute() {
    try {
      applyParentData(this);
    } catch (exception, stackTrace) {
      final FlutterErrorDetails details = FlutterErrorDetails(
        exception: exception,
        stack: stackTrace,
        library: 'signal_widgets: SignalParentData',
        context: ErrorDescription('applying parent data'),
      );
      FlutterError.reportError(details);
      child = ErrorWidget.builder(details);
      markNeedsBuild();
    }
  }
}
