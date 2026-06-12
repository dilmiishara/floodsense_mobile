class UserModel {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? district;
  final String? city;
  final String? address;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.district,
    this.city,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      district: json['district'],
      city: json['city'],
      address: json['address'],
    );
  }
}