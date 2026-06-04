-- Data API 権限付与（GRANT）
-- プロジェクト作成時に「Automatically expose new tables」を OFF にしたため、
-- マイグレーションで作成したテーブルは anon/authenticated ロールへ権限が自動付与されない。
-- PostgREST 経由でアクセスするために明示的に GRANT する。
-- 行レベルの可視性は各テーブルの RLS ポリシーで制御されるため、CRUD を広く付与しても安全。

-- keepalive: 匿名(anon)で読み取り可能に（凍結回避の活動発生用）
grant select on public.keepalive to anon;

-- アプリ各テーブル: 認証ユーザ(authenticated、匿名サインイン含む)に CRUD を付与
-- ※ 実際に見える/触れる行は RLS（user_id = auth.uid() 等）で限定される
grant select, insert, update, delete on public.collections   to authenticated;
grant select, insert, update, delete on public.items         to authenticated;
grant select, insert, update, delete on public.explanations  to authenticated;
grant select, insert, update, delete on public.audios        to authenticated;
grant select, insert, update, delete on public.review_states to authenticated;
