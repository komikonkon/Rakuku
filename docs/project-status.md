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
| 2. アプリ骨組み | Flutter初期化・テーマ(ColorScheme)・supabase接続・データ層 | ▶ 着手 |
| 3. 機能実装 | 保存→一覧→詳細(AI解説/TTS)→復習→ブックマーク→設定/認証昇格 | 未 |
| 4. 仕上げ | テスト・CI・ベータ配信 | 未 |

---

## 技術選定（フェーズ2入口で確定する）

| 項目 | 推奨 | 状態 |
|---|---|---|
| 状態管理 | Riverpod | ⬜ 未確定 |
| ローカルDB | Drift（SQLite, offline-first） | ⬜ 未確定 |
| ルーティング | go_router | ⬜ 未確定 |

> 確定したら本表と [architecture-layers.md](./design/architecture-layers.md) を更新する。
