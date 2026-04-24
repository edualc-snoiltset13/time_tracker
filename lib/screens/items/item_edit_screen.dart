// lib/screens/items/item_edit_screen.dart
import 'package:flutter/material.dart';

import 'package:time_tracker/models/item.dart';
import 'package:time_tracker/services/item_repository.dart';

/// Create or edit a barcoded item.
///
/// If [item] is non-null, the form is pre-populated and saving updates it.
/// Otherwise a new item is created. [prefilledBarcode] is used only for the
/// create path and is ignored when editing.
class ItemEditScreen extends StatefulWidget {
  final Item? item;
  final String? prefilledBarcode;
  final RemoteDraftSeed? remoteSeed;

  const ItemEditScreen({
    super.key,
    this.item,
    this.prefilledBarcode,
    this.remoteSeed,
  });

  @override
  State<ItemEditScreen> createState() => _ItemEditScreenState();
}

/// Minimal data needed to seed the form from a remote lookup. Declared here
/// to avoid coupling the edit screen to the lookup service types.
class RemoteDraftSeed {
  final String name;
  final String? brand;
  final String? description;
  final String? category;
  final String? unit;
  final String? imageUrl;
  final String source;

  const RemoteDraftSeed({
    required this.name,
    required this.source,
    this.brand,
    this.description,
    this.category,
    this.unit,
    this.imageUrl,
  });
}

class _ItemEditScreenState extends State<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'USD');
  String? _imageUrl;
  String? _source;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final i = widget.item!;
      _barcodeCtrl.text = i.barcode;
      _nameCtrl.text = i.name;
      _brandCtrl.text = i.brand ?? '';
      _descriptionCtrl.text = i.description ?? '';
      _categoryCtrl.text = i.category ?? '';
      _unitCtrl.text = i.unit ?? '';
      _priceCtrl.text = i.price?.toString() ?? '';
      _currencyCtrl.text = i.currency ?? 'USD';
      _imageUrl = i.imageUrl;
      _source = i.source;
    } else {
      if (widget.prefilledBarcode != null) {
        _barcodeCtrl.text = widget.prefilledBarcode!;
      }
      final seed = widget.remoteSeed;
      if (seed != null) {
        _nameCtrl.text = seed.name;
        _brandCtrl.text = seed.brand ?? '';
        _descriptionCtrl.text = seed.description ?? '';
        _categoryCtrl.text = seed.category ?? '';
        _unitCtrl.text = seed.unit ?? '';
        _imageUrl = seed.imageUrl;
        _source = seed.source;
      }
    }
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ItemRepository.instance;
    final barcode = _barcodeCtrl.text.trim();

    if (!_isEditing) {
      final existing = await repo.findByBarcode(barcode);
      if (existing != null && mounted) {
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Barcode already exists'),
            content: Text(
              'An item named "${existing.name}" is already registered for '
              'this barcode. Overwrite it with your new values?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Overwrite'),
              ),
            ],
          ),
        );
        if (overwrite != true) return;
      }
    }

    final price = double.tryParse(_priceCtrl.text.trim());

    if (_isEditing) {
      final updated = widget.item!.copyWith(
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        unit: _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
        price: price,
        currency: _currencyCtrl.text.trim().isEmpty
            ? null
            : _currencyCtrl.text.trim(),
        imageUrl: _imageUrl,
        source: _source,
      );
      await repo.update(updated);
    } else {
      await repo.upsert(
        barcode: barcode,
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        unit: _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim(),
        price: price,
        currency: _currencyCtrl.text.trim().isEmpty
            ? 'USD'
            : _currencyCtrl.text.trim(),
        imageUrl: _imageUrl,
        source: _source ?? 'manual',
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item' : 'New Item'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_imageUrl != null && _imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
            TextFormField(
              controller: _barcodeCtrl,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                prefixIcon: Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.text,
              enabled: !_isEditing,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(labelText: 'Brand (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryCtrl,
              decoration:
                  const InputDecoration(labelText: 'Category (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Price (optional)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _currencyCtrl,
                    decoration: const InputDecoration(labelText: 'Currency'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitCtrl,
              decoration: const InputDecoration(
                labelText: 'Unit / pack size (e.g. 500 g, 12 pk)',
              ),
            ),
            if (_source != null) ...[
              const SizedBox(height: 24),
              Text(
                'Source: $_source',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
