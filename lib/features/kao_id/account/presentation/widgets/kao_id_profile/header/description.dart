import 'package:flutter/material.dart';

final class ProfileDescription extends StatelessWidget {
  const ProfileDescription({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'คุณสามารถเปลี่ยนชื่อที่แสดงและรูปโปรไฟล์ของ Kao ID ได้ '
      'ข้อมูลนี้จะแสดงใน Marketplace และบริการต่าง ๆ ของ Kao Ecosystem',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}