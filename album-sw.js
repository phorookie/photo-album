/* 欣赏相册集 · Service Worker
   作用：让 App 可安装、可离线打开。图片与笔记在 IndexedDB，不经过这里。 */
const CACHE = 'album-shell-v3';
const SHELL = [
  './album-manifest.webmanifest',
  './album-icon.svg',
  './album-icon-192.png',
  './album-icon-512.png'
];

function isOurs(url) {
  let p = url.pathname;
  try { p = decodeURIComponent(p); } catch (e) {}
  return p.indexOf('album') >= 0 || p.indexOf('欣赏相册') >= 0;
}

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;
  if (!isOurs(url)) return;               // 不拦截同目录下的其他站点资源

  e.respondWith(
    caches.match(req).then(hit => {
      if (hit) return hit;
      return fetch(req).then(res => {
        const cp = res.clone();
        caches.open(CACHE).then(c => c.put(req, cp));
        return res;
      }).catch(() => {
        if (req.mode === 'navigate') return caches.match('./album.html');
        return new Response('', { status: 504, statusText: 'offline' });
      });
    })
  );
});
