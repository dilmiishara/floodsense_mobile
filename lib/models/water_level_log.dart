class WaterLevelLog {
  final int id;
  final String recordedAt;
  final String stationName;
  final String riverName;
  final double waterLevel;
  final double previousWaterLevel;
  final String alertStatus;
  final double floodScore;
  final String risingOrFalling;
  final double rainfallMm;
  final String remarks;
  final String sourceTimestamp;

  WaterLevelLog({
    required this.id,
    required this.recordedAt,
    required this.stationName,
    required this.riverName,
    required this.waterLevel,
    required this.previousWaterLevel,
    required this.alertStatus,
    required this.floodScore,
    required this.risingOrFalling,
    required this.rainfallMm,
    required this.remarks,
    required this.sourceTimestamp,
  });

  factory WaterLevelLog.fromJson(Map<String, dynamic> json) {
    return WaterLevelLog(
      id: json['id'] ?? 0,
      recordedAt: json['recorded_at']?.toString() ?? '',
      stationName: json['station_name']?.toString() ?? '',
      riverName: json['river_name']?.toString() ?? '',
      waterLevel:
          double.tryParse(json['water_level']?.toString() ?? '0') ?? 0.0,
      previousWaterLevel:
          double.tryParse(json['previous_water_level']?.toString() ?? '0') ??
              0.0,
      alertStatus: json['alert_status']?.toString() ?? 'NORMAL',
      floodScore:
          double.tryParse(json['flood_score']?.toString() ?? '0') ?? 0.0,
      risingOrFalling: json['rising_or_falling']?.toString() ?? '',
      rainfallMm:
          double.tryParse(json['rainfall_mm']?.toString() ?? '0') ?? 0.0,
      remarks: json['remarks']?.toString() ?? '',
      sourceTimestamp: json['source_timestamp']?.toString() ?? '',
    );
  }

  // Water level change from previous
  double get waterLevelChange => waterLevel - previousWaterLevel;

  // Is rising
  bool get isRising => waterLevelChange > 0;

  // Is falling
  bool get isFalling => waterLevelChange < 0;
}