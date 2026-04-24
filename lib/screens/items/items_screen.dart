// lib/screens/items/items_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:time_tracker/models/item.dart';
import 'package:time_tracker/services/item_repository.dart';
import 'package:time_tracker/screens/items/barcode_scanner_screen.dart';
import 'package:time_tracker/screens/items/item_edit_screen.dart';
import 'package:time_tracker/screens/items/scan_result_screen.dart';

/// Browse, search, and scan items in the barcode library.
class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    final result = await Navigator.of(context).push<BarcodeScanResult>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanResultScreen(
          barcode: result.barcode,
          format: result.format,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(icon: Icon(Icons.inventory_2), text: 'Library'),
                Tab(icon: Icon(Icons.history), text: 'Scan History'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildLibraryTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scan_barcode_fab',
            onPressed: _startScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'add_item_fab',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ItemEditScreen()),
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, brand, or barcode',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Item>>(
            stream: ItemRepository.instance.watchItems(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No items yet. Tap Scan to identify a product '
                      'or + to add one manually.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final filtered = _query.isEmpty
                  ? items
                  : items.where((i) {
                      final haystack = [
                        i.name,
                        i.brand ?? '',
                        i.barcode,
                        i.category ?? '',
                      ].join(' ').toLowerCase();
                      return haystack.contains(_query);
                    }).toList();

              filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              if (filtered.isEmpty) {
                return const Center(child: Text('No matching items.'));
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, idx) => _itemTile(filtered[idx]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _itemTile(Item item) {
    final priceText = _priceText(item);
    final subtitleBits = <String>[
      if (item.brand != null && item.brand!.isNotEmpty) item.brand!,
      item.barcode,
    ];

    return Dismissible(
      key: Key('item-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete item?'),
            content: Text('Remove "${item.name}" from your library?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => ItemRepository.instance.deleteById(item.id),
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    item.imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.inventory_2),
                  ),
                )
              : const CircleAvatar(child: Icon(Icons.inventory_2)),
          title: Text(item.name),
          subtitle: Text(subtitleBits.join(' · ')),
          trailing: priceText == null
              ? null
              : Text(priceText,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ItemEditScreen(item: item)),
          ),
        ),
      ),
    );
  }

  String? _priceText(Item item) {
    if (item.price == null) return null;
    try {
      return NumberFormat.simpleCurrency(name: item.currency ?? 'USD')
          .format(item.price);
    } catch (_) {
      return '${item.currency ?? ''} ${item.price!.toStringAsFixed(2)}';
    }
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<ScanEvent>>(
      stream: ItemRepository.instance.watchScans(),
      builder: (context, snapshot) {
        final scans = snapshot.data ?? [];
        if (scans.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No scans yet.', textAlign: TextAlign.center),
            ),
          );
        }
        return ListView.separated(
          itemCount: scans.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, idx) {
            if (idx == 0) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear history'),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear scan history?'),
                          content: const Text(
                              'This removes the record of all past scans. '
                              'Your saved items are not affected.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ItemRepository.instance.clearScanHistory();
                      }
                    },
                  ),
                ),
              );
            }
            final scan = scans[idx - 1];
            return FutureBuilder<Item?>(
              future: scan.itemId == null
                  ? Future.value(null)
                  : ItemRepository.instance.findById(scan.itemId!),
              builder: (context, itemSnap) {
                final item = itemSnap.data;
                return ListTile(
                  leading: Icon(
                    item == null ? Icons.help_outline : Icons.check_circle,
                    color: item == null ? Colors.orange : Colors.tealAccent,
                  ),
                  title: Text(item?.name ?? 'Unknown barcode'),
                  subtitle: Text(
                    '${scan.barcode}\n${DateFormat.yMMMd().add_jm().format(scan.scannedAt)}'
                    '${scan.format != null ? ' · ${scan.format}' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScanResultScreen(
                          barcode: scan.barcode,
                          format: scan.format,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
