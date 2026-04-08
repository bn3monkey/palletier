import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cli_config.dart';
import '../providers/cli_provider.dart';

class CliConnectionPanel extends ConsumerStatefulWidget {
  const CliConnectionPanel({super.key});

  @override
  ConsumerState<CliConnectionPanel> createState() =>
      _CliConnectionPanelState();
}

class _CliConnectionPanelState extends ConsumerState<CliConnectionPanel> {
  String? _toastMessage;
  bool _toastIsError = false;

  void _showToast(String message, {bool isError = false}) {
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(cliConfigProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Model dropdown, Auto-detect, Manual-detect, Status
          Row(
            children: [
              Expanded(
                child: DropdownButton<CliModel>(
                  value: config.model,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: CliModel.values.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Text(m.displayName,
                          style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (m) {
                    if (m != null) {
                      ref.read(cliConfigProvider.notifier).setModel(m);
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok =
                        await ref.read(cliConfigProvider.notifier).autoDetect();
                    if (!ok) {
                      _showToast(
                        '${config.model.displayName} CLI를 찾을 수 없습니다.',
                        isError: true,
                      );
                    } else {
                      _showToast('CLI 연결 성공!');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Auto'),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () => _pickFile(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Manual'),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: config.status),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Login button, current path
          Row(
            children: [
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: config.status == CliStatus.connected
                      ? () => ref.read(cliConfigProvider.notifier).login()
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  config.executablePath ?? 'No CLI path set',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          // Toast message
          if (_toastMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _toastIsError
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _toastIsError
                        ? Colors.red[200]!
                        : Colors.green[200]!,
                  ),
                ),
                child: Text(
                  _toastMessage!,
                  style: TextStyle(
                    fontSize: 11,
                    color: _toastIsError ? Colors.red[700] : Colors.green[700],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final controller = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CLI executable path'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: r'C:\Users\...\claude.exe',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                final picked = await _browseFile();
                if (picked != null) controller.text = picked;
              },
              icon: const Icon(Icons.more_horiz),
              tooltip: 'Browse...',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[200],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (path != null && path.isNotEmpty) {
      ref.read(cliConfigProvider.notifier).manualSetPath(path);
    }
  }

  /// Launch native file picker via PowerShell OpenFileDialog.
  Future<String?> _browseFile() async {
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        r'''
Add-Type -AssemblyName System.Windows.Forms
$d = New-Object System.Windows.Forms.OpenFileDialog
$d.Filter = "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
$d.Title = "Select CLI executable"
if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output $d.FileName
}
''',
      ]);
      final path = (result.stdout as String).trim();
      if (path.isNotEmpty) return path;
    } catch (_) {}
    return null;
  }
}

class _StatusBadge extends StatelessWidget {
  final CliStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case CliStatus.disconnected:
        color = Colors.red;
      case CliStatus.connected:
        color = Colors.orange;
      case CliStatus.authenticated:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
