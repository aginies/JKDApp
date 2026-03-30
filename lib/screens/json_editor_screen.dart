import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class JsonEditorScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const JsonEditorScreen({
    super.key,
    required this.filePath,
    required this.title,
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
    _controller = TextEditingController();
    _loadJson();
  }

  Future<void> _loadJson() async {
    try {
      // Check if the file exists in the app's document directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fullPath = '${appDocDir.path}/${widget.filePath}';
      final File file = File(fullPath);

      String jsonString;
      if (await file.exists()) {
        jsonString = await file.readAsString();
      } else {
        // If not, load from assets
        jsonString = await rootBundle.loadString(widget.filePath);
      }

      final decoded = json.decode(jsonString);
      setState(() {
        _controller.text = const JsonEncoder.withIndent('  ').convert(decoded);
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading JSON: $e';
        _controller.text = '';
      });
    }
  }

  Future<void> _saveJson() async {
    try {
      final decoded = json.decode(_controller.text); // Validate JSON
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fullPath = '${appDocDir.path}/${widget.filePath}';
      final File file = File(fullPath);

      // Ensure the directory exists
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(decoded),
      );
      setState(() {
        _error = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON saved successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error saving JSON: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving JSON: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveJson,
            tooltip: 'Save JSON',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Edit JSON for ${widget.filePath}',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
