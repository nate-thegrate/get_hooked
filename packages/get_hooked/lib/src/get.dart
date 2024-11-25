/// Get hooked!
///
/// @docImport 'dart:ui';
/// @docImport 'hooked.dart';
/// @docImport 'ref.dart';
library;

import 'package:collection/collection.dart';
import 'package:collection_notifiers/collection_notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';

import '../utils/_all_utils.dart';
import 'hooked/builder/hooks.dart';
import 'ref.dart';

export 'package:flutter/foundation.dart' show ValueListenable;
export 'hooked/builder/hooks.dart';

part 'get/dispose_guard.dart';
part 'get/get.dart';
part 'get/scoped_get.dart';
part 'get/vsync.dart';

/// A `typedef` representing all objects that [Get] can represent.
typedef ValueRef = ValueListenable<Object?>;

/// Allows the hook functions defined in [Ref] to access
/// a [Get] object's [ValueListenable].
extension GetHooked<V extends ValueRef> on Get<Object?, V> {
  /// Don't get hooked.
  V get hooked => _hooked;
}
