import 'package:flutter/material.dart';

final class IdentityVerificationNotSubmittedCard
    extends StatelessWidget {
  const IdentityVerificationNotSubmittedCard({
    super.key,
    this.onStart,
  });

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 72,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่ได้ยืนยันตัวตน',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'เริ่มการยืนยันตัวตนเพื่อเข้าใช้งานฟีเจอร์ทั้งหมดของระบบและเพิ่มความน่าเชื่อถือให้บัญชีของคุณ',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const _StepItem(
              number: '1',
              text: 'เตรียมเอกสารยืนยันตัวตน',
            ),
            const SizedBox(height: 12),
            const _StepItem(
              number: '2',
              text: 'อัปโหลดเอกสารเข้าสู่ระบบ',
            ),
            const SizedBox(height: 12),
            const _StepItem(
              number: '3',
              text: 'รอการตรวจสอบจากเจ้าหน้าที่',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'เริ่มยืนยันตัวตน',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}