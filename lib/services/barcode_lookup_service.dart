// lib/services/barcode_lookup_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:time_tracker/models/item.dart';
import 'package:time_tracker/services/item_repository.dart';

/// Where an identified item came from.
enum BarcodeLookupSource {
  /// Resolved from the local item database.
  local,

  /// Resolved from an external API (e.g. Open Food Facts).
  remote,

  /// The barcode is syntactically valid but could not be identified anywhere.
  unknown,
}

/// Result of attempting to identify a barcode.
class BarcodeLookupResult {
  final String barcode;
  final BarcodeLookupSource source;

  /// The matched local item, if [source] is [BarcodeLookupSource.local].
  final Item? item;

  /// A draft item built from a remote lookup. Not persisted; the caller
  /// decides whether to save it. Populated when [source] is
  /// [BarcodeLookupSource.remote].
  final RemoteItemDraft? remoteDraft;

  final String? error;

  const BarcodeLookupResult._({
    required this.barcode,
    required this.source,
    this.item,
    this.remoteDraft,
    this.error,
  });

  factory BarcodeLookupResult.local(Item item) => BarcodeLookupResult._(
        barcode: item.barcode,
        source: BarcodeLookupSource.local,
        item: item,
      );

  factory BarcodeLookupResult.remote(String barcode, RemoteItemDraft draft) =>
      BarcodeLookupResult._(
        barcode: barcode,
        source: BarcodeLookupSource.remote,
        remoteDraft: draft,
      );

  factory BarcodeLookupResult.unknown(String barcode, {String? error}) =>
      BarcodeLookupResult._(
        barcode: barcode,
        source: BarcodeLookupSource.unknown,
        error: error,
      );

  bool get isFound =>
      source == BarcodeLookupSource.local ||
      source == BarcodeLookupSource.remote;
}

/// Lightweight, non-persisted data pulled from a remote API. The UI turns
/// this into an [Item] if the user confirms.
class RemoteItemDraft {
  final String barcode;
  final String name;
  final String? brand;
  final String? description;
  final String? category;
  final String? unit;
  final String? imageUrl;
  final String source;

  const RemoteItemDraft({
    required this.barcode,
    required this.name,
    required this.source,
    this.brand,
    this.description,
    this.category,
    this.unit,
    this.imageUrl,
  });
}

/// Identifies items by barcode. Checks the local repository first, then
/// falls back to Open Food Facts (free, no auth required).
class BarcodeLookupService {
  BarcodeLookupService({
    ItemRepository? repository,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 6),
  })  : _repository = repository ?? ItemRepository.instance,
        _httpClient = httpClient ?? http.Client(),
        _timeout = timeout;

  final ItemRepository _repository;
  final http.Client _httpClient;
  final Duration _timeout;

  /// Identifies [barcode] and records the scan. If [recordScan] is false,
  /// the lookup is performed but no scan history entry is added.
  Future<BarcodeLookupResult> identify(
    String barcode, {
    String? format,
    bool recordScan = true,
  }) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) {
      return BarcodeLookupResult.unknown(barcode, error: 'Empty barcode');
    }

    final local = await _repository.findByBarcode(trimmed);
    if (local != null) {
      if (recordScan) {
        await _repository.recordScan(
          barcode: trimmed,
          itemId: local.id,
          format: format,
        );
      }
      return BarcodeLookupResult.local(local);
    }

    RemoteItemDraft? remote;
    String? remoteError;
    try {
      remote = await _lookupOpenFoodFacts(trimmed);
    } catch (e) {
      remoteError = e.toString();
    }

    if (recordScan) {
      await _repository.recordScan(barcode: trimmed, format: format);
    }

    if (remote != null) return BarcodeLookupResult.remote(trimmed, remote);
    return BarcodeLookupResult.unknown(trimmed, error: remoteError);
  }

  /// Calls the Open Food Facts public API to try to identify a barcode.
  /// Returns null when the product is not found.
  Future<RemoteItemDraft?> _lookupOpenFoodFacts(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
    );
    final response =
        await _httpClient.get(uri).timeout(_timeout);

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;

    final status = decoded['status'];
    if (status != 1) return null;

    final product = decoded['product'];
    if (product is! Map<String, dynamic>) return null;

    final name = (product['product_name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final brand = (product['brands'] as String?)?.split(',').first.trim();
    final category =
        (product['categories'] as String?)?.split(',').first.trim();
    final quantity = (product['quantity'] as String?)?.trim();
    final imageUrl = (product['image_small_url'] as String?) ??
        (product['image_url'] as String?) ??
        (product['image_front_small_url'] as String?);

    return RemoteItemDraft(
      barcode: barcode,
      name: name,
      brand: (brand != null && brand.isNotEmpty) ? brand : null,
      description: (quantity != null && quantity.isNotEmpty) ? quantity : null,
      category: (category != null && category.isNotEmpty) ? category : null,
      unit: (quantity != null && quantity.isNotEmpty) ? quantity : null,
      imageUrl: imageUrl,
      source: 'openfoodfacts',
    );
  }

  void dispose() {
    _httpClient.close();
  }
}
