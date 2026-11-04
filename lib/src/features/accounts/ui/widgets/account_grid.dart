import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/sticker_paper.dart';
import 'account_card.dart';

/// Сколько карточек аккаунтов в ряду: на телефоне две, на широком экране ряд
/// длиннее, чтобы карточки не вырастали во весь лист.
int accountCardColumns(double width) => math.max(2, width ~/ 240);

/// Ряды карточек аккаунтов внутри прокрутки.
class AccountGrid extends StatelessWidget {
  const AccountGrid({super.key, required this.accountIds});

  final List<String> accountIds;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: StickerPaper.gridEdge,
        vertical: 4,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) => SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: accountCardColumns(constraints.crossAxisExtent),
            mainAxisExtent: AccountCard.heightOf(context),
            mainAxisSpacing: StickerPaper.gridGap,
            crossAxisSpacing: StickerPaper.gridGap,
          ),
          itemCount: accountIds.length,
          itemBuilder: (context, index) => AccountCard(
            key: ValueKey(accountIds[index]),
            accountId: accountIds[index],
          ),
        ),
      ),
    );
  }
}
