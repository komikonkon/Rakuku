-- keepalive テーブル
-- 日次の GitHub Actions ワークフロー（.github/workflows/supabase-keepalive.yml）から
-- SELECT され、Supabase 無料プロジェクトが無活動で停止するのを防ぐ。
-- 1行だけ持つシングルトンテーブル。

create table if not exists public.keepalive (
  id        smallint primary key default 1,
  last_ping timestamptz not null default now(),
  constraint keepalive_singleton check (id = 1)
);

insert into public.keepalive (id) values (1)
  on conflict (id) do nothing;

-- 公開 anon キーでの読み取りを許可（ヘルスチェック用途）。
alter table public.keepalive enable row level security;

create policy "keepalive readable by anyone"
  on public.keepalive
  for select
  using (true);
