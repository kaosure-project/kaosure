import 'package:equatable/equatable.dart';

/// Value Object สำหรับวันหมดอายุของเอกสาร
///
/// ทำหน้าที่เก็บค่าวันหมดอายุเท่านั้น
/// ไม่รับผิดชอบ Business Rules เช่น การแจ้งเตือนหรือการต่ออายุ
final class ExpiryDate extends Equatable {
  const ExpiryDate(this.value);

  /// วันหมดอายุของเอกสาร
  final DateTime value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value.toIso8601String();

  /// เอกสารไม่มีวันหมดอายุหรือไม่
  bool get isPermanent => false;
}