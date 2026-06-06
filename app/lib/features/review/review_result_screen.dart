import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// S08 復習結果（プレースホルダ）。
/// 出題アイテム一覧＋判定（覚えた/うろ覚え/苦手）・正答数(=覚えた件数)は次バッチ。
class ReviewResultScreen extends StatelessWidget {
  const ReviewResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('結果')),
      body: Center(
        child: OutlinedButton(
          onPressed: () => context.goNamed('home'),
          child: const Text('一覧に戻る'),
        ),
      ),
    );
  }
}
