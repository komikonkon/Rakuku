import 'package:flutter/material.dart';

/// S04/S05 アイテム追加（手動・音声）（プレースホルダ）。
class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アイテムを追加')),
      body: const Center(child: Text('手動入力／音声入力 — 実装予定')),
    );
  }
}
