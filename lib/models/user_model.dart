class UserModel {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,

      firstName: json['first_name']?.toString() ?? "",

      lastName: json['last_name']?.toString() ?? "",

      email: json['user_email']?.toString() ?? "",
    );
  }
}