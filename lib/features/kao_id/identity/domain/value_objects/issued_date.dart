import 'package:equatable/equatable.dart';

/// Value Object สำหรับวันที่ออกเอกสาร
///
/// ทำหน้าที่เก็บค่าและให้ข้อมูลพื้นฐานเท่านั้น
/// ไม่ตรวจสอบกฎทางธุรกิจ
final class IssuedDate extends Equatable {
  const IssuedDate(this.value);

  /// วันที่ออกเอกสาร
  final DateTime value;

  /// ออกเอกสารในอนาคตหรือไม่
  bool get isFuture => value.isAfter(DateTime.now());

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value.toIso8601String();
}