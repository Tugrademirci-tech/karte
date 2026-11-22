const V = 'navi-v1';
const SHELL = [
  './',
  './index.html',
  'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js',
  'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(V).then(c => Promise.allSettled(SHELL.map(u => c.add(u)))).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== V).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});

self.addEventListener('fetch', e => {
  const r = e.request;
  if (r.method !== 'GET') return;
  const h = new URL(r.url).hostname;
  // Routing & Suche laufen immer direkt übers Netz (die App speichert Ergebnisse selbst)
  if (h.includes('routing.openstreetmap.de') || h.includes('nominatim')) return;

  // Cache zuerst (schnell/offline), im Hintergrund aktualisieren, sobald online
  e.respondWith(caches.open(V).then(async c => {
    const hit = await c.match(r, { ignoreSearch: false });
    const net = fetch(r).then(res => {
      if (res && (res.ok || res.type === 'opaque')) c.put(r, res.clone());
      return res;
    }).catch(() => null);
    return hit || (await net) || (r.mode === 'navigate' ? c.match('./index.html') : Response.error());
  }));
});
