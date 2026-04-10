
const CACHE_NAME = "mudskipper-cache-v7";   
const URLS_TO_CACHE = [
  "./",    
  "sw.js",
  "manifest.json",
  "split.min.js",  
  "ekonly-logo.svg",
  "en_US.aff", 
  "en_US.dic"   
];

// INSTALL: precache
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(URLS_TO_CACHE))
  );
  self.skipWaiting();
});

// ACTIVATE: cleanup old caches
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// FETCH: cache-first for precached, network fallback
self.addEventListener("fetch", (event) => {
  const req = event.request;
  event.respondWith(
    caches.match(req).then((cached) => {
      if (cached) return cached;
      return fetch(req).then((res) => {
        // Optionally cache GETs from same-origin
        try {
          const url = new URL(req.url);
          if (req.method === "GET" && url.origin === location.origin) {
            const clone = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, clone));
          }
        } catch(e) {}
        return res;
      }).catch(() => cached); // if fetch fails, and we had a cached version, use it
    })
  );
});

