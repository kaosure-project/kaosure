/// Domain Service สำหรับจัดการวันหมดอายุของเอกสาร
final class DocumentExpiryService {
  const DocumentExpiryService();

  /// เอกสารหมดอายุแล้วหรือไม่
  bool isExpired(DateTime expiryDate, {DateTime? now}) {
    final current = now ?? DateTime.now();

    return expiryDate.isBefore(
      DateTime(
        current.year,
        current.month,
        current.day,
      ),
    );
  }

  /// จำนวนวันที่เหลือก่อนหมดอายุ
  ///
  /// ถ้าติดลบ แสดงว่าหมดอายุแล้ว
  int remainingDays(DateTime expiryDate, {DateTime? now}) {
    final current = now ?? DateTime.now();

    final today = DateTime(
      current.year,
      current.month,
      current.day,
    );

    final target = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    return target.difference(today).inDays;
  }

  /// ต้องแจ้งเตือนหรือไม่
  bool shouldNotify({
    required DateTime expiryDate,
    int beforeDays = 30,
    DateTime? now,
  }) {
    final days = remainingDays(expiryDate, now: now);

    return days >= 0 && days <= beforeDays;
  }

  /// สามารถต่ออายุได้หรือไม่
  bool canRenew(DateTime expiryDate, {DateTime? now}) {
    final days = remainingDays(expiryDate, now: now);

    return days <= 30;
  }
}