# Rakuku ER図（データモデル）

> 本書は `docs/requirements.md` §8 に基づくデータベースのER図と関係定義。
> Supabase（PostgreSQL）上のスキーマを表す。図は GitHub 上で Mermaid として描画される。

- **対象**: Rakuku MVP
- **最終更新**: 2026-06-04
- **関連**: [要件定義書](./requirements.md) ／ [システム構成図](./architecture.md)

---

## 1. ER図

```mermaid
erDiagram
    AUTH_USERS  ||--o{ COLLECTIONS    : "所有"
    AUTH_USERS  ||--o{ ITEMS          : "所有"
    COLLECTIONS ||--o{ ITEMS          : "まとめる"
    ITEMS       ||--o| EXPLANATIONS   : "解説を持つ(0/1)"
    ITEMS       ||--o{ AUDIOS         : "音声を持つ"
    ITEMS       ||--|| REVIEW_STATES  : "学習状態を持つ"
    AUTH_USERS  ||--o{ REVIEW_STATES  : "所有"

    AUTH_USERS {
        uuid id PK "Supabase Auth が管理（匿名/Google）"
    }

    COLLECTIONS {
        uuid        id          PK
        uuid        user_id     FK "所有ユーザー"
        text        name        "単語帳名（MVPは既定1件）"
        timestamptz created_at
    }

    ITEMS {
        uuid        id            PK
        uuid        user_id       FK "所有ユーザー"
        uuid        collection_id FK "所属コレクション（nullable）"
        text        source_text   "保存した英語原文"
        text        item_type     "word | phrase"
        text        input_method  "share | manual | voice"
        text        source_url    "出典URL（nullable）"
        text        source_app    "共有元アプリ名（nullable）"
        boolean     is_bookmarked "ブックマーク（既定 false）"
        text        gen_status    "new | generated | error"
        timestamptz created_at
        timestamptz updated_at
    }

    EXPLANATIONS {
        uuid        id          PK
        uuid        item_id     FK "対象アイテム"
        text        meaning     "意味・訳（日本語）"
        text        core_image  "コアイメージ（日本語）"
        text        nuance      "ニュアンス（日本語）"
        jsonb       examples    "例文 [{en, ja}]"
        text        model       "生成モデル名"
        timestamptz created_at
    }

    AUDIOS {
        uuid        id           PK
        uuid        item_id      FK "対象アイテム"
        text        target       "expression | example"
        text        storage_path "クラウドTTS時のみ（端末TTSは不要）"
        timestamptz created_at
    }

    REVIEW_STATES {
        uuid        id               PK
        uuid        item_id          FK "対象アイテム（1対1）"
        uuid        user_id          FK "所有ユーザー"
        text        status           "not_reviewed | weak | vague | learned"
        timestamptz last_reviewed_at "直近の復習日時（nullable）"
        boolean     last_used_hint   "直近でヒント使用（nullable）"
        boolean     last_revealed    "直近で答えを見た（nullable）"
        boolean     last_correct     "直近で正解（nullable）"
        int         review_count     "復習回数"
    }
```

> `AUTH_USERS` は Supabase Auth（`auth.users`）が管理する既存テーブル。アプリ側テーブルは `user_id` で参照する。

---

## 2. リレーション一覧

| 親 | 子 | 多重度 | 外部キー | 削除時（ON DELETE） |
|---|---|---|---|---|
| auth.users | collections | 1 — 0..N | collections.user_id | CASCADE |
| auth.users | items | 1 — 0..N | items.user_id | CASCADE |
| collections | items | 1 — 0..N | items.collection_id（nullable） | SET NULL |
| items | explanations | 1 — 0..1 | explanations.item_id | CASCADE |
| items | audios | 1 — 0..N | audios.item_id | CASCADE |
| items | review_states | 1 — 1 | review_states.item_id（UNIQUE） | CASCADE |
| auth.users | review_states | 1 — 0..N | review_states.user_id | CASCADE |

### 補足
- **explanations は 0..1**：保存直後（`gen_status=new`）は未生成のため0件、生成後に1件。再生成は同一行を更新（履歴は持たない）。
- **review_states は 1対1**：アイテム保存時に `status=not_reviewed` で1件作成する。`item_id` に UNIQUE 制約。
- **review_states.user_id** は items 経由でも辿れるが、RLS とクエリ簡略化のため冗長に保持する。
- **audios は端末TTS方針では基本未使用**（将来クラウドTTS採用時に格納）。MVPでは空でも可。

---

## 3. RLS（行レベルセキュリティ）方針

全アプリテーブルで「本人のデータのみ」を強制する。

| テーブル | ポリシー（SELECT/INSERT/UPDATE/DELETE） |
|---|---|
| collections | `user_id = auth.uid()` |
| items | `user_id = auth.uid()` |
| review_states | `user_id = auth.uid()` |
| explanations | 親 items の `user_id = auth.uid()`（item_id 経由のサブクエリ）または生成は Edge Function（service role）で実施 |
| audios | 同上（item_id 経由） |

> explanations / audios は `user_id` を直接持たないため、`item_id` で親 items を辿って認可する（またはこれらに `user_id` を非正規化して付与する案もある）。実装時に確定。

---

## 4. 主なインデックス候補

| テーブル | インデックス | 目的 |
|---|---|---|
| items | (user_id, created_at desc) | 一覧の新着順表示 |
| items | (user_id, is_bookmarked) | ブックマーク絞り込み |
| review_states | (user_id, status, last_reviewed_at) | 出題順（ステータス優先＋古い順 §6.11） |
| explanations | (item_id) UNIQUE | 1対1の保証・結合 |
| review_states | (item_id) UNIQUE | 1対1の保証 |

---

## 5. 運用テーブル（ドメイン外）

`keepalive`（§13）は凍結回避専用のシングルトンテーブルで、ドメインモデルとは独立。本ER図には含めない。

---

*本書は要件定義書 v1.1 に追従する。スキーマ変更時は本図も更新する。*
