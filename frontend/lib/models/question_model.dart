class QuestionModel {
  final String id;
  final String source;
  final String subject;
  final String question;
  final List<String> options;

  const QuestionModel({
    required this.id,
    required this.source,
    required this.subject,
    required this.question,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      source: json['source'] as String,
      subject: json['subject'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'subject': subject,
        'question': question,
        'options': options,
      };
}
