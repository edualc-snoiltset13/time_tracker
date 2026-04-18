import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/line_item.dart';

void main() {
  group('LineItem', () {
    group('total', () {
      test('computes quantity times unitPrice', () {
        final item = LineItem(
          description: 'Development',
          quantity: 5.0,
          unitPrice: 100.0,
        );
        expect(item.total, 500.0);
      });

      test('returns zero when quantity is zero', () {
        final item = LineItem(
          description: 'Idle',
          quantity: 0.0,
          unitPrice: 100.0,
        );
        expect(item.total, 0.0);
      });

      test('returns zero when unitPrice is zero', () {
        final item = LineItem(
          description: 'Pro bono',
          quantity: 10.0,
          unitPrice: 0.0,
        );
        expect(item.total, 0.0);
      });

      test('handles fractional hours and rates', () {
        final item = LineItem(
          description: 'Consulting',
          quantity: 1.5,
          unitPrice: 75.50,
        );
        expect(item.total, closeTo(113.25, 0.001));
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final item = LineItem(
          description: 'Design work',
          quantity: 3.0,
          unitPrice: 120.0,
        );
        final json = item.toJson();
        expect(json['description'], 'Design work');
        expect(json['quantity'], 3.0);
        expect(json['unitPrice'], 120.0);
      });
    });

    group('fromJson', () {
      test('deserializes from a map', () {
        final json = {
          'description': 'Review',
          'quantity': 2.5,
          'unitPrice': 80.0,
        };
        final item = LineItem.fromJson(json);
        expect(item.description, 'Review');
        expect(item.quantity, 2.5);
        expect(item.unitPrice, 80.0);
      });

      test('handles int values by coercing to double', () {
        final json = {
          'description': 'Meeting',
          'quantity': 1,
          'unitPrice': 50,
        };
        final item = LineItem.fromJson(json);
        expect(item.quantity, 1.0);
        expect(item.unitPrice, 50.0);
        expect(item.quantity, isA<double>());
        expect(item.unitPrice, isA<double>());
      });
    });

    group('round-trip serialization', () {
      test('toJson then fromJson preserves data', () {
        final original = LineItem(
          description: 'Backend API',
          quantity: 7.25,
          unitPrice: 150.0,
        );
        final restored = LineItem.fromJson(original.toJson());
        expect(restored.description, original.description);
        expect(restored.quantity, original.quantity);
        expect(restored.unitPrice, original.unitPrice);
        expect(restored.total, original.total);
      });
    });
  });

  group('lineItemsToJson / lineItemsFromJson', () {
    test('serializes and deserializes a list of items', () {
      final items = [
        LineItem(description: 'Task A', quantity: 2.0, unitPrice: 100.0),
        LineItem(description: 'Task B', quantity: 3.5, unitPrice: 80.0),
      ];

      final jsonString = lineItemsToJson(items);
      final decoded = jsonDecode(jsonString) as List;
      expect(decoded, hasLength(2));

      final restored = lineItemsFromJson(jsonString);
      expect(restored, hasLength(2));
      expect(restored[0].description, 'Task A');
      expect(restored[0].quantity, 2.0);
      expect(restored[0].unitPrice, 100.0);
      expect(restored[1].description, 'Task B');
      expect(restored[1].quantity, 3.5);
      expect(restored[1].unitPrice, 80.0);
    });

    test('handles empty list', () {
      final jsonString = lineItemsToJson([]);
      expect(jsonString, '[]');

      final restored = lineItemsFromJson(jsonString);
      expect(restored, isEmpty);
    });

    test('preserves totals through list serialization', () {
      final items = [
        LineItem(description: 'X', quantity: 1.5, unitPrice: 200.0),
      ];
      final restored = lineItemsFromJson(lineItemsToJson(items));
      expect(restored[0].total, closeTo(300.0, 0.001));
    });
  });
}
