import '../../../../core/data/model_validation.dart';

final class Member {
  Member({
    required String id,
    required String name,
    String? phone,
    required this.createdAt,
  }) : id = documentId(id),
       name = requiredName(name),
       phone = optionalText(phone);

  final String id;
  final String name;
  final String? phone;
  final DateTime createdAt;

  Member edit({required String name, String? phone}) =>
      Member(id: id, name: name, phone: phone, createdAt: createdAt);
}
