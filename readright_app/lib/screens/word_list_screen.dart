import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

import '../models/word_item.dart';

class WordListScreen extends StatefulWidget {
  final String name;
  final String path;
  final bool isAsset;

  const WordListScreen({
    super.key,
    required this.name,
    required this.path,
    required this.isAsset,
  });

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  List<WordItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      String csvText;

      if (widget.isAsset) {
        csvText = await rootBundle.loadString(widget.path);
      } else {
        csvText = await File(widget.path).readAsString();
      }

      // Parse CSV into rows
      final rows = const CsvToListConverter().convert(csvText);

      if (rows.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }

      // Assume first row is header: category, word, example_sentence_1, ...
      final dataRows = rows.skip(1);

      final items = <WordItem>[];

      for (final row in dataRows) {
        // Convert dynamic -> String
        final parts = row.map((cell) => cell.toString()).toList();

        // We need at least category, word, exampleSentence
        if (parts.length < 3) continue;

        // Your factory handles mastered and extra columns gracefully
        items.add(WordItem.fromCsv(parts));
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading list: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No words found in this list.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final w = _items[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                w.word,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (w.mastered)
                              const Icon(Icons.check_circle, size: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          w.exampleSentence,
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (w.category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            w.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
