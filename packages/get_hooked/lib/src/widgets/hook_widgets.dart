/// @docImport 'package:get_hooked/get_hooked.dart';
library;

import 'package:flutter/widgets.dart';

import '../ref_element.dart';

// Use `extends … with` (not mixin application `=`) so mixin fields initialize
// correctly on web (DDC/dart2js); `= Super with Mixin` only exposes getters.
final class _StatelessRefElement extends StatelessElement with RefElement {
  _StatelessRefElement(super.widget);
}

final class _StatefulRefElement extends StatefulElement with RefElement {
  _StatefulRefElement(super.widget);
}

mixin _StatelessRefWidget on StatelessWidget {
  @override
  StatelessElement createElement() => _StatelessRefElement(this);
}

mixin _StatefulRefWidget on StatefulWidget {
  @override
  StatefulElement createElement() => _StatefulRefElement(this);
}

/// A variation of a [StatelessWidget] whose `build` method can use [ref]
/// to watch [ValueListenable] objects.
///
/// To create a Ref widget, replace `extends StatelessWidget` with `extends RefWidget`.
///
/// See also:
///
/// - [StatefulRefWidget], a variant of [StatefulWidget] whose [State.build]
///   method can use [ref].
/// - [RefBuilder], a variant of [Builder] whose callback can use [ref].
abstract class RefWidget = StatelessWidget with _StatelessRefWidget;

/// A variation of a [StatefulWidget] whose [State.build] method can use [ref]
/// to watch [ValueListenable] objects.
///
/// To create a Stateful Ref widget, replace `extends StatefulWidget`
/// with `extends StatefulRefWidget`.
abstract class StatefulRefWidget = StatefulWidget with _StatefulRefWidget;

/// A variation of a [Builder] whose callback can use [ref] to watch
/// [ValueListenable] objects.
class RefBuilder extends Builder with _StatelessRefWidget {
  /// Creates a [RefBuilder].
  const RefBuilder(WidgetBuilder builder, {super.key}) : super(builder: builder);
}
