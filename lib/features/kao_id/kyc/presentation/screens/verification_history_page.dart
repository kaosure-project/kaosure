import 'package:flutter/material.dart';

final class VerificationHistoryPage extends StatelessWidget {
  const VerificationHistoryPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ประวัติการยืนยันตัวตน',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Icon(
              Icons.history,
              size: 72,
              color: Colors.blueGrey,
            ),

            const SizedBox(height: 24),

            Text(
              'ประวัติการยืนยันตัวตน',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Text(
                'หน้านี้ใช้แสดงประวัติการยืนยันตัวตนทั้งหมดของบัญชี Kao ID เช่น การส่งเอกสาร การอนุมัติ การปฏิเสธ และการอัปเดตข้อมูล',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),
            ),

            const SizedBox(height: 32),

            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                    ),
                    title: Text(
                      'ยังไม่มีประวัติ',
                    ),
                    subtitle: Text(
                      'เมื่อมีการยืนยันตัวตน ระบบจะแสดงรายการที่นี่',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}