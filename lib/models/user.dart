class HapkeUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String gender; // "Man", "Vrouw", "Anders", "Zeg ik liever niet"
  HapkeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.gender,
  });

  factory HapkeUser.fromJson(Map<String, dynamic> json) {
    return HapkeUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'gender': gender,
    };
  }
}

class AuthSession {
  final HapkeUser user;
  final String token;
  const AuthSession({required this.user, required this.token});
}
