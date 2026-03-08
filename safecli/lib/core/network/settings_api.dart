import 'package:safeclik/core/network/api_client.dart';

class SettingsApi {
  final ApiClient _client;

  SettingsApi(this._client);

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _client.dio.get('/auth/settings/');
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _client.dio.put('/auth/settings/', data: settings);
      return response.data;
    } catch (e) {
      return _client.handleDioError(e);
    }
  }
}
