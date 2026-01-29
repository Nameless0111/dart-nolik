/// Модель для коррекции орфографии
class SpellCheckModel {
  /// Оригинальный текст
  final String original;

  /// Исправленный текст
  final String corrected;

  /// Список исправлений
  final List<Correction> corrections;

  SpellCheckModel({
    required this.original,
    required this.corrected,
    required this.corrections,
  });

  /// Создание модели из JSON данных
  factory SpellCheckModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> correctionsJson = json['corrections'] as List<dynamic>;
    
    return SpellCheckModel(
      original: json['original'] as String,
      corrected: json['corrected'] as String,
      corrections: correctionsJson
          .map((corr) => Correction.fromJson(corr as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'SpellCheckModel(original: $original, corrected: $corrected)';
  }
}

/// Модель отдельного исправления
class Correction {
  /// Неправильное слово
  final String word;

  /// Индекс слова в оригинальном тексте
  final int index;

  /// Исправленное слово
  final String correction;

  /// Возможные варианты исправления
  final List<String> candidates;

  Correction({
    required this.word,
    required this.index,
    required this.correction,
    required this.candidates,
  });

  /// Создание модели из JSON данных
  factory Correction.fromJson(Map<String, dynamic> json) {
    final List<dynamic> candidatesJson = json['candidates'] as List<dynamic>;
    
    return Correction(
      word: json['word'] as String,
      index: json['index'] as int,
      correction: json['correction'] as String,
      candidates: candidatesJson.map((c) => c as String).toList(),
    );
  }

  @override
  String toString() {
    return 'Correction(word: $word, correction: $correction)';
  }
}