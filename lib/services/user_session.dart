class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? name;
  String? email;

  bool get isLoggedIn => name != null && email != null && name!.isNotEmpty;

  void login(String userName, String userEmail) {
    name = userName;
    email = userEmail;
  }

  void logout() {
    name = null;
    email = null;
  }
}