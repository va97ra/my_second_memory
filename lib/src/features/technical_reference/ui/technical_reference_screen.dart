import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tool_data/tool_data.dart';
import 'widgets/reference_entry_sheet.dart';

class TechnicalReferenceScreen extends ConsumerStatefulWidget {
  const TechnicalReferenceScreen({super.key});

  @override
  ConsumerState<TechnicalReferenceScreen> createState() =>
      _TechnicalReferenceScreenState();
}

class _TechnicalReferenceScreenState
    extends ConsumerState<TechnicalReferenceScreen> {
  final _search = TextEditingController();
  TechnicalDiscipline? _discipline;
  bool _favoritesOnly = false;

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
    final favoriteIds = {for (final item in snapshot.bookmarks) item.entryId};
    final query = _search.text.trim().toLowerCase();
    final entries = technicalReferenceEntries.where((entry) {
      if (_discipline != null && entry.discipline != _discipline) return false;
      if (_favoritesOnly && !favoriteIds.contains(entry.id)) return false;
      if (query.isEmpty) return true;
      return [
        entry.title(strings.isRu),
        entry.body(strings.isRu),
        ...entry.aliases
      ].join(' ').toLowerCase().contains(query);
    }).toList();
    return ToolPageFrame(
      maxWidth: 840,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              key: const ValueKey('reference_search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: strings.search,
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  selected: _discipline == null,
                  label: Text(strings.allRecords),
                  onSelected: (_) => setState(() => _discipline = null),
                ),
                for (final value in TechnicalDiscipline.values) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _discipline == value,
                    label: Text(_disciplineLabel(value, strings)),
                    onSelected: (_) => setState(() => _discipline = value),
                  ),
                ],
                const SizedBox(width: 8),
                FilterChip(
                  selected: _favoritesOnly,
                  avatar: const Icon(Icons.star_outline_rounded, size: 18),
                  label: Text(strings.favorites),
                  onSelected: (value) => setState(() => _favoritesOnly = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final bookmark = snapshot.bookmarks
                    .where((item) => item.entryId == entry.id)
                    .firstOrNull;
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    title: Text(entry.title(strings.isRu)),
                    subtitle: Text(
                      entry.body(strings.isRu),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => showReferenceEntrySheet(context, ref, entry),
                    trailing: IconButton(
                      tooltip: strings.favorites,
                      onPressed: () => bookmark == null
                          ? ref
                              .read(toolDataControllerProvider.notifier)
                              .saveBookmark(entryId: entry.id, note: '')
                          : ref
                              .read(toolDataControllerProvider.notifier)
                              .deleteBookmark(entry.id),
                      icon: Icon(bookmark == null
                          ? Icons.star_outline_rounded
                          : Icons.star_rounded),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _disciplineLabel(TechnicalDiscipline value, AppStrings strings) =>
    switch (value) {
      TechnicalDiscipline.electrical => strings.electrical,
      TechnicalDiscipline.plumbing => strings.plumbing,
      TechnicalDiscipline.ventilation => strings.ventilation,
    };
