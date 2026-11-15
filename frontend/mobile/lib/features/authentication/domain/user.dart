/// The `user` shape from docs/api-contract.md. Email cannot change after registering.
class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;

  /// "AL" for the header avatar.
  String get initials {
    String first(String s) => s.trim().isEmpty ? '' : s.trim()[0].toUpperCase();
    return '${first(firstName)}${first(lastName)}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
  );
}

/// Successful POST /auth/login: the 24-hour JWT plus the user.
class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token'] as String,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );
}
