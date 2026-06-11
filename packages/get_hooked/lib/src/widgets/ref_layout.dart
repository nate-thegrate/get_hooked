// ignore_for_file: public_member_api_docs, use_late_for_private_fields_and_variables, unused_field, unused_element, procrastinate!

import 'package:flutter/widgets.dart';

import 'ref_layout_delegates.dart';

export 'ref_layout_delegates.dart' show LayoutRef, RefLayoutDelegate, RefLayoutState;

/// `RefLayout` is designed to display a finite number of children. To show a widget [List]
/// of arbitrary length, consider using [Wrap], [GridView], [CustomScrollView], or `TableView`
/// from the [two_dimensional_scrollables](https://pub.dev/packages/two_dimensional_scrollables)
/// package.
abstract class RefLayout extends RenderObjectWidget {
  const RefLayout({super.key});

  @override
  RenderObjectElement createElement() => RefLayoutElement(this);

  @override
  RenderObject createRenderObject(covariant RefLayoutElement element) {
    return RenderRefLayout()..state = element.state;
  }

  @protected
  @factory
  RefLayoutState<RefLayout> createState();
}
