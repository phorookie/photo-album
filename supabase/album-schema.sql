-- ============================================================
--  欣赏相册集 · 云同步结构（Supabase）
--  用法：Supabase 后台 → SQL Editor → New query → 整段粘贴 → Run
--  只做「新增」，不会动你现有的 passwords / admin_settings 表。
-- ============================================================

-- ---------- 1. 状态表：整个相册存成一行（分类树 + 标签 + 图片元数据） ----------
create table if not exists public.album_state (
  user_id     uuid primary key references auth.users on delete cascade,
  categories  jsonb not null default '[]'::jsonb,
  tags        jsonb not null default '[]'::jsonb,
  items       jsonb not null default '[]'::jsonb,   -- 元数据；图片本体在 Storage
  updated_at  timestamptz not null default now()
);

alter table public.album_state enable row level security;

drop policy if exists "album_state own read"   on public.album_state;
drop policy if exists "album_state own insert" on public.album_state;
drop policy if exists "album_state own update" on public.album_state;

create policy "album_state own read"   on public.album_state for select using (auth.uid() = user_id);
create policy "album_state own insert" on public.album_state for insert with check (auth.uid() = user_id);
create policy "album_state own update" on public.album_state for update using (auth.uid() = user_id);

-- ---------- 2. 图片桶：路径固定为 <用户id>/<图片id>.<扩展名> ----------
insert into storage.buckets (id, name, public)
values ('album-images', 'album-images', false)
on conflict (id) do nothing;

drop policy if exists "album images own read"   on storage.objects;
drop policy if exists "album images own upload" on storage.objects;
drop policy if exists "album images own delete" on storage.objects;

create policy "album images own read"   on storage.objects for select
  using (bucket_id = 'album-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "album images own upload" on storage.objects for insert
  with check (bucket_id = 'album-images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "album images own delete" on storage.objects for delete
  using (bucket_id = 'album-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- 3. 开启匿名登录（零门槛，一人一库） ----------
-- Supabase 后台 → Authentication → Providers → Anonymous Sign-ins → 打开
-- （如只想用邮箱登录，可跳过这步，并告诉我改成邮箱魔法链接）
