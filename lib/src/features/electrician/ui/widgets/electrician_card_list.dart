import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tool_data/tool_data.dart';
import 'electrician_card_sheet.dart';
import 'electrician_art_view.dart';

/// Список карточек раздела или результатов поиска.
class ElectricianCardList extends ConsumerWidget {
  const ElectricianCardList({
    required this.cards,
    required this.favouriteIds,
    this.trade,
    this.showTradeFilter = false,
    this.onTradeChanged,
    super.key,
  });

  final List<ElectricianCard> cards;
  final Set<String> favouriteIds;
  final ElectricianTrade? trade;
  final bool showTradeFilter;
  final ValueChanged<ElectricianTrade?>? onTradeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final ru = strings.isRu;
    return Column(
      children: [
        if (showTradeFilter)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  selected: trade == null,
                  label: Text(strings.allRecords),
                  onSelected: (_) => onTradeChanged?.call(null),
                ),
                for (final value in ElectricianTrade.values) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: trade == value,
                    label: Text(_tradeLabel(strings, value)),
                    onSelected: (_) => onTradeChanged?.call(value),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: cards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      strings.nothingFound,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final favourite = favouriteIds.contains(card.id);
                    final art = hasElectricianArt(card.symbol);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        leading: art
                            ? ElectricianArtView(name: card.symbol, size: 44)
                            : null,
                        title: Text(card.title(ru)),
                        subtitle: Text(
                          card.what(ru),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () =>
                            showElectricianCardSheet(context, ref, card),
                        trailing: IconButton(
                          tooltip: strings.favorites,
                          onPressed: () => favourite
                              ? ref
                                  .read(toolDataControllerProvider.notifier)
                                  .deleteBookmark(card.id)
                              : ref
                                  .read(toolDataControllerProvider.notifier)
                                  .saveBookmark(entryId: card.id, note: ''),
                          icon: Icon(
                            favourite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _tradeLabel(AppStrings strings, ElectricianTrade value) =>
      switch (value) {
        ElectricianTrade.electrical => strings.electrical,
        ElectricianTrade.plumbing => strings.plumbing,
        ElectricianTrade.ventilation => strings.ventilation,
      };
}
