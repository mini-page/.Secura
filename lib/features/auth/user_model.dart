class UserModel {
  final String email;
  final String name;
  final String profileEmoji;
  final DateTime joinedDate;
  final String? securityQuestion;
  final String? securityAnswerHash;

  UserModel({
    required this.email,
    required this.name,
    this.profileEmoji = '👤',
    DateTime? joinedDate,
    this.securityQuestion,
    this.securityAnswerHash,
  }) : joinedDate = joinedDate ?? DateTime.now();

  UserModel copyWith({
    String? name,
    String? profileEmoji,
    String? securityQuestion,
    String? securityAnswerHash,
  }) {
    return UserModel(
      email: email,
      name: name ?? this.name,
      profileEmoji: profileEmoji ?? this.profileEmoji,
      joinedDate: joinedDate,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'name': name,
    'profileEmoji': profileEmoji,
    'joinedDate': joinedDate.toIso8601String(),
    'securityQuestion': securityQuestion,
    'securityAnswerHash': securityAnswerHash,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    email: json['email'] ?? '',
    name: json['name'] ?? 'Guest User',
    profileEmoji: json['profileEmoji'] ?? '👤',
    joinedDate: DateTime.parse(json['joinedDate'] ?? DateTime.now().toIso8601String()),
    securityQuestion: json['securityQuestion'],
    securityAnswerHash: json['securityAnswerHash'],
  );
}
