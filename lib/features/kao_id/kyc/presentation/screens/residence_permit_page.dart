import 'package:flutter/material.dart';

final class ResidencePermitPage extends StatelessWidget {
  const ResidencePermitPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ใบพำนัก',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.badge_outlined,
              size: 72,
              color: Colors.teal,
            ),

            const SizedBox(height: 24),

            Text(
              'ใบพำนัก',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            Text(
              'ใช้สำหรับยืนยันสิทธิ์การพำนัก และรองรับการตรวจสอบผ่านระบบ KYC ของ Kao ID',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),

            const SizedBox(height: 32),

            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.info_outline,
                ),
                title: Text(
                  'สถานะ',
                ),
                subtitle: Text(
                  'ยังไม่ได้เพิ่มใบพำนัก',
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.event_outlined,
                ),
                title: Text(
                  'วันหมดอายุ',
                ),
                subtitle: Text(
                  '-',
                ),
              ),
            ),

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: () {
                // TODO:
                // Upload Residence Permit
              },
              icon: const Icon(
                Icons.upload_file,
              ),
              label: const Text(
                'อัปโหลดใบพำนัก',
              ),
            ),
          ],
        ),
      ),
    );
  }
}