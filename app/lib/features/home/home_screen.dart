import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env.dart';

/// S02 ホーム（アイテム一覧）— フェーズ2の骨組み（プレースホルダ）。
/// データ層（一覧取得・絞り込み）は次バッチで実装する。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイ単語帳'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed('settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!Env.isSupabaseConfigured)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Supabase 未設定で起動中（UI確認モード）。\n'
                  '--dart-define-from-file=env.json を付けて実行すると接続します。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'フェーズ2: アプリ骨組み',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'テーマ・ルーティング・Supabase接続まで配線済み。'
            '一覧/詳細/復習の中身は次バッチで実装します。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.goNamed('reviewConfig'),
            child: const Text('復習へ'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.goNamed('itemDetail',
                pathParameters: {'id': 'sample'}),
            child: const Text('サンプル詳細へ'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goNamed('add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
