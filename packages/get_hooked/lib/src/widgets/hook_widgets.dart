import 'package:flutter/widgets.dart';

import '../ref_element.dart';

final class _StatelessRefElement = StatelessElement with RefElement;
final class _StatefulRefElement = StatefulElement with RefElement;

mixin _StatelessRefWidget on StatelessWidget {
  @override
  StatelessElement createElement() => _StatelessRefElement(this);
}

mixin _StatefulRefWidget on StatefulWidget {
  @override
  StatefulElement createElement() => _StatefulRefElement(this);
}

/// A variation of a [StatelessWidget] whose [build] method can use [ref]
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
