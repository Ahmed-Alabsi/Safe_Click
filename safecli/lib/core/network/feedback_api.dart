import 'package:safeclik/core/network/api_client.dart';

class FeedbackApi {
  final ApiClient _client;

  FeedbackApi(this._client);

  Future<Map<String, dynamic>> getAppRating() async {
    try {
      final response = await _client.dio.get('/feedback/rating/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> submitAppRating(int rating, String comment) async {
    try {
      final response = await _client.dio.put('/feedback/rating/', data: {
        'rating': rating,
        'comment': comment,
      });
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }
}
