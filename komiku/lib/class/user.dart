class UserModel {
  int id;
  String name;
  String username;
  String email;
  String? avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'].toString(),
      username: json['username'].toString(),
      email: json['email'].toString(),
      avatar: json['avatar']?.toString(),
    );
  }
}
