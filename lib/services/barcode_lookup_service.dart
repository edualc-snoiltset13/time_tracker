// lib/services/barcode_lookup_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:time_tracker/models/item.dart';
import 'package:time_tracker/services/item_repository.dart';

/// Where an identified item came from.
enum BarcodeLookupSource { local, remote, unknown }

/// Why a lookup ended in [BarcodeLookupSource.unknown]. Lets the UI render
/// distinct messages without string-matching error text.
enum BarcodeLookupError { notFound, network, timeout, parseError, emptyInput }

/// Result of attempting to identify a barcode.
class BarcodeLookupResult {
  final String barcode;
  final BarcodeLookupSource source;

  /// Populated when [source] is [BarcodeLookupSource.local].
  final Item? item;

  /// Populated when [source] is [BarcodeLookupSource.remote].
  final RemoteItem? remote;

  /// Populated when [source] is [BarcodeLookupSource.unknown].
  final BarcodeLookupError? error;

  const BarcodeLookupResult._({
    required this.barcode,
    required this.source,
    this.item,
    this.remote,
    this.error,
  });

  factory BarcodeLookupResult.local(Item item) => BarcodeLookupResult._(
        barcode: item.barcode,
        source: BarcodeLookupSource.local,
        item: item,
      );

  factory BarcodeLookupResult.remote(RemoteItem remote) =>
      BarcodeLookupResult._(
        barcode: remote.barcode,
        source: BarcodeLookupSource.remote,
        remote: remote,
      );

  factory BarcodeLookupResult.unknown(
    String barcode,
    BarcodeLookupError error,
  ) =>
      BarcodeLookupResult._(
        barcode: barcode,
        source: BarcodeLookupSource.unknown,
        error: error,
      );

  bool get isFound =>
      source == BarcodeLookupSource.local ||
      source == BarcodeLookupSource.remote;
}

/// Identifies items by barcode. Checks the local repository first, then
/// falls back to Open Food Facts (free, no auth required).
class BarcodeLookupService {
  BarcodeLookupService({
    required ItemRepository repository,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 6),
  })  : _repository = repository,
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
      return BarcodeLookupResult.unknown(barcode, BarcodeLookupError.emptyInput);
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

    final remoteResult = await _lookupOpenFoodFacts(trimmed);

    if (recordScan) {
      await _repository.recordScan(barcode: trimmed, format: format);
    }

    return remoteResult;
  }

  /// Tries to identify a barcode via the Open Food Facts public API.
  /// Returns a [BarcodeLookupResult] carrying either the remote item or a
  /// typed error describing why nothing was produced.
  Future<BarcodeLookupResult> _lookupOpenFoodFacts(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
    );

    http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(_timeout);
    } on TimeoutException {
      return BarcodeLookupResult.unknown(barcode, BarcodeLookupError.timeout);
    } catch (_) {
      return BarcodeLookupResult.unknown(barcode, BarcodeLookupError.network);
    }

    if (response.statusCode != 200) {
      return BarcodeLookupResult.unknown(barcode, BarcodeLookupError.network);
    }

    final Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is! Map<String, dynamic>) {
        return BarcodeLookupResult.unknown(
            barcode, BarcodeLookupError.parseError);
      }
      decoded = parsed;
    } catch (_) {
      return BarcodeLookupResult.unknown(
          barcode, BarcodeLookupError.parseError);
    }

    if (decoded['status'] != 1) {
      return BarcodeLookupResult.unknown(barcode, BarcodeLookupError.notFound);
    }

    final product = decoded['product'];
    if (product is! Map<String, dynamic>) {
      return BarcodeLookupResult.unknown(barcode, BarcodeLookupError.notFound);
    }

    final name = (product['product_name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return BarcodeLookupResult.unknown(barcode, BarcodeLookupError.notFound);
    }

    final brand = (product['brands'] as String?)?.split(',').first.trim();
    final category =
        (product['categories'] as String?)?.split(',').first.trim();
    final quantity = (product['quantity'] as String?)?.trim();
    final imageUrl = (product['image_small_url'] as String?) ??
        (product['image_url'] as String?) ??
        (product['image_front_small_url'] as String?);

    return BarcodeLookupResult.remote(RemoteItem(
      barcode: barcode,
      name: name,
      brand: (brand != null && brand.isNotEmpty) ? brand : null,
      description: (quantity != null && quantity.isNotEmpty) ? quantity : null,
      category: (category != null && category.isNotEmpty) ? category : null,
      unit: (quantity != null && quantity.isNotEmpty) ? quantity : null,
      imageUrl: imageUrl,
      source: 'openfoodfacts',
    ));
  }

  void dispose() {
    _httpClient.close();
  }
}
