// lib/screens/items/scan_result_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:time_tracker/models/item.dart';
import 'package:time_tracker/services/barcode_lookup_service.dart';
import 'package:time_tracker/services/item_repository.dart';
import 'package:time_tracker/screens/items/item_edit_screen.dart';

/// Shows the outcome of a barcode lookup: a known local item, a remote
/// suggestion that the user can save, or an unknown barcode with an option
/// to register a new item.
///
/// If the user taps "Use this item" (for scans launched from another screen),
/// this screen pops with the resolved [Item]. Otherwise it pops with null.
class ScanResultScreen extends StatefulWidget {
  final String barcode;
  final String? format;

  /// When true, shows a "Use this item" call-to-action that returns the
  /// [Item] to the caller via [Navigator.pop]. Used when the scan was
  /// initiated from a context that wants to consume the item (e.g. Expenses).
  final bool selectionMode;

  const ScanResultScreen({
    super.key,
    required this.barcode,
    this.format,
    this.selectionMode = false,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late final BarcodeLookupService _lookup;
  late Future<BarcodeLookupResult> _future;

  @override
  void initState() {
    super.initState();
    _lookup = BarcodeLookupService();
    _future = _lookup.identify(widget.barcode, format: widget.format);
  }

  @override
  void dispose() {
    _lookup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: FutureBuilder<BarcodeLookupResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _loading();
          }
          if (snapshot.hasError) {
            return _unknown(error: snapshot.error.toString());
          }
          final result = snapshot.data!;
          switch (result.source) {
            case BarcodeLookupSource.local:
              return _local(result.item!);
            case BarcodeLookupSource.remote:
              return _remote(result.remoteDraft!);
            case BarcodeLookupSource.unknown:
              return _unknown(error: result.error);
          }
        },
      ),
    );
  }

  Widget _loading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Identifying ${widget.barcode}...'),
        ],
      ),
    );
  }

  Widget _local(Item item) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _badge('Matched in your library', Colors.tealAccent),
        const SizedBox(height: 12),
        _itemCard(item),
        const SizedBox(height: 24),
        if (widget.selectionMode)
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Use this item'),
            onPressed: () => Navigator.of(context).pop(item),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Edit item'),
          onPressed: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ItemEditScreen(item: item),
              ),
            );
            if (changed == true && mounted) {
              setState(() {
                _future = _lookup.identify(widget.barcode,
                    format: widget.format, recordScan: false);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _remote(RemoteItemDraft draft) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _badge('Found via ${draft.source}', Colors.orangeAccent),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draft.imageUrl != null && draft.imageUrl!.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        draft.imageUrl!,
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(draft.name,
                    style: Theme.of(context).textTheme.titleLarge),
                if (draft.brand != null && draft.brand!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(draft.brand!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                if (draft.category != null && draft.category!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Category: ${draft.category}'),
                  ),
                if (draft.unit != null && draft.unit!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Quantity: ${draft.unit}'),
                  ),
                const SizedBox(height: 8),
                Text('Barcode: ${widget.barcode}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save to my library'),
          onPressed: () async {
            final saved = await _saveDraft(draft);
            if (!mounted) return;
            if (widget.selectionMode) {
              Navigator.of(context).pop(saved);
            } else {
              setState(() {
                _future = Future.value(BarcodeLookupResult.local(saved));
              });
            }
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Review and edit before saving'),
          onPressed: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ItemEditScreen(
                  prefilledBarcode: widget.barcode,
                  remoteSeed: RemoteDraftSeed(
                    name: draft.name,
                    brand: draft.brand,
                    description: draft.description,
                    category: draft.category,
                    unit: draft.unit,
                    imageUrl: draft.imageUrl,
                    source: draft.source,
                  ),
                ),
              ),
            );
            if (changed == true && mounted) {
              setState(() {
                _future = _lookup.identify(widget.barcode,
                    format: widget.format, recordScan: false);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _unknown({String? error}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _badge('Unknown barcode', Colors.redAccent),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Barcode: ${widget.barcode}',
                    style: Theme.of(context).textTheme.titleMedium),
                if (widget.format != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Format: ${widget.format}'),
                  ),
                const SizedBox(height: 12),
                const Text(
                  "This barcode isn't in your library and no match was "
                  'found in the public database. Register it now so future '
                  'scans will recognize it.',
                ),
                if (error != null && error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Lookup error: $error',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Register new item'),
          onPressed: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ItemEditScreen(
                  prefilledBarcode: widget.barcode,
                ),
              ),
            );
            if (changed == true && mounted) {
              setState(() {
                _future = _lookup.identify(widget.barcode,
                    format: widget.format, recordScan: false);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _itemCard(Item item) {
    final priceText = _formatPrice(item);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl!,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(item.name, style: Theme.of(context).textTheme.titleLarge),
            if (item.brand != null && item.brand!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(item.brand!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            if (item.category != null && item.category!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Category: ${item.category}'),
              ),
            if (item.unit != null && item.unit!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Unit: ${item.unit}'),
              ),
            if (priceText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(priceText,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 8),
            Text('Barcode: ${item.barcode}',
                style: Theme.of(context).textTheme.bodySmall),
            if (item.description != null && item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(item.description!),
              ),
          ],
        ),
      ),
    );
  }

  String? _formatPrice(Item item) {
    if (item.price == null) return null;
    try {
      final f =
          NumberFormat.simpleCurrency(name: item.currency ?? 'USD');
      return f.format(item.price);
    } catch (_) {
      return '${item.currency ?? ''} ${item.price!.toStringAsFixed(2)}';
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }

  Future<Item> _saveDraft(RemoteItemDraft draft) {
    return ItemRepository.instance.upsert(
      barcode: widget.barcode,
      name: draft.name,
      brand: draft.brand,
      description: draft.description,
      category: draft.category,
      unit: draft.unit,
      imageUrl: draft.imageUrl,
      source: draft.source,
      currency: 'USD',
    );
  }
}
