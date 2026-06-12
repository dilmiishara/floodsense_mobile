class SafeLocation {
  final int id;
  final String locationName;
  final String locationType;
  final String address;
  final String district;
  final String? province;
  final double latitude;
  final double longitude;
  final int? maxCapacity;
  final String? contactPerson;
  final String? contactNumber;
  final bool disabledAccess;

  SafeLocation({
    required this.id,
    required this.locationName,
    required this.locationType,
    required this.address,
    required this.district,
    this.province,
    required this.latitude,
    required this.longitude,
    this.maxCapacity,
    this.contactPerson,
    this.contactNumber,
    required this.disabledAccess,
  });

  factory SafeLocation.fromJson(Map<String, dynamic> json) {
    return SafeLocation(
      id: json['id'],
      locationName: json['location_name'] ?? 'Unknown',
      locationType: json['location_type'] ?? 'Safe Location',
      address: json['address'] ?? 'No address',
      district: json['district'] ?? '',
      province: json['province'],
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      maxCapacity: json['max_capacity'],
      contactPerson: json['contact_person'],
      contactNumber: json['contact_number'],
      disabledAccess: json['disabled_access'] ?? false,
    );
  }
}