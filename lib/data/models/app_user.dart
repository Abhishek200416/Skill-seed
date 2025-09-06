import 'package:meta/meta.dart';

@immutable
class AppUser {
  final String id;
  final String role; // 'student' | 'teacher' | 'admin'
  final String name;
  final String email;
  final String phone;
  final int? age;
  final String? college;
  final String? standard;
  final bool isApproved;
  final String? specialty; // teachers only
  final String? about; // teachers only

  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    this.age,
    this.college,
    this.standard,
    this.isApproved = false,
    this.specialty,
    this.about,
  });

  AppUser copyWith({
    String? id,
    String? role,
    String? name,
    String? email,
    String? phone,
    int? age,
    String? college,
    String? standard,
    bool? isApproved,
    String? specialty,
    String? about,
  }) {
    return AppUser(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      college: college ?? this.college,
      standard: standard ?? this.standard,
      isApproved: isApproved ?? this.isApproved,
      specialty: specialty ?? this.specialty,
      about: about ?? this.about,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'role': role,
        'name': name,
        'email': email,
        'phone': phone,
        'age': age,
        'college': college,
        'standard': standard,
        'isApproved': isApproved,
        'specialty': specialty,
        'about': about,
      };

  static AppUser fromMap(Map<String, dynamic> m) {
    final rawApproved = m['isApproved'];
    final approved =
        rawApproved is bool ? rawApproved : ((rawApproved as int? ?? 0) == 1);
    return AppUser(
      id: m['id'] as String,
      role: m['role'] as String,
      name: m['name'] as String,
      email: m['email'] as String,
      phone: (m['phone'] ?? '') as String,
      age: m['age'] is int ? m['age'] as int : (m['age'] as num?)?.toInt(),
      college: m['college'] as String?,
      standard: m['standard'] as String?,
      isApproved: approved,
      specialty: m['specialty'] as String?,
      about: m['about'] as String?,
    );
  }
}
