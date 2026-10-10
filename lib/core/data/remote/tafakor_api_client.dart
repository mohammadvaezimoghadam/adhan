import 'package:flutter/foundation.dart';
import '../../services/downloader/adapters/http_adapter.dart';
import '../../../features/tafakor/infrastructure/dtos/tafakor_topic_dto.dart';
import '../../../features/tafakor/infrastructure/datasources/tafakor_local_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';

import '../../../common/constants/app_constants.dart';

import '../../../features/tafakor/application/controllers/tafakor_auth_controller.dart';

part 'tafakor_api_client.g.dart';

@RestApi()
abstract class TafakorApiClient {
  factory TafakorApiClient(Dio dio, {String? baseUrl}) = _TafakorApiClient;

  @POST('auth/request-otp/')
  Future<HttpResponse<dynamic>> requestOtp(@Body() Map<String, dynamic> body);

  @POST('auth/verify-otp/')
  Future<HttpResponse<dynamic>> verifyOtp(@Body() Map<String, dynamic> body);

  @GET('auth/connect-token/')
  Future<HttpResponse<dynamic>> getConnectToken(
    @Query('platform') String platform,
  );

  @GET('auth/profile/')
  Future<HttpResponse<dynamic>> getProfile();

  @GET('notes/topics/')
  Future<List<TafakorTopicDto>> getTopics();

  @POST('notes/')
  Future<HttpResponse<dynamic>> createPost(@Body() Map<String, dynamic> body);
}

final tafakorDioProvider = Provider<Dio>((ref) {
  final options = BaseOptions(
    baseUrl: AppConstants.tafakorBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  final dio = Dio(options);
  configureHttpClientAdapter(dio);

  dio.interceptors.add(
    LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint('[Dio/Tafakor] $obj'),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Automatically inject Authorization token if user is logged in
        final localDataSource = ref.read(tafakorLocalDataSourceProvider);
        final token = await localDataSource.getToken();
        if (token != null && token.isNotEmpty && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Token $token';
        }
        return handler.next(options);
      },
      onError: (DioException err, handler) {
        if (err.response?.statusCode == 401) {
          debugPrint('[Dio/Tafakor] 401 Unauthorized detected for: ${err.requestOptions.path}');
          ref.read(tafakorLocalDataSourceProvider).clear();
          Future.microtask(() {
            try {
              ref.read(tafakorAuthControllerProvider.notifier).logout();
            } catch (e) {
              debugPrint('[Dio/Tafakor] Error during logout on 401: $e');
            }
          });
        }
        return handler.next(err);
      },
    ),
  );

  return dio;
});

final tafakorApiClientProvider = Provider<TafakorApiClient>((ref) {
  final dio = ref.watch(tafakorDioProvider);
  return TafakorApiClient(dio, baseUrl: AppConstants.tafakorBaseUrl);
});
