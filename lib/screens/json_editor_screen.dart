import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/series_provider.dart';
import '../services/localization_service.dart';

class JsonEditorScreen extends StatefulWidget {
  final String title;
  final String initialJson;
  final Future<void> Function(String) onSave;

  const JsonEditorScreen({
    super.key,
    required this.title,
    required this.initialJson,
    required this.onSave,
  });

  @override
  State<JsonEditorScreen> createState() => _JsonEditorScreenState();
}

class _JsonEditorScreenState extends State<JsonEditorScreen> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pretty print initial JSON
    try {
      final decoded = json.decode(widget.initialJson);
      _controller = TextEditingController(
        text: const JsonEncoder.withIndent('  ').convert(decoded),
      );
    } catch (_) {
      _controller = TextEditingController(text: widget.initialJson);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSave() async {
    setState(() => _error = null);
    final lang = Provider.of<SeriesProvider>(context, listen: false).language;

    try {
      json.decode(_controller.text); // Validate format
      await widget.onSave(_controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.translate('json_saved', lang)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(
        () => _error =
            '${LocalizationService.translate('invalid_json', lang)}: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<SeriesProvider>(context).language;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _validateAndSave,
            tooltip: LocalizationService.translate('save', lang),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red.withOpacity(0.2),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{ ... }',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
