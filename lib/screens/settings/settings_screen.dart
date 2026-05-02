import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:time_tracker/database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:time_tracker/utils/csv_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  File? _logo;
  bool _showLetterhead = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final settings = await (db.select(db.companySettings)..where((s) => s.id.equals(1))).getSingleOrNull();
    if (settings != null) {
      _nameController.text = settings.companyName;
      _addressController.text = settings.companyAddress;
      if (settings.logoPath != null) {
        _logo = File(settings.logoPath!);
      }
      _showLetterhead = settings.showLetterhead;
      setState(() {});
    }
  }

  Future<void> _pickLogo() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logo = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final db = Provider.of<AppDatabase>(context, listen: false);
    final companion = CompanySettingsCompanion(
      id: const drift.Value(1),
      companyName: drift.Value(_nameController.text),
      companyAddress: drift.Value(_addressController.text),
      logoPath: _logo != null ? drift.Value(_logo!.path) : const drift.Value.absent(),
      showLetterhead: drift.Value(_showLetterhead),
    );

    await db.into(db.companySettings).insertOnConflictUpdate(companion);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully.')));
    }
  }

  Future<void> _exportCSV(String tableName, String label) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final path = await exportTableToCSV(db: db, tableName: tableName);
    if (!mounted) return;

    if (path != null) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('$label exported to $path')));
    } else {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('No $label data to export.')));
    }
  }

  Future<void> _importCSV(String tableName, String label) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await importTableFromCSV(db: db, tableName: tableName);
    if (!mounted) return;

    if (result.errors.isNotEmpty && result.inserted == 0) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Import failed: ${result.errors.first}')));
    } else {
      final msg = StringBuffer('Imported ${result.inserted} $label');
      if (result.skipped > 0) msg.write(', ${result.skipped} skipped');
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(msg.toString())));
    }
  }

  void _showImportExportDialog(String tableName, String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text('Choose an action for $label data.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _importCSV(tableName, label);
            },
            child: const Text('Import CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportCSV(tableName, label);
            },
            child: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
              validator: (value) => value!.isEmpty ? 'Please enter your company name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Company Address'),
              maxLines: 3,
              validator: (value) => value!.isEmpty ? 'Please enter your company address' : null,
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Company Logo'),
              subtitle: _logo == null ? const Text('No logo selected') : Text(_logo!.path.split('/').last),
              trailing: const Icon(Icons.image),
              onTap: _pickLogo,
            ),
            if (_logo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Image.file(_logo!, height: 100),
              ),
            SwitchListTile(
              title: const Text('Show Letterhead on Invoices'),
              subtitle: const Text('Includes your logo and company details at the top.'),
              value: _showLetterhead,
              onChanged: (bool value) {
                setState(() {
                  _showLetterhead = value;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Import / Export Data', style: Theme.of(context).textTheme.titleMedium),
            ),
            _buildDataTile(Icons.people, 'Clients', 'clients'),
            _buildDataTile(Icons.folder, 'Projects', 'projects'),
            _buildDataTile(Icons.timer, 'Time Entries', 'time_entries'),
            _buildDataTile(Icons.receipt, 'Expenses', 'expenses'),
            _buildDataTile(Icons.request_quote, 'Invoices', 'invoices'),
            _buildDataTile(Icons.list_alt, 'Todos', 'todos'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTile(IconData icon, String label, String tableName) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.swap_horiz),
      onTap: () => _showImportExportDialog(tableName, label),
    );
  }
}
