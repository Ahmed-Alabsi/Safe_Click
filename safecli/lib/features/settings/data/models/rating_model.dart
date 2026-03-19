class AppRating {
  final int? rating;
  final String comment;

  AppRating({this.rating, required this.comment});

  factory AppRating.fromJson(Map<String, dynamic> json) {
    return AppRating(
      rating: json['rating'],
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
    };
  }
}
