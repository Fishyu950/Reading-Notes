const CACHE_NAME = 'reading-notes-v16';

const PRECACHE_URLS = [
  '/Reading-Notes/',
  '/Reading-Notes/index.html',
  '/Reading-Notes/read%20app%20icon.svg',
  '/Reading-Notes/read%20app%20icon1.png',
  '/Reading-Notes/read%20app%20icon_%E5%B7%A5%E4%BD%9C%E5%8D%80%E5%9F%9F%201.png',
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(PRECACHE_URLS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  // 只處理 GET，忽略 POST / chrome-extension 等
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).then(response => {
        // 只快取同源的成功回應
        if (!response || response.status !== 200 || response.type !== 'basic') {
          return response;
        }
        const clone = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        return response;
      });
    })
  );
});
