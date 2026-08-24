import 'package:ez_domain/ez_domain.dart';

/// Аккаунт по набранному в редакторе.
///
/// Пароль сохраняется как есть: пробелы в нём значимы. Остальные поля
/// подрезаются — лишний пробел в названии сервиса или в адресе только мешает
/// поиску.
AccountItem accountFromForm({
  required AccountItem? existing,
  required String serviceName,
  required String login,
  required String password,
  required String email,
  required String website,
  required String note,
  required DateTime now,
}) {
  if (existing != null) {
    return existing.copyWith(
      serviceName: serviceName.trim(),
      login: login.trim(),
      password: password,
      email: email.trim(),
      website: website.trim(),
      note: note.trim(),
      updatedAt: now,
    );
  }
  return AccountItem(
    id: now.microsecondsSinceEpoch.toString(),
    serviceName: serviceName.trim(),
    login: login.trim(),
    password: password,
    email: email.trim(),
    website: website.trim(),
    note: note.trim(),
    createdAt: now,
    updatedAt: now,
  );
}
