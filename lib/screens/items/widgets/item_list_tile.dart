// lib/screens/items/widgets/item_list_tile.dart
import 'package:flutter/material.dart';

import 'package:time_tracker/models/item.dart';
import 'package:time_tracker/utils/formatting.dart';

/// The compact list-row rendering of an [Item]. Used on the library list
/// and anywhere else a one-line item summary is needed.
class ItemListTile extends StatelessWidget {
  const ItemListTile({
    super.key,
    required this.item,
    this.onTap,
    this.trailingOverride,
  });

  final Item item;
  final VoidCallback? onTap;

  /// Overrides the default trailing (price). Useful for selection checkmarks
  /// or action buttons. Pass an empty [SizedBox.shrink] to hide the trailing.
  final Widget? trailingOverride;

  @override
  Widget build(BuildContext context) {
    final priceText = formatItemPrice(item.price, item.currency);
    final subtitleBits = <String>[
      if (item.brand != null && item.brand!.isNotEmpty) item.brand!,
      item.barcode,
    ];

    Widget leading;
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          item.imageUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2),
        ),
      );
    } else {
      leading = const CircleAvatar(child: Icon(Icons.inventory_2));
    }

    return ListTile(
      leading: leading,
      title: Text(item.name),
      subtitle: Text(subtitleBits.join(' · ')),
      trailing: trailingOverride ??
          (priceText == null
              ? null
              : Text(priceText,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
      onTap: onTap,
    );
  }
}
