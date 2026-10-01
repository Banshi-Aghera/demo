import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';

part 'group_deal.freezed.dart';
part 'group_deal.g.dart';

@freezed
abstract class GroupDeal with _$GroupDeal {
  const GroupDeal._();

  const factory GroupDeal({
    required String id,
    required String societyId,
    required String initiatorId,
    required String productId,
    required int requiredParticipants,
    @Default([]) List<String> participantIds,
    @Default('active') String status, // 'active', 'successful', 'expired'
    @TimestampConverter() required DateTime expiresAt,
    @TimestampConverter() required DateTime createdAt,
  }) = _GroupDeal;

  factory GroupDeal.fromJson(Map<String, dynamic> json) =>
      _$GroupDealFromJson(json);

  bool get isSuccessful => status == 'successful';
  bool get isExpired => status == 'expired' || expiresAt.isBefore(DateTime.now());
  
  double get progress => (participantIds.length / requiredParticipants).clamp(0.0, 1.0);
}
