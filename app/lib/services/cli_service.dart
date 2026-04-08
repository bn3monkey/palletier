import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/cli_config.dart';

class CliService {
  String? _executablePath;

  String? get executablePath => _executablePath;

  /// Auto-detect CLI executable path using `where` (Windows) or `which` (Unix).
  Future<String?> detect(CliModel model) async {
    final command = Platform.isWindows ? 'where' : 'which';
    try {
      final result = await Process.run(command, [model.executableName]);
      if (result.exitCode == 0) {
        final path =
            (result.stdout as String).trim().split('\n').first.trim();
        if (path.isNotEmpty) return path;
      }
    } catch (_) {}
    return null;
  }

  void setPath(String path) {
    _executablePath = path;
  }

  /// Check if the CLI executable exists and is runnable.
  Future<bool> verify() async {
    final path = _executablePath;
    if (path == null || path.isEmpty) return false;
    try {
      final result = await Process.run(path, ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Run a single prompt via `claude -p "prompt"` and stream stdout chunks.
  /// Yields partial output as it arrives.
  Stream<String> runPrompt(String prompt) async* {
    final path = _executablePath;
    if (path == null || path.isEmpty) {
      throw StateError('CLI executable path is not set');
    }

    // claude -p "prompt" --output-format text
    final process = await Process.start(
      path,
      ['-p', prompt, '--output-format', 'text'],
    );

    // Stream stdout
    await for (final chunk in process.stdout.transform(utf8.decoder)) {
      yield chunk;
    }

    // Also capture stderr at the end
    final stderr = await process.stderr.transform(utf8.decoder).join();
    if (stderr.isNotEmpty) {
      yield '\n[stderr] $stderr';
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      yield '\n[Process exited with code $exitCode]';
    }
  }

  /// Login / authenticate by running the CLI auth login command.
  Future<bool> login() async {
    final path = _executablePath;
    if (path == null || path.isEmpty) return false;

    final result = await Process.run(path, ['auth', 'login']);
    return result.exitCode == 0;
  }
}
