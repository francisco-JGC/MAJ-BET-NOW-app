import 'package:equatable/equatable.dart';

enum LuckyKind {
  cross('cross'),
  pyramid('pyramid');

  const LuckyKind(this.apiKey);

  final String apiKey;

  static LuckyKind fromApiKey(String value) {
    for (final k in LuckyKind.values) {
      if (k.apiKey == value) return k;
    }
    throw ArgumentError('Unknown LuckyKind api key: $value');
  }
}

class CrossCorners extends Equatable {
  const CrossCorners({
    required this.tl,
    required this.tr,
    required this.bl,
    required this.br,
  });

  final int tl;
  final int tr;
  final int bl;
  final int br;

  @override
  List<Object?> get props => [tl, tr, bl, br];
}

class CrossInner extends Equatable {
  const CrossInner({
    required this.n,
    required this.e,
    required this.s,
    required this.w,
  });

  final int n;
  final int e;
  final int s;
  final int w;

  @override
  List<Object?> get props => [n, e, s, w];
}

sealed class LuckyPayload extends Equatable {
  const LuckyPayload();
}

class CrossLuckyPayload extends LuckyPayload {
  const CrossLuckyPayload({
    required this.corners,
    required this.inner,
    required this.recommended,
  });

  final CrossCorners corners;
  final CrossInner inner;
  final List<String> recommended;

  @override
  List<Object?> get props => [corners, inner, recommended];
}

class PyramidLuckyPayload extends LuckyPayload {
  const PyramidLuckyPayload({
    required this.rows,
    required this.recommended,
  });

  final List<List<int>> rows;
  final List<String> recommended;

  @override
  List<Object?> get props => [rows, recommended];
}

class LuckyDaily extends Equatable {
  const LuckyDaily({
    required this.id,
    required this.kind,
    required this.forDate,
    required this.payload,
  });

  final String id;
  final LuckyKind kind;
  final DateTime forDate;
  final LuckyPayload payload;

  @override
  List<Object?> get props => [id, kind, forDate, payload];
}
