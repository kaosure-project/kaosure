import 'package:equatable/equatable.dart';

/// Value Object สำหรับหมายเลขเอกสาร
///
/// ทำหน้าที่เก็บค่าเท่านั้น
/// ไม่ตรวจสอบประเภทเอกสาร
/// ไม่ตรวจสอบกฎของแต่ละประเทศ
final class DocumentNumber extends Equatable {
  const DocumentNumber(this. value) ;

  /// หมายเลขเอกสาร
  final String value;

  /// ค่าว่างหรือไม่
  bool get isEmpty => value.isEmpty;

  /// มีค่าหรือไม่
  bool get isNotEmpty => value.isNotEmpty;

  /// ความยาวของหมายเลขเอกสาร
  int get length => value.length;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}