import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'note_model.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _notesStorageKey = 'notes_v1';

  final TextEditingController _textController = TextEditingController();
  final List<Note> _notes = [];
  Note? _editingNote;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notesStorageKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final loaded = decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map(Note.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _notes
          ..clear()
          ..addAll(loaded);
      });
    } catch (_) {
      // Если формат сломан — просто игнорируем, чтобы не ломать UI.
    }
  }

  Future<void> _persistNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await prefs.setString(_notesStorageKey, raw);
  }

  /// Сохранение новой заметки или обновление существующей
  void _saveNote() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (_editingNote != null) {
        // Редактирование существующей заметки
        _editingNote!.updateText(text);
        _editingNote = null;
      } else {
        // Создание новой заметки
        _notes.add(Note.create(text));
      }
      _textController.clear();
    });
    _persistNotes();
  }

  /// Редактирование заметки
  void _editNote(Note note) {
    setState(() {
      _editingNote = note;
      _textController.text = note.text;
    });
  }

  /// Удаление заметки
  void _deleteNote(Note note) {
    setState(() {
      _notes.remove(note);
    });
    _persistNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои заметки'), centerTitle: true),
      body: Column(
        children: [
          // Поле ввода и кнопка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: _editingNote != null
                          ? 'Редактирование заметки...'
                          : 'Введите текст заметки...',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 16.0,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: Text(_editingNote != null ? 'Обновить' : 'Сохранить'),
                ),
              ],
            ),
          ),

          // Список заметок
          Expanded(
            child: _notes.isEmpty
                ? const Center(
                    child: Text(
                      'Заметок пока нет\nДобавьте первую заметку!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            note.text,
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                            'Создано: ${_formatDate(note.createdAt)}\n'
                            'Обновлено: ${_formatDate(note.updatedAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editNote(note),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteNote(note),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Форматирование даты для отображения
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
