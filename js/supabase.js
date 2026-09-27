const sbConfigured = SUPABASE_URL.startsWith('http') && !SUPABASE_ANON_KEY.includes('YOUR_');
const supabaseClient = sbConfigured ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;
function requireSupabase(){ if(!supabaseClient) throw new Error('Supabase belum dikonfigurasi. Isi js/config.js terlebih dahulu.'); return supabaseClient; }
