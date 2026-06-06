import 'package:flutter/material.dart';

/// S03 アイテム詳細（プレースホルダ）。解説・音声・操作は次バッチ。
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('詳細')),
      body: Center(child: Text('アイテム詳細（id: $itemId）— 実装予定')),
    );
  }
}
