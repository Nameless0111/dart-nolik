import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:ninjas_api/models/spellcheck_model.dart';
import 'package:ninjas_api/services/spellcheck_service.dart';

/// Виджет для проверки орфографии с расширенной функциональностью
class SpellCheckWidget extends StatefulWidget {
  const SpellCheckWidget({super.key});

  @override
  State<SpellCheckWidget> createState() => _SpellCheckWidgetState();
}

class _SpellCheckWidgetState extends State<SpellCheckWidget> {
  final NinjaSpellCheckService _service =
      GetIt.instance<NinjaSpellCheckService>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  SpellCheckModel? _result;
  bool _isLoading = false;
  String? _errorMessage;
  List<HistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    // Загружаем пример текста при запуске
    _loadSampleText();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Загрузка примера текста
  void _loadSampleText() {
    _textController.text = _service.getSampleText();
  }

  /// Загрузка другого примера
  void _loadAnotherSample() {
    _textController.text = _service.getAnotherSample();
    _clearResult();
  }

  /// Проверка орфографии
  Future<void> _checkSpelling() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Введите текст для проверки';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.checkSpelling(text);

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;

          if (result != null) {
            // Добавляем в историю
            _history.insert(
              0,
              HistoryItem(
                original: result.original,
                corrected: result.corrected,
                timestamp: DateTime.now(),
              ),
            );

            // Ограничиваем историю 10 элементами
            if (_history.length > 10) {
              _history.removeLast();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка проверки: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Очистка результата
  void _clearResult() {
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }

  /// Очистка всего
  void _clearAll() {
    _textController.clear();
    _clearResult();
  }

  /// Копирование исправленного текста
  void _copyCorrectedText() {
    if (_result != null) {
      Clipboard.setData(ClipboardData(text: _result!.corrected));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Исправленный текст скопирован')),
      );
    }
  }

  /// Копирование оригинального текста
  void _copyOriginalText() {
    if (_result != null) {
      Clipboard.setData(ClipboardData(text: _result!.original));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оригинальный текст скопирован')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInputSection(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 16),
          Expanded(child: _buildResultsSection()),
        ],
      ),
    );
  }

  /// Секция ввода текста
  Widget _buildInputSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Введите текст для проверки орфографии:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Введите текст здесь...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Кнопки действий
  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _checkSpelling,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.spellcheck),
          label: Text(_isLoading ? 'Проверка...' : 'Проверить'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _loadSampleText,
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('Пример 1'),
        ),
        OutlinedButton.icon(
          onPressed: _loadAnotherSample,
          icon: const Icon(Icons.lightbulb),
          label: const Text('Пример 2'),
        ),
        OutlinedButton.icon(
          onPressed: _clearAll,
          icon: const Icon(Icons.clear_all),
          label: const Text('Очистить всё'),
        ),
        if (_result != null) ...[
          OutlinedButton.icon(
            onPressed: _copyCorrectedText,
            icon: const Icon(Icons.content_copy),
            label: const Text('Копировать исправленное'),
          ),
          OutlinedButton.icon(
            onPressed: _copyOriginalText,
            icon: const Icon(Icons.copy_all),
            label: const Text('Копировать оригинал'),
          ),
        ],
      ],
    );
  }

  /// Секция результатов
  Widget _buildResultsSection() {
    if (_result == null && _history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spellcheck, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Введите текст и нажмите "Проверить"',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: const TabBar(
              tabs: [
                Tab(text: 'Результат'),
                Tab(text: 'История'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF444444)),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: TabBarView(
                children: [_buildResultTab(), _buildHistoryTab()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Вкладка с результатом
  Widget _buildResultTab() {
    if (_result == null) {
      return const Center(child: Text('Нет результатов для отображения'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextComparison(),
          const SizedBox(height: 20),
          if (_result!.corrections.isNotEmpty) ...[
            const Text(
              'Найденные ошибки:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._result!.corrections.map(
              (correction) => _buildCorrectionItem(correction),
            ),
          ],
        ],
      ),
    );
  }

  /// Сравнение текстов
  Widget _buildTextComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Оригинальный текст:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF331111),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_result!.original),
        ),
        const Text(
          'Исправленный текст:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF113311),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_result!.corrected),
        ),
      ],
    );
  }

  /// Элемент исправления
  Widget _buildCorrectionItem(Correction correction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF442222),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ошибка: ${correction.word}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF224422),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Исправление: ${correction.correction}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (correction.candidates.length > 1) ...[
              const SizedBox(height: 8),
              const Text(
                'Другие варианты:',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              Wrap(
                spacing: 8,
                children: correction.candidates
                    .where((candidate) => candidate != correction.correction)
                    .map(
                      (candidate) => Chip(
                        label: Text(candidate),
                        backgroundColor: const Color(0xFF223344),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Вкладка истории
  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'История проверок пуста',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              item.corrected,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Оригинал: ${item.original}'),
                const SizedBox(height: 4),
                Text(
                  'Проверено: ${_formatDateTime(item.timestamp)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeFromHistory(index),
            ),
            onTap: () => _loadFromHistory(item),
          ),
        );
      },
    );
  }

  /// Удаление из истории
  void _removeFromHistory(int index) {
    setState(() {
      _history.removeAt(index);
    });
  }

  /// Загрузка из истории
  void _loadFromHistory(HistoryItem item) {
    _textController.text = item.original;
    _clearResult();
  }

  /// Форматирование даты и времени
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }
}

/// Модель элемента истории
class HistoryItem {
  final String original;
  final String corrected;
  final DateTime timestamp;

  HistoryItem({
    required this.original,
    required this.corrected,
    required this.timestamp,
  });
}
