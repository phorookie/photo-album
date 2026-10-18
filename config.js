/* ============================================================
   欣赏相册集 · 配置文件
   ------------------------------------------------------------
   相册默认纯本地运行（IndexedDB），不依赖任何后端。
   只有想开「云同步」时才需要填下面两行：

   1. Supabase 后台 → SQL Editor → 粘贴 supabase/album-schema.sql → Run
   2. Authentication → Providers → 打开 Anonymous Sign-ins
   3. 把下面 URL / ANON 改成你的 Project URL 和 anon(publishable) key，
      并把 ALBUM_SYNC_ON 改成 true

   不开云同步就保持现状即可，相册功能完整可用。
   anon key 本就设计为可公开，数据安全由 RLS 行级权限保证。
   ============================================================ */
window.SB_CONFIG = {
  URL:  '',
  ANON: ''
};

/* 云同步总开关：false = 只用本地；true = 「⋯」菜单出现云端上传/恢复 */
window.ALBUM_SYNC_ON = false;
