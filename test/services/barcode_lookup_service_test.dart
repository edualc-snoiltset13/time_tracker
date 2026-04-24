// test/services/barcode_lookup_service_test.dart
//
// Unit tests for BarcodeLookupService. Uses http's MockClient so no real
// network calls are made. The repository is backed by a temp directory.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:time_tracker/services/barcode_lookup_service.dart';
import 'package:time_tracker/services/item_repository.dart';

void main() {
  late Directory tempDir;
  late ItemRepository repo;

  Future<Directory> resolver() async => tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lookup_svc_test_');
    repo = ItemRepository(dirResolver: resolver);
  });

  tearDown(() async {
    repo.dispose();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  BarcodeLookupService withClient(http.Client client) => BarcodeLookupService(
        repository: repo,
        httpClient: client,
        timeout: const Duration(milliseconds: 200),
      );

  test('local hit returns BarcodeLookupSource.local without calling HTTP',
      () async {
    await repo.upsert(barcode: '555', name: 'Cached');
    var httpCalls = 0;
    final svc = withClient(MockClient((req) async {
      httpCalls++;
      return http.Response('{}', 200);
    }));
    addTearDown(svc.dispose);

    final result = await svc.identify('555');

    expect(result.source, BarcodeLookupSource.local);
    expect(result.item?.name, 'Cached');
    expect(httpCalls, 0, reason: 'local hit must short-circuit');
  });

  test('no local + valid OFF product → remote result', () async {
    final svc = withClient(MockClient((req) async {
      expect(req.url.path, contains('/api/v2/product/999.json'));
      return http.Response(
        jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Test Bar',
            'brands': 'Acme',
            'categories': 'Snacks,Chocolate',
            'quantity': '50 g',
            'image_small_url': 'https://example.com/img.jpg',
          },
        }),
        200,
      );
    }));
    addTearDown(svc.dispose);

    final result = await svc.identify('999');

    expect(result.source, BarcodeLookupSource.remote);
    expect(result.remote?.name, 'Test Bar');
    expect(result.remote?.brand, 'Acme');
    expect(result.remote?.category, 'Snacks');
    expect(result.remote?.unit, '50 g');
    expect(result.remote?.imageUrl, 'https://example.com/img.jpg');
    expect(result.remote?.source, 'openfoodfacts');
  });

  test('OFF status:0 → unknown with notFound error', () async {
    final svc = withClient(MockClient((req) async {
      return http.Response(jsonEncode({'status': 0}), 200);
    }));
    addTearDown(svc.dispose);

    final result = await svc.identify('888');
    expect(result.source, BarcodeLookupSource.unknown);
    expect(result.error, BarcodeLookupError.notFound);
  });

  test('HTTP 500 → unknown with network error', () async {
    final svc = withClient(MockClient((req) async {
      return http.Response('boom', 500);
    }));
    addTearDown(svc.dispose);

    final result = await svc.identify('777');
    expect(result.source, BarcodeLookupSource.unknown);
    expect(result.error, BarcodeLookupError.network);
  });

  test('timeout → unknown with timeout error', () async {
    final svc = withClient(MockClient((req) async {
      // Exceed the configured 200ms timeout.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return http.Response('{}', 200);
    }));
    addTearDown(svc.dispose);

    final result = await svc.identify('666');
    expect(result.source, BarcodeLookupSource.unknown);
    expect(result.error, BarcodeLookupError.timeout);
  });

  test('malformed JSON → unknown with parseError', () async {
    final svc = withClient(MockClient((req) async {
      return http.Response('not json at all', 200);
    }));
    addTearDown(svc.dispose);

    final result = await svc.identify('444');
    expect(result.source, BarcodeLookupSource.unknown);
    expect(result.error, BarcodeLookupError.parseError);
  });

  test('empty input returns unknown/emptyInput without touching HTTP',
      () async {
    var httpCalls = 0;
    final svc = withClient(MockClient((req) async {
      httpCalls++;
      return http.Response('{}', 200);
    }));
    addTearDown(svc.dispose);

    final result = await svc.identify('   ');
    expect(result.source, BarcodeLookupSource.unknown);
    expect(result.error, BarcodeLookupError.emptyInput);
    expect(httpCalls, 0);
  });

  test('records scan when identified (remote)', () async {
    final svc = withClient(MockClient((req) async {
      return http.Response(
        jsonEncode({
          'status': 1,
          'product': {'product_name': 'X'},
        }),
        200,
      );
    }));
    addTearDown(svc.dispose);

    await svc.identify('100', format: 'EAN_13');

    final scans = await repo.watchScans().first;
    expect(scans, hasLength(1));
    expect(scans.first.barcode, '100');
    expect(scans.first.format, 'EAN_13');
  });

  test('records scan with itemId on local hit', () async {
    final saved = await repo.upsert(barcode: '200', name: 'Local');
    final svc = withClient(MockClient((req) async {
      fail('must not call HTTP on local hit');
    }));
    addTearDown(svc.dispose);

    await svc.identify('200');

    final scans = await repo.watchScans().first;
    expect(scans.first.itemId, saved.id);
  });

  test('recordScan: false does not create history entry', () async {
    final svc = withClient(MockClient((req) async {
      return http.Response(jsonEncode({'status': 0}), 200);
    }));
    addTearDown(svc.dispose);

    await svc.identify('300', recordScan: false);

    final scans = await repo.watchScans().first;
    expect(scans, isEmpty);
  });
}
