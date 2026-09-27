# WIDYA PRATAMA CLASS — Learning Resource Hub

Microsite library untuk menyimpan dan membagikan materi pembelajaran secara online.

## Stack
- Static HTML/CSS/JavaScript
- GitHub Pages
- Supabase Database + Auth

## 1. Buat project Supabase
Buat project baru di Supabase. Buka **SQL Editor**, lalu jalankan seluruh isi `supabase.sql`.

## 2. Buat akun admin
Di Supabase: **Authentication → Users → Add user**. Buat email dan password admin.

## 3. Ambil API credentials
Di Supabase: **Project Settings → API**. Salin:
- Project URL
- Publishable/anon key

Masukkan ke `js/config.js`:
```js
const SUPABASE_URL = 'https://PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```
Jangan pernah memasukkan `service_role` key ke frontend.

## 4. Jalankan lokal
Buka project dengan VS Code. Untuk pengalaman terbaik gunakan Live Server extension, lalu buka `index.html` melalui Live Server.

## 5. Deploy ke GitHub Pages
1. Buat repository baru di GitHub, misalnya `widya-pratama-class`.
2. Upload seluruh isi folder project.
3. Buka **Settings → Pages**.
4. Source: **Deploy from a branch**.
5. Branch: `main`, folder `/root`.
6. Save.
7. Tunggu GitHub Pages membuat URL.

## 6. Menambah materi
Buka:
`https://USERNAME.github.io/NAMA-REPOSITORY/admin.html`

Login menggunakan akun Supabase.

Klik **Tambah Materi**. Isi judul, kategori, tipe, kelas, dan link. Setelah disimpan, materi langsung muncul di public library.

## Catatan keamanan
RLS sudah diaktifkan dalam SQL. Public hanya membaca materi published. Operasi tambah/edit/hapus memerlukan login Supabase.

Untuk produksi dengan beberapa level pengguna, sebaiknya tambahkan tabel role/profile sehingga hanya user admin/editor tertentu yang boleh melakukan CRUD.
