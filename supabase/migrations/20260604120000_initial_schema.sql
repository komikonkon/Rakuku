-- Rakuku 初期スキーマ（MVP）
-- 設計根拠: docs/er-diagram.md / docs/requirements.md §8
--   - PK名は <entity>_id、型は UUIDv7（クライアント生成が基本、DBはフォールバック）
--   - 監査列: created_at は全テーブル / updated_at は更新が起きるテーブルのみ（audios は不変）
--   - FK: 必須は NOT NULL + ON DELETE CASCADE、任意(items.collection_id)のみ nullable + SET NULL
--   - RLS: 本人のデータのみ（explanations/audios は items 経由で認可）

-- ===== 拡張 =====
create extension if not exists pgcrypto;   -- gen_random_uuid()（v4 フォールバック用）

-- ===== UUID生成ヘルパ =====
-- クライアントが UUIDv7 を生成して INSERT するのを基本とし、本関数は DB側の保険。
-- 時系列の v7 を優先し、未提供環境では v4 にフォールバックする。
create or replace function app_gen_uuid()
returns uuid
language plpgsql
volatile
as $$
begin
  -- Postgres 18 ネイティブ
  begin
    return uuidv7();
  exception when undefined_function then
    null;
  end;
  -- pg_uuidv7 拡張
  begin
    return uuid_generate_v7();
  exception when undefined_function then
    null;
  end;
  -- フォールバック（v4）
  return gen_random_uuid();
end;
$$;

-- ===== updated_at 自動更新トリガ関数 =====
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ===== collections（コレクション／単語帳。MVPは既定1件想定） =====
create table if not exists public.collections (
  collection_id uuid        primary key default app_gen_uuid(),
  user_id       uuid        not null references auth.users(id) on delete cascade,
  name          text        not null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ===== items（保存アイテム） =====
create table if not exists public.items (
  item_id       uuid        primary key default app_gen_uuid(),
  user_id       uuid        not null references auth.users(id) on delete cascade,
  collection_id uuid        references public.collections(collection_id) on delete set null,
  source_text   text        not null,
  item_type     text        not null check (item_type in ('word','phrase')),
  input_method  text        not null check (input_method in ('share','manual','voice')),
  source_url    text,
  source_app    text,
  is_bookmarked boolean     not null default false,
  gen_status    text        not null default 'new' check (gen_status in ('new','generated','error')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ===== explanations（AI生成解説。items と 1対0/1） =====
create table if not exists public.explanations (
  explanation_id uuid        primary key default app_gen_uuid(),
  item_id        uuid        not null unique references public.items(item_id) on delete cascade,
  meaning        text,
  core_image     text,
  nuance         text,
  examples       jsonb       not null default '[]'::jsonb,
  model          text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- ===== audios（音声。クラウドTTS時のみ。不変レコードのため updated_at なし） =====
create table if not exists public.audios (
  audio_id     uuid        primary key default app_gen_uuid(),
  item_id      uuid        not null references public.items(item_id) on delete cascade,
  target       text        not null check (target in ('expression','example')),
  storage_path text,
  created_at   timestamptz not null default now()
);

-- ===== review_states（学習状態。items と 1対1） =====
create table if not exists public.review_states (
  review_state_id  uuid        primary key default app_gen_uuid(),
  item_id          uuid        not null unique references public.items(item_id) on delete cascade,
  user_id          uuid        not null references auth.users(id) on delete cascade,
  status           text        not null default 'not_reviewed'
                     check (status in ('not_reviewed','weak','vague','learned')),
  last_reviewed_at timestamptz,
  last_used_hint   boolean,
  last_revealed    boolean,
  last_correct     boolean,
  review_count     integer     not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- ===== updated_at トリガ（audios を除く） =====
create trigger trg_collections_updated_at   before update on public.collections   for each row execute function set_updated_at();
create trigger trg_items_updated_at         before update on public.items         for each row execute function set_updated_at();
create trigger trg_explanations_updated_at  before update on public.explanations  for each row execute function set_updated_at();
create trigger trg_review_states_updated_at before update on public.review_states for each row execute function set_updated_at();

-- ===== インデックス（docs/er-diagram.md §4） =====
create index if not exists idx_items_user_created    on public.items (user_id, created_at desc);
create index if not exists idx_items_user_bookmarked on public.items (user_id, is_bookmarked);
create index if not exists idx_review_user_status    on public.review_states (user_id, status, last_reviewed_at);
create index if not exists idx_audios_item           on public.audios (item_id);
create index if not exists idx_items_collection      on public.items (collection_id);
-- explanations(item_id) / review_states(item_id) は UNIQUE 制約で索引済み

-- ===== RLS（行レベルセキュリティ） =====
alter table public.collections   enable row level security;
alter table public.items         enable row level security;
alter table public.explanations  enable row level security;
alter table public.audios        enable row level security;
alter table public.review_states enable row level security;

-- user_id を直接持つテーブル: 本人のみ
create policy collections_owner on public.collections
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy items_owner on public.items
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy review_states_owner on public.review_states
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- user_id を持たないテーブル: 親 items を辿って認可
-- （生成は Edge Function の service role で行い RLS をバイパスする想定。閲覧/同期はクライアントから本ポリシーで）
create policy explanations_via_item on public.explanations
  for all
  using (exists (select 1 from public.items i where i.item_id = explanations.item_id and i.user_id = auth.uid()))
  with check (exists (select 1 from public.items i where i.item_id = explanations.item_id and i.user_id = auth.uid()));

create policy audios_via_item on public.audios
  for all
  using (exists (select 1 from public.items i where i.item_id = audios.item_id and i.user_id = auth.uid()))
  with check (exists (select 1 from public.items i where i.item_id = audios.item_id and i.user_id = auth.uid()));
