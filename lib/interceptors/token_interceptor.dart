import 'package:dio/dio.dart';

/// Интерсептор для автоматического добавления API ключа в заголовки запросов
class TokenInterceptor extends Interceptor {
  final String apiKey;

  TokenInterceptor({required this.apiKey});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Добавляем API ключ в заголовки каждого запроса
    options.headers['X-Api-Key'] = apiKey;
    
    print('Добавлен API ключ в запрос к: ${options.path}');
    super.onRequest(options, handler);
  }
}