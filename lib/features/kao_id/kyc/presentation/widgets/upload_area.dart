import 'package:flutter/material.dart';

final class UploadArea extends StatelessWidget {
  const UploadArea({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.cloud_upload_outlined,
    this.title = 'อัปโหลดเอกสาร',
    this.description = 'แตะเพื่อเลือกไฟล์จากเครื่อง',
    this.buttonText = 'เลือกไฟล์',
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.showGuidelines = true,
  });

  final VoidCallback onPressed;

  final bool isLoading;

  final IconData icon;

  final String title;

  final String description;

  final String buttonText;

  final Color? backgroundColor;

  final Color? borderColor;

  final Color? iconColor;

  final bool showGuidelines;

  @override
  Widget build(BuildContext context) {
    final Color bg =
        backgroundColor ?? Colors.blue.shade50;

    final Color border =
        borderColor ?? Colors.blue.shade300;

    final Color iconClr =
        iconColor ?? Colors.blue.shade700;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: isLoading ? null : onPressed,
        child: Ink(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: border,
              width: 1.5,
            ),
            color: bg,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 72,
                color: iconClr,
              ),

              const SizedBox(height: 20),

              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),

              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed:
                    isLoading ? null : onPressed,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.upload_file,
                      ),
                label: Text(
                  isLoading
                      ? 'กำลังดำเนินการ...'
                      : buttonText,
                ),
              ),

              if (!showGuidelines)
                const SizedBox(height: 8),

              if (showGuidelines) ...[
                const SizedBox(height: 24),

                const Divider(),

                const SizedBox(height: 16),

                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'รองรับ JPG, PNG และ PDF',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ขนาดไฟล์ไม่เกิน 10 MB',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                const Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ไฟล์ถูกเข้ารหัสและจัดเก็บอย่างปลอดภัย',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}