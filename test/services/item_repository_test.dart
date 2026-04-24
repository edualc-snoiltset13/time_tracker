// test/services/item_repository_test.dart
//
// Unit tests for ItemRepository. We inject a temp directory resolver so no
// platform channels (path_provider) are needed — tests run under the default
// `flutter test` VM.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:time_tracker/services/item_repository.dart';

void main() {
  late Directory tempDir;

  Future<Directory> resolver() async => tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('item_repo_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('upsert inserts a new item with an id and timestamps', () async {
    final repo = ItemRepository(dirResolver: resolver);
    addTearDown(repo.dispose);

    final created = await repo.upsert(barcode: '123', name: 'Coffee');

    expect(created.id, isNotEmpty);
    expect(created.barcode, '123');
    expect(created.name, 'Coffee');
    expect(created.createdAt, isNotNull);
    expect(created.updatedAt, created.createdAt);
    expect(created.source, 'manual');
  });

  test('upsert by existing barcode preserves id and createdAt', () async {
    final repo = ItemRepository(dirResolver: resolver);
    addTearDown(repo.dispose);

    final first = await repo.upsert(barcode: '456', name: 'First');
    // Give the clock a chance to advance so updatedAt differs.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = await repo.upsert(barcode: '456', name: 'Renamed');

    expect(second.id, first.id);
    expect(second.createdAt, first.createdAt);
    expect(second.name, 'Renamed');
    expect(second.updatedAt.isAfter(first.updatedAt) ||
        second.updatedAt.isAtSameMomentAs(first.updatedAt), isTrue);
  });

  test('findByBarcode returns null when absent', () async {
    final repo = ItemRepository(dirResolver: resolver);
    addTearDown(repo.dispose);

    expect(await repo.findByBarcode('nope'), isNull);
  });

  test('findByBarcode returns the persisted item', () async {
    final repo = ItemRepository(dirResolver: resolver);
    addTearDown(repo.dispose);

    final saved = await repo.upsert(barcode: '789', name: 'Thing');
    final found = await repo.findByBarcode('789');
    expect(found?.id, saved.id);
  });

  test('findById returns the persisted item', () async {
    final repo = ItemRepository(dirResolver: resolver);
    addTearDown(repo.dispose);

    final saved = await repo.upsert(barcode: '111', name: 'Widget');
    expect((await repo.findById(saved.id))?.name, 'Widget');
    expect(await repo.findById('nonexistent'), isNull);
  });

  test('deleteById removes the item', () async {
    final repo = ItemRepository(dirResolver: resolver);
    addTearDown(repo.dispose);

    final saved = await repo.upsert(barcode: '222', name: 'Gone');
    await repo.deleteById(saved.id);
    expect(await repo.findById(saved.id), isNull);
    expect(await repo.findByBarcode('222'), isNull);
  });

  test('recordScan inserts at the head of scan history', () async {
    final repo = ItemRepository(dirResolver: resolver);
    addTearDown(repo.dispose);

    await repo.recordScan(barcode: 'a');
    await repo.recordScan(barcode: 'b');
    await repo.recordScan(barcode: 'c');

    // watchScans yields the current list immediately.
    final scans = await repo.watchScans().first;
    expect(scans.map((s) => s.barcode).toList(), ['c', 'b', 'a']);
  });

  test('scans persist across repository instances', () async {
    final repo1 = ItemRepository(dirResolver: resolver);
    await repo1.recordScan(barcode: 'persisted');
    repo1.dispose();

    final repo2 = ItemRepository(dirResolver: resolver);
    addTearDown(repo2.dispose);

    final scans = await repo2.watchScans().first;
    expect(scans.first.barcode, 'persisted');
  });

  test('items persist across repository instances', () async {
    final repo1 = ItemRepository(dirResolver: resolver);
    final saved = await repo1.upsert(barcode: 'p1', name: 'Persisted');
    repo1.dispose();

    final repo2 = ItemRepository(dirResolver: resolver);
    addTearDown(repo2.dispose);

    final found = await repo2.findByBarcode('p1');
    expect(found?.id, saved.id);
    expect(found?.name, 'Persisted');
  });

  test('corrupt items.json is treated as empty', () async {
    // Write garbage to the items file; repo should load as if empty rather
    // than throw.
    final f = File(p.join(tempDir.path, 'items.json'));
    await f.writeAsString('not valid json');

    final repo = ItemRepository(dirResolver: resolver);
    addTearDown(repo.dispose);

    expect(await repo.getAllItems(), isEmpty);
  });

  test('clearScanHistory empties the history but keeps items', () async {
    final repo = ItemRepository(dirResolver: resolver);
    addTearDown(repo.dispose);

    await repo.upsert(barcode: 'x', name: 'Keep me');
    await repo.recordScan(barcode: 'x');
    await repo.clearScanHistory();

    expect(await repo.watchScans().first, isEmpty);
    expect((await repo.findByBarcode('x'))?.name, 'Keep me');
  });
}
