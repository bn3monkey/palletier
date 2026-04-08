import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../models/color_palette.dart';
import '../services/cli_service.dart';
import '../services/palette_parser.dart';
import 'cli_provider.dart';
import 'palette_provider.dart';

final chatLoadingProvider =
    NotifierProvider<ChatLoadingNotifier, bool>(ChatLoadingNotifier.new);

class ChatLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final chatProvider =
    NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  final _parser = PaletteParser();

  @override
  List<ChatMessage> build() => [];

  CliService get _cliService => ref.read(cliServiceProvider);

  Future<void> send(String text, int colorCount) async {
    ref.read(chatLoadingProvider.notifier).set(true);

    // Add user message
    state = [
      ...state,
      ChatMessage(
        role: MessageRole.user,
        content: text,
        timestamp: DateTime.now(),
      ),
    ];

    // Build prompt
    final prompt = _buildPrompt(text, colorCount);

    // Add empty assistant message for streaming
    final assistantMsg = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
    );
    state = [...state, assistantMsg];
    final assistantIndex = state.length - 1;

    // Run CLI and stream output
    final buffer = StringBuffer();
    try {
      await for (final chunk in _cliService.runPrompt(prompt)) {
        buffer.write(chunk);
        final updated = state[assistantIndex].copyWith(
          content: buffer.toString(),
        );
        state = [
          ...state.sublist(0, assistantIndex),
          updated,
        ];
      }
    } catch (e) {
      final updated = state[assistantIndex].copyWith(
        content: '${buffer.toString()}\n\n[Error: $e]',
      );
      state = [
        ...state.sublist(0, assistantIndex),
        updated,
      ];
    }

    ref.read(chatLoadingProvider.notifier).set(false);

    // Try to parse palette from the final response
    final fullResponse = buffer.toString();
    final palette = _parser.parse(fullResponse);
    if (palette != null) {
      ref.read(paletteProvider.notifier).addPalette(palette);

      // Replace the raw assistant message with just the description
      final descriptionContent = _buildDisplayContent(palette);
      final updated = state[assistantIndex].copyWith(
        content: descriptionContent,
      );
      state = [
        ...state.sublist(0, assistantIndex),
        updated,
      ];
    }
  }

  String _buildDisplayContent(ColorPalette palette) {
    final sb = StringBuffer();
    sb.writeln(palette.description);
    sb.writeln();
    for (final c in palette.colors) {
      sb.writeln('- **${c.name}** (${c.hex}): ${c.description}');
    }
    return sb.toString();
  }

  String _buildPrompt(String userInput, int colorCount) {
    return '당신은 색상 팔레트 추천 전문가입니다. '
        '사용자가 원하는 느낌을 설명하면, $colorCount개의 색상으로 구성된 팔레트를 추천해주세요. '
        '반드시 아래 JSON 형식으로 응답하세요: '
        '```json\n'
        '{"description": "팔레트 전체에 대한 설명 (한국어, 2-3문장)", '
        '"colors": [{"name": "영문 색상 이름", "hex": "#RRGGBB", '
        '"r": 0, "g": 0, "b": 0, '
        '"description": "이 색상을 선택한 이유 (한국어, 1문장)"}]}\n'
        '```\n'
        'JSON 블록 앞뒤에 추가 설명을 자유롭게 작성해도 됩니다.\n\n'
        '사용자 요청: $userInput';
  }
}
