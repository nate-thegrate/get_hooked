/// @docImport 'package:flutter_hooks/flutter_hooks.dart';
library;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Builds a [Widget], given the [Key] from the [ImmutableSubtree.placeholder].
typedef SubtreeBuilder = Widget Function(BuildContext context, Key? key);

/// Those darn times when 1 widget makes it so the entire thing can't be `const`.
///
/// Not anymore!
///
/// <br>
///
/// # Warning
///
/// This class is entirely unrelated to "get_hooked" and will probably be relocated.
sealed class ImmutableSubtree implements Widget {
  /// Creates an [ImmutableSubtree] object.
  ///
  /// Consider setting the [placeholderBuilder] as a class method
  /// or via [useCallback] to prevent unnecessary rebuilds.
  const factory ImmutableSubtree({
    Key? key,
    required SubtreeBuilder placeholderBuilder,
    required Widget child,
  }) = _ImmutableSubtree;

  const factory ImmutableSubtree.placeholder({Key? key}) = _Placeholder;
}

class _ImmutableSubtree extends InheritedWidget implements ImmutableSubtree {
  const _ImmutableSubtree({super.key, required this.placeholderBuilder, required super.child});

  final SubtreeBuilder placeholderBuilder;

  @override
  bool updateShouldNotify(_ImmutableSubtree oldWidget) {
    return placeholderBuilder != oldWidget.placeholderBuilder;
  }
}

class _Placeholder extends StatelessWidget implements ImmutableSubtree {
  const _Placeholder({super.key});

  @override
  Widget build(BuildContext context) {
    final _ImmutableSubtree? ancestor = context.dependOnInheritedWidgetOfExactType();
    assert(() {
      if (ancestor == null) {
        throw FlutterError.fromParts([
          ErrorSummary(
            '$ImmutableSubtree.placeholder() was used in a context without '
            'an $ImmutableSubtree widget.',
          ),
          ErrorHint(
            'Consider removing the reference to $ImmutableSubtree.placeholder(), '
            'or wrapping it with an $ImmutableSubtree widget.',
          ),
        ]);
      }
      return true;
    }());

    return ancestor!.placeholderBuilder(context, key);
  }
}
