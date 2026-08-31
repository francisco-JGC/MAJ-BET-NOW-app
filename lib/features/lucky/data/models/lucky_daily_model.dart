import '../../domain/entities/lucky_daily.dart';

class LuckyDailyModel extends LuckyDaily {
  const LuckyDailyModel({
    required super.id,
    required super.kind,
    required super.forDate,
    required super.payload,
  });

  factory LuckyDailyModel.fromJson(Map<String, dynamic> json) {
    final kind = LuckyKind.fromApiKey(json['kind'] as String);
    final forDate = DateTime.parse(json['forDate'] as String);
    final rawPayload = json['payload'] as Map<String, dynamic>;
    final payload = switch (kind) {
      LuckyKind.cross => _parseCross(rawPayload),
      LuckyKind.pyramid => _parsePyramid(rawPayload),
    };
    return LuckyDailyModel(
      id: json['id'] as String,
      kind: kind,
      forDate: forDate,
      payload: payload,
    );
  }

  static CrossLuckyPayload _parseCross(Map<String, dynamic> raw) {
    final corners = raw['corners'] as Map<String, dynamic>;
    final inner = raw['inner'] as Map<String, dynamic>;
    final rec = (raw['recommended'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
    return CrossLuckyPayload(
      corners: CrossCorners(
        tl: (corners['tl'] as num).toInt(),
        tr: (corners['tr'] as num).toInt(),
        bl: (corners['bl'] as num).toInt(),
        br: (corners['br'] as num).toInt(),
      ),
      inner: CrossInner(
        n: (inner['n'] as num).toInt(),
        e: (inner['e'] as num).toInt(),
        s: (inner['s'] as num).toInt(),
        w: (inner['w'] as num).toInt(),
      ),
      recommended: rec,
    );
  }

  static PyramidLuckyPayload _parsePyramid(Map<String, dynamic> raw) {
    final rows = (raw['rows'] as List<dynamic>)
        .map((row) => (row as List<dynamic>)
            .map((n) => (n as num).toInt())
            .toList())
        .toList();
    final rec = (raw['recommended'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
    return PyramidLuckyPayload(rows: rows, recommended: rec);
  }
}
