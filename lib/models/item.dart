// lib/models/item.dart
import 'dart:convert';

/// An item that can be identified by its barcode.
class Item {
  final String id;
  final String barcode;
  final String name;
  final String? brand;
  final String? description;
  final String? category;
  final String? unit;
  final double? price;
  final String? currency;
  final String? imageUrl;
  final String? source; // 'manual', 'openfoodfacts', etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.description,
    this.category,
    this.unit,
    this.price,
    this.currency,
    this.imageUrl,
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  Item copyWith({
    String? name,
    String? brand,
    String? description,
    String? category,
    String? unit,
    double? price,
    String? currency,
    String? imageUrl,
    String? source,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id,
      barcode: barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'description': description,
        'category': category,
        'unit': unit,
        'price': price,
        'currency': currency,
        'imageUrl': imageUrl,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        barcode: json['barcode'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        description: json['description'] as String?,
        category: json['category'] as String?,
        unit: json['unit'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        currency: json['currency'] as String?,
        imageUrl: json['imageUrl'] as String?,
        source: json['source'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// A single barcode scan event, whether or not it resolved to a known item.
class ScanEvent {
  final String id;
  final String barcode;
  final String? itemId;
  final String? format; // e.g. 'EAN_13', 'CODE_128'
  final DateTime scannedAt;

  ScanEvent({
    required this.id,
    required this.barcode,
    required this.scannedAt,
    this.itemId,
    this.format,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'itemId': itemId,
        'format': format,
        'scannedAt': scannedAt.toIso8601String(),
      };

  factory ScanEvent.fromJson(Map<String, dynamic> json) => ScanEvent(
        id: json['id'] as String,
        barcode: json['barcode'] as String,
        itemId: json['itemId'] as String?,
        format: json['format'] as String?,
        scannedAt: DateTime.parse(json['scannedAt'] as String),
      );
}

String itemsToJson(List<Item> items) =>
    jsonEncode(items.map((i) => i.toJson()).toList());

List<Item> itemsFromJson(String jsonString) {
  if (jsonString.isEmpty) return [];
  final parsed = jsonDecode(jsonString) as List<dynamic>;
  return parsed.map((j) => Item.fromJson(j as Map<String, dynamic>)).toList();
}

String scansToJson(List<ScanEvent> scans) =>
    jsonEncode(scans.map((s) => s.toJson()).toList());

List<ScanEvent> scansFromJson(String jsonString) {
  if (jsonString.isEmpty) return [];
  final parsed = jsonDecode(jsonString) as List<dynamic>;
  return parsed
      .map((j) => ScanEvent.fromJson(j as Map<String, dynamic>))
      .toList();
}
