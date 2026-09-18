import '../../models/identity_document_model.dart';
import '../../models/verification_model.dart';

abstract interface class IdentityRemoteDataSource {
  /// ดึงเอกสาร Identity ทั้งหมดของผู้ใช้ปัจจุบัน
  Future<List<IdentityDocumentModel>> getDocuments();

  /// ดึงเอกสาร Identity ตาม ID
  Future<IdentityDocumentModel?> getDocumentById(
    String documentId,
  );

  /// สร้างหรือบันทึกเอกสาร Identity
  ///
  /// ไฟล์ใน [document.files] จะถูกจัดการโดย
  /// Remote DataSource implementation
  /// และบันทึกลง `document_files`
  Future<IdentityDocumentModel> uploadDocument({
    required IdentityDocumentModel document,
  });

  /// อัปเดตเอกสาร Identity
  ///
  /// ข้อมูลหลักถูกบันทึกลง `identity_documents`
  /// และรายการไฟล์จะถูก sync กับ `document_files`
  Future<IdentityDocumentModel> updateDocument({
    required IdentityDocumentModel document,
  });

  /// ลบเอกสาร Identity
  ///
  /// `document_files` จะถูกลบตาม foreign key
  /// ของ `identity_documents`
  Future<void> deleteDocument(
    String documentId,
  );

  /// ส่งคำขอตรวจสอบ Identity
  Future<VerificationModel> submitVerification();

  /// ดึงคำขอตรวจสอบล่าสุด
  Future<VerificationModel?> getVerification();

  /// ตรวจสอบสถานะการยืนยันล่าสุด
  Future<VerificationModel?> refreshVerification();

  /// ยกเลิกคำขอตรวจสอบ
  Future<void> cancelVerification();

  /// ตรวจสอบว่าผู้ใช้มีเอกสารที่จำเป็นแล้วหรือไม่
  Future<bool> hasCompletedRequiredDocuments();
}