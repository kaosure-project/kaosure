import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/pudtan_chat_controller.dart';

class PudtanChatScreen extends ConsumerStatefulWidget {
  const PudtanChatScreen({super.key});

  @override
  ConsumerState<PudtanChatScreen> createState() =>
      _PudtanChatScreenState();
}

class _PudtanChatScreenState
    extends ConsumerState<PudtanChatScreen> {
  final TextEditingController _textController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    _textController.clear();

    await ref
        .read(pudtanChatControllerProvider.notifier)
        .sendMessage(text);

    if (!mounted) {
      return;
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState =
        ref.watch(pudtanChatControllerProvider);

    ref.listen<PudtanChatState>(
      pudtanChatControllerProvider,
      (previous, next) {
        final previousCount =
            previous?.messages.length ?? 0;

        if (next.messages.length > previousCount) {
          _scrollToBottom();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('พุดตาน'),
            Text(
              'Organizational Intelligence',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ล้างบทสนทนา',
            onPressed: chatState.isLoading
                ? null
                : () {
                    ref
                        .read(
                          pudtanChatControllerProvider
                              .notifier,
                        )
                        .clearConversation();
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? const _PudtanEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message =
                          chatState.messages[index];

                      return _MessageBubble(
                        message: message,
                      );
                    },
                  ),
          ),
          if (chatState.isLoading)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('พุดตานกำลังคิด...'),
                  ],
                ),
              ),
            ),
          if (chatState.error != null)
            _ErrorBanner(
              message: chatState.error!,
            ),
          _InputBar(
            controller: _textController,
            enabled: !chatState.isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _PudtanEmptyState extends StatelessWidget {
  const _PudtanEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'สวัสดีค่ะ ฉันพุดตาน',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'ฉันช่วยวิเคราะห์ความรู้และสถานะขององค์กร '
              'จากข้อมูลที่มีอยู่ใน KaoSure Brain ได้ค่ะ',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
  });

  final PudtanChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme
                  .colorScheme
                  .surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'เชื่อมต่อพุดตานไม่สำเร็จ\n$message',
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'พิมพ์คุยกับพุดตาน...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
              tooltip: 'ส่ง',
            ),
          ],
        ),
      ),
    );
  }
}