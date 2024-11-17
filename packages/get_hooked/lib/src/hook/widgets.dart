// ignore_for_file: use_to_and_as_if_applicable, smh my head

part of '_hook.dart';

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
/// To create a `HookWidget`, replace "extends StatelessWidget"
/// with "extends HookWidget".
abstract class HookWidget = StatelessWidget with _StatelessHookWidget;

/// A [HookWidget] that delegates its `build` to a callback.
class HookBuilder = Builder with _StatelessHookWidget;

/// A variation of a [StatefulWidget] that can call [Hook] functions
/// in its [State.build] method.
///
/// To create a `StatefulHookWidget`, replace "extends StatefulWidget"
/// with "extends StatefulHookWidget".
abstract class StatefulHookWidget = StatefulWidget with _StatefulHookWidget;
