import 'package:flutter/widgets.dart';

import '../hook_ref/hook_ref.dart';

final class _StatelessHookElement = StatelessElement with HookElement;
final class _StatefulHookElement = StatefulElement with HookElement;

mixin _StatelessHookWidget on StatelessWidget {
  @override
  StatelessElement createElement() => _StatelessHookElement(this);
}

mixin _StatefulHookWidget on StatefulWidget {
  @override
  StatefulElement createElement() => _StatefulHookElement(this);
}

/// A variation of a [StatelessWidget] that can call [Hook] functions
/// in its [HookWidget.build] method.
///
/// To create a Hook widget, replace `extends StatelessWidget` with `extends HookWidget`.
///
/// See also:
///
/// - [StatefulHookWidget], a variant of [StatefulWidget] that can use Hooks
///   in its [State.build] method.
/// - [HookBuilder], a variant of [Builder] that can use Hooks in its `builder` callback.
abstract class HookWidget = StatelessWidget with _StatelessHookWidget;

/// A variation of a [StatefulWidget] that can call [Hook] functions
/// in its [State.build] method.
///
/// To create a Stateful Hook widget, replace `extends StatefulWidget`
/// with `extends StatefulHookWidget`.
abstract class StatefulHookWidget = StatefulWidget with _StatefulHookWidget;

/// A variation of a [Builder] that can call [Hook] functions
/// in its [HookWidget.build] method.
class HookBuilder extends Builder with _StatelessHookWidget {
  /// Creates a [HookBuilder].
  const HookBuilder(WidgetBuilder builder, {super.key}) : super(builder: builder);
}
