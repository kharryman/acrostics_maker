import 'package:flutter/material.dart';

class NonDismissingPopupMenuItem<T> extends PopupMenuItem<T> {
  const NonDismissingPopupMenuItem(
      {super.key,
      super.value,
      super.onTap,
      super.enabled = true,
      super.height = kMinInteractiveDimension,
      super.padding,
      super.textStyle,
      super.labelTextStyle,
      super.mouseCursor,
      super.child});

  @override
  PopupMenuItemState<T, PopupMenuItem<T>> createState() =>
      _NonDismissingPopupMenuItem<T, PopupMenuItem<T>>();
}

class _NonDismissingPopupMenuItem<T, W extends PopupMenuItem<T>>
    extends PopupMenuItemState<T, W> {
  @override
  void handleTap() {
    widget.onTap?.call(); // this override prevents popup menu to close
  }
}
