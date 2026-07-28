import 'package:flutter/widgets.dart';

import 'signal_layout_delegates.dart';

export 'signal_layout_delegates.dart' show SignalLayoutDelegate, SignalLayoutState;

/// `SignalLayout` is designed to display a finite number of children. To show a widget [List]
/// of arbitrary length, consider using [Wrap], [GridView], [CustomScrollView], or `TableView`
/// from the [two_dimensional_scrollables](https://pub.dev/packages/two_dimensional_scrollables)
/// package.
///
/// Signals read via `.value` during [SignalLayoutState.performLayout] are tracked
/// automatically; when they change, the layout is recomputed without rebuilding
/// the widget tree.
abstract class SignalLayout extends RenderObjectWidget {
  /// Initializes fields for subclasses.
  const SignalLayout({super.key});

  @override
  RenderObjectElement createElement() => SignalLayoutElement(this);

  @override
  RenderObject createRenderObject(covariant SignalLayoutElement element) {
    return RenderSignalLayout()..state = element.state;
  }

  @protected
  @factory
  /// Creates the mutable state for this widget at a given location in the tree.
  SignalLayoutState<SignalLayout> createState();
}
