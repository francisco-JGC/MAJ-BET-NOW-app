enum UserRole {
  admin,
  seller;

  static UserRole fromKey(String key) {
    return UserRole.values.firstWhere(
      (r) => r.name == key,
      orElse: () => UserRole.seller,
    );
  }
}
