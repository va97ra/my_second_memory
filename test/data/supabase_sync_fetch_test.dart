import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Столько строк Supabase отдаёт на один запрос по умолчанию (Max rows):
/// остальное молча отрезается, ошибки нет.
const _maxRows = 1000;

/// Таблица `sync_entities` одного пользователя за PostgREST: понимает
/// `revision=gt.N`, `order`, `offset` и `limit` и, как настоящий сервер, не
/// отдаёт за раз больше [maxRows] строк. Порядок — тот, что попросили:
/// `order=revision.desc` даёт строки от новых к старым.
class _Cloud {
  _Cloud(int count, {this.maxRows = _maxRows})
      : rows = [
          for (var revision = 1; revision <= count; revision++)
            (id: 'record-$revision', revision: revision),
        ];

  final int maxRows;
  List<({String id, int revision})> rows;

  /// Вызывается после каждого ответа: так строка меняется посреди чтения.
  void Function(int answered)? afterAnswer;
  var _answered = 0;

  /// Сколько запросов ушло в облако.
  int get requests => _answered;

  late final client = MockClient((request) async {
    final url = request.url;
    if (request.method != 'GET' ||
        !url.path.endsWith('/rest/v1/sync_entities')) {
      return http.Response('unexpected ${request.method} $url', 500);
    }
    final query = url.queryParameters;
    final after = query['revision']?.startsWith('gt.') == true
        ? int.parse(query['revision']!.substring(3))
        : 0;
    final offset = int.tryParse(query['offset'] ?? '') ?? 0;
    final asked = int.tryParse(query['limit'] ?? '');
    final limit = asked == null || asked > maxRows ? maxRows : asked;
    final descending = query['order']?.startsWith('revision.desc') == true;
    final page = (rows.where((row) => row.revision > after).toList()
          ..sort((a, b) => descending
              ? b.revision.compareTo(a.revision)
              : a.revision.compareTo(b.revision)))
        .skip(offset)
        .take(limit);
    final body = jsonEncode([
      for (final row in page)
        {
          'entity_kind': 'memory_item',
          'entity_id': row.id,
          'encrypted_payload': 'payload-${row.revision}',
          'updated_at': '2026-11-12T09:00:00Z',
          'deleted_at': null,
          'revision': row.revision,
        },
    ]);
    _answered++;
    afterAnswer?.call(_answered);
    return http.Response(
      body,
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
      request: request,
    );
  });
}

Future<SupabaseSyncRemoteStore> _signedInStore(_Cloud cloud) async {
  final client = SupabaseClient(
    'https://cloud.test',
    'anon-key',
    httpClient: cloud.client,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  // Токен не JWT, поэтому срока у сессии нет и сеть для входа не нужна.
  await client.auth.recoverSession(jsonEncode({
    'access_token': 'token',
    'token_type': 'bearer',
    'user': {
      'id': 'user-1',
      'aud': 'authenticated',
      'app_metadata': <String, Object?>{},
      'created_at': '2026-01-01T00:00:00Z',
    },
  }));
  return SupabaseSyncRemoteStore(client);
}

List<int> _revisions(int from, int to) =>
    [for (var revision = from; revision <= to; revision++) revision];

void main() {
  test('every cloud row reaches the device, not only the first page', () async {
    final store = await _signedInStore(_Cloud(2500));

    final entities = await store.fetchEntities();

    expect(entities, hasLength(2500));
    expect(
      entities.map((entity) => entity.revision),
      orderedEquals(_revisions(1, 2500)),
    );
  });

  test('each page moves the cursor past all of its rows', () async {
    // Курсор, вставший не на последнюю ревизию страницы, перечитывает её
    // снова и снова: 139 строк превращались в 139 запросов и таймаут.
    final cloud = _Cloud(2500);
    final store = await _signedInStore(cloud);

    await store.fetchEntities();

    // Три полные-неполные страницы и пустая в конце.
    expect(cloud.requests, 4);
  });

  test('a cloud that fits exactly into whole pages is read to the end',
      () async {
    final store = await _signedInStore(_Cloud(2 * _maxRows));

    expect(await store.fetchEntities(), hasLength(2 * _maxRows));
  });

  test('a project with a lower Max rows still gives everything', () async {
    final store = await _signedInStore(_Cloud(1200, maxRows: 500));

    expect(await store.fetchEntities(), hasLength(1200));
  });

  test('a row edited while reading arrives once, in its newest version',
      () async {
    final cloud = _Cloud(2500);
    cloud.afterAnswer = (answered) {
      // Другое устройство правит уже прочитанную запись: у неё новая ревизия,
      // и все строки за ней сдвигаются на одну позицию.
      if (answered != 1) return;
      cloud.rows = [
        for (final row in cloud.rows)
          if (row.id == 'record-5') (id: row.id, revision: 2501) else row,
      ];
    };
    final store = await _signedInStore(cloud);

    final entities = await store.fetchEntities();

    expect(entities, hasLength(2500));
    expect(
      entities.map((entity) => entity.entityId).toSet(),
      hasLength(2500),
    );
    expect(
      entities.singleWhere((entity) => entity.entityId == 'record-5').revision,
      2501,
    );
  });

  test('an empty cloud gives an empty list', () async {
    final store = await _signedInStore(_Cloud(0));

    expect(await store.fetchEntities(), isEmpty);
  });
}
