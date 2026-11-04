class AccountItem {
  const AccountItem({
    required this.id,
    required this.serviceName,
    required this.login,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
    this.email = '',
    this.website = '',
    this.note = '',
    this.tintHue,
  });

  final String id;
  final String serviceName;
  final String login;
  final String password;
  final String email;
  final String website;
  final String note;

  /// Оттенок карточки, 0–359 по цветовому кругу. Пусто — бумага без краски.
  final int? tintHue;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountItem copyWith({
    String? serviceName,
    String? login,
    String? password,
    String? email,
    String? website,
    String? note,
    int? tintHue,
    bool clearTintHue = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountItem(
      id: id,
      serviceName: serviceName ?? this.serviceName,
      login: login ?? this.login,
      password: password ?? this.password,
      email: email ?? this.email,
      website: website ?? this.website,
      note: note ?? this.note,
      tintHue: clearTintHue ? null : tintHue ?? this.tintHue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'login': login,
      'password': password,
      'email': email,
      'website': website,
      'note': note,
      if (tintHue != null) 'tintHue': tintHue,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory AccountItem.fromJson(Map<String, Object?> json) {
    return AccountItem(
      id: json['id'] as String,
      serviceName: json['serviceName'] as String,
      login: json['login'] as String,
      password: json['password'] as String,
      email: json['email'] as String? ?? '',
      website: json['website'] as String? ?? '',
      note: json['note'] as String? ?? '',
      tintHue: json['tintHue'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }
}
