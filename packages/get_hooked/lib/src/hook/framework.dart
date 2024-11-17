part of '_hook.dart';

/// Allows a [Widget] to create and access its own mutable data without a [State].
///
/// A [State] and a [Hook] are similar, in that they house a widget's logic
/// and internal state. But instead of returning a [Widget] subtree,
/// [Hook.build] can return any value.
///
/// A widget can access a Hook if its [BuildContext] is an [Element] with
/// the [HookElement] mixin.
///
// /// To create such a widget, extend [HookWidget]
// /// class or
// ///
// /// A [Hook] is typically the equivalent of [State] for [StatefulWidget],
// /// with the notable difference that a [HookWidget] can have more than one [Hook].
// /// A [Hook] is created within the [HookState.build] method of a [HookWidget] and the creation
// /// must be made unconditionally, always in the same order.
// ///
// /// ### Good:
// /// ```dart
// /// class Good extends HookWidget {
// ///   @override
// ///   Widget build(BuildContext context) {
// ///     final name = useState("");
// ///     // ...
// ///   }
// /// }
// /// ```
// ///
// /// ### Bad:
// /// ```dart
// /// class Bad extends HookWidget {
// ///   @override
// ///   Widget build(BuildContext context) {
// ///     if (condition) {
// ///       final name = useState("");
// ///       // ...
// ///     }
// ///   }
// /// }
// /// ```
// ///
// /// The reason for such restrictions is that [HookState] are obtained based on their index.
// /// So the index must never ever change, or it will lead to undesired behavior.
// ///
// /// ## Usage
// ///
// /// [Hook] is a powerful tool which enables the reuse of [State] logic between multiple [Widget].
// /// They are used to extract logic that depends on a [Widget] life-cycle (such as [HookState.dispose]).
// ///
// /// While mixins are a good candidate too, they do not allow sharing values. A mixin cannot reasonably
// /// define a variable, as this can lead to variable conflicts in bigger widgets.
// ///
// /// Hooks are designed so that they get the benefits of mixins, but are totally independent from each other.
// /// This means that hooks can store and expose values without needing to check if the name is already taken by another mixin.
// ///
// /// ## Example
// ///
// /// A common use-case is to handle disposable objects such as [AnimationController].
// ///
// /// With the usual [StatefulWidget], we would typically have the following:
// ///
// /// ```dart
// /// class Usual extends StatefulWidget {
// ///   @override
// ///   _UsualState createState() => _UsualState();
// /// }
// ///
// /// class _UsualState extends State<Usual>
// ///     with SingleTickerProviderStateMixin {
// ///   late final _controller = AnimationController(
// ///     vsync: this,
// ///     duration: const Duration(seconds: 1),
// ///   );
// ///
// ///   @override
// ///   void dispose() {
// ///     _controller.dispose();
// ///     super.dispose();
// ///   }
// ///
// ///   @override
// ///   Widget build(BuildContext context) {
// ///     return Container();
// ///   }
// /// }
// /// ```
// ///
// /// This is undesired because every single widget that wants to use an [AnimationController] will have to
// /// rewrite this exact piece of code.
// ///
// /// With hooks, it is possible to extract that exact piece of code into a reusable one.
// ///
// /// This means that with [HookWidget] the following code is functionally equivalent to the previous example:
// ///
// /// ```dart
// /// class Usual extends HookWidget {
// ///   @override
// ///   Widget build(BuildContext context) {
// ///     final animationController = useAnimationController(duration: const Duration(seconds: 1));
// ///     return Container();
// ///   }
// /// }
// /// ```
// ///
// /// This is visibly less code then before, but in this example, the `animationController` is still
// /// guaranteed to be disposed when the widget is removed from the tree.
// ///
// /// In fact, this has a secondary bonus: `duration` is kept updated with the latest value.
// /// If we were to pass a variable as `duration` instead of a constant, then on value change the [AnimationController] will be updated.
abstract class Hook<Result, Data> with Diagnosticable {
  static HookElement? _currentElement;
  static bool _debugInitializing = false;

  /// Equivalent of [State.context] for [Hook]
  @protected
  BuildContext get context => _element;

  late final HookElement _element;
  late final Object? _key;
  late final String? _debugLabel;

  Result? _debugPreviousResult;

  /// The value shown in the devtool.
  ///
  /// Defaults to the last value returned by [build].
  Object? get debugResult => _debugPreviousResult;

  /// Equivalent of [State.widget] for a [Hook].
  Data get data => _data;
  late Data _data;

  /// Equivalent of [State.initState] for [Hook].
  @protected
  void initHook() {}

  /// Equivalent of [State.dispose] for [Hook].
  @protected
  void dispose() {}

  /// Called everytime the [Hook] is requested.
  ///
  /// [build] is where a [Hook] may use other hooks.
  /// This restriction is made to ensure that hooks are always unconditionally requested.
  @protected
  Result build();

  /// Equivalent of [State.didUpdateWidget] for [Hook].
  @protected
  void didUpdate(Data oldHook) {}

  /// Equivalent of [State.deactivate] for [Hook].
  void deactivate() {}

  /// {@macro flutter.widgets.reassemble}
  ///
  /// In addition to this method being invoked, it is guaranteed that the
  /// [build] method will be invoked when a reassemble is signaled. Most
  /// widgets therefore do not need to do anything in the [reassemble] method.
  ///
  /// See also:
  ///
  ///  * [State.reassemble]
  void reassemble() {}

  /// Called before a [build] triggered by [markMayNeedRebuild].
  ///
  /// If [shouldRebuild] returns `false` on all the hooks that called [markMayNeedRebuild]
  /// then this aborts the rebuild of the associated [HookWidget].
  ///
  /// There is no guarantee that this method will be called after [markMayNeedRebuild]
  /// was called.
  ///
  /// Some situations where [shouldRebuild] will not be called:
  ///
  /// - [setState] was called
  /// - a previous hook's [shouldRebuild] returned `true`
  /// - the associated [HookWidget] changed.
  bool shouldRebuild() => true;

  /// Mark the associated [HookWidget] as **potentially** needing to rebuild.
  ///
  /// As opposed to [setState], the rebuild is optional and can be cancelled right
  /// before `build` is called, by having [shouldRebuild] return false.
  void markMayNeedRebuild() {
    if (_element._isOptionalRebuild ?? true) {
      _element
        .._isOptionalRebuild = true
        .._shouldRebuildQueue.add(_Entry(shouldRebuild))
        ..markNeedsBuild();
    }
    assert(_element.dirty, 'Bad state');
  }

  /// Equivalent of [State.setState] for [Hook].
  @protected
  void setState([VoidCallback? fn]) {
    fn?.call();
    _element
      .._isOptionalRebuild = false
      ..markNeedsBuild();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (debugResult != null) {
      properties.add(DiagnosticsProperty(_debugLabel, debugResult));
    }
    if (data case final Diagnosticable diagnosticable) {
      diagnosticable.debugFillProperties(properties);
    } else {
      properties.add(DiagnosticsProperty('data', data));
    }
  }
}

final class _Entry<T> extends LinkedListEntry<_Entry<T>> {
  _Entry(this.value);
  T value;
}

typedef _HookEntry = _Entry<Hook<Object?, Object?>>;

/// An [Element] that uses a [HookWidget] as its configuration.
base mixin HookElement on ComponentElement {
  _HookEntry? _currentEntry;
  final _hooks = LinkedList<_HookEntry>();
  final _shouldRebuildQueue = LinkedList<_Entry<bool Function()>>();
  LinkedList<_HookEntry>? _needDispose;
  bool? _isOptionalRebuild = false;
  Widget? _buildCache;

  bool _debugDidReassemble = false;

  /// A read-only list of all available hooks.
  ///
  /// In release mode, returns `null`.
  List<Hook<Object?, Object?>>? get debugHooks {
    if (!kDebugMode) {
      return null;
    }
    return [for (final hook in _hooks) hook.value];
  }

  @override
  void update(Widget newWidget) {
    _isOptionalRebuild = false;
    super.update(newWidget);
  }

  @override
  void didChangeDependencies() {
    _isOptionalRebuild = false;
    super.didChangeDependencies();
  }

  @override
  void reassemble() {
    super.reassemble();
    _isOptionalRebuild = false;
    assert(_debugDidReassemble = true);
    for (final _HookEntry hook in _hooks) {
      hook.value.reassemble();
    }
  }

  @override
  Widget build() {
    // Check whether we can cancel the rebuild (caused by HookState.mayNeedRebuild).
    final bool mustRebuild =
        (_isOptionalRebuild ?? false) || _shouldRebuildQueue.any((cb) => cb.value());

    _isOptionalRebuild = null;
    _shouldRebuildQueue.clear();

    if (!mustRebuild && _buildCache != null) {
      return _buildCache!;
    }

    assert(!(Hook._debugInitializing = false));

    _currentEntry = _hooks.firstOrNull;
    Hook._currentElement = this;
    try {
      _buildCache = super.build();
    } finally {
      _isOptionalRebuild = null;
      _debugDidReassemble = false;
      _unmountAllRemainingHooks();
      Hook._currentElement = null;
      if (_needDispose != null && _needDispose!.isNotEmpty) {
        for (
          _Entry<Hook<Object?, Object?>>? toDispose = _needDispose!.last;
          toDispose != null;
          toDispose = toDispose.previous
        ) {
          toDispose.value.dispose();
        }
        _needDispose = null;
      }
    }

    return _buildCache!;
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) {
    assert(() {
      if (!Hook._debugInitializing) return true;
      throw FlutterError.fromParts([
        ErrorSummary('Attempted to access an InheritedWidget from within initHook().'),
      ]);
    }());
    return super.dependOnInheritedWidgetOfExactType<T>(aspect: aspect);
  }

  @override
  void unmount() {
    super.unmount();
    if (_hooks.isNotEmpty) {
      for (_HookEntry? entry = _hooks.last; entry != null; entry = entry.previous) {
        try {
          entry.value.dispose();
        } catch (exception, stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: exception,
              stack: stack,
              library: 'hooks library',
              context: DiagnosticsNode.message('while disposing ${entry.runtimeType}'),
            ),
          );
        }
      }
    }
  }

  void _unmountAllRemainingHooks() {
    if (_currentEntry != null) {
      final LinkedList<_HookEntry> needDispose = _needDispose ??= LinkedList();
      // Mark all hooks >= this one as needing dispose
      while (_currentEntry != null) {
        final _HookEntry previousEntry = _currentEntry!;
        _currentEntry = previousEntry.next;
        previousEntry.unlink();
        needDispose.add(_Entry(previousEntry.value));
      }
    }
  }

  @override
  void deactivate() {
    for (final _HookEntry hook in _hooks) {
      try {
        hook.value.deactivate();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'hooks library',
            context: DiagnosticsNode.message('while deactivating ${hook.runtimeType}'),
          ),
        );
      }
    }
    super.deactivate();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final Hook(debugResult: debugValue, :_debugLabel) in debugHooks!) {
      if (debugValue != null) {
        properties.add(DiagnosticsProperty<dynamic>(_debugLabel, debugValue));
      } else if (_debugLabel != null) {
        properties.add(StringProperty(_debugLabel, '', ifEmpty: ''));
      }
    }
  }
}
