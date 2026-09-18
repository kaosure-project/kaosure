import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/pudtan_remote_datasource.dart';
import '../data/models/pudtan_response.dart';

class PudtanChatMessage {
  const PudtanChatMessage({
    required this.text,
    required this.isUser,
    this.response,
  });

  final String text;
  final bool isUser;
  final PudtanResponse? response;
}

class PudtanChatState {
  const PudtanChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  final List<PudtanChatMessage> messages;
  final bool isLoading;
  final String? error;

  PudtanChatState copyWith({
    List<PudtanChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PudtanChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final pudtanRemoteDataSourceProvider =
    Provider<PudtanRemoteDataSource>((ref) {
  return PudtanRemoteDataSource();
});

final pudtanChatControllerProvider =
    NotifierProvider<PudtanChatController, PudtanChatState>(
  PudtanChatController.new,
);

class PudtanChatController
    extends Notifier<PudtanChatState> {
  static const String projectId =
      '3f2728d5-8d95-44a5-ae50-0b00cad439fa';

  @override
  PudtanChatState build() {
    return const PudtanChatState();
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();

    if (query.isEmpty || state.isLoading) {
      return;
    }

    final userMessage = PudtanChatMessage(
      text: query,
      isUser: true,
    );

    state = state.copyWith(
      messages: [
        ...state.messages,
        userMessage,
      ],
      isLoading: true,
      clearError: true,
    );

    try {
      final response =
          await ref
              .read(pudtanRemoteDataSourceProvider)
              .ask(
                projectId: projectId,
                query: query,
                limit: 10,
              );

      final pudtanMessage = PudtanChatMessage(
        text: response.answer,
        isUser: false,
        response: response,
      );

      state = state.copyWith(
        messages: [
          ...state.messages,
          pudtanMessage,
        ],
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  void clearConversation() {
    state = const PudtanChatState();
  }
}