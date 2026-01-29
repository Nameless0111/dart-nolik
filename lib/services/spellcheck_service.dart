import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:ninjas_api/models/spellcheck_model.dart';

final service = GetIt.instance;

class NinjaSpellCheckService {
  /// Проверка орфографии текста
  Future<SpellCheckModel?> checkSpelling(String text) async {
    try {
      // Экранируем пробелы в тексте для URL
      final encodedText = Uri.encodeComponent(text);
      
      final response = await service<Dio>().get(
        '/spellcheck?text=$encodedText',
      );
      
      // Проверяем успешный статус ответа
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        return SpellCheckModel.fromJson(data);
      } else {
        print('Ошибка API: получен статус ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('Ошибка API: ${e.message}');
      if (e.response != null) {
        print('Статус: ${e.response?.statusCode}');
        print('Тело: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      print('Неожиданная ошибка: $e');
      return null;
    }
  }

  /// Получение примера текста с ошибками
  String getSampleText() {
    return 'i am not kkiddign and i wnat to byu somethign';
  }

  /// Получение другого примера
  String getAnotherSample() {
    return 'Ths is a tset sentance with speling erors';
  }
}