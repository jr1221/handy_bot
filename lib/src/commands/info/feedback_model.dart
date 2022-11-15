class FeedbackModel {
  final DateTime recievedAt;
  final String username;
  final String feedbackInput;

  FeedbackModel(this.recievedAt, this.username, this.feedbackInput);

  FeedbackModel.fromJson(Map<String, dynamic> json)
      : recievedAt = DateTime.parse(json['recievedAt']),
        username = json['username'],
        feedbackInput = json['feedbackInput'];

  Map<String, dynamic> toJson() => {
        'recievedAt': recievedAt.toIso8601String(),
        'username': username,
        'feedbackInput': feedbackInput
      };
}
