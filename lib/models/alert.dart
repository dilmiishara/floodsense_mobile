class Alert {
  final int id;
  final String type;
  final String severity;
  final String message;
  final String status;
  final DateTime detectedAt;
  final int? areaId;

  Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.status,
    required this.detectedAt,
    this.areaId,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      type: json['type'] ?? 'Alert',
      severity: json['severity'] ?? 'LOW',
      message: json['message'] ?? '',
      status: json['status'] ?? 'active',
      detectedAt: DateTime.parse(json['detected_at']),
      areaId: json['area_id'],
    );
  }
}