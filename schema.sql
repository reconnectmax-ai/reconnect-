-- ============================================================
-- JALANKAN INI DI: Supabase Dashboard > SQL Editor > New Query
-- (bisa dibuka & dijalankan langsung dari browser HP)
-- ============================================================

-- 1. Tabel profile tiap user
create table profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) unique not null,
  username text unique not null,
  name text not null default '',
  bio text default '',
  avatar_emoji text default '🌱',
  links jsonb default '[]',
  created_at timestamptz default now()
);

-- 2. Tabel grup/circle (mis. "seeking")
create table groups (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  sub text default '',
  bio text default '',
  photos jsonb default '[]',
  created_at timestamptz default now()
);

-- 3. Tabel penghubung: siapa saja member grup apa
create table group_members (
  group_id uuid references groups(id) on delete cascade,
  profile_id uuid references profiles(id) on delete cascade,
  primary key (group_id, profile_id)
);

-- ============================================================
-- ROW LEVEL SECURITY: siapa boleh baca/tulis apa
-- ============================================================
alter table profiles enable row level security;
alter table groups enable row level security;
alter table group_members enable row level security;

-- Semua orang boleh BACA profile, grup, dan member (portfolio itu publik)
create policy "profiles are public to read" on profiles
  for select using (true);
create policy "groups are public to read" on groups
  for select using (true);
create policy "group_members are public to read" on group_members
  for select using (true);

-- User hanya boleh EDIT profile miliknya sendiri
create policy "users can insert own profile" on profiles
  for insert with check (auth.uid() = user_id);
create policy "users can update own profile" on profiles
  for update using (auth.uid() = user_id);

-- User yang login boleh gabung grup atas nama profile-nya sendiri
create policy "users can join a group as themselves" on group_members
  for insert with check (
    profile_id in (select id from profiles where user_id = auth.uid())
  );

-- Catatan: tabel "groups" sengaja TIDAK punya policy insert/update publik.
-- Kamu (admin) yang bikin/ubah grup langsung lewat Supabase Dashboard > Table Editor,
-- supaya isi grup "Seeking" tetap terkontrol.
