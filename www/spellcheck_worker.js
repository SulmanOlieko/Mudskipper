
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

      var regex = /[a-zA-Z']+/g;
      var match;

      while ((match = regex.exec(line)) !== null) {
        var word = match[0];
        if (match.index > 0 && line[match.index - 1] === "\\") continue;
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

