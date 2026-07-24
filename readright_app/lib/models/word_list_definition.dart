// lib/models/word_list_definition.dart

class WordListDefinition {
  final String name; // Name shown in UI
  final String assetPath; // Path to CSV file inside assets

  const WordListDefinition({required this.name, required this.assetPath});
}

// Built-in lists shipped with the app
const List<WordListDefinition> builtInWordLists = [
  WordListDefinition(name: 'Seed Words', assetPath: 'lib/data/seed_words.csv'),
  WordListDefinition(
    name: 'Dolch – PreK',
    assetPath: 'lib/data/dolch_prek.csv',
  ),
  WordListDefinition(
    name: 'Dolch – Kindergarten',
    assetPath: 'lib/data/dolch_kindergarten.csv',
  ),
  WordListDefinition(
    name: 'Dolch – 1st Grade',
    assetPath: 'lib/data/dolch_1st.csv',
  ),
  WordListDefinition(
    name: 'Dolch – 2nd Grade',
    assetPath: 'lib/data/dolch_2nd.csv',
  ),
  WordListDefinition(
    name: 'Dolch – 3rd Grade',
    assetPath: 'lib/data/dolch_3rd.csv',
  ),
  WordListDefinition(
    name: 'Dolch – Nouns',
    assetPath: 'lib/data/dolch_nouns.csv',
  ),
  WordListDefinition(name: 'Test List 1', assetPath: 'lib/data/test1.csv'),
  WordListDefinition(name: 'Test List 2', assetPath: 'lib/data/test2.csv'),
];
