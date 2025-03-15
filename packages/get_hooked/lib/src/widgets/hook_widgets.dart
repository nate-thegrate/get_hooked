// ignore_for_file: use_to_and_as_if_applicable, smh my head

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../hook_ref/hook_ref.dart';

final class _StatelessHookElement = StatelessElement with HookElement;
final class _StatefulHookElement = StatefulElement with HookElement;

mixin _StatefulHookWidget on StatefulWidget {
  @override
  StatefulElement createElement() => _StatefulHookElement(this);
}

/// A variation of a [StatelessWidget] that can call [Hook] functions
/// in its [HookWidget.build] method.
///
/// To create a Hook widget, replace `extends StatelessWidget` with `extends HookWidget`,
/// or use the [HookWidget.new] constructor and pass a [builder].
///
/// See also: [StatefulHookWidget], a variant of [StatefulWidget] that can use Hooks
/// in its [State.build] method.
class HookWidget extends StatelessWidget {
  /// This constructor serves 2 purposes:
  ///
  /// 1. Initializes the [key] field for subclasses.
  /// 2. Can be called directly by specifying a [builder].
  /// [Builder]
  const HookWidget({super.key, this.builder});

  /// Called to create a widget subtree.
  ///
  /// This function is called whenever this widget is included in its parent's
  /// build and the old widget (if any) that it synchronizes with has a distinct
  /// object identity.
  ///
  /// The `builder` is ignored in any class that extends [HookWidget],
  /// since they will override [build] directly.
  final WidgetBuilder? builder;

  @mustBeOverridden
  @override
  Widget build(BuildContext context) {
    assert(() {
      if (builder != null) return true;
      throw FlutterError.fromParts([
        ErrorSummary('This HookWidget did not build anything.'),
        if (runtimeType == HookWidget)
          ErrorHint('Consider specifying a builder in the HookWidget() constructor.')
        else
          ErrorHint('Consider overriding the build method of the $runtimeType class.'),
      ]);
    }());

    return builder?.call(context) ?? const SizedBox.shrink();
  }
}

@Deprecated('Use HookWidget instead. Smaller namespace!')
/// Helps with migrating code that used `flutter_hooks`.
typedef HookBuilder = HookWidget;

/// A variation of a [StatefulWidget] that can call [Hook] functions
/// in its [State.build] method.
///
/// To create a `StatefulHookWidget`, replace "extends StatefulWidget"
/// with "extends StatefulHookWidget".
abstract class StatefulHookWidget = StatefulWidget with _StatefulHookWidget;
