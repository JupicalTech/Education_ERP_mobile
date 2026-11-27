import 'user_role.dart';

class Profile {
  const Profile({
    required this.id,
    this.instituteId = '',
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
  });

  final String id;
  final String instituteId;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;

  String get fullName => '$firstName $lastName'.trim();

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      instituteId: (json['institute_id'] as String?) ?? '',
      role: UserRole.fromString(json['role'] as String),
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institute_id': instituteId,
      'role': role.toDb(),
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_active': isActive,
    };
  }

  Profile copyWith({
    String? id,
    String? instituteId,
    UserRole? role,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    bool? isActive,
  }) {
    return Profile(
      id: id ?? this.id,
      instituteId: instituteId ?? this.instituteId,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
