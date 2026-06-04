# Rakuku 画面遷移図

> 本書は `docs/requirements.md`（要件定義書 v1.1）に基づく画面遷移のビジュアル資料。
> 図は GitHub 上で Mermaid として描画される。UIのルック（色・トーン）はプロト先行で別途決定し、本書は**構造（遷移）**を定義する。

- **対象**: Rakuku MVP
- **最終更新**: 2026-06-04
- **関連**: [要件定義書](./requirements.md) ／ [システム構成図](./architecture.md)

---

## 1. 全体の画面遷移

```mermaid
flowchart TD
    Launch(["アプリ起動"]) --> AuthChk{"セッション有り?"}
    AuthChk -- なし --> Anon["匿名サインイン（自動・ログイン不要）"]
    Anon --> Home
    AuthChk -- あり --> Home["ホーム / アイテム一覧"]

    Home -->|アイテムをタップ| Detail["アイテム詳細"]
    Home -->|＋ 手動入力| AddManual["手動入力で追加"]
    Home -->|音声入力| Voice["音声入力（端末STT）"]
    Home -->|復習| ReviewCfg["復習設定"]
    Home -->|設定| Settings["設定 / アカウント"]
    Home -->|フィルタ切替| Filter{"表示対象<br/>全件 / ブックマークのみ"}
    Filter --> Home

    AddManual -->|保存| Home
    Voice --> VoicePick["認識候補から選択"]
    VoicePick -->|保存| Home

    Detail -->|ブックマーク ON/OFF| Detail
    Detail -->|音声再生（端末TTS）| Detail
    Detail -->|解説を再生成| Detail
    Detail -->|削除| Home
    Detail -->|戻る| Home

    ReviewCfg -->|開始| Session["復習セッション（タイピング想起）"]
    Session --> Result["結果"]
    Result -->|もう一度| ReviewCfg
    Result -->|終了| Home

    Settings -->|Googleログイン| Upgrade["匿名 → Google 昇格"]
    Upgrade --> Settings
    Settings -->|戻る| Home
```

---

## 2. 保存の3経路

### 2-A. 共有から保存（アプリを開かず）

```mermaid
flowchart TD
    Ext["他アプリで英語を選択 → 共有ボタン"] --> Sheet["共有シート / 共有インテントで Rakuku を選択"]
    Sheet --> MiniUI["保存ミニUI（オーバーレイ）<br/>アプリ本体は開かない"]
    MiniUI -->|保存| Done["保存完了（トースト表示）"]
    Done --> BackExt["元のアプリに戻る"]
    MiniUI -.->|アプリで開く（任意）| HomeRef["ホーム / 一覧へ"]
```

### 2-B. 手動入力 ／ 2-C. 音声入力（アプリ内）

```mermaid
flowchart TD
    Home["ホーム / 一覧"] -->|＋ 手動入力| Manual["テキスト入力 / 貼り付け"]
    Manual -->|保存| Save["保存 → AI生成は非同期で開始"]

    Home -->|音声入力| Speak["英語を発話"]
    Speak --> STT["端末STTがテキスト化<br/>認識候補（複数）を提示"]
    STT --> Pick["候補から選択"]
    Pick -->|保存| Save
    Save --> Back["一覧へ（生成中はプレースホルダ表示）"]
```

> 保存直後は `gen_status = new`。AI解説（意味・コアイメージ・ニュアンス・例文）はバックグラウンドで生成され、完了後に詳細へ反映される。

---

## 3. 復習フロー（タイピング想起）

```mermaid
flowchart TD
    Cfg["復習設定<br/>出題数 5/10/20/50/100・対象=全件/ブックマーク"] --> Begin["出題開始（ステータス優先順）"]
    Begin --> Q["問題表示（意味＝日本語）"]
    Q --> Op{"ユーザー操作"}

    Op -->|英語を入力して送信| Judge{"完全一致?"}
    Op -->|ヒント| Hint["先頭1文字を表示"]
    Op -->|答えを見る| Reveal["灰色で全文表示"]

    Hint --> Q
    Reveal --> SetWeak1["status = 苦手"]
    Judge -->|正解・ヒント未使用| SetLearned["status = 覚えた"]
    Judge -->|正解・ヒント使用| SetVague["status = うろ覚え"]
    Judge -->|不正解| SetWeak2["status = 苦手"]

    SetLearned --> Next
    SetVague --> Next
    SetWeak1 --> Next
    SetWeak2 --> Next

    Next{"残り問題?"} -->|あり| Q
    Next -->|なし| Result["結果表示<br/>正答数・ステータス内訳"]
    Result -->|もう一度| Cfg
    Result -->|終了| HomeEnd["ホーム / 一覧"]
```

> ステータス判定の詳細は要件定義書 §5.9 を参照。

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
