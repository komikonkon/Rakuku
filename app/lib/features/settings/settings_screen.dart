import 'package:flutter/material.dart';

/// S09 設定 / アカウント（プレースホルダ）。
/// ログイン状態・Googleログイン（昇格）・各種設定は次バッチ。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: const Center(child: Text('アカウント・各種設定 — 実装予定')),
    );
  }
}
