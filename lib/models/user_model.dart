class User {
  final String id;
  final String email;
  final String username;
  final String m3uUrl;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.m3uUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      m3uUrl: json['m3u_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'm3u_url': m3uUrl,
    };
  }
}