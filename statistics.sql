-- Jalankan sekali di SQL Editor project Supabase WIDYA PRATAMA CLASS yang baru.
-- Tidak mengubah tabel SISJAR atau data materi.
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



-- Fungsi baca agregat untuk halaman publik.
-- Pengunjung hanya menerima jumlah kunjungan per materi terbit,
-- bukan visitor_id atau detail waktu kunjungan.
create or replace function public.get_public_material_view_counts()
returns table (material_id uuid, view_count bigint)
language sql
stable
security definer
set search_path = public
as $$
  select mv.material_id, count(*)::bigint as view_count
  from public.material_views mv
  join public.materials m on m.id = mv.material_id
  where m.is_published = true
  group by mv.material_id;
$$;

revoke all on function public.get_public_material_view_counts() from public;
grant execute on function public.get_public_material_view_counts() to anon, authenticated;
