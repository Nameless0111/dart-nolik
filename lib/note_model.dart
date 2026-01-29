/// Модель заметки
class Note {
  final String id;
  String text;
  final DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создание новой заметки
  factory Note.create(String text) {
    final now = DateTime.now();
    return Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Обновление текста заметки
  void updateText(String newText) {
    text = newText;
    updatedAt = DateTime.now();
  }

  /// Преобразование в Map для сериализации
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Создание из Map для десериализации
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
