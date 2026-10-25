import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dictionary_model.dart';

class DictionaryService {
  final http.Client client;

  /// In-memory cache for dictionary lookups to avoid redundant API calls.
  final Map<String, DictionaryWord> _cache = {};

  /// Maximum number of cached entries before evicting oldest.
  static const int _maxCacheSize = 100;

  DictionaryService({http.Client? client}) : client = client ?? http.Client();

  /// Common irregular English words mapped to their root (base/lemma) form.
  static const Map<String, String> _irregulars = {
    'went': 'go', 'gone': 'go', 'goes': 'go',
    'was': 'be', 'were': 'be', 'been': 'be', 'am': 'be', 'is': 'be', 'are': 'be',
    'had': 'have', 'has': 'have',
    'did': 'do', 'does': 'do', 'done': 'do',
    'said': 'say', 'made': 'make', 'came': 'come',
    'took': 'take', 'taken': 'take',
    'saw': 'see', 'seen': 'see',
    'knew': 'know', 'known': 'know',
    'got': 'get', 'gotten': 'get',
    'gave': 'give', 'given': 'give',
    'found': 'find', 'thought': 'think', 'told': 'tell',
    'became': 'become', 'left': 'leave', 'leaves': 'leave',
    'felt': 'feel', 'brought': 'bring',
    'began': 'begin', 'begun': 'begin',
    'kept': 'keep', 'held': 'hold',
    'wrote': 'write', 'written': 'write',
    'stood': 'stand', 'heard': 'hear',
    'ran': 'run', 'paid': 'pay', 'sat': 'sit',
    'spoke': 'speak', 'spoken': 'speak',
    'built': 'build', 'understood': 'understand',
    'drew': 'draw', 'drawn': 'draw',
    'broke': 'break', 'broken': 'break',
    'spent': 'spend', 'rose': 'rise', 'risen': 'rise',
    'drove': 'drive', 'driven': 'drive',
    'bought': 'buy', 'wore': 'wear', 'worn': 'wear',
    'chose': 'choose', 'chosen': 'choose',
    'better': 'good', 'best': 'good',
    'worse': 'bad', 'worst': 'bad',
    'children': 'child', 'men': 'man', 'women': 'woman',
    'teeth': 'tooth', 'feet': 'foot', 'mice': 'mouse',
    'people': 'person', 'geese': 'goose',
  };

  /// Generates plausible root/base word candidates for inflected words.
  List<String> _generateLemmaCandidates(String word) {
    final candidates = <String>[];
    if (_irregulars.containsKey(word)) {
      candidates.add(_irregulars[word]!);
    }

    if (word.endsWith('ies') && word.length > 3) {
      candidates.add('${word.substring(0, word.length - 3)}y');
    } else if (word.endsWith('ied') && word.length > 3) {
      candidates.add('${word.substring(0, word.length - 3)}y');
    } else if (word.endsWith('ing') && word.length > 4) {
      final base = word.substring(0, word.length - 3);
      candidates.add(base);
      candidates.add('${base}e');
      if (base.length >= 3 && base[base.length - 1] == base[base.length - 2]) {
        candidates.add(base.substring(0, base.length - 1));
      }
    } else if (word.endsWith('ed') && word.length > 3) {
      final base = word.substring(0, word.length - 2);
      candidates.add(base);
      candidates.add('${base}e');
      if (base.length >= 3 && base[base.length - 1] == base[base.length - 2]) {
        candidates.add(base.substring(0, base.length - 1));
      }
    } else if (word.endsWith('es') && word.length > 3) {
      candidates.add(word.substring(0, word.length - 2));
    } else if (word.endsWith('s') && word.length > 2 && !word.endsWith('ss')) {
      candidates.add(word.substring(0, word.length - 1));
    } else if (word.endsWith('ier') && word.length > 3) {
      candidates.add('${word.substring(0, word.length - 3)}y');
    } else if (word.endsWith('iest') && word.length > 4) {
      candidates.add('${word.substring(0, word.length - 4)}y');
    } else if (word.endsWith('er') && word.length > 3) {
      final base = word.substring(0, word.length - 2);
      candidates.add(base);
      candidates.add('${base}e');
    } else if (word.endsWith('est') && word.length > 4) {
      final base = word.substring(0, word.length - 3);
      candidates.add(base);
      candidates.add('${base}e');
    }

    return candidates.toSet().toList();
  }

  /// Fetches English definition from Free Dictionary API (Oxford Style)
  /// with automatic lemmatization fallback and Vietnamese translation.
  Future<DictionaryWord> getWordDefinition(String word) async {
    final cleanWord = word.trim().toLowerCase();

    // Return cached result if available
    if (_cache.containsKey(cleanWord)) {
      return _cache[cleanWord]!;
    }

    // Try primary word lookup
    try {
      final result = await _fetchFromApi(cleanWord);
      _addToCache(cleanWord, result);
      return result;
    } catch (_) {
      // Primary lookup failed, try lemmatized candidates (e.g. running -> run, went -> go)
      final candidates = _generateLemmaCandidates(cleanWord);
      for (final candidate in candidates) {
        try {
          final result = await _fetchFromApi(candidate);
          // Prepend a note that this is the base form
          final viTrans = await translateText(cleanWord);
          result.vietnameseTranslation = viTrans.isNotEmpty 
              ? '$viTrans (Từ gốc: ${result.word})'
              : '(Từ gốc: ${result.word})';

          _addToCache(cleanWord, result);
          return result;
        } catch (_) {
          continue;
        }
      }

      // If dictionary API fails completely, try direct translation fallback
      final translation = await translateText(cleanWord);
      if (translation.isNotEmpty && !translation.startsWith('Dịch lỗi')) {
        final fallbackWord = DictionaryWord(
          word: cleanWord,
          phonetic: '',
          audioUrl: 'https://dict.youdao.com/dictvoice?type=2&audio=$cleanWord',
          definitions: [
            DictionaryDefinition(
              partOfSpeech: 'từ vựng',
              definition: 'Bản dịch nhanh: $translation',
              example: '',
              vietnameseTranslation: translation,
            ),
          ],
          vietnameseTranslation: translation,
        );
        _addToCache(cleanWord, fallbackWord);
        return fallbackWord;
      }

      throw Exception('Không tìm thấy từ vựng trong từ điển. Vui lòng kiểm tra lại chính tả.');
    }
  }

  Future<DictionaryWord> _fetchFromApi(String targetWord) async {
    final url = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$targetWord');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      if (jsonList.isNotEmpty) {
        final dictionaryWord = DictionaryWord.fromJson(jsonList[0]);

        // Translate the main word and first 3 definitions in parallel
        final translations = await Future.wait([
          translateText(dictionaryWord.word),
          ...dictionaryWord.definitions
              .where((d) => d.definition.isNotEmpty)
              .take(3)
              .map((d) => translateText(d.definition)),
        ]);

        dictionaryWord.vietnameseTranslation = translations.first;

        int idx = 1;
        for (var def in dictionaryWord.definitions) {
          if (idx > 3) break;
          if (def.definition.isNotEmpty && idx < translations.length) {
            def.vietnameseTranslation = translations[idx];
            idx++;
          }
        }

        return dictionaryWord;
      }
    }
    throw Exception('Word not found in dictionary API');
  }

  /// Add an entry to the in-memory cache with LRU eviction.
  void _addToCache(String key, DictionaryWord value) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  /// Clear the in-memory cache (useful for testing or manual refresh).
  void clearCache() {
    _cache.clear();
  }

  /// Translates text from English to Vietnamese using the free Google Translate client API.
  Future<String> translateText(String text) async {
    if (text.isEmpty) return '';
    final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q=${Uri.encodeComponent(text)}');

    try {
      final response = await client.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> jsonResult = jsonDecode(response.body);
        if (jsonResult.isNotEmpty && jsonResult[0] != null) {
          final buffer = StringBuffer();
          for (var item in jsonResult[0]) {
            if (item is List && item.isNotEmpty && item[0] is String) {
              buffer.write(item[0]);
            }
          }
          return buffer.toString();
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }
}
