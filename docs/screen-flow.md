# Rakuku 画面遷移図

> 本書は `docs/requirements.md`（要件定義書 v1.1）に基づく画面遷移のビジュアル資料。
> 図は GitHub 上で Mermaid として描画される。UIのルック（色・トーン）はプロト先行で別途決定し、本書は**構造（遷移）**を定義する。
> 線を減らすため、**画面内で完結する操作はノード内に併記**し、線は**画面が切り替わる遷移のみ**を示す。

- **対象**: Rakuku MVP
- **最終更新**: 2026-06-04
- **関連**: [要件定義書](./requirements.md) ／ [システム構成図](./architecture.md)

---

## 凡例（色の意味）

```mermaid
flowchart LR
    L_scr["画面"]:::screen
    L_proc["処理 / 保存"]:::proc
    L_dec{"判定 / 分岐"}:::dec
    L_term(["起動 / 外部入口"]):::term

    L_scr ~~~ L_proc ~~~ L_dec ~~~ L_term

    classDef screen fill:#E3F2FD,stroke:#1976D2,color:#0D47A1;
    classDef proc   fill:#E0F2F1,stroke:#00897B,color:#004D40;
    classDef dec    fill:#FFFDE7,stroke:#F9A825,color:#827717;
    classDef term   fill:#ECEFF1,stroke:#546E7A,color:#263238;
```

学習ステータスは復習フロー（図3）で次の4色を用いる：
🟢 覚えた ／ 🟡 うろ覚え ／ 🔴 苦手 ／ ⚪ 未復習

---

## 1. 全体の画面遷移

```mermaid
flowchart TD
    Launch(["アプリ起動"]):::term --> AuthChk{"セッション有り?"}:::dec
    AuthChk -- なし --> Anon["匿名サインイン（自動）"]:::proc --> Home
    AuthChk -- あり --> Home

    Home["ホーム / アイテム一覧<br/>(ステータスバッジ・ブックマーク絞り込み)"]:::screen

    Home -->|タップ| Detail["アイテム詳細<br/>(意味/コアイメージ/例文/音声再生<br/>ブックマークON/OFF・再生成)"]:::screen
    Home -->|＋ 手動入力| AddManual["手動入力で追加"]:::screen
    Home -->|音声入力| Voice["音声入力（端末STT）"]:::screen
    Home -->|復習| ReviewCfg["復習設定<br/>(出題数 5/10/20/50/100・対象)"]:::screen
    Home -->|設定| Settings["設定 / アカウント"]:::screen

    AddManual -->|保存| Home
    Voice --> VoicePick["認識候補から選択"]:::proc -->|保存| Home
    Detail -->|戻る / 削除| Home

    ReviewCfg -->|開始| Session["復習セッション<br/>(タイピング想起)"]:::screen --> Result["結果"]:::screen
    Result -->|もう一度| ReviewCfg
    Result -->|終了| Home

    Settings -->|Googleログイン| Upgrade["匿名 → Google 昇格"]:::proc --> Settings
    Settings -->|戻る| Home

    classDef screen fill:#E3F2FD,stroke:#1976D2,color:#0D47A1;
    classDef proc   fill:#E0F2F1,stroke:#00897B,color:#004D40;
    classDef dec    fill:#FFFDE7,stroke:#F9A825,color:#827717;
    classDef term   fill:#ECEFF1,stroke:#546E7A,color:#263238;
```

---

## 2. 保存の3経路

### 2-A. 共有から保存（アプリを開かず）

```mermaid
flowchart LR
    Ext(["他アプリで英語を選択<br/>→ 共有ボタン"]):::term --> Sheet(["共有シート / インテントで<br/>Rakuku を選択"]):::term
    Sheet --> MiniUI["保存ミニUI（オーバーレイ）<br/>アプリ本体は開かない"]:::screen
    MiniUI -->|保存| Done["保存完了（トースト）"]:::proc
    Done --> BackExt(["元のアプリに戻る"]):::term
    MiniUI -.->|アプリで開く（任意）| HomeRef["ホーム / 一覧へ"]:::screen

    classDef term   fill:#ECEFF1,stroke:#546E7A,color:#263238;
    classDef screen fill:#E3F2FD,stroke:#1976D2,color:#0D47A1;
    classDef proc   fill:#E0F2F1,stroke:#00897B,color:#004D40;
```

### 2-B. 手動入力 ／ 2-C. 音声入力（アプリ内）

```mermaid
flowchart LR
    Home["ホーム / 一覧"]:::screen -->|＋ 手動入力| Manual["テキスト入力 / 貼り付け"]:::screen
    Home -->|音声入力| Speak["英語を発話"]:::screen

    Manual --> Save["保存<br/>(gen_status = new)"]:::proc
    Speak --> STT["端末STTがテキスト化<br/>認識候補を提示"]:::proc --> Pick["候補から選択"]:::screen --> Save

    Save --> Gen["AI生成を非同期で開始"]:::proc --> Back["一覧へ<br/>(生成中はプレースホルダ表示)"]:::screen

    classDef screen fill:#E3F2FD,stroke:#1976D2,color:#0D47A1;
    classDef proc   fill:#E0F2F1,stroke:#00897B,color:#004D40;
```

> 保存直後は `gen_status = new`。AI解説（意味・コアイメージ・ニュアンス・例文）はバックグラウンドで生成され、完了後に詳細へ反映される。

---

## 3. 復習フロー（タイピング想起）

> 出題 → 操作（入力／ヒント／答えを見る）→ ステータス更新 → 次の問題、を繰り返す。ステータスは結果に応じて4色に分岐。

```mermaid
flowchart TD
    Cfg["復習設定<br/>出題数 5/10/20/50/100・対象=全件/ブックマーク"]:::screen --> Q["問題表示<br/>(意味＝日本語)"]:::screen
    Q --> Op{"ユーザー操作"}:::dec

    Op -->|ヒント| Hint["先頭1文字を表示"]:::proc --> Q
    Op -->|英語を入力| Judge{"完全一致?"}:::dec
    Op -->|答えを見る| Reveal["灰色で全文表示"]:::proc

    Judge -->|正解・ヒント未使用| SLearned["status = 覚えた"]:::learned
    Judge -->|正解・ヒント使用| SVague["status = うろ覚え"]:::vague
    Judge -->|不正解| SWeak["status = 苦手"]:::weak
    Reveal --> SWeak2["status = 苦手"]:::weak

    SLearned --> Next{"残り問題?"}:::dec
    SVague --> Next
    SWeak --> Next
    SWeak2 --> Next

    Next -->|あり| Q
    Next -->|なし| Result["結果表示<br/>正答数・ステータス内訳"]:::screen

    classDef screen  fill:#E3F2FD,stroke:#1976D2,color:#0D47A1;
    classDef proc    fill:#E0F2F1,stroke:#00897B,color:#004D40;
    classDef dec     fill:#FFFDE7,stroke:#F9A825,color:#827717;
    classDef learned fill:#C8E6C9,stroke:#2E7D32,color:#1B5E20;
    classDef vague   fill:#FFF9C4,stroke:#F9A825,color:#827717;
    classDef weak    fill:#FFCDD2,stroke:#C62828,color:#B71C1C;
```

> ⚪ 未復習 は「復習0回」の初期状態（図では遷移後のため省略）。判定の詳細は要件定義書 §5.9 を参照。

---

## 4. 画面インベントリ（一覧）

| 画面 | 主な構成要素 | 主な遷移先 |
|---|---|---|
| 起動 | スプラッシュ／匿名サインイン（自動） | → ホーム |
| ホーム / アイテム一覧 | アイテム一覧（ステータスバッジ）、ブックマーク絞り込み、追加（手動/音声）、復習、設定 | → 詳細 / 手動入力 / 音声入力 / 復習設定 / 設定 |
| アイテム詳細 | 原文、意味、コアイメージ、ニュアンス、例文、音声再生、ブックマークON/OFF、再生成、削除 | → ホーム（戻る/削除） |
| 手動入力 | テキスト入力・貼り付け、保存 | → ホーム |
| 音声入力 | 発話、認識候補リスト、選択、保存 | → ホーム |
| 保存ミニUI（共有経由） | 受信テキスト確認、保存、トースト | → 元アプリ（任意でホーム） |
| 復習設定 | 出題数選択（5/10/20/50/100）、対象（全件/ブックマーク）、開始 | → 復習セッション |
| 復習セッション | 意味提示、英語入力、ヒント、答えを見る | → 結果 |
| 結果 | 正答数、ステータス内訳、もう一度/終了 | → 復習設定 / ホーム |
| 設定 / アカウント | ログイン状態、Googleログイン（昇格）、各種設定 | → ホーム |

---

## 5. ナビゲーション方針（MVP）

- **ホームを起点**としたシンプルな階層遷移。タブバーは必須としない（MVPは画面数が少ないため）。
- **共有経由の保存**はアプリ本体の遷移とは独立した軽量フロー（OSのオーバーレイ上で完結）。
- 破壊的操作（削除）は確認を挟む。
- ルックや細部のレイアウトはプロト（モック）で決定する。

---

*本書は要件定義書 v1.1 に追従する。要件変更時は本図も更新する。*
