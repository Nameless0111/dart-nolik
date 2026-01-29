import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:ninjas_api/interceptors/logging_interceptors.dart';
import 'package:ninjas_api/interceptors/token_interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:ninjas_api/widgets/spellcheck_widget.dart';
import 'package:ninjas_api/services/spellcheck_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const MainApp());
}

/// Настройка dependency injection
void setupDependencies() {
  final String apiKey = '85QPvyOWCQY50TGoJe2LVY4luHHbLPaLg4P2kSXu';

  // Регистрация Dio с интерсепторами
  GetIt.instance.registerLazySingleton(
    () => Dio(BaseOptions(baseUrl: 'https://api.api-ninjas.com/v1/'))
      ..interceptors.addAll([
        TokenInterceptor(apiKey: apiKey), // Автоматическое добавление API ключа
        LoggingInterceptor(), // Логирование запросов
        PrettyDioLogger(), // Красивое логирование для отладки
      ]),
  );

  // Регистрация сервиса проверки орфографии
  GetIt.instance.registerLazySingleton<NinjaSpellCheckService>(
    () => NinjaSpellCheckService(),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpellCheck App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(color: Color(0xFF1E1E1E), elevation: 4),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2D2D2D),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
      home: const SpellCheckScreen(),
    );
  }
}

/// Основной экран приложения для проверки орфографии
class SpellCheckScreen extends StatelessWidget {
  const SpellCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Проверка орфографии"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: const SpellCheckWidget(),
    );
  }

  /// Показ диалога с информацией
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('О приложении'),
          content: const Text(
            'Это приложение использует API Ninja для проверки орфографии. '
            'Введите текст с ошибками, и система предложит исправления.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}
