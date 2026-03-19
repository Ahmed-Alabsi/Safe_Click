import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeclik/core/network/feedback_api.dart';
import 'package:safeclik/features/settings/data/models/rating_model.dart';
import 'package:safeclik/core/di/di.dart';
import 'package:flutter/foundation.dart';

final ratingProvider = AsyncNotifierProvider<RatingNotifier, AppRating>(
  () => RatingNotifier(),
);

class RatingNotifier extends AsyncNotifier<AppRating> {
  final FeedbackApi _api = sl<FeedbackApi>();

  @override
  Future<AppRating> build() async {
    return _fetchRating();
  }

  Future<AppRating> _fetchRating() async {
    try {
      final response = await _api.getAppRating();
      return AppRating.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching rating: $e');
      return AppRating(rating: null, comment: '');
    }
  }

  Future<bool> submitRating(int rating, String comment) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.submitAppRating(rating, comment);
      if (response['success'] == true || response['rating'] != null) {
        state = AsyncValue.data(AppRating.fromJson(response));
        return true;
      }
      state = AsyncValue.error('Failed to save rating', StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}
