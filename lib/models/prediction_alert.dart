class PredictionAlert {
  final int id;
  final String stationName;
  final String forecastTime;
  final double predictedWaterLevel;
  final String floodRiskLevel;
  final double affectedAreaSqkm;
  final double durationDays;
  final double temperature;
  final double humidity;
  final double rainfall;
  final String createdAt;

  PredictionAlert({
    required this.id,
    required this.stationName,
    required this.forecastTime,
    required this.predictedWaterLevel,
    required this.floodRiskLevel,
    required this.affectedAreaSqkm,
    required this.durationDays,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.createdAt,
  });

  factory PredictionAlert.fromJson(Map<String, dynamic> json) {
    return PredictionAlert(
      id: json['id'] ?? 0,
      stationName: json['station_name']?.toString() ?? '',
      forecastTime: json['forecast_time']?.toString() ?? '',
      predictedWaterLevel:
          double.tryParse(json['predicted_water_level']?.toString() ?? '0') ?? 0.0,
      floodRiskLevel: json['flood_risk_level']?.toString() ?? 'Normal',
      affectedAreaSqkm:
          double.tryParse(json['affected_area_sqkm']?.toString() ?? '0') ?? 0.0,
      durationDays:
          double.tryParse(json['duration_days']?.toString() ?? '0') ?? 0.0,
      temperature:
          double.tryParse(json['temperature']?.toString() ?? '0') ?? 0.0,
      humidity:
          double.tryParse(json['humidity']?.toString() ?? '0') ?? 0.0,
      rainfall:
          double.tryParse(json['rainfall']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}