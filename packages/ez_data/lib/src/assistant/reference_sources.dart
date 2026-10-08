import 'package:ez_domain/ez_domain.dart';
import 'package:xml/xml.dart';

import 'online_fetch.dart';

/// Справка из русской Википедии.
///
/// У владельца на мобильном МТС Википедия закрыта. Тогда нейросеть получает
/// не молчание, а указание: ответить по своим знаниям и предупредить, что
/// это по памяти.
class WikipediaSource {
  WikipediaSource(this._fetch);

  final OnlineFetch _fetch;

  Future<Map<String, Object?>> lookup(String query) async {
    try {
      return await _lookup(query);
    } on _NotFound catch (missing) {
      throw OnlineException(missing.message);
    } on OnlineException {
      throw const OnlineException(
          'Википедия сейчас недоступна (возможно, её ограничивает оператор '
          'связи). Ответь по своим знаниям и предупреди, что это по памяти.');
    }
  }

  Future<Map<String, Object?>> _lookup(String query) async {
    final search = await _fetch.json(Uri.https('ru.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'list': 'search',
      'srsearch': query,
      'srlimit': '1',
      'format': 'json',
      'utf8': '1',
    })) as Map;
    final hits = ((search['query'] as Map?)?['search'] as List?) ?? const [];
    if (hits.isEmpty) throw _NotFound('В Википедии нет статьи про «$query»');
    final title = (hits.first as Map)['title'] as String;
    final page = await _fetch.json(Uri.https('ru.wikipedia.org',
            '/api/rest_v1/page/summary/${Uri.encodeComponent(title.replaceAll(' ', '_'))}'))
        as Map;
    var summary = (page['extract'] as String? ?? '').trim();
    if (summary.length > 900) summary = '${summary.substring(0, 897)}…';
    return {
      'source': 'Википедия',
      'title': page['title'] ?? title,
      'summary': summary,
    };
  }
}

class _NotFound implements Exception {
  const _NotFound(this.message);

  final String message;
}

/// Свежие заголовки новостей: RSS ТАСС, РИА Новости и Ленты.ру.
class NewsSource {
  NewsSource(this._fetch);

  final OnlineFetch _fetch;

  static const _feeds = {
    'ТАСС': 'https://tass.ru/rss/v2.xml',
    'РИА Новости': 'https://ria.ru/export/rss2/archive/index.xml',
    'Лента.ру': 'https://lenta.ru/rss/news',
  };

  /// До [limit] свежих заголовков; [topic] — оставить только про это.
  /// Одна сломанная лента не мешает остальным; молчат все — нет сети.
  Future<Map<String, Object?>> headlines({String? topic, int limit = 5}) async {
    final stems = searchStems(topic ?? '');
    final items = <NewsItem>[];
    var failures = 0;
    for (final feed in _feeds.entries) {
      try {
        items.addAll(parseRss(await _fetch.text(Uri.parse(feed.value)), feed.key));
      } on OnlineException {
        failures++;
      }
    }
    if (failures == _feeds.length) throw const OnlineException('Нет интернета');
    final matching = [
      for (final item in items)
        if (stems.every(normalizePhrase(item.title).contains)) item,
    ]..sort((left, right) =>
        (right.at ?? DateTime(0)).compareTo(left.at ?? DateTime(0)));
    return {
      'source': _feeds.keys.join(', '),
      if (topic != null && topic.isNotEmpty) 'topic': topic,
      'news': [
        for (final item in matching.take(limit))
          {'title': item.title, 'source': item.source},
      ],
    };
  }

  /// Заголовки из RSS 2.0; сломанная лента — пустой список.
  static List<NewsItem> parseRss(String xml, String source) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException {
      return const [];
    }
    return [
      for (final item in document.findAllElements('item'))
        if ((item.getElement('title')?.innerText.trim() ?? '').isNotEmpty)
          NewsItem(
            title: item.getElement('title')!.innerText.trim(),
            source: source,
            at: _rfc822(item.getElement('pubDate')?.innerText),
          ),
    ];
  }

  static const _months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  /// «Wed, 07 Oct 2026 16:50:52 +0300» → момент в UTC.
  static DateTime? _rfc822(String? value) {
    final match = RegExp(r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) '
            r'([+-])(\d{2})(\d{2})')
        .firstMatch(value ?? '');
    if (match == null) return null;
    final month = _months[match.group(2)];
    if (month == null) return null;
    final utc = DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
    final offset = Duration(
      hours: int.parse(match.group(8)!),
      minutes: int.parse(match.group(9)!),
    );
    return match.group(7) == '+' ? utc.subtract(offset) : utc.add(offset);
  }
}

/// Один заголовок новостей.
class NewsItem {
  const NewsItem({required this.title, required this.source, this.at});

  final String title;
  final String source;
  final DateTime? at;
}
