class UserModel {
  final String phoneNumber;
  final String name;
  final String profileEmoji;
  final DateTime joinedDate;

  UserModel({
    required this.phoneNumber,
    required this.name,
    this.profileEmoji = '👤',
    DateTime? joinedDate,
  }) : joinedDate = joinedDate ?? DateTime.now();

  UserModel copyWith({
    String? name,
    String? profileEmoji,
  }) {
    return UserModel(
      phoneNumber: phoneNumber,
      name: name ?? this.name,
      profileEmoji: profileEmoji ?? this.profileEmoji,
      joinedDate: joinedDate,
    );
  }

  Map<String, String> toJson() => {
    'phoneNumber': phoneNumber,
    'name': name,
    'profileEmoji': profileEmoji,
    'joinedDate': joinedDate.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    phoneNumber: json['phoneNumber'] ?? '',
    name: json['name'] ?? 'Guest User',
    profileEmoji: json['profileEmoji'] ?? '👤',
    joinedDate: DateTime.parse(json['joinedDate'] ?? DateTime.now().toIso8601String()),
  );
}
