part of '../hook_ref.dart';

/// Allows accessing the relevant value from an ancestor [SubScope] in a reasonably
/// concise manner.
extension GetFromContext on BuildContext {
  /// Allows accessing the relevant value from an ancestor [SubScope] in a reasonably
  /// concise manner.
  V get<V extends ValueListenable<Object?>>(
    V get, {
    bool createDependency = true,
    bool throwIfMissing = false,
  }) {
    return SubScope.of(
      this,
      get,
      createDependency: createDependency,
      throwIfMissing: throwIfMissing,
    );
  }
}
