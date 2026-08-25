class PudtanResponse {
  const PudtanResponse({
    required this.answer,
    required this.confidence,
    required this.score,
    required this.decision,
    required this.reason,
  });

  final String answer;
  final String confidence;
  final double score;
  final String decision;
  final String reason;

  factory PudtanResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid Pudtan response: missing data',
      );
    }

    final confidence = data['confidence'];

    if (confidence is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid Pudtan response: missing confidence',
      );
    }

    return PudtanResponse(
      answer: data['answer']?.toString() ?? '',
      confidence:
          confidence['confidence']?.toString() ?? 'none',
      score: _toDouble(confidence['score']),
      decision:
          confidence['decision']?.toString() ?? 'block',
      reason:
          confidence['reason']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}