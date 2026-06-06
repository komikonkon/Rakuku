# Rakuku セットアップ進捗・残タスク（Living Doc）

> プロジェクトの構築状況と「あとでやる」残タスクを追跡する。完了したらチェックを入れ、
> 新しい残タスクが出たらここに追記する。クラウドセッションは毎回リセットされるため、
> 進捗の正本はこのファイル（リポジトリ）に置く。
> 関連: [要件定義書](./requirements.md) ／ [詳細設計](./design/architecture-layers.md)

- **最終更新**: 2026-06-04

---

## 現在地

**設計フェーズ完了 → フェーズ2（Flutter初期化）着手**

---

## Supabase セットアップ

### ✅ 完了
- [x] プロジェクト作成（Asia-Pacific / 無料枠）
- [x] スキーマ（テーブル・UUIDv7既定・updated_atトリガ・インデックス）
- [x] RLS 有効化＋ポリシー（全テーブル）
- [x] Data API 権限付与（GRANT：keepalive=anon SELECT / アプリ各テーブル=authenticated CRUD）
- [x] keepalive テーブル＆日次ワークフロー稼働
- [x] **Anonymous sign-ins 有効化**

### ⬜ 残タスク（漏らさない）
- [ ] **#2 URL Configuration**（Site URL / Redirect URLs）— アプリのディープリンク登録。Google設定とセット。**アプリのURLスキーム確定後（フェーズ2〜3）**
- [ ] **#3 Google OAuth プロバイダ設定**（Google Cloud Console で Client ID/Secret 発行 → Supabase登録）— **認証画面実装時**
- [ ] **Allow manual linking を ON**（Auth → Sign In/Providers）— **匿名→Google昇格（`linkIdentity`）実装時**。#3とセット
- [ ] **#4 Edge Function `generate-explanation` をデプロイ ＋ Secret `ANTHROPIC_API_KEY`（必要なら `CLAUDE_MODEL`）**— **AI解説実装時（フェーズ3）**。IF設計: [edge-function-claude.md](./design/edge-function-claude.md)
- [ ] （確認）アプリが使うAPIキーの確定（GRANT後に `sb_publishable_...` で通るか / だめなら Legacy anon JWT）— **Flutter接続実装時**
- [ ] （任意）`pg_uuidv7` 拡張を有効化（DB既定もv7に。未対応なら放置でOK＝クライアント生成で担保）

### 不要
- Storage（端末TTSのため）／ Realtime（オフライン同期方式のため）／ Email・Phone・SAML等の他プロバイダ

---

## フェーズ・ロードマップ

| フェーズ | 内容 | 状態 |
|---|---|---|
| 1. 基盤 | DBスキーマ・RLS・Supabase Auth(匿名)・keepalive | ✅ ほぼ完了（Google/Edgeは各実装段で） |
| 2. アプリ骨組み | Flutter初期化・テーマ(ColorScheme)・supabase接続・データ層 | ▶ 進行中（バッチ1完了：雛形/テーマ/ルーティング/接続。次：データ層） |
| 3. 機能実装 | 保存→一覧→詳細(AI解説/TTS)→復習→ブックマーク→設定/認証昇格 | 未 |
| 4. 仕上げ | テスト・CI・ベータ配信 | 未 |

---

## ブランチ運用の不整合・注意（branchリネーム起因 / 2026-06-04）

デフォルトブランチを `claude/rakuku-app-requirements-CawyG` → `main` にリネームし、
そのままだと環境のgitプロキシが `main` へのpushを **403** で拒否したため、
「**main維持＋作業ブランチ `claude/rakuku-app-requirements-CawyG` 運用**」に変更した。それに伴う事項：

### 要対応
- [ ] **main へ作業ブランチを取り込む**：`claude/rakuku-app-requirements-CawyG`（最新）→ `main` を**常設PRでマージ**。これをしないと `main` が古いまま（現状 `project-status.md` 等が main 未反映）。
- [ ] **常設PRの作成**（claude/... → main）。以降のpushもこのPRに集約し、区切りでMerge。
- [ ] **プレビューURLの基準を main に**：共有用の githack/htmlpreview リンクは将来 `main` 参照に統一（例 `.../komikonkon/Rakuku/main/prototype/index.html`）。リポジトリ内にハードコードは無いので、次に共有する時に差し替えればよい。

### 確認済み・問題なし
- ✅ **cron/keepalive**：ワークフローはブランチ名をハードコードしておらず、cronは**デフォルトブランチ（=main）**で実行。main に最終版ワークフロー（Legacy anon JWT・GRANT反映）が入っているため正常稼働。
- ✅ **ブランチ名のハードコード無し**：リポジトリ内（docs/workflows/prototype）に `claude/rakuku-app-requirements-CawyG` の直接参照は0件。
- ✅ **Secrets**（`SUPABASE_URL`/`SUPABASE_ANON_KEY`）はリポジトリ単位でブランチ非依存。

### 既知の別件（rename無関係）
- コミットの "Unverified" バッジ … 署名鍵がこの環境に無いだけ。履歴・コードに影響なし。必要なら後日対応。

---

## 技術選定（フェーズ2入口で確定する）

| 項目 | 採用 | 状態 |
|---|---|---|
| 状態管理 | **Riverpod** | ✅ 確定 |
| ローカルDB | **Drift（SQLite, offline-first）** | ✅ 確定 |
| ルーティング | **go_router** | ✅ 確定 |
| Flutter作成 | ローカルで `flutter create .`（platformは各自生成・gitignore） | ✅ 確定 |

### フェーズ2 残タスク
- [ ] データ層：Driftスキーマ（サーバと同型）＋モデル＋DAO
- [ ] Repository（Item/Explanation/Review/Auth）＋ Supabase同期（LWW）
- [ ] 各画面の実装（一覧→詳細→復習→ブックマーク→設定）
- [ ] アプリが使うAPIキー確認（publishable で疎通するか）
- [ ] （後で）プラットフォーム固有設定：STT/TTS権限・共有受け取り・ディープリンク（gitignore解除して個別コミット）
