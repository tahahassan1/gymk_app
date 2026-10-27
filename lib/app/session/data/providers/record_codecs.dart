import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/time/date_only_codec.dart';
import '../../../../features/dropins/data/models/dropin.dart';
import '../../../../features/members/data/models/member.dart';
import '../../../../features/settings/data/models/gym_settings.dart';
import '../../../../features/subscriptions/data/models/subscription_record.dart';

/// Firestore serialization stays entirely inside the provider boundary.
abstract final class RecordCodecs {
  static Member member(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) throw _invalid('createdAt');
    return Member(
      id: id,
      name: _name(data, 'name'),
      phone: _optionalString(data, 'phone'),
      createdAt: createdAt.toDate().toUtc(),
    );
  }

  static Map<String, dynamic> memberData(Member member) => {
    'name': member.name,
    if (member.phone != null) 'phone': member.phone,
    'createdAt': Timestamp.fromDate(member.createdAt),
  };

  static GymSettings settings(Map<String, dynamic> data) => GymSettings(
    gymName: _name(data, 'gymName'),
    subscriptionPrice: _integer(data, 'defaultSubscriptionPrice'),
    dropinPrice: _integer(data, 'defaultDropinPrice'),
  );

  static Map<String, dynamic> settingsData(GymSettings settings) => {
    'gymName': settings.gymName,
    'defaultSubscriptionPrice': settings.subscriptionPrice,
    'defaultDropinPrice': settings.dropinPrice,
  };

  static SubscriptionRecord subscription(
    String id,
    Map<String, dynamic> data,
  ) => SubscriptionRecord(
    id: id,
    memberId: _string(data, 'memberId'),
    startDate: DateOnlyCodec.decode(data['startDate']),
    endDate: DateOnlyCodec.decode(data['endDate']),
    amount: _integer(data, 'amount'),
    paidAt: DateOnlyCodec.decode(data['paidAt']),
  );

  static Map<String, dynamic> subscriptionData(SubscriptionRecord record) => {
    'memberId': record.memberId,
    'startDate': DateOnlyCodec.encode(record.startDate),
    'endDate': DateOnlyCodec.encode(record.endDate),
    'amount': record.amount,
    'paidAt': DateOnlyCodec.encode(record.paidAt),
  };

  static Dropin dropin(String id, Map<String, dynamic> data) => Dropin(
    id: id,
    name: _optionalString(data, 'name'),
    amount: _integer(data, 'amount'),
    date: DateOnlyCodec.decode(data['date']),
  );

  static Map<String, dynamic> dropinData(Dropin record) => {
    if (record.name != null) 'name': record.name,
    'amount': record.amount,
    'date': DateOnlyCodec.encode(record.date),
  };

  static String _string(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) throw _invalid(key);
    return value;
  }

  static String? _optionalString(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key)) return null;
    final value = data[key];
    if (value is! String || value.isEmpty || value != value.trim()) {
      throw _invalid(key);
    }
    return value;
  }

  static String _name(Map<String, dynamic> data, String key) {
    final value = _string(data, key);
    if (value.isEmpty || value != value.trim()) throw _invalid(key);
    return value;
  }

  static int _integer(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! int) throw _invalid(key);
    return value;
  }

  static AppFailure _invalid(String key) =>
      AppFailure(FailureKind.validation, code: 'record-$key');
}
