# Rakuku アプリ（Flutter）

要件・設計は [`../docs`](../docs) を参照。技術スタック：**Flutter / Riverpod / go_router / Drift（SQLite, offline-first）/ supabase_flutter**。

## 初回セットアップ

このリポジトリには **Dart ソース（`lib/`）と `pubspec.yaml` のみ**を置いています。
プラットフォーム生成物（`android/`・`ios/` 等）は gitignore しており、各自で生成します。

```bash
cd app

# 1) プラットフォームフォルダを生成（既存の lib/ と pubspec.yaml はそのまま使われる）
flutter create . --org com.rakuku --project-name rakuku --platforms=android,ios

# 2) 依存解決
flutter pub get
# 解決に失敗したら:
# flutter pub upgrade --major-versions

# 3) 接続情報を設定
cp env.example.json env.json    # env.json に anon/publishable キーを記入

# 4) 実行
flutter run --dart-define-from-file=env.json
```

> 接続情報なしでも `flutter run`（dart-define なし）で起動でき、UIだけ確認できます（ホームに未設定バナーを表示）。

## ディレクトリ構成（予定）

```
lib/
  main.dart            # 起動・Supabase初期化・匿名サインイン
  app/                 # テーマ(ColorScheme)・ルーティング・アプリ本体
  core/                # 環境変数など共通
  domain/              # モデル・復習ロジック（次バッチ）
  data/                # Drift / Supabase / Repository（次バッチ）
  features/            # 画面（home/detail/add/review/settings）
```

## 現在の実装状況

- [x] プロジェクト雛形（pubspec / lint）
- [x] テーマ（確定トークン Indigo×ライト → `ColorScheme`）
- [x] ルーティング（go_router、S02〜S09の骨組み）
- [x] Supabase 初期化＋匿名サインイン起動
- [ ] データ層（Drift・モデル・Repository）← 次バッチ
- [ ] 各画面の中身（一覧→詳細→復習→…）

詳細な残タスクは [`../docs/project-status.md`](../docs/project-status.md)。
