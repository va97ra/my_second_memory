import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tool_data/tool_data.dart';
import 'widgets/electrician_card_list.dart';
import 'widgets/electrician_learning_list.dart';
import 'widgets/electrician_tiles.dart';

/// Учебник электрика: разделы, поиск по ним и карточки.
///
/// Разделы переключаются внутри экрана, а не маршрутом: вкладка инструмента
/// одна, и перелистывание страницы принадлежит ей целиком.
class ElectricianScreen extends ConsumerStatefulWidget {
  const ElectricianScreen({super.key});

  @override
  ConsumerState<ElectricianScreen> createState() => _ElectricianScreenState();
}

class _ElectricianScreenState extends ConsumerState<ElectricianScreen> {
  final _search = TextEditingController();
  ElectricianSection? _section;
  ElectricianTrade? _trade;
  bool _favouritesOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final snapshot = ref.watch(toolDataControllerProvider).valueOrNull ??
        const ToolDataSnapshot();
    final favouriteIds = {for (final item in snapshot.bookmarks) item.entryId};
    final query = _search.text.trim();
    final showList = _section != null || query.isNotEmpty || _favouritesOnly;
    return ToolPageFrame(
      maxWidth: 840,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(
              children: [
                if (_section != null)
                  IconButton(
                    onPressed: () => setState(() => _section = null),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                  )
                else
                  const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _section == null
                        ? strings.electricianGuide
                        : sectionTitle(strings, _section!),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _favouritesOnly = !_favouritesOnly),
                  tooltip: strings.favorites,
                  icon: Icon(
                    _favouritesOnly
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const ValueKey('electrician_search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: strings.search,
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _section == ElectricianSection.learning
                ? ElectricianLearningList(query: query)
                : showList
                        ? ElectricianCardList(
                        cards: searchElectricianCards(
                          query,
                          ru: strings.isRu,
                          section: _section,
                          trade: _trade,
                          onlyIds: favouriteIds,
                          favouritesOnly: _favouritesOnly,
                        ),
                        favouriteIds: favouriteIds,
                        trade: _trade,
                        showTradeFilter:
                            _section == ElectricianSection.reference,
                        onTradeChanged: (value) =>
                            setState(() => _trade = value),
                      )
                    : ElectricianTiles(
                        onSelected: (section) => setState(() {
                          _section = section;
                          _trade = null;
                        }),
                      ),
          ),
        ],
      ),
    );
  }
}
