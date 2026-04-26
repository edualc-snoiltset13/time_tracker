import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/line_item.dart';

void main() {
  group('LineItem.total', () {
    test('multiplies quantity by unitPrice', () {
      final item = LineItem(description: 'Dev', quantity: 8.0, unitPrice: 100.0);
      expect(item.total, 800.0);
    });

    test('zero quantity yields zero', () {
      final item = LineItem(description: 'X', quantity: 0.0, unitPrice: 100.0);
      expect(item.total, 0.0);
    });

    test('zero unitPrice yields zero', () {
      final item = LineItem(description: 'X', quantity: 5.0, unitPrice: 0.0);
      expect(item.total, 0.0);
    });

    test('fractional values', () {
      final item = LineItem(description: 'X', quantity: 1.5, unitPrice: 75.50);
      expect(item.total, closeTo(113.25, 0.001));
    });

    test('very small values', () {
      final item = LineItem(description: 'X', quantity: 0.01, unitPrice: 0.01);
      expect(item.total, closeTo(0.0001, 1e-10));
    });

    test('large values', () {
      final item =
          LineItem(description: 'X', quantity: 10000.0, unitPrice: 500.0);
      expect(item.total, 5000000.0);
    });
  });

  group('LineItem.toJson', () {
    test('includes all fields', () {
      final json = LineItem(
        description: 'Design',
        quantity: 3.0,
        unitPrice: 120.0,
      ).toJson();
      expect(json, {
        'description': 'Design',
        'quantity': 3.0,
        'unitPrice': 120.0,
      });
    });

    test('preserves special characters in description', () {
      final json = LineItem(
        description: 'Work "quoted" & <tagged>',
        quantity: 1.0,
        unitPrice: 50.0,
      ).toJson();
      expect(json['description'], 'Work "quoted" & <tagged>');
    });

    test('preserves unicode in description', () {
      final json = LineItem(
        description: 'Travail en français',
        quantity: 2.0,
        unitPrice: 80.0,
      ).toJson();
      expect(json['description'], 'Travail en français');
    });
  });

  group('LineItem.fromJson', () {
    test('constructs from double values', () {
      final item = LineItem.fromJson({
        'description': 'Review',
        'quantity': 2.5,
        'unitPrice': 80.0,
      });
      expect(item.description, 'Review');
      expect(item.quantity, 2.5);
      expect(item.unitPrice, 80.0);
    });

    test('coerces int values to double', () {
      final item = LineItem.fromJson({
        'description': 'Meeting',
        'quantity': 1,
        'unitPrice': 50,
      });
      expect(item.quantity, isA<double>());
      expect(item.quantity, 1.0);
      expect(item.unitPrice, isA<double>());
      expect(item.unitPrice, 50.0);
    });

    test('computed total works after deserialization', () {
      final item = LineItem.fromJson({
        'description': 'X',
        'quantity': 4,
        'unitPrice': 25,
      });
      expect(item.total, 100.0);
    });
  });

  group('LineItem round-trip', () {
    test('toJson then fromJson preserves all fields', () {
      final original = LineItem(
        description: 'API development',
        quantity: 7.25,
        unitPrice: 150.0,
      );
      final restored = LineItem.fromJson(original.toJson());
      expect(restored.description, original.description);
      expect(restored.quantity, original.quantity);
      expect(restored.unitPrice, original.unitPrice);
      expect(restored.total, original.total);
    });

    test('survives JSON encode/decode cycle', () {
      final original = LineItem(
        description: 'Testing',
        quantity: 3.33,
        unitPrice: 99.99,
      );
      final jsonString = jsonEncode(original.toJson());
      final restored =
          LineItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
      expect(restored.description, original.description);
      expect(restored.quantity, closeTo(original.quantity, 1e-10));
      expect(restored.unitPrice, closeTo(original.unitPrice, 1e-10));
    });
  });

  group('lineItemsToJson', () {
    test('encodes a list of items', () {
      final items = [
        LineItem(description: 'A', quantity: 1.0, unitPrice: 10.0),
        LineItem(description: 'B', quantity: 2.0, unitPrice: 20.0),
      ];
      final json = lineItemsToJson(items);
      final decoded = jsonDecode(json) as List;
      expect(decoded, hasLength(2));
      expect(decoded[0]['description'], 'A');
      expect(decoded[1]['description'], 'B');
    });

    test('empty list produces []', () {
      expect(lineItemsToJson([]), '[]');
    });

    test('single item list', () {
      final items = [
        LineItem(description: 'Solo', quantity: 5.0, unitPrice: 100.0),
      ];
      final decoded = jsonDecode(lineItemsToJson(items)) as List;
      expect(decoded, hasLength(1));
      expect(decoded[0]['quantity'], 5.0);
    });
  });

  group('lineItemsFromJson', () {
    test('decodes a list of items', () {
      const json =
          '[{"description":"X","quantity":2,"unitPrice":50},{"description":"Y","quantity":3.5,"unitPrice":80}]';
      final items = lineItemsFromJson(json);
      expect(items, hasLength(2));
      expect(items[0].description, 'X');
      expect(items[0].total, 100.0);
      expect(items[1].description, 'Y');
      expect(items[1].total, closeTo(280.0, 0.001));
    });

    test('decodes empty list', () {
      expect(lineItemsFromJson('[]'), isEmpty);
    });
  });

  group('list round-trip', () {
    test('encode then decode preserves all items', () {
      final original = [
        LineItem(description: 'Task 1', quantity: 2.0, unitPrice: 100.0),
        LineItem(description: 'Task 2', quantity: 0.5, unitPrice: 200.0),
        LineItem(description: 'Task 3', quantity: 10.0, unitPrice: 50.0),
      ];
      final restored = lineItemsFromJson(lineItemsToJson(original));
      expect(restored, hasLength(3));
      for (var i = 0; i < original.length; i++) {
        expect(restored[i].description, original[i].description);
        expect(restored[i].quantity, original[i].quantity);
        expect(restored[i].unitPrice, original[i].unitPrice);
        expect(restored[i].total, original[i].total);
      }
    });
  });
}
