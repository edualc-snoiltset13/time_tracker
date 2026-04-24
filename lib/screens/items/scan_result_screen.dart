// lib/screens/items/scan_result_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:time_tracker/models/item.dart';
import 'package:time_tracker/services/barcode_lookup_service.dart';
import 'package:time_tracker/services/item_repository.dart';
import 'package:time_tracker/screens/items/item_edit_screen.dart';
import 'package:time_tracker/screens/items/widgets/item_detail_card.dart';

/// Shows the outcome of a barcode lookup: a known local item, a remote
/// suggestion that the user can save, or an unknown barcode with an option
/// to register a new item.
///
/// If [selectionMode] is true, pops with an [Item] once the user commits
/// to one; otherwise the screen is purely informational and pops with null.
class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({
    super.key,
    required this.barcode,
    this.format,
    this.selectionMode = false,
  });

  final String barcode;
  final String? format;
  final bool selectionMode;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late Future<BarcodeLookupResult> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `didChangeDependencies` matches the app's pattern (see
    // project_edit_screen.dart) — Provider is available here but not in
    // initState. The null check prevents re-running on every call.
    _future = _identify();
  }

  Future<BarcodeLookupResult> _identify({bool recordScan = true}) {
    final lookup = Provider.of<BarcodeLookupService>(context, listen: false);
    return lookup.identify(widget.barcode,
        format: widget.format, recordScan: recordScan);
  }

  void _reload({bool recordScan = false}) {
    setState(() => _future = _identify(recordScan: recordScan));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: FutureBuilder<BarcodeLookupResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _LoadingView(barcode: widget.barcode);
          }
          if (snapshot.hasError) {
            return _UnknownBarcode(
              barcode: widget.barcode,
              format: widget.format,
              error: BarcodeLookupError.network,
              onRegistered: () => _reload(),
            );
          }
          final result = snapshot.data!;
          switch (result.source) {
            case BarcodeLookupSource.local:
              return _LocalMatch(
                item: result.item!,
                selectionMode: widget.selectionMode,
                onEdited: () => _reload(),
              );
            case BarcodeLookupSource.remote:
              return _RemoteSuggestion(
                draft: result.remote!,
                selectionMode: widget.selectionMode,
                onSaved: (saved) {
                  if (widget.selectionMode) {
                    Navigator.of(context).pop(saved);
                  } else {
                    setState(() =>
                        _future = Future.value(BarcodeLookupResult.local(saved)));
                  }
                },
              );
            case BarcodeLookupSource.unknown:
              return _UnknownBarcode(
                barcode: widget.barcode,
                format: widget.format,
                error: result.error,
                onRegistered: () => _reload(),
              );
          }
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.barcode});
  final String barcode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Identifying $barcode...'),
        ],
      ),
    );
  }
}

class _LocalMatch extends StatelessWidget {
  const _LocalMatch({
    required this.item,
    required this.selectionMode,
    required this.onEdited,
  });

  final Item item;
  final bool selectionMode;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Badge(text: 'Matched in your library', color: Colors.tealAccent),
        const SizedBox(height: 12),
        ItemDetailCard(item: item),
        const SizedBox(height: 24),
        if (selectionMode)
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
              MaterialPageRoute(builder: (_) => ItemEditScreen(item: item)),
            );
            if (changed == true) onEdited();
          },
        ),
      ],
    );
  }
}

class _RemoteSuggestion extends StatelessWidget {
  const _RemoteSuggestion({
    required this.draft,
    required this.selectionMode,
    required this.onSaved,
  });

  final RemoteItem draft;
  final bool selectionMode;
  final ValueChanged<Item> onSaved;

  Future<Item> _persist(BuildContext context) {
    final repo = Provider.of<ItemRepository>(context, listen: false);
    return repo.upsert(
      barcode: draft.barcode,
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Badge(text: 'Found via ${draft.source}', color: Colors.orangeAccent),
        const SizedBox(height: 12),
        ItemDetailCard(remote: draft),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save to my library'),
          onPressed: () async {
            final saved = await _persist(context);
            onSaved(saved);
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Review and edit before saving'),
          onPressed: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ItemEditScreen(
                  prefilledBarcode: draft.barcode,
                  remoteSeed: draft,
                ),
              ),
            );
            // On return, let the parent re-run the lookup so it picks up
            // the newly-persisted (or edited) item.
            if (context.mounted && selectionMode) {
              final repo =
                  Provider.of<ItemRepository>(context, listen: false);
              final saved = await repo.findByBarcode(draft.barcode);
              if (saved != null) onSaved(saved);
            }
          },
        ),
      ],
    );
  }
}

class _UnknownBarcode extends StatelessWidget {
  const _UnknownBarcode({
    required this.barcode,
    required this.onRegistered,
    this.format,
    this.error,
  });

  final String barcode;
  final String? format;
  final BarcodeLookupError? error;
  final VoidCallback onRegistered;

  String get _errorMessage {
    switch (error) {
      case BarcodeLookupError.notFound:
      case null:
        return "This barcode isn't in your library and was not found in the "
            'public database. Register it now so future scans recognize it.';
      case BarcodeLookupError.network:
        return "Couldn't reach the public barcode database. Register this "
            'item manually, or try again when online.';
      case BarcodeLookupError.timeout:
        return 'The lookup timed out. Register this item manually or try '
            'again — a weak connection can cause this.';
      case BarcodeLookupError.parseError:
        return 'The public database returned an unexpected response. '
            'Register this item manually.';
      case BarcodeLookupError.emptyInput:
        return 'No barcode was provided.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Badge(text: 'Unknown barcode', color: Colors.redAccent),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Barcode: $barcode',
                    style: Theme.of(context).textTheme.titleMedium),
                if (format != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Format: $format'),
                  ),
                const SizedBox(height: 12),
                Text(_errorMessage),
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
                builder: (_) => ItemEditScreen(prefilledBarcode: barcode),
              ),
            );
            if (changed == true) onRegistered();
          },
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
}
