import 'package:flutter/material.dart';

import 'info_tile.dart';

final class DocumentInfoCard extends StatelessWidget {
  const DocumentInfoCard({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.uploadDate,
    this.onChange,
  });

  final String fileName;
  final String fileSize;
  final String uploadDate;

  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          InfoTile(
            icon: Icons.description_outlined,
            title: 'ชื่อไฟล์',
            value: fileName,
          ),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          InfoTile(
            icon: Icons.storage_outlined,
            title: 'ขนาดไฟล์',
            value: fileSize,
          ),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          InfoTile(
            icon: Icons.schedule_outlined,
            title: 'อัปโหลดเมื่อ',
            value: uploadDate,
          ),

          if (onChange != null) ...[
            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onChange,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    'เปลี่ยนไฟล์',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}