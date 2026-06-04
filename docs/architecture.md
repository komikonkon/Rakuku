# Rakuku システム構成図

> 本書は `docs/requirements.md`（要件定義書 v1.1）に基づくシステム構成のビジュアル資料。
> 図は GitHub 上で Mermaid として描画される。

- **対象**: Rakuku MVP
- **最終更新**: 2026-06-04
- **関連**: [要件定義書](./requirements.md)

---

## 1. 全体構成図

```mermaid
flowchart TB
    subgraph OS["端末 / OS"]
        OtherApps["他アプリ<br/>(Safari / SNS / 記事など)"]
        ShareSheet["共有シート / 共有インテント"]
        STT["端末STT<br/>(音声認識)"]
        TTS["端末TTS<br/>(音声合成 flutter_tts)"]
    end

    subgraph App["Flutter アプリ (Dart)"]
        UI["UI層<br/>(一覧 / 詳細 / 保存 / 復習 / 設定)"]
        ShareExt["共有受け取り<br/>(iOS Share Extension / Android ACTION_SEND)"]
        Repo["Repository層<br/>(ItemRepository / ReviewRepository など)"]
        Clients["抽象クライアント<br/>AiClient / AudioClient / StorageClient"]
        SDK["Supabase SDK"]
    end

    subgraph Supabase["Supabase (BaaS)"]
        Auth["Auth (GoTrue)<br/>匿名 + Google OAuth"]
        REST["PostgREST<br/>(テーブルから自動生成されるAPI)"]
        DB[("PostgreSQL<br/>+ Row Level Security")]
        Storage["Storage<br/>(将来のクラウド音声用)"]
        Edge["Edge Functions<br/>(TypeScript / Deno)"]
    end

    Claude["Claude API<br/>(Anthropic)"]
    GHA["GitHub Actions<br/>日次 keepalive"]

    OtherApps --> ShareSheet --> ShareExt --> Repo
    UI --> Repo --> Clients
    Repo --> SDK
    Clients -->|音声合成| TTS
    UI -->|音声入力 → 認識候補| STT
    SDK -->|認証| Auth
    SDK -->|CRUD（RLSで本人のみ）| REST --> DB
    Clients -->|AI生成要求| Edge
    SDK -.->|invoke| Edge
    Edge -->|APIキーを秘匿して呼び出し| Claude
    Edge -->|解説をINSERT| DB
    Clients -.->|将来クラウドTTS時| Storage
    GHA -->|日次ping| Auth
    GHA -->|keepalive SELECT| REST
```

### 登場人物と役割

| 区分 | 要素 | 役割 |
|---|---|---|
| 端末/OS | 共有シート/インテント | 他アプリから「共有」でRakukuへテキストをDownする入口 |
| 端末/OS | 端末STT | アプリ内音声入力。認識候補を返しユーザーが選択 |
| 端末/OS | 端末TTS | 発音確認の音声合成（無料・オフライン） |
| アプリ | UI層 | 画面・操作 |
| アプリ | Repository層 | データアクセスを集約（ベンダー直叩きを隠蔽し移植性を確保） |
| アプリ | 抽象クライアント | AI/音声/ストレージを差し替え可能にするインターフェース |
| Supabase | Auth | 匿名サインイン＋Googleログイン＋昇格 |
| Supabase | PostgREST | テーブルから自動生成されるREST API（自前API不要） |
| Supabase | PostgreSQL+RLS | データ本体。RLSで「自分のデータのみ」を強制 |
| Supabase | Edge Functions | 秘密鍵が要る処理のみ（Claude中継） |
| 外部 | Claude API | 解説・コアイメージ・例文の生成 |
| 運用 | GitHub Actions | 無料枠の凍結回避（日次ping） |

---

## 2. 実装言語・責務の分離

```mermaid
flowchart LR
    Dart["Dart<br/>Flutterアプリ全般<br/>(UI / Repository / SDK呼び出し)"]
    SQL["SQL<br/>テーブル定義 / RLS / マイグレーション"]
    TS["TypeScript<br/>Edge Functions<br/>(Claude中継など秘密鍵が要る処理のみ)"]

    Dart -->|単純CRUDは直接| SQL
    Dart -->|秘密鍵が要る処理だけ| TS
    TS --> SQL
```

> 単語帳の保存・取得・同期・苦手フラグ等の**単純CRUDはサーバコードを書かず** Flutterから直接DBへ（RLSが安全性を担保）。
> Claude呼び出しなど**秘密鍵が要る処理だけ** Edge Function（TypeScript）を経由する。

---

## 3. シーケンス：アイテム保存とAI生成

```mermaid
sequenceDiagram
    autonumber
    participant U as ユーザー
    participant App as Flutterアプリ
    participant REST as PostgREST / DB
    participant Edge as Edge Function
    participant Claude as Claude API

    U->>App: アイテムを保存（共有 / 手動 / 音声入力）
    App->>REST: items INSERT (gen_status = new)
    App->>Edge: 解説生成を要求 (invoke)
    Edge->>Claude: プロンプト送信（APIキーはEdge内に秘匿）
    Claude-->>Edge: 意味 / コアイメージ / ニュアンス / 例文（日本語）
    Edge->>REST: explanations INSERT・items.gen_status = generated
    Edge-->>App: 生成完了
    App->>REST: 詳細を取得（以後はDBから読むだけ・再生成しない）
    REST-->>App: 保存済みの解説を返す
```

---

## 4. シーケンス：復習（タイピング想起）と学習ステータス更新

```mermaid
sequenceDiagram
    autonumber
    participant U as ユーザー
    participant App as Flutterアプリ
    participant DB as PostgREST / DB

    U->>App: 復習開始（出題数 5/10/20/50/100・対象=全件/ブックマーク）
    App->>DB: 出題対象を取得（ステータス優先順 §6.11）
    DB-->>App: 出題アイテム一覧
    loop 各問題
        App->>U: 意味（日本語）を提示
        alt 自力で入力
            U->>App: 英語をタイピング
        else ヒント
            U->>App: ヒント押下（先頭1文字表示）
        else 答えを見る
            U->>App: 答え押下（灰色で全文表示）
        end
        App->>App: 完全一致で正誤判定 → ステータス算出
        App->>DB: review_states 更新（status / last_*・review_count++）
    end
    App->>U: 結果表示
```

### ステータス判定ルール（§5.9）

| 直近の結果 | ステータス |
|---|---|
| 復習0回 | 未復習 |
| ヒント未使用・答えを見ず一発正解 | 覚えた |
| ヒントを使って正解 | うろ覚え |
| 答えを見た／自力で不正解 | 苦手 |

---

## 5. フロー：認証（匿名スタート → Google昇格）

```mermaid
flowchart LR
    Start["初回起動"] --> Anon["匿名サインイン<br/>(即利用開始・ログイン不要)"]
    Anon --> Use["保存・復習<br/>(データは匿名user_idに紐づく)"]
    Use --> Q{"Googleログイン?"}
    Q -- いいえ --> Use
    Q -- はい --> Upgrade["匿名 → Google 昇格<br/>(同一ユーザーとしてデータ引き継ぎ)"]
    Upgrade --> Sync["複数端末で同期<br/>(RLSで本人データのみ)"]
```

---

## 6. 構成：Supabase 凍結回避（keepalive）

```mermaid
flowchart LR
    Cron["GitHub Actions<br/>cron 毎日 06:00 UTC"] -->|GET /auth/v1/health| Auth["Supabase Auth"]
    Cron -->|SELECT keepalive| REST["PostgREST"] --> DB[("PostgreSQL")]
    Note["プロジェクト停止を防ぐ<br/>＝外部からの定期アクセスが必須"]
```

> 詳細は要件定義書 §13 を参照。スケジュール実行はデフォルトブランチのワークフローのみ動作するため、マージが必要。

---

*本書は要件定義書 v1.1 に追従する。要件変更時は本図も更新する。*
