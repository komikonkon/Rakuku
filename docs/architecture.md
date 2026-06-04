# Rakuku システム構成図

> 本書は `docs/requirements.md`（要件定義書 v1.1）に基づくシステム構成のビジュアル資料。
> 図は GitHub 上で Mermaid として描画される。

- **対象**: Rakuku MVP
- **最終更新**: 2026-06-04
- **関連**: [要件定義書](./requirements.md) ／ [画面遷移図](./screen-flow.md)
- **詳細設計**: [レイヤー・主要クラス](./design/architecture-layers.md) ／ [復習状態遷移](./design/review-state-machine.md) ／ [Edge Function IF](./design/edge-function-claude.md) ／ DDL: `supabase/migrations/`

### 図の読み方（レイアウト規約）

- **視線は左上→右下**。番号（①②③④）の順に読む。
- 主フローは**実線・一方向**、補助連携（端末機能・将来・運用）は**点線**。
- 線は**直線（折れ線）**で表示し、交差を最小化。色は意味ごとに固定（下記凡例）。

---

## 凡例（色の意味）

```mermaid
%%{init: {'flowchart': {'curve': 'linear'}}}%%
flowchart LR
    L_app["Flutter アプリ"]:::app
    L_sb["Supabase"]:::sb
    L_ext["外部API（Claude）"]:::ext
    L_os["端末 / OS"]:::os
    L_ops["運用（CI）"]:::ops
    L_dec{"判定"}:::dec

    L_app ~~~ L_sb ~~~ L_ext ~~~ L_os ~~~ L_ops ~~~ L_dec

    classDef app  fill:#E3F2FD,stroke:#1976D2,color:#0D47A1;
    classDef sb   fill:#E8F5E9,stroke:#2E7D32,color:#1B5E20;
    classDef ext  fill:#FFF3E0,stroke:#EF6C00,color:#E65100;
    classDef os   fill:#ECEFF1,stroke:#546E7A,color:#263238;
    classDef ops  fill:#F3E5F5,stroke:#7B1FA2,color:#4A148C;
    classDef dec  fill:#FFFDE7,stroke:#F9A825,color:#827717;
```

---

## 1. 全体構成図

> ① 入力（OS）→ ② アプリ → ③ Supabase → ④ データ/外部、の順に左→右へ流れる。点線は補助連携。

```mermaid
%%{init: {'flowchart': {'curve': 'linear', 'nodeSpacing': 45, 'rankSpacing': 75}}}%%
flowchart LR
    subgraph OS["① 端末 / OS（入力）"]
        direction TB
        OtherApps["他アプリ<br/>(Safari/SNS/記事)"]:::os
        ShareSheet["共有シート / インテント"]:::os
        STT["端末STT（音声認識）"]:::os
        TTS["端末TTS（音声合成）"]:::os
    end

    subgraph App["② Flutter アプリ"]
        direction TB
        ShareExt["共有受け取り"]:::app
        UI["UI層"]:::app
        Repo["Repository層"]:::app
        Clients["抽象クライアント<br/>Ai / Audio / Storage"]:::app
        SDK["Supabase SDK"]:::app
    end

    subgraph SB["③ Supabase"]
        direction TB
        Auth["Auth<br/>匿名 + Google"]:::sb
        REST["PostgREST（自動API）"]:::sb
        Edge["Edge Functions（TS）"]:::sb
    end

    subgraph Data["④ データ / 外部"]
        direction TB
        DB[("PostgreSQL + RLS")]:::sb
        Storage["Storage（将来）"]:::sb
        Claude["Claude API"]:::ext
    end

    %% 主フロー（実線・左→右）
    OtherApps --> ShareSheet --> ShareExt --> Repo
    UI --> Repo --> Clients --> SDK
    SDK --> Auth
    SDK --> REST --> DB
    SDK --> Edge
    Edge --> DB
    Edge --> Claude

    %% 補助連携（点線）
    UI -. 音声入力 .-> STT
    Clients -. 音声合成 .-> TTS
    Clients -. 将来 .-> Storage

    classDef app  fill:#E3F2FD,stroke:#1976D2,color:#0D47A1;
    classDef sb   fill:#E8F5E9,stroke:#2E7D32,color:#1B5E20;
    classDef ext  fill:#FFF3E0,stroke:#EF6C00,color:#E65100;
    classDef os   fill:#ECEFF1,stroke:#546E7A,color:#263238;

    style OS   fill:#FAFAFA,stroke:#B0BEC5
    style App  fill:#F5FAFE,stroke:#90CAF9
    style SB   fill:#F4FBF5,stroke:#A5D6A7
    style Data fill:#F4FBF5,stroke:#A5D6A7
```

> 運用（keepalive）は独立した補助系のため §6 に分離して記載。

### 登場人物と役割

| 区分 | 要素 | 役割 |
|---|---|---|
| ① 端末/OS | 共有シート/インテント | 他アプリから「共有」でRakukuへテキストを送る入口 |
| ① 端末/OS | 端末STT | アプリ内音声入力。認識候補を返しユーザーが選択 |
| ① 端末/OS | 端末TTS | 発音確認の音声合成（無料・オフライン） |
| ② アプリ | UI層 | 画面・操作 |
| ② アプリ | Repository層 | データアクセスを集約（ベンダー直叩きを隠蔽し移植性を確保） |
| ② アプリ | 抽象クライアント | AI/音声/ストレージを差し替え可能にするインターフェース |
| ③ Supabase | Auth | 匿名サインイン＋Googleログイン＋昇格 |
| ③ Supabase | PostgREST | テーブルから自動生成されるREST API（自前API不要） |
| ③ Supabase | Edge Functions | 秘密鍵が要る処理のみ（Claude中継） |
| ④ データ/外部 | PostgreSQL+RLS | データ本体。RLSで「自分のデータのみ」を強制 |
| ④ データ/外部 | Claude API | 解説・コアイメージ・例文の生成 |

---

## 2. 実装言語・責務の分離

```mermaid
%%{init: {'flowchart': {'curve': 'linear', 'rankSpacing': 70}}}%%
flowchart LR
    Dart["Dart<br/>Flutterアプリ全般<br/>(UI / Repository / SDK呼び出し)"]:::app
    TS["TypeScript<br/>Edge Functions<br/>(秘密鍵が要る処理のみ)"]:::sb
    SQL["SQL<br/>テーブル定義 / RLS / マイグレーション"]:::sb

    Dart -->|単純CRUDは直接| SQL
    Dart -->|秘密鍵が要る処理だけ| TS
    TS -->|DB更新| SQL

    classDef app fill:#E3F2FD,stroke:#1976D2,color:#0D47A1;
    classDef sb  fill:#E8F5E9,stroke:#2E7D32,color:#1B5E20;
```

> 単純CRUD（保存・取得・同期・苦手フラグ等）は**サーバコードを書かず** Flutterから直接DBへ（RLSが安全性を担保）。
> Claude呼び出しなど**秘密鍵が要る処理だけ** Edge Function（TypeScript）を経由する。

---

## 3. シーケンス：アイテム保存とAI生成

```mermaid
sequenceDiagram
    autonumber
    actor U as ユーザー
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
    actor U as ユーザー
    participant App as Flutterアプリ
    participant DB as PostgREST / DB

    U->>App: 復習開始（出題数・対象=全件/ブックマーク）
    App->>DB: 出題対象を取得（ステータス優先順 §6.11）
    DB-->>App: 出題アイテム一覧
    loop 各問題（正解を打ち切るまで次へ進まない）
        App->>U: 意味（日本語）を提示
        alt 自力で入力
            U->>App: 英語をタイピング →「回答する」（何度でも可）
            App->>App: 完全一致で判定。初回で外したら正否=✗ を記録
        else ヒント
            U->>App: ヒント押下（先頭1文字表示）
        else 答えを見る
            U->>App: 答え押下（灰色ゴースト表示＋誤字ブロック=タイプ強制）
            App->>App: 判定=苦手 を確定
        end
        Note over App,U: 入力が正解と完全一致するまでループ内で再回答
        App->>App: 初回操作から判定（覚えた/うろ覚え/苦手）を算出
        App->>DB: review_states 更新（status / last_*・review_count++）
    end
    App->>U: 結果表示（出題一覧＋判定3区分・正答数=覚えた件数・ステータス内訳）
```

---

## 5. フロー：認証（匿名スタート → Google昇格）

```mermaid
%%{init: {'flowchart': {'curve': 'linear', 'rankSpacing': 65}}}%%
flowchart LR
    Start(["初回起動"]):::os --> Anon["匿名サインイン<br/>(即利用開始)"]:::app
    Anon --> Use["保存・復習<br/>(匿名user_idに紐づく)"]:::app
    Use --> Q{"Googleログイン?"}:::dec
    Q -- いいえ --> Use
    Q -- はい --> Upgrade["匿名 → Google 昇格<br/>(データ引き継ぎ)"]:::sb
    Upgrade --> Sync["複数端末で同期<br/>(RLSで本人のみ)"]:::sb

    classDef os  fill:#ECEFF1,stroke:#546E7A,color:#263238;
    classDef app fill:#E3F2FD,stroke:#1976D2,color:#0D47A1;
    classDef sb  fill:#E8F5E9,stroke:#2E7D32,color:#1B5E20;
    classDef dec fill:#FFFDE7,stroke:#F9A825,color:#827717;
```

---

## 6. 構成：Supabase 凍結回避（keepalive）

```mermaid
%%{init: {'flowchart': {'curve': 'linear', 'rankSpacing': 65}}}%%
flowchart LR
    Cron["GitHub Actions<br/>cron 毎日 06:00 UTC"]:::ops --> Auth["Supabase Auth<br/>GET /auth/v1/health"]:::sb
    Cron --> REST["PostgREST<br/>SELECT keepalive"]:::sb --> DB[("PostgreSQL")]:::sb

    classDef ops fill:#F3E5F5,stroke:#7B1FA2,color:#4A148C;
    classDef sb  fill:#E8F5E9,stroke:#2E7D32,color:#1B5E20;
```

> プロジェクト停止を防ぐには**外部からの定期アクセスが必須**。詳細は要件定義書 §13 を参照。

---

*本書は要件定義書 v1.1 に追従する。要件変更時は本図も更新する。*
