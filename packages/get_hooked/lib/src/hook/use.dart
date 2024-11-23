part of '_hook.dart';

/// Signature for a callback that returns a [Hook].
typedef GetHook<Result, Data> = ValueGetter<Hook<Result, Data>>;

/// Registers a [Hook] and returns its value.
///
/// Must be called from within a [HookWidget.build] method.
/// See [Hook] for more explanation.
Result use<Result, Data>(
  GetHook<Result, Data> getHook, {
  required Data data,
  required Object? key,
  required String? debugLabel,
}) {
  final HookElement? hookElement = Hook._currentElement;
  if (hookElement == null) {
    assert(
      throw FlutterError.fromParts([
        ErrorSummary(
          'Attempted to access ${debugLabel ?? 'a Hook'} '
          "outside of a hook widget's build method.",
        ),
      ]),
    );
    return getHook().build();
  }
  final _HookEntry? currentEntry = hookElement._currentEntry;

  Hook<Result, Data> init() {
    assert(Hook._debugInitializing = true);
    final Hook<Result, Data> hook =
        getHook()
          .._key = key
          .._data = data
          .._element = hookElement
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
      (hookElement._needDispose ??= LinkedList()).add(_HookEntry(hook));
      entry.value = init();
    } else if (data != oldData) {
      entry.value
        .._data = data
        ..didUpdate(oldData);
    }
  } else {
    if (currentEntry != null) {
      hookElement._unmountAllRemainingHooks();
      if (!hookElement._debugDidReassemble) {
        throw StateError(
          'Type mismatch between hooks:\n'
          '  - old hook: ${currentEntry.value.runtimeType}\n'
          '  - current hook: ${debugLabel ?? getHook().runtimeType.toString()}',
        );
      }
    }
    entry = _HookEntry(init());
    hookElement
      .._currentEntry = entry
      .._hooks.add(entry);
  }

  final Result result = entry.value.build() as Result;
  assert(() {
    entry.value._debugPreviousResult = result;
    return true;
  }());
  hookElement._currentEntry = entry.next;
  return result;
}

/// If a class is being declared just to store data for a [Hook],
/// it might as well extend [HookData].
@immutable
abstract class HookData<Result> {
  /// Creates a data object to be passed into a [Hook].
  const HookData({this.key});

  /// Changing this key's value will cause the [Hook] to reset.
  final Object? key;

  /// Uses an [HookData] instance to create a [Hook]
  /// and return its result.
  static Result use<Result>(HookData<Result> hookData, {String? debugLabel}) {
    return _use(hookData.createHook, data: hookData, key: hookData.key, debugLabel: debugLabel);
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
  final BuildContext? result = Hooked.active ?? Hook._currentElement;
  assert(result != null, '`useContext` can only be called from the build method of HookWidget');
  return result!;
}
