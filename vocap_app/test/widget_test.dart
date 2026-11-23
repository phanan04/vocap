import 'package:flutter_test/flutter_test.dart';
import 'package:vocap_app/models/word_model.dart';

void main() {
  test('WordModel serialization test', () {
    final json = {
      'id': 1,
      'word': 'ability',
      'type': 'noun',
      'cefr': 'a2',
      'ielts_band': '4.0 - 4.5',
      'meaning_vi': 'khả năng',
      'definition': 'the fact that sb is able to do sth',
      'example': 'She has the ability to succeed.',
      'example_vi': 'Cô ấy có khả năng thành công.',
      'collocations': ['great ability'],
      'synonyms': ['capability'],
      'antonyms': ['inability'],
      'word_family': {},
      'topic': 'General',
      'subtopic': 'General',
    };

    final word = WordModel.fromJson(json);
    expect(word.id, 1);
    expect(word.word, 'ability');
    expect(word.cefr, 'A2');
  });
}
