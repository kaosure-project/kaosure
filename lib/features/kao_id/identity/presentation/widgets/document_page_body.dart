import 'package:flutter/material.dart';

final class DocumentPageBody extends StatelessWidget {
  const DocumentPageBody({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}