/// Business timezone helpers, mirroring the backend's `BUSINESS_TZ`.
///
/// Operators live in Central American CST (Nicaragua, Honduras, El Salvador,
/// Costa Rica) — all fixed UTC-6, no DST. Every schedule ("11:00") is
/// interpreted as wall-clock time in this zone.
///
/// Building DateTimes with `DateTime(y, m, d, h, m)` uses the DEVICE's local
/// timezone, which is a footgun if the device is in a different zone (dev
/// simulators default to UTC, travellers, etc.). These helpers always anchor
/// to the business zone regardless of device settings.
library;

class BusinessTime {
  BusinessTime._();

  /// Named zone kept in sync with the backend (`shared/domain/business-time.ts`).
  static const timeZoneName = 'America/Managua';

  /// Fixed offset from UTC. Managua/Tegucigalpa/San José/San Salvador do not
  /// observe DST, so a constant offset is safe.
  static const _hoursFromUtc = -6;

  /// Current instant expressed as a UTC DateTime whose *components*
  /// (year/month/day/hour/minute) match the business-zone wall clock. Useful
  /// for reading "what day/hour is it right now in Managua" without device-TZ
  /// distortion. Never use `.toLocal()` on the result — the offset would be
  /// applied twice.
  static DateTime nowInBusinessTz() {
    return DateTime.now().toUtc().add(const Duration(hours: _hoursFromUtc));
  }

  /// Absolute UTC instant whose Managua wall clock equals the passed
  /// components. Send this over the wire as the ticket's `drawAt`.
  static DateTime toUtc({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) {
    // Managua = UTC-6, so UTC hour = local hour + 6.
    return DateTime.utc(year, month, day, hour - _hoursFromUtc, minute);
  }

  /// Formats a DateTime whose y/m/d/h/m/s components are intended as Managua
  /// wall-clock time into an ISO 8601 string with an explicit `-06:00` offset.
  /// Use this for query params like `from`/`to` when the DateTime came from a
  /// date picker or `DateTime.now()` — device TZ is ignored, only the numeric
  /// components matter. Mirrors what the web client sends.
  static String toBusinessIso(DateTime dt) {
    String pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');
    return '${pad(dt.year, 4)}-${pad(dt.month)}-${pad(dt.day)}'
        'T${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}-06:00';
  }
}
