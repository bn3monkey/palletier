import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cli_config.dart';
import '../services/cli_service.dart';

final cliServiceProvider = Provider<CliService>((ref) => CliService());

final cliConfigProvider =
    NotifierProvider<CliConfigNotifier, CliConfig>(CliConfigNotifier.new);

class CliConfigNotifier extends Notifier<CliConfig> {
  @override
  CliConfig build() {
    _loadSaved();
    return const CliConfig();
  }

  CliService get _service => ref.read(cliServiceProvider);

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final modelStr = prefs.getString('cli_model');
    final path = prefs.getString('cli_path');

    CliModel model = CliModel.claudeCode;
    if (modelStr != null) {
      model = CliModel.values.firstWhere(
        (m) => m.name == modelStr,
        orElse: () => CliModel.claudeCode,
      );
    }

    state = state.copyWith(model: model, executablePath: path);
    if (path != null) {
      _service.setPath(path);
      await _verifyAndUpdateStatus();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cli_model', state.model.name);
    if (state.executablePath != null) {
      await prefs.setString('cli_path', state.executablePath!);
    }
  }

  Future<void> _verifyAndUpdateStatus() async {
    final ok = await _service.verify();
    state = state.copyWith(
      status: ok ? CliStatus.connected : CliStatus.disconnected,
    );
  }

  void setModel(CliModel model) {
    state = state.copyWith(model: model);
    _save();
  }

  /// Returns true if detection succeeded.
  Future<bool> autoDetect() async {
    final path = await _service.detect(state.model);
    if (path != null) {
      _service.setPath(path);
      state = state.copyWith(executablePath: path);
      await _save();
      await _verifyAndUpdateStatus();
      return true;
    }
    return false;
  }

  void manualSetPath(String path) {
    _service.setPath(path);
    state = state.copyWith(
      executablePath: path,
      status: CliStatus.disconnected,
    );
    _save();
    _verifyAndUpdateStatus();
  }

  Future<void> login() async {
    final ok = await _service.login();
    if (ok) {
      state = state.copyWith(status: CliStatus.authenticated);
    }
  }
}
