// lib/screens/manage_word_list_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';

import '../models/word_list_definition.dart';
import 'word_list_screen.dart';

class ManageWordListScreen extends StatefulWidget {
  const ManageWordListScreen({super.key});

  @override
  State<ManageWordListScreen> createState() => _ManageWordListScreenState();
}

class _ManageWordListScreenState extends State<ManageWordListScreen> {
  List<File> uploadedLists = [];

  @override
  void initState() {
    super.initState();
    _loadUploadedLists();
  }

  Future<void> _loadUploadedLists() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/uploaded_wordlists');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final files = folder
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.csv'))
        .toList();

    if (!mounted) return;
    setState(() {
      uploadedLists = files;
    });
  }

  Future<void> _uploadWordList() async {
    // Accept CSV files only
    final typeGroup = XTypeGroup(label: 'CSV', extensions: ['csv']);

    final XFile? picked = await openFile(acceptedTypeGroups: [typeGroup]);

    if (picked == null) return; // User cancelled

    final bytes = await picked.readAsBytes();
    final fileName = picked.name;

    // Save to local app storage
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/uploaded_wordlists');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final savePath = '${folder.path}/$fileName';
    final file = File(savePath);
    await file.writeAsBytes(bytes);

    await _loadUploadedLists();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Uploaded: $fileName')));
  }

  void _openList(
    BuildContext context,
    String name,
    String path, {
    required bool isAsset,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WordListScreen(name: name, path: path, isAsset: isAsset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Word Lists')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Built-In Lists',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Built-in lists from assets
          ...builtInWordLists.map(
            (list) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(list.name),
                subtitle: Text(list.assetPath.split('/').last),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openList(
                  context,
                  list.name,
                  list.assetPath,
                  isAsset: true,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Uploaded Lists',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (uploadedLists.isEmpty)
            const Text(
              'No uploaded lists yet.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),

          // Uploaded CSV files
          ...uploadedLists.map((file) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(fileName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _openList(context, fileName, file.path, isAsset: false),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadWordList,
        tooltip: 'Upload CSV word list',
        child: const Icon(Icons.file_upload),
      ),
    );
  }
}
