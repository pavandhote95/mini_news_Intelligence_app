import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/news_response_model.dart';

abstract interface class NewsRemoteDataSource {
  Future<NewsResponseModel> fetchTopHeadlines({
    required String category,
    required int page,
    required int pageSize,
  });

  Future<NewsResponseModel> searchArticles({
    required String query,
    required String sortBy,
    required int page,
    required int pageSize,
    String? language,
    DateTime? from,
  });
}

/// NewsAPI.org implementation. Throws [ServerException], [MissingApiKeyException]
/// or [DioException]; the repository maps them to failures.
class NewsApiRemoteDataSource implements NewsRemoteDataSource {
  NewsApiRemoteDataSource(this._dio, {required String apiKey}) : _apiKey = apiKey;

  final Dio _dio;
  final String _apiKey;

  @override
  Future<NewsResponseModel> fetchTopHeadlines({
    required String category,
    required int page,
    required int pageSize,
  }) {
    return _get(ApiEndpoints.topHeadlines, {
      'country': ApiEndpoints.defaultCountry,
      'category': category,
      'page': page,
      'pageSize': pageSize,
    });
  }

  @override
  Future<NewsResponseModel> searchArticles({
    required String query,
    required String sortBy,
    required int page,
    required int pageSize,
    String? language,
    DateTime? from,
  }) {
    return _get(ApiEndpoints.everything, {
      'q': query,
      'searchIn': 'title,description',
      'sortBy': sortBy,
      'page': page,
      'pageSize': pageSize,
      if (language != null) 'language': language,
      if (from != null) 'from': from.toUtc().toIso8601String(),
    });
  }

  Future<NewsResponseModel> _get(String path, Map<String, dynamic> query) async {
    if (_apiKey.trim().isEmpty) throw const MissingApiKeyException();

    final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
    final data = response.data;
    if (data == null) throw const FormatException('Empty response body');

    if (data['status'] != 'ok') {
      throw ServerException(
        message: data['message'] as String? ?? 'Unknown error from news service',
        code: data['code'] as String?,
        statusCode: response.statusCode,
      );
    }
    return NewsResponseModel.fromJson(data);
  }
}
