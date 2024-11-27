part of '../hooked.dart';

/// Signature for a callback that returns a [Hook].
typedef GetHook<Result, Data> = ValueGetter<Hook<Result, Data>>;

/// Registers a [Hook] and returns its value.
///
/// Must be called from within a [HookWidget.build] method.
/// See [Hook] for more explanation.
Result use<Result, Data>(
  GetHook<Result, Data> getHook, {
  required Object? key,
  required Data data,
  required String debugLabel,
}) {
  final HookElement? currentElement = HookElement._current;
  if (currentElement == null) {
    assert(
      throw FlutterError.fromParts([
        ErrorSummary(
          'Attempted to access $debugLabel '
          "outside of a hook widget's build method.",
        ),
      ]),
    );
    return getHook().build();
  }
  final _HookEntry? currentEntry = currentElement._currentEntry;

  Hook<Result, Data> init() {
    assert(Hook._debugInitializing = true);
    final Hook<Result, Data> hook =
        getHook()
          .._key = key
          .._data = data
          .._element = currentElement
          .._debugLabel = debugLabel
          ..initHook();
    assert(!(Hook._debugInitializing = false));

    return hook;
  }

  final _HookEntry entry;
  late final Object? oldData = currentEntry?.value._data;

  if (currentEntry case _HookEntry(value: final hook) when oldData is Data) {
    entry = currentEntry;
    if (key != hook._key) {
      (currentElement._needDispose ??= LinkedList()).add(_HookEntry(hook));
      entry.value = init();
    } else if (data != oldData) {
      entry.value
        .._data = data
        ..didUpdate(oldData);
    }
  } else {
    if (currentEntry != null) {
      currentElement._unmountAllRemainingHooks();
      if (!currentElement._debugDidReassemble) {
        throw StateError(
          'Type mismatch between hooks:\n'
          '  - old hook: ${currentEntry.value.runtimeType}\n'
          '  - current hook: $debugLabel',
        );
      }
    }
    entry = _HookEntry(init());
    currentElement
      .._currentEntry = entry
      .._hooks.add(entry);
  }

  final Result result = entry.value.build() as Result;
  assert(() {
    entry.value._debugPreviousResult = result;
    return true;
  }());
  currentElement._currentEntry = entry.next;
  return result;
}

/// This class makes it easier for a [Hook] to work with a complex data model.
@immutable
abstract class HookData<Result> {
  /// Creates a data object to be passed into a [Hook].
  const HookData({this.key});

  /// Changing this key's value will cause the [Hook] to reset.
  final Object? key;

  /// Uses a [HookData] instance to create a [Hook]
  /// and return its result.
  static Result use<Result>(HookData<Result> hookData, {String? debugLabel}) {
    return _use(
      hookData.createHook,
      data: hookData,
      key: hookData.key,
      debugLabel: debugLabel ?? describeIdentity(hookData),
    );
  }

  /// Generally returns an empty constructor for a [Hook] subclass.
  @protected
  @factory
  Hook<Result, HookData<Result>> createHook();
}

/// Prevents name overlap!
const _use = use;

/// Obtains the [BuildContext] of the building [HookWidget].
BuildContext useContext() {
  final BuildContext? result = HookElement._current;
  assert(result != null, '`useContext` can only be called during a HookWidget build() method.');
  return result!;
}
