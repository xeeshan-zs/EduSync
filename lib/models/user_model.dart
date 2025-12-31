
enum UserRole { super_admin, admin, teacher, student, unknown }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isDisabled;
  final Map<String, dynamic> metadata;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isDisabled = false,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name, // Store as string
      'isDisabled': isDisabled,
      'metadata': metadata,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'unknown'),
        orElse: () => UserRole.unknown,
      ),
      isDisabled: map['isDisabled'] ?? false,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  // Helpers specific to roles
  String? get department => metadata['department'];
  String? get rollNumber => metadata['rollNumber'];
  String? get degree => metadata['degree'];
  String? get semester => metadata['semester'];
  String? get section => metadata['section'];

  String get className {
    if (degree != null && semester != null) {
      return '$degree-$semester${section ?? ""}';
    }
    return 'N/A';
  }
}
