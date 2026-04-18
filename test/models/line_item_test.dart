import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/line_item.dart';

void main() {
  group('LineItem', () {
    test('total multiplies quantity by unitPrice', () {
      final item = LineItem(
        description: 'Consulting',
        quantity: 2.5,
        unitPrice: 120.0,
      );

      expect(item.total, 300.0);
    });

    test('total handles zero quantity', () {
      final item = LineItem(
        description: 'Free sample',
        quantity: 0,
        unitPrice: 99.99,
      );

      expect(item.total, 0);
    });

    test('total handles fractional quantities without precision loss', () {
      final item = LineItem(
        description: 'Short task',
        quantity: 0.25,
        unitPrice: 80.0,
      );

      expect(item.total, closeTo(20.0, 1e-9));
    });

    test('toJson emits every field with original types', () {
      final item = LineItem(
        description: 'Design work',
        quantity: 3.0,
        unitPrice: 150.0,
      );

      expect(item.toJson(), {
        'description': 'Design work',
        'quantity': 3.0,
        'unitPrice': 150.0,
      });
    });

    test('fromJson parses integer numeric values as doubles', () {
      final item = LineItem.fromJson({
        'description': 'Integration',
        'quantity': 4,
        'unitPrice': 200,
      });

      expect(item.description, 'Integration');
      expect(item.quantity, 4.0);
      expect(item.unitPrice, 200.0);
      expect(item.quantity, isA<double>());
      expect(item.unitPrice, isA<double>());
    });

    test('toJson/fromJson round-trip preserves values', () {
      final original = LineItem(
        description: 'Round-trip',
        quantity: 1.75,
        unitPrice: 95.5,
      );

      final restored = LineItem.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.description, original.description);
      expect(restored.quantity, original.quantity);
      expect(restored.unitPrice, original.unitPrice);
      expect(restored.total, original.total);
    });
  });

  group('lineItemsToJson / lineItemsFromJson', () {
    test('encodes an empty list to "[]"', () {
      expect(lineItemsToJson(const []), '[]');
    });

    test('decodes "[]" to an empty list', () {
      expect(lineItemsFromJson('[]'), isEmpty);
    });

    test('round-trips a multi-item list preserving order and values', () {
      final items = [
        LineItem(description: 'First', quantity: 1.0, unitPrice: 50.0),
        LineItem(description: 'Second', quantity: 2.5, unitPrice: 75.25),
        LineItem(description: 'Third', quantity: 0.5, unitPrice: 10.0),
      ];

      final restored = lineItemsFromJson(lineItemsToJson(items));

      expect(restored.length, items.length);
      for (var i = 0; i < items.length; i++) {
        expect(restored[i].description, items[i].description);
        expect(restored[i].quantity, items[i].quantity);
        expect(restored[i].unitPrice, items[i].unitPrice);
      }
    });

    test('fromJson throws when a required field is missing', () {
      expect(
        () => LineItem.fromJson({'quantity': 1, 'unitPrice': 1}),
        throwsA(isA<TypeError>()),
      );
    });

    test('lineItemsFromJson throws on malformed JSON', () {
      expect(
        () => lineItemsFromJson('not json'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
