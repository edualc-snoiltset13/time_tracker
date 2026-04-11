// test/models/line_item_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_tracker/models/line_item.dart';

void main() {
  group('LineItem', () {
    group('total', () {
      test('calculates quantity * unitPrice', () {
        final item = LineItem(
          description: 'Dev work',
          quantity: 10.0,
          unitPrice: 50.0,
        );
        expect(item.total, 500.0);
      });

      test('returns 0 when quantity is 0', () {
        final item = LineItem(
          description: 'No hours',
          quantity: 0.0,
          unitPrice: 100.0,
        );
        expect(item.total, 0.0);
      });

      test('returns 0 when unitPrice is 0', () {
        final item = LineItem(
          description: 'Free work',
          quantity: 5.0,
          unitPrice: 0.0,
        );
        expect(item.total, 0.0);
      });

      test('handles fractional values', () {
        final item = LineItem(
          description: 'Partial hour',
          quantity: 1.5,
          unitPrice: 75.0,
        );
        expect(item.total, 112.5);
      });

      test('handles very small quantities', () {
        final item = LineItem(
          description: 'Quick task',
          quantity: 0.25,
          unitPrice: 100.0,
        );
        expect(item.total, 25.0);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final item = LineItem(
          description: 'Design work',
          quantity: 8.0,
          unitPrice: 120.0,
        );
        final json = item.toJson();

        expect(json['description'], 'Design work');
        expect(json['quantity'], 8.0);
        expect(json['unitPrice'], 120.0);
      });

      test('preserves special characters in description', () {
        final item = LineItem(
          description: 'Work on "Project A" & B',
          quantity: 1.0,
          unitPrice: 50.0,
        );
        final json = item.toJson();
        expect(json['description'], 'Work on "Project A" & B');
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final json = {
          'description': 'QA Testing',
          'quantity': 4.0,
          'unitPrice': 80.0,
        };
        final item = LineItem.fromJson(json);

        expect(item.description, 'QA Testing');
        expect(item.quantity, 4.0);
        expect(item.unitPrice, 80.0);
      });

      test('handles integer values for quantity and unitPrice', () {
        final json = {
          'description': 'Work',
          'quantity': 5, // int, not double
          'unitPrice': 100, // int, not double
        };
        final item = LineItem.fromJson(json);

        expect(item.quantity, 5.0);
        expect(item.unitPrice, 100.0);
        expect(item.total, 500.0);
      });
    });

    group('roundtrip serialization', () {
      test('toJson then fromJson preserves all data', () {
        final original = LineItem(
          description: 'Consulting',
          quantity: 3.75,
          unitPrice: 200.0,
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
        LineItem(description: 'Item 1', quantity: 2.0, unitPrice: 50.0),
        LineItem(description: 'Item 2', quantity: 5.0, unitPrice: 100.0),
        LineItem(description: 'Item 3', quantity: 0.5, unitPrice: 200.0),
      ];

      final jsonString = lineItemsToJson(items);
      final restored = lineItemsFromJson(jsonString);

      expect(restored.length, 3);
      expect(restored[0].description, 'Item 1');
      expect(restored[0].total, 100.0);
      expect(restored[1].description, 'Item 2');
      expect(restored[1].total, 500.0);
      expect(restored[2].description, 'Item 3');
      expect(restored[2].total, 100.0);
    });

    test('handles an empty list', () {
      final items = <LineItem>[];
      final jsonString = lineItemsToJson(items);
      final restored = lineItemsFromJson(jsonString);

      expect(restored, isEmpty);
    });

    test('produces valid JSON string', () {
      final items = [
        LineItem(description: 'Test', quantity: 1.0, unitPrice: 10.0),
      ];

      final jsonString = lineItemsToJson(items);

      // Should be parseable as JSON
      expect(() => jsonDecode(jsonString), returnsNormally);

      // Should be a JSON array
      final decoded = jsonDecode(jsonString);
      expect(decoded, isA<List>());
      expect((decoded as List).length, 1);
    });

    test('handles single item list', () {
      final items = [
        LineItem(description: 'Solo', quantity: 10.0, unitPrice: 25.0),
      ];

      final restored = lineItemsFromJson(lineItemsToJson(items));
      expect(restored.length, 1);
      expect(restored[0].description, 'Solo');
      expect(restored[0].total, 250.0);
    });
  });
}
