import '../../domain/entities/draw_schedule.dart';

class DrawScheduleModel extends DrawSchedule {
  const DrawScheduleModel({
    required super.id,
    required super.gameId,
    required super.dayOfWeek,
    required super.drawTime,
    required super.cutoffMinutes,
    required super.isActive,
  });

  factory DrawScheduleModel.fromJson(Map<String, dynamic> json) {
    return DrawScheduleModel(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
      drawTime: json['drawTime'] as String,
      cutoffMinutes: (json['cutoffMinutes'] as num).toInt(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
