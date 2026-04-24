// lib/screens/items/widgets/item_detail_card.dart
import 'package:flutter/material.dart';

import 'package:time_tracker/models/item.dart';
import 'package:time_tracker/utils/formatting.dart';

/// The large "hero" card used on screens that display a single item or
/// remote suggestion in detail (scan result, save confirmation, etc.).
///
/// Either [item] or [remote] must be provided (mutually exclusive). Price
/// and id-ish metadata are only rendered for saved [item] instances.
class ItemDetailCard extends StatelessWidget {
  const ItemDetailCard({super.key, this.item, this.remote})
      : assert(item != null || remote != null,
            'ItemDetailCard requires either item or remote');

  final Item? item;
  final RemoteItem? remote;

  String get _barcode => item?.barcode ?? remote!.barcode;
  String get _name => item?.name ?? remote!.name;
  String? get _brand => item?.brand ?? remote?.brand;
  String? get _category => item?.category ?? remote?.category;
  String? get _unit => item?.unit ?? remote?.unit;
  String? get _description => item?.description ?? remote?.description;
  String? get _imageUrl => item?.imageUrl ?? remote?.imageUrl;

  @override
  Widget build(BuildContext context) {
    final priceText = item == null ? null : formatItemPrice(item!.price, item!.currency);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imageUrl != null && _imageUrl!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrl!,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(_name, style: Theme.of(context).textTheme.titleLarge),
            if (_brand != null && _brand!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_brand!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            if (_category != null && _category!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Category: ${_category!}'),
              ),
            if (_unit != null && _unit!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Unit: ${_unit!}'),
              ),
            if (priceText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  priceText,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 8),
            Text('Barcode: $_barcode',
                style: Theme.of(context).textTheme.bodySmall),
            if (_description != null && _description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_description!),
              ),
          ],
        ),
      ),
    );
  }
}
