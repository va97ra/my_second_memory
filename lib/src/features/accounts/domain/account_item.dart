class AccountItem {
  const AccountItem({
    required this.id,
    required this.serviceName,
    required this.login,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
    this.website = '',
    this.note = '',
  });

  final String id;
  final String serviceName;
  final String login;
  final String password;
  final String website;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountItem copyWith({
    String? serviceName,
    String? login,
    String? password,
    String? website,
    String? note,
    DateTime? updatedAt,
  }) {
    return AccountItem(
      id: id,
      serviceName: serviceName ?? this.serviceName,
      login: login ?? this.login,
      password: password ?? this.password,
      website: website ?? this.website,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'login': login,
      'password': password,
      'website': website,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AccountItem.fromJson(Map<String, Object?> json) {
    return AccountItem(
      id: json['id'] as String,
      serviceName: json['serviceName'] as String,
      login: json['login'] as String,
      password: json['password'] as String,
      website: json['website'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
