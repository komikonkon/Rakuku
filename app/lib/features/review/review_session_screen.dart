import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// S07 復習セッション（プレースホルダ）。
/// タイピング想起・カラオケ式ゴースト・タイプ強制は
/// docs/design/review-state-machine.md に基づき次バッチで実装。
class ReviewSessionScreen extends StatelessWidget {
  const ReviewSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1 / 10')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.goNamed('reviewResult'),
          child: const Text('結果へ（仮）'),
        ),
      ),
    );
  }
}
