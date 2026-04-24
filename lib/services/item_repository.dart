// lib/services/item_repository.dart
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:time_tracker/models/item.dart';

/// File-backed repository for barcoded items and scan events.
///
/// Items are keyed by barcode (unique). Each write persists the full list
/// as JSON and pushes to the broadcast streams so UI widgets can rebuild.
class ItemRepository {
  ItemRepository._();
  static final ItemRepository instance = ItemRepository._();

  static const _itemsFileName = 'items.json';
  static const _scansFileName = 'barcode_scans.json';
  static const _maxScanHistory = 500;

  final _uuid = const Uuid();

  final _itemsController = StreamController<List<Item>>.broadcast();
  final _scansController = StreamController<List<ScanEvent>>.broadcast();

  List<Item>? _cachedItems;
  List<ScanEvent>? _cachedScans;
  bool _initialized = false;
  Future<void>? _initFuture;

  Future<File> _fileFor(String name) async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, name));
  }

  Future<void> _ensureInit() {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _cachedItems = await _loadItems();
    _cachedScans = await _loadScans();
    _initialized = true;
    _itemsController.add(List.unmodifiable(_cachedItems!));
    _scansController.add(List.unmodifiable(_cachedScans!));
  }

  Future<List<Item>> _loadItems() async {
    final file = await _fileFor(_itemsFileName);
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      return itemsFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  Future<List<ScanEvent>> _loadScans() async {
    final file = await _fileFor(_scansFileName);
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      return scansFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistItems() async {
    final file = await _fileFor(_itemsFileName);
    await file.writeAsString(itemsToJson(_cachedItems ?? []));
    _itemsController.add(List.unmodifiable(_cachedItems ?? const []));
  }

  Future<void> _persistScans() async {
    final file = await _fileFor(_scansFileName);
    await file.writeAsString(scansToJson(_cachedScans ?? []));
    _scansController.add(List.unmodifiable(_cachedScans ?? const []));
  }

  /// Emits the current items list and every subsequent change.
  Stream<List<Item>> watchItems() async* {
    await _ensureInit();
    yield List.unmodifiable(_cachedItems ?? const []);
    yield* _itemsController.stream;
  }

  /// Emits the current scan history (most recent first) and every subsequent change.
  Stream<List<ScanEvent>> watchScans() async* {
    await _ensureInit();
    yield List.unmodifiable(_cachedScans ?? const []);
    yield* _scansController.stream;
  }

  Future<List<Item>> getAllItems() async {
    await _ensureInit();
    return List.unmodifiable(_cachedItems ?? const []);
  }

  Future<Item?> findByBarcode(String barcode) async {
    await _ensureInit();
    for (final item in _cachedItems!) {
      if (item.barcode == barcode) return item;
    }
    return null;
  }

  Future<Item?> findById(String id) async {
    await _ensureInit();
    for (final item in _cachedItems!) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Upserts an item by barcode. If an item with the same barcode exists, it
  /// is updated (preserving id + createdAt); otherwise a new one is created.
  Future<Item> upsert({
    required String barcode,
    required String name,
    String? brand,
    String? description,
    String? category,
    String? unit,
    double? price,
    String? currency,
    String? imageUrl,
    String? source,
  }) async {
    await _ensureInit();
    final now = DateTime.now();
    final existingIdx =
        _cachedItems!.indexWhere((i) => i.barcode == barcode);

    if (existingIdx >= 0) {
      final existing = _cachedItems![existingIdx];
      final updated = existing.copyWith(
        name: name,
        brand: brand,
        description: description,
        category: category,
        unit: unit,
        price: price,
        currency: currency,
        imageUrl: imageUrl,
        source: source,
        updatedAt: now,
      );
      _cachedItems![existingIdx] = updated;
      await _persistItems();
      return updated;
    }

    final created = Item(
      id: _uuid.v4(),
      barcode: barcode,
      name: name,
      brand: brand,
      description: description,
      category: category,
      unit: unit,
      price: price,
      currency: currency,
      imageUrl: imageUrl,
      source: source ?? 'manual',
      createdAt: now,
      updatedAt: now,
    );
    _cachedItems!.add(created);
    await _persistItems();
    return created;
  }

  Future<void> update(Item item) async {
    await _ensureInit();
    final idx = _cachedItems!.indexWhere((i) => i.id == item.id);
    if (idx < 0) return;
    _cachedItems![idx] = item.copyWith(updatedAt: DateTime.now());
    await _persistItems();
  }

  Future<void> deleteById(String id) async {
    await _ensureInit();
    _cachedItems!.removeWhere((i) => i.id == id);
    await _persistItems();
  }

  /// Records a scan. Keeps only the [_maxScanHistory] most recent scans.
  Future<ScanEvent> recordScan({
    required String barcode,
    String? itemId,
    String? format,
  }) async {
    await _ensureInit();
    final scan = ScanEvent(
      id: _uuid.v4(),
      barcode: barcode,
      itemId: itemId,
      format: format,
      scannedAt: DateTime.now(),
    );
    _cachedScans!.insert(0, scan);
    if (_cachedScans!.length > _maxScanHistory) {
      _cachedScans!.removeRange(_maxScanHistory, _cachedScans!.length);
    }
    await _persistScans();
    return scan;
  }

  Future<void> clearScanHistory() async {
    await _ensureInit();
    _cachedScans!.clear();
    await _persistScans();
  }

  void dispose() {
    _itemsController.close();
    _scansController.close();
  }
}
