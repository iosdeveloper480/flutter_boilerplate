import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/config/constants.dart';
// import 'package:flutter_boilerplate/screens/widgets/custom_linkify/custom_linkify.dart';
import 'package:flutter_boilerplate/styles/styles.dart';
import 'package:flutter_boilerplate/utils/utils.dart';

extension ContextMenuBuilder on Widget {
  Widget contextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final int start = editableTextState.textEditingValue.selection.base.offset;
    final int end = editableTextState.textEditingValue.selection.end;

    final List<ContextMenuButtonItem> items = <ContextMenuButtonItem>[
      ...editableTextState.contextMenuButtonItems,
    ];

    if (start != -1 && end != -1) {
      final String text = "";
      final String selectedText = text.substring(start, end);

      items.addAll(<ContextMenuButtonItem>[
        ContextMenuButtonItem(
          onPressed: () => LinkUtil.launch(
            '''${Constants.wikipediaLink}$selectedText''',
            context,
          ),
          label: 'Wikipedia',
        ),
        ContextMenuButtonItem(
          onPressed: () => LinkUtil.launch(
            '''${Constants.wiktionaryLink}$selectedText''',
            context,
          ),
          label: 'Wiktionary',
        ),
      ]);
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: items,
    );
  }
}

extension WidgetModifier on Widget {
  Widget padded([
    EdgeInsetsGeometry value = const EdgeInsets.all(Dimens.pt12),
  ]) {
    return Padding(
      padding: value,
      child: this,
    );
  }
}
