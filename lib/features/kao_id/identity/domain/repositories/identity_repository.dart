import '../entities/identity_document.dart';

/// Repository Contract สำหรับ Identity
///
/// Domain Layer จะรู้จักเฉพาะ Interface นี้
/// ส่วนการเชื่อมต่อ Supabase จะอยู่ใน Data Layer
abstract interface class IdentityRepository {
  /// ดึงเอกสารทั้งหมดของผู้ใช้
  Future<List<IdentityDocument>> getDocuments({
    required String userId,
  });

  /// ดึงเอกสารตามรหัสเอกสาร
  Future<IdentityDocument?> getDocumentById({
    required String documentId,
  });

  /// สร้างเอกสารใหม่
  Future<void> createDocument(
    IdentityDocument document,
  );

  /// อัปเดตข้อมูลเอกสาร
  Future<void> updateDocument(
    IdentityDocument document,
  );

  /// ลบเอกสาร
  Future<void> deleteDocument({
    required String documentId,
  });

  /// ส่งเอกสารเข้าสู่กระบวนการตรวจสอบ
  Future<void> submitVerification({
    required String documentId,
  });

  /// ต่ออายุเอกสาร
  Future<void> renewDocument({
    required String documentId,
  });
}