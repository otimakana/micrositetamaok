-- WIDYA PRATAMA CLASS — Supabase setup (dedicated Library project)
-- Jalankan HANYA pada project baru: ojtvsmhyrslvotfrrzfo
-- Tidak menyentuh project/database SISJAR.

create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  icon text default '✦',
  description text,
  color text,
  sort_order integer default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text,
  description text,
  category_id uuid references public.categories(id) on delete set null,
  subject text,
  grade text,
  semester text,
  material_type text not null default 'Website',
  thumbnail_url text,
  resource_url text,
  external_url text,
  tags text[] default '{}',
  is_featured boolean not null default false,
  is_published boolean not null default true,
  sort_order integer default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists materials_category_idx on public.materials(category_id);
create index if not exists materials_published_idx on public.materials(is_published);
create index if not exists materials_created_idx on public.materials(created_at desc);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists materials_updated_at on public.materials;
create trigger materials_updated_at before update on public.materials
for each row execute function public.set_updated_at();

alter table public.categories enable row level security;
alter table public.materials enable row level security;
alter table public.admin_users enable row level security;

-- Users can only see their own admin membership.
drop policy if exists "Admin can read own membership" on public.admin_users;
create policy "Admin can read own membership" on public.admin_users
for select to authenticated using (user_id = auth.uid());

-- Public can read categories.
drop policy if exists "Public can read categories" on public.categories;
create policy "Public can read categories" on public.categories
for select to anon, authenticated using (true);

-- Public reads published materials only; admins can also read drafts.
drop policy if exists "Public can read published materials" on public.materials;
create policy "Public can read published materials" on public.materials
for select to anon, authenticated
using (is_published = true or exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));

-- Only explicitly registered admins can manage materials/categories.
drop policy if exists "Admin can insert materials" on public.materials;
create policy "Admin can insert materials" on public.materials
for insert to authenticated with check (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
);
drop policy if exists "Admin can update materials" on public.materials;
create policy "Admin can update materials" on public.materials
for update to authenticated using (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
) with check (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
);
drop policy if exists "Admin can delete materials" on public.materials;
create policy "Admin can delete materials" on public.materials
for delete to authenticated using (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
);

drop policy if exists "Admin can insert categories" on public.categories;
create policy "Admin can insert categories" on public.categories
for insert to authenticated with check (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
);
drop policy if exists "Admin can update categories" on public.categories;
create policy "Admin can update categories" on public.categories
for update to authenticated using (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
) with check (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
);
drop policy if exists "Admin can delete categories" on public.categories;
create policy "Admin can delete categories" on public.categories
for delete to authenticated using (
  exists (select 1 from public.admin_users a where a.user_id = auth.uid())
);

insert into public.categories(name,slug,icon,description,sort_order) values
('Kimia','kimia','⚗','Materi pembelajaran kimia',1),
('Media Interaktif','media-interaktif','◈','Media digital, simulasi, dan game',2),
('TKA','tka','✦','Latihan dan asesmen TKA',3),
('Perangkat Pembelajaran','perangkat-pembelajaran','▣','RPM, LKPD, modul, dan asesmen',4),
('Workshop','workshop','⌁','Materi workshop dan pengembangan guru',5)
on conflict (slug) do nothing;

-- BOOTSTRAP ADMIN:
-- 1. Buat user melalui Authentication > Users > Add user.
-- 2. Salin UUID user tersebut.
-- 3. Jalankan query ini di SQL Editor dengan UUID asli:
-- insert into public.admin_users(user_id) values ('PASTE-AUTH-USER-UUID-HERE') on conflict do nothing;


-- STORAGE: thumbnail materi (gambar sampul bersifat publik untuk ditampilkan di Library)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('material-thumbnails', 'material-thumbnails', true, 5242880, array['image/png','image/jpeg','image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Semua pengunjung boleh membaca thumbnail publik.
drop policy if exists "Public can view material thumbnails" on storage.objects;
create policy "Public can view material thumbnails" on storage.objects
for select to anon, authenticated
using (bucket_id = 'material-thumbnails');

-- Hanya user yang terdaftar sebagai admin Library boleh mengunggah/mengubah/menghapus thumbnail.
drop policy if exists "Admins can upload material thumbnails" on storage.objects;
create policy "Admins can upload material thumbnails" on storage.objects
for insert to authenticated
with check (bucket_id = 'material-thumbnails' and exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));

drop policy if exists "Admins can update material thumbnails" on storage.objects;
create policy "Admins can update material thumbnails" on storage.objects
for update to authenticated
using (bucket_id = 'material-thumbnails' and exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
))
with check (bucket_id = 'material-thumbnails' and exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));

drop policy if exists "Admins can delete material thumbnails" on storage.objects;
create policy "Admins can delete material thumbnails" on storage.objects
for delete to authenticated
using (bucket_id = 'material-thumbnails' and exists (
  select 1 from public.admin_users a where a.user_id = auth.uid()
));


-- STATISTIK KUNJUNGAN MATERI
-- Setiap klik "Buka materi" membuat satu baris kunjungan.
-- visitor_id disimpan di browser (localStorage) agar pengunjung unik dapat dihitung
-- secara pseudonim tanpa menyimpan nama, email, atau alamat IP.
create table if not exists public.material_views (
  id bigint generated always as identity primary key,
  material_id uuid not null references public.materials(id) on delete cascade,
  visitor_id text not null,
  visited_at timestamptz not null default now()
);
create index if not exists material_views_material_idx on public.material_views(material_id);
create index if not exists material_views_visited_idx on public.material_views(visited_at desc);
create index if not exists material_views_visitor_idx on public.material_views(visitor_id);
alter table public.material_views enable row level security;
drop policy if exists "Visitors can record published material views" on public.material_views;
create policy "Visitors can record published material views" on public.material_views
for insert to anon, authenticated
with check (
  length(visitor_id) between 10 and 100
  and exists (select 1 from public.materials m where m.id = material_id and m.is_published = true)
);
drop policy if exists "Admins can read material views" on public.material_views;
create policy "Admins can read material views" on public.material_views
for select to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));
grant insert on public.material_views to anon, authenticated;
grant select on public.material_views to authenticated;
