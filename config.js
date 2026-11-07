/* ============================================================
   欣赏相册集 · 配置文件
   ------------------------------------------------------------
   相册是纯本地应用（IndexedDB），不依赖任何后端、也不联网。

   云同步已停用：URL / ANON 留空，ALBUM_SYNC_ON 保持 false。
   此时「⋯」菜单不会出现云端上传/恢复，页面不会请求任何外部资源。

   如果以后想恢复云同步，需要同时做三件事：
   1. 在 album.html 的 head 里加回这行 SDK 引用：
      <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
   2. Supabase 后台执行 supabase/album-schema.sql，并在
      Authentication -> Providers -> Email 开启邮箱登录、关闭 Confirm email
   3. 把下面 URL / ANON 填成你的 Project URL 与 anon key，并把开关置 true
   ============================================================ */
window.SB_CONFIG = {
  URL:  '',
  ANON: ''
};

/* 云同步总开关：false = 只用本地；true = 「⋯」菜单出现云端上传/恢复 */
window.ALBUM_SYNC_ON = false;
