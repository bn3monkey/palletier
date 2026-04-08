enum CliModel {
  geminiCli,
  claudeCode;

  String get displayName {
    switch (this) {
      case CliModel.geminiCli:
        return 'Gemini CLI';
      case CliModel.claudeCode:
        return 'Claude Code';
    }
  }

  String get executableName {
    switch (this) {
      case CliModel.geminiCli:
        return 'gemini';
      case CliModel.claudeCode:
        return 'claude';
    }
  }
}

enum CliStatus {
  disconnected,
  connected,
  authenticated;

  String get displayName {
    switch (this) {
      case CliStatus.disconnected:
        return 'Disconnected';
      case CliStatus.connected:
        return 'Connected';
      case CliStatus.authenticated:
        return 'Authenticated';
    }
  }
}

class CliConfig {
  final CliModel model;
  final String? executablePath;
  final CliStatus status;

  const CliConfig({
    this.model = CliModel.claudeCode,
    this.executablePath,
    this.status = CliStatus.disconnected,
  });

  CliConfig copyWith({
    CliModel? model,
    String? executablePath,
    CliStatus? status,
  }) {
    return CliConfig(
      model: model ?? this.model,
      executablePath: executablePath ?? this.executablePath,
      status: status ?? this.status,
    );
  }
}
