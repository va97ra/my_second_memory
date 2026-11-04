import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import 'account_copy_button.dart';

/// Заметка аккаунта под его полями.
class AccountNoteBox extends StatelessWidget {
  const AccountNoteBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            AccountCopyButton(
              text: text,
              tooltip: strings.copyNote,
              copiedMessage: strings.noteCopied,
            ),
          ],
        ),
      ),
    );
  }
}
