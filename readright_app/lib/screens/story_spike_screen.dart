import 'package:flutter/material.dart';
import '../services/story_service.dart';

/// M2 de-risk spike: proves the AI Story Builder path works end to end
/// (Flutter -> backend proxy -> mini-tier model -> story back) using a
/// fixed sample of Dolch words. This is not the real Story Builder UI,
/// which will let a teacher pick a word list and theme — see the PRD.
class StorySpikeScreen extends StatefulWidget {
  const StorySpikeScreen({super.key});

  @override
  State<StorySpikeScreen> createState() => _StorySpikeScreenState();
}

class _StorySpikeScreenState extends State<StorySpikeScreen> {
  final _storyService = StoryService();
  static const _sampleWords = ['all', 'am', 'are', 'brown', 'eat', 'good'];

  bool _loading = false;
  String? _story;
  String? _error;

  Future<void> _runSpike() async {
    setState(() {
      _loading = true;
      _error = null;
      _story = null;
    });
    try {
      final story = await _storyService.generateStory(
        words: _sampleWords,
        theme: 'a trip to the park',
        gradeLevel: 'kindergarten',
      );
      setState(() => _story = story);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Story Spike (M2 test)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target Dolch words: ${_sampleWords.join(', ')}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _runSpike,
              child: Text(_loading ? 'Generating...' : 'Generate test story'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_story != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_story!, style: Theme.of(context).textTheme.bodyLarge),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
