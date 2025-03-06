part of '../hooked.dart';

/// An [Element] that uses a [HookWidget] as its configuration.
base mixin HookElement on ComponentElement {
  static HookElement? _current;
  _HookEntry? _currentEntry;
  final _hooks = LinkedList<_HookEntry>();
  final _shouldRebuildQueue = LinkedList<_Entry<bool Function()>>();
  LinkedList<_HookEntry>? _needDispose;
  bool? _rebuildRequired = true;
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
    _rebuildRequired = true;
    super.update(newWidget);
  }

  @override
  void didChangeDependencies() {
    _rebuildRequired = true;
    for (final _HookEntry hook in _hooks) {
      try {
        hook.value.didChangeDependencies();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'hooks library',
            context: DiagnosticsNode.message(
              'during didChangeDependencies - ${hook.runtimeType}',
            ),
          ),
        );
      }
    }
    super.didChangeDependencies();
  }

  @override
  void reassemble() {
    super.reassemble();
    _rebuildRequired = true;
    assert(_debugDidReassemble = true);
    for (final _HookEntry hook in _hooks) {
      hook.value.reassemble();
    }
  }

  @override
  Widget build() {
    // Check whether we can cancel the rebuild (caused by HookState.mayNeedRebuild).
    final bool mustRebuild =
        (_rebuildRequired ?? true) || _shouldRebuildQueue.any((cb) => cb.value());

    _rebuildRequired = null;
    _shouldRebuildQueue.clear();

    if (!mustRebuild && _buildCache != null) {
      return _buildCache!;
    }

    assert(!(Hook._debugInitializing = false));

    _currentEntry = _hooks.firstOrNull;
    _current = this;
    try {
      _buildCache = super.build();
    } finally {
      _rebuildRequired = null;
      _debugDidReassemble = false;
      _unmountAllRemainingHooks();
      _current = null;
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
  void activate() {
    super.activate();
    for (final _HookEntry hook in _hooks) {
      try {
        hook.value.activate();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'hooks library',
            context: DiagnosticsNode.message('while activating ${hook.runtimeType}'),
          ),
        );
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final Hook(debugResult: debugValue, :_debugLabel) in debugHooks!) {
      if (debugValue != null) {
        properties.add(DiagnosticsProperty<dynamic>(_debugLabel, debugValue));
      } else {
        properties.add(StringProperty(_debugLabel, '', ifEmpty: ''));
      }
    }
  }
}
