import 'package:flutter/material.dart';

final class SelectedFileCard extends StatelessWidget {
  const SelectedFileCard({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.onChangeFile,
  });

  final String fileName;
  final String fileSize;
  final VoidCallback onChangeFile;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 42,
              color: Colors.blue,
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w600,
                        ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    fileSize,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: Colors.grey,
                        ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: onChangeFile,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'เลือกไฟล์ใหม่',
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