import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// S06 復習設定（プレースホルダ）。出題数/対象選択は次バッチ。
class ReviewConfigScreen extends StatelessWidget {
  const ReviewConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('復習')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.goNamed('reviewSession'),
          child: const Text('復習を始める'),
        ),
      ),
    );
  }
}
