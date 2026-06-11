@internal
library;

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Updates the nodes of `oldSemantics` using data in `newChildSemantics`, and
/// returns a new list containing child nodes sorted according to the order
/// specified by `newChildSemantics`.
///
/// [SemanticsNode]s that match [CustomPainterSemantics] by [Key]s preserve
/// their [SemanticsNode.key] field. If a node with the same key appears in
/// a different position in the list, it is moved to the new position, but the
/// same object is reused.
///
/// [SemanticsNode]s whose `key` is null may be updated from
/// [CustomPainterSemantics] whose `key` is also null. However, the algorithm
/// does not guarantee it. If your semantics require that specific nodes are
/// updated from specific [CustomPainterSemantics], it is recommended to match
/// them by specifying non-null keys.
///
/// The algorithm tries to be as close to [RenderObjectElement.updateChildren]
/// as possible, deviating only where the concepts diverge between widgets and
/// semantics. For example, a [SemanticsNode] can be updated from a
/// [CustomPainterSemantics] based on `Key` alone; their types are not
/// considered because there is only one type of [SemanticsNode]. There is no
/// concept of a "forgotten" node in semantics, deactivated nodes, or global
/// keys.
List<SemanticsNode> updateSemanticsChildren(
  List<SemanticsNode>? oldSemantics,
  List<CustomPainterSemantics>? newChildSemantics,
) {
  oldSemantics = oldSemantics ?? const <SemanticsNode>[];
  newChildSemantics = newChildSemantics ?? const <CustomPainterSemantics>[];

  if (kDebugMode) {
    final keys = HashMap<Object, int>();
    final information = <DiagnosticsNode>[];
    for (int i = 0; i < newChildSemantics.length; i += 1) {
      final CustomPainterSemantics child = newChildSemantics[i];
      if (child.key != null) {
        if (keys.containsKey(child.key)) {
          information.add(ErrorDescription('- duplicate key ${child.key} found at position $i'));
        }
        keys[child.key!] = i;
      }
    }

    if (information.isNotEmpty) {
      information.insert(0, ErrorSummary('Failed to update the list of CustomPainterSemantics:'));
      throw FlutterError.fromParts(information);
    }
  }

  int newChildrenTop = 0;
  int oldChildrenTop = 0;
  int newChildrenBottom = newChildSemantics.length - 1;
  int oldChildrenBottom = oldSemantics.length - 1;

  final List<SemanticsNode?> newChildren = List<SemanticsNode?>.filled(
    newChildSemantics.length,
    null,
  );

  // Update the top of the list.
  while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
    final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
    final CustomPainterSemantics newSemantics = newChildSemantics[newChildrenTop];
    if (!_canUpdateSemanticsChild(oldChild, newSemantics)) {
      break;
    }
    final SemanticsNode newChild = _updateSemanticsChild(oldChild, newSemantics);
    newChildren[newChildrenTop] = newChild;
    newChildrenTop += 1;
    oldChildrenTop += 1;
  }

  // Scan the bottom of the list.
  while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
    final SemanticsNode oldChild = oldSemantics[oldChildrenBottom];
    final CustomPainterSemantics newChild = newChildSemantics[newChildrenBottom];
    if (!_canUpdateSemanticsChild(oldChild, newChild)) {
      break;
    }
    oldChildrenBottom -= 1;
    newChildrenBottom -= 1;
  }

  // Scan the old children in the middle of the list.
  final bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
  late final Map<Key, SemanticsNode> oldKeyedChildren;
  if (haveOldChildren) {
    oldKeyedChildren = <Key, SemanticsNode>{};
    while (oldChildrenTop <= oldChildrenBottom) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
      if (oldChild.key != null) {
        oldKeyedChildren[oldChild.key!] = oldChild;
      }
      oldChildrenTop += 1;
    }
  }

  // Update the middle of the list.
  while (newChildrenTop <= newChildrenBottom) {
    SemanticsNode? oldChild;
    final CustomPainterSemantics newSemantics = newChildSemantics[newChildrenTop];
    if (haveOldChildren) {
      final Key? key = newSemantics.key;
      if (key != null) {
        oldChild = oldKeyedChildren[key];
        if (oldChild != null) {
          if (_canUpdateSemanticsChild(oldChild, newSemantics)) {
            // we found a match!
            // remove it from oldKeyedChildren so we don't unsync it later
            oldKeyedChildren.remove(key);
          } else {
            // Not a match, let's pretend we didn't see it for now.
            oldChild = null;
          }
        }
      }
    }
    assert(oldChild == null || _canUpdateSemanticsChild(oldChild, newSemantics));
    final SemanticsNode newChild = _updateSemanticsChild(oldChild, newSemantics);
    assert(oldChild == newChild || oldChild == null);
    newChildren[newChildrenTop] = newChild;
    newChildrenTop += 1;
  }

  // We've scanned the whole list.
  assert(oldChildrenTop == oldChildrenBottom + 1);
  assert(newChildrenTop == newChildrenBottom + 1);
  assert(newChildSemantics.length - newChildrenTop == oldSemantics.length - oldChildrenTop);
  newChildrenBottom = newChildSemantics.length - 1;
  oldChildrenBottom = oldSemantics.length - 1;

  // Update the bottom of the list.
  while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
    final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
    final CustomPainterSemantics newSemantics = newChildSemantics[newChildrenTop];
    assert(_canUpdateSemanticsChild(oldChild, newSemantics));
    final SemanticsNode newChild = _updateSemanticsChild(oldChild, newSemantics);
    assert(oldChild == newChild);
    newChildren[newChildrenTop] = newChild;
    newChildrenTop += 1;
    oldChildrenTop += 1;
  }

  if (kDebugMode) {
    for (final SemanticsNode? node in newChildren) {
      assert(node != null);
    }
  }

  return newChildren.cast<SemanticsNode>();
}

/// Whether `oldChild` can be updated with properties from `newSemantics`.
///
/// If `oldChild` can be updated, it is updated using [_updateSemanticsChild].
/// Otherwise, the node is replaced by a new instance of [SemanticsNode].
bool _canUpdateSemanticsChild(SemanticsNode oldChild, CustomPainterSemantics newSemantics) {
  return oldChild.key == newSemantics.key;
}

/// Updates `oldChild` using the properties of `newSemantics`.
///
/// This method requires that `_canUpdateSemanticsChild(oldChild, newSemantics)`
/// is true prior to calling it.
SemanticsNode _updateSemanticsChild(
  SemanticsNode? oldChild,
  CustomPainterSemantics newSemantics,
) {
  assert(oldChild == null || _canUpdateSemanticsChild(oldChild, newSemantics));

  final SemanticsNode newChild = oldChild ?? SemanticsNode(key: newSemantics.key);

  final SemanticsProperties properties = newSemantics.properties;
  final SemanticsConfiguration config = SemanticsConfiguration();
  if (properties.sortKey != null) {
    config.sortKey = properties.sortKey;
  }
  if (properties.checked != null) {
    config.isChecked = properties.checked;
  }
  if (properties.mixed != null) {
    config.isCheckStateMixed = properties.mixed;
  }
  if (properties.selected != null) {
    config.isSelected = properties.selected!;
  }
  if (properties.button != null) {
    config.isButton = properties.button!;
  }
  if (properties.expanded != null) {
    config.isExpanded = properties.expanded;
  }
  if (properties.link != null) {
    config.isLink = properties.link!;
  }
  if (properties.linkUrl != null) {
    config.linkUrl = properties.linkUrl;
  }
  if (properties.textField != null) {
    config.isTextField = properties.textField!;
  }
  if (properties.slider != null) {
    config.isSlider = properties.slider!;
  }
  if (properties.keyboardKey != null) {
    config.isKeyboardKey = properties.keyboardKey!;
  }
  if (properties.readOnly != null) {
    config.isReadOnly = properties.readOnly!;
  }
  if (properties.focused != null) {
    config.isFocused = properties.focused;
  }
  if (properties.enabled != null) {
    config.isEnabled = properties.enabled;
  }
  if (properties.inMutuallyExclusiveGroup != null) {
    config.isInMutuallyExclusiveGroup = properties.inMutuallyExclusiveGroup!;
  }
  if (properties.obscured != null) {
    config.isObscured = properties.obscured!;
  }
  if (properties.multiline != null) {
    config.isMultiline = properties.multiline!;
  }
  if (properties.hidden != null) {
    config.isHidden = properties.hidden!;
  }
  if (properties.header != null) {
    config.isHeader = properties.header!;
  }
  if (properties.headingLevel != null) {
    config.headingLevel = properties.headingLevel!;
  }
  if (properties.scopesRoute != null) {
    config.scopesRoute = properties.scopesRoute!;
  }
  if (properties.namesRoute != null) {
    config.namesRoute = properties.namesRoute!;
  }
  if (properties.liveRegion != null) {
    config.liveRegion = properties.liveRegion!;
  }
  if (properties.maxValueLength != null) {
    config.maxValueLength = properties.maxValueLength;
  }
  if (properties.currentValueLength != null) {
    config.currentValueLength = properties.currentValueLength;
  }
  if (properties.toggled != null) {
    config.isToggled = properties.toggled;
  }
  if (properties.image != null) {
    config.isImage = properties.image!;
  }
  if (properties.label != null) {
    config.label = properties.label!;
  }
  if (properties.value != null) {
    config.value = properties.value!;
  }
  if (properties.increasedValue != null) {
    config.increasedValue = properties.increasedValue!;
  }
  if (properties.decreasedValue != null) {
    config.decreasedValue = properties.decreasedValue!;
  }
  if (properties.hint != null) {
    config.hint = properties.hint!;
  }
  if (properties.textDirection != null) {
    config.textDirection = properties.textDirection;
  }
  if (properties.onTap != null) {
    config.onTap = properties.onTap;
  }
  if (properties.onLongPress != null) {
    config.onLongPress = properties.onLongPress;
  }
  if (properties.onScrollLeft != null) {
    config.onScrollLeft = properties.onScrollLeft;
  }
  if (properties.onScrollRight != null) {
    config.onScrollRight = properties.onScrollRight;
  }
  if (properties.onScrollUp != null) {
    config.onScrollUp = properties.onScrollUp;
  }
  if (properties.onScrollDown != null) {
    config.onScrollDown = properties.onScrollDown;
  }
  if (properties.onIncrease != null) {
    config.onIncrease = properties.onIncrease;
  }
  if (properties.onDecrease != null) {
    config.onDecrease = properties.onDecrease;
  }
  if (properties.onCopy != null) {
    config.onCopy = properties.onCopy;
  }
  if (properties.onCut != null) {
    config.onCut = properties.onCut;
  }
  if (properties.onPaste != null) {
    config.onPaste = properties.onPaste;
  }
  if (properties.onMoveCursorForwardByCharacter != null) {
    config.onMoveCursorForwardByCharacter = properties.onMoveCursorForwardByCharacter;
  }
  if (properties.onMoveCursorBackwardByCharacter != null) {
    config.onMoveCursorBackwardByCharacter = properties.onMoveCursorBackwardByCharacter;
  }
  if (properties.onMoveCursorForwardByWord != null) {
    config.onMoveCursorForwardByWord = properties.onMoveCursorForwardByWord;
  }
  if (properties.onMoveCursorBackwardByWord != null) {
    config.onMoveCursorBackwardByWord = properties.onMoveCursorBackwardByWord;
  }
  if (properties.onSetSelection != null) {
    config.onSetSelection = properties.onSetSelection;
  }
  if (properties.onSetText != null) {
    config.onSetText = properties.onSetText;
  }
  if (properties.onDidGainAccessibilityFocus != null) {
    config.onDidGainAccessibilityFocus = properties.onDidGainAccessibilityFocus;
  }
  if (properties.onDidLoseAccessibilityFocus != null) {
    config.onDidLoseAccessibilityFocus = properties.onDidLoseAccessibilityFocus;
  }
  if (properties.onFocus != null) {
    config.onFocus = properties.onFocus;
  }
  if (properties.onDismiss != null) {
    config.onDismiss = properties.onDismiss;
  }

  newChild.updateWith(config: config, childrenInInversePaintOrder: const <SemanticsNode>[]);

  newChild
    ..rect = newSemantics.rect
    ..transform = newSemantics.transform
    ..tags = newSemantics.tags;

  return newChild;
}
