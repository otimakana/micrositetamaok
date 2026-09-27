-- WIDYA PRATAMA CLASS — SUPABASE SETUP
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

create index if not exists materials_category_idx on public.materials(category_id);
create index if not exists materials_published_idx on public.materials(is_published);
create index if not exists materials_created_idx on public.materials(created_at desc);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists materials_updated_at on public.materials;
create trigger materials_updated_at before update on public.materials for each row execute function public.set_updated_at();

alter table public.categories enable row level security;
alter table public.materials enable row level security;

drop policy if exists "Public can read categories" on public.categories;
create policy "Public can read categories" on public.categories for select using (true);

drop policy if exists "Public can read published materials" on public.materials;
create policy "Public can read published materials" on public.materials for select using (is_published = true or auth.uid() is not null);

drop policy if exists "Authenticated can insert materials" on public.materials;
create policy "Authenticated can insert materials" on public.materials for insert to authenticated with check (true);

drop policy if exists "Authenticated can update materials" on public.materials;
create policy "Authenticated can update materials" on public.materials for update to authenticated using (true) with check (true);

drop policy if exists "Authenticated can delete materials" on public.materials;
create policy "Authenticated can delete materials" on public.materials for delete to authenticated using (true);

drop policy if exists "Authenticated can insert categories" on public.categories;
create policy "Authenticated can insert categories" on public.categories for insert to authenticated with check (true);
drop policy if exists "Authenticated can update categories" on public.categories;
create policy "Authenticated can update categories" on public.categories for update to authenticated using (true) with check (true);
drop policy if exists "Authenticated can delete categories" on public.categories;
create policy "Authenticated can delete categories" on public.categories for delete to authenticated using (true);

insert into public.categories(name,slug,icon,description,sort_order) values
('Kimia','kimia','⚗','Materi pembelajaran kimia',1),
('Media Interaktif','media-interaktif','◈','Media digital, simulasi, dan game',2),
('TKA','tka','✦','Latihan dan asesmen TKA',3),
('Perangkat Pembelajaran','perangkat-pembelajaran','▣','RPM, LKPD, modul, dan asesmen',4),
('Workshop','workshop','⌁','Materi workshop dan pengembangan guru',5)
on conflict (slug) do nothing;

insert into public.materials(title,description,category_id,subject,grade,material_type,tags,is_featured,is_published,resource_url)
select 'Redoks Interaktif','Media interaktif untuk penyetaraan reaksi redoks.',id,'Kimia','XII','Media Pembelajaran',array['redoks','interaktif'],true,true,'https://example.com'
from public.categories where slug='kimia' and not exists(select 1 from public.materials where title='Redoks Interaktif');
