# ----------------------------- PWA ASSETS ------------------------------
# ---- Ensure www/ exists and vendor Split.js locally ----
if (!dir.exists("www")) {
  dir.create("www")
}
split_local <- file.path("www", "split.min.js")
if (!file.exists(split_local)) {
  ok <- FALSE
  urls <- c(
    "https://unpkg.com/split.js/dist/split.min.js",
    "https://cdn.jsdelivr.net/npm/split.js/dist/split.min.js",
    "https://raw.githubusercontent.com/nathancahill/split/master/dist/split.min.js"
  )
  for (u in urls) {
    try(
      {
        utils::download.file(
          u,
          destfile = split_local,
          mode = "wb",
          quiet = TRUE
        )
        ok <- file.exists(split_local) && file.info(split_local)$size > 0
        if (ok) break
      },
      silent = TRUE
    )
  }
  if (!ok) {
    stop(
      "Could not download Split.js to www/split.min.js. Check your connection and try again."
    )
  }
}

# ---- Download logo for offline use ----
logo_local <- file.path("www", "ekonly-logo.svg")
if (!file.exists(logo_local)) {
  ok <- FALSE
  logo_url <- "https://raw.githubusercontent.com/SulmanOlieko/sulmanolieko.github.io/main/img/ekonly-logo.svg"
  try(
    {
      utils::download.file(
        logo_url,
        destfile = logo_local,
        mode = "wb",
        quiet = TRUE
      )
      ok <- file.exists(logo_local) && file.info(logo_local)$size > 0
    },
    silent = TRUE
  )
  if (!ok) {
    warning(
      "Could not download logo to www/ekonly-logo.svg. The app will try to load it online."
    )
  }
}

# ---- Download dictionaries for spell checking ----
dict_aff_local <- file.path("www", "en_US.aff")
if (!file.exists(dict_aff_local)) {
  try(
    {
      utils::download.file(
        "https://raw.githubusercontent.com/cfinke/Typo.js/refs/heads/master/typo/dictionaries/en_US/en_US.aff",
        destfile = dict_aff_local,
        mode = "wb",
        quiet = TRUE
      )
    },
    silent = TRUE
  )
}

dict_dic_local <- file.path("www", "en_US.dic")
if (!file.exists(dict_dic_local)) {
  try(
    {
      utils::download.file(
        "https://raw.githubusercontent.com/cfinke/Typo.js/refs/heads/master/typo/dictionaries/en_US/en_US.dic",
        destfile = dict_dic_local,
        mode = "wb",
        quiet = TRUE
      )
    },
    silent = TRUE
  )
}

if (!file.exists(dict_aff_local) || !file.exists(dict_dic_local)) {
  warning(
    "Could not download spell-check dictionaries. Spell checking will be disabled."
  )
}

sw_path <- file.path("www", "sw.js")

if (!file.exists(sw_path)) {
  writeLines('
const CACHE_NAME = "mudskipper-cache-v78";   
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
', sw_path)
}

manifest_path <- file.path("www", "manifest.json")
if (!file.exists(manifest_path)) {
  writeLines(
    '{
  "name": "Mudskipper",
  "short_name": "Mudskipper",
  "start_url": "./",
  "display": "standalone",
  "background_color": "#18181b",
  "theme_color": "#2fb344",
  "icons": [
    {
      "src": "mudskipper_logo.svg",
      "sizes": "192x192",
      "type": "image/svg"
    }
  ]
}',
    manifest_path
  )
}


# ---- Create Spellcheck Worker (Updated for Dynamic Languages) ----
worker_path <- file.path("www", "spellcheck_worker.js")
writeLines(
  '
importScripts("https://cdn.jsdelivr.net/npm/typo-js@1.0.3/typo.min.js");

var typo;
var isLoaded = false;
var currentLang = "en_US";

// Function to load dictionary from URLs
function loadDictionary(lang, affUrl, dicUrl) {
  isLoaded = false;
  currentLang = lang;
  
  Promise.all([
    fetch(affUrl).then(r => {
        if (!r.ok) throw new Error("Failed to fetch AFF");
        return r.text();
    }),
    fetch(dicUrl).then(r => {
        if (!r.ok) throw new Error("Failed to fetch DIC");
        return r.text();
    })
  ]).then(function(values) {
    try {
      var affData = values[0];
      var dicData = values[1];
      typo = new Typo(lang, affData, dicData);
      isLoaded = true;
      postMessage({type: "ready", lang: lang});
    } catch(e) { 
      console.error("Worker Typo Init Failed", e); 
      postMessage({type: "error", message: "Failed to initialize dictionary"});
    }
  }).catch(function(err) {
    console.error("Dictionary download failed:", err);
  });
}

// Initial Load (Default to local en_US if no message received yet)
loadDictionary("en_US", "en_US.aff", "en_US.dic");

onmessage = function(e) {
  // CASE 0: Load new Language
  if (e.data.command === "load_dictionary") {
    loadDictionary(e.data.lang, e.data.aff, e.data.dic);
    return;
  }

  if (!isLoaded) return;

  // CASE 1: Check Spelling
  if (e.data.lines) {
    var lines = e.data.lines;
    var results = [];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (!line || line.trim().startsWith("%")) continue;

      var regex = /[a-zA-Z\']+/g;
      var match;

      while ((match = regex.exec(line)) !== null) {
        var word = match[0];
        if (match.index > 0 && line[match.index - 1] === "\\\\") continue;
        if (word.length < 2) continue;

        if (!typo.check(word)) {
          results.push({
            row: i,
            col: match.index,
            len: word.length,
            word: word
          });
        }
      }
    }
    postMessage({type: "result", typos: results});
  }
  
  // CASE 2: Get Suggestions
  if (e.data.command === "suggest") {
    var suggestions = typo.suggest(e.data.word);
    
    // Echo back the coordinates and range to the main thread
    postMessage({
      type: "suggestions_ready", 
      list: suggestions, 
      range: e.data.range,
      coords: e.data.coords 
    });
  }
};
',
  worker_path
)
