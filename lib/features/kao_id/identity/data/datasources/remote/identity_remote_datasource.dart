import '../../models/identity_document_model.dart';

/// Remote Data Source สำหรับเชื่อมต่อ Supabase
///
/// ทำหน้าที่รับส่งข้อมูลกับ Backend เท่านั้น
/// ไม่มี Business Logic
abstract interface class IdentityRemoteDataSource {
  /// ดึงเอกสารทั้งหมดของผู้ใช้
  Future<List<IdentityDocumentModel>> getDocuments({
    required String userId,
  });

  /// ดึงเอกสารตามรหัส
  Future<IdentityDocumentModel?> getDocumentById({
    required String documentId,
  });

  /// สร้างเอกสารใหม่
  Future<void> createDocument(
    IdentityDocumentModel document,
  );

  /// อัปเดตเอกสาร
  Future<void> updateDocument(
    IdentityDocumentModel document,
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