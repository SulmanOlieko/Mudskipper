// Create this file at www/latex_wordcounter.js
self.addEventListener('message', function(e) {
    const stats = processLaTeXText(e.data);
    self.postMessage(stats);
});

// Helper to count words and characters in a raw string (stripping remaining LaTeX)
function countCleanText(text) {
    if (!text || text.trim().length === 0) return { words: 0, chars: 0 };

    let clean = text;

    // 1. Remove remaining structural LaTeX commands but keep text content if meaningful
    // (e.g. \textbf{word} -> word)
    // We assume major structures (sections/abstracts) are already extracted, 
    // so this is for formatting commands within those blocks.
    clean = clean.replace(/\\(?:maketitle|tableofcontents|listoffigures|listoftables|appendix|clearpage|newpage|pagebreak|noindent|hfill|vfill)/g, ' ');

    // 2. Handle generic commands \cmd{arg} -> arg
    clean = clean.replace(/\\([a-zA-Z]+\*?)(\[[^\]]*\])?(\{([^{}]|{[^{}]*})*\})?/g, function(match, cmd, opt, arg) {
        // Keep arguments for text-producing commands
        if (/(?:text|emph|bf|it|rm|sf|tt|ul|color|href|url|em|strong|cite|ref)/i.test(cmd)) {
            // Strip outer braces from arg
            return (arg ? arg.replace(/^\{|\}$/g, '') : '') + ' ';
        }
        return ' '; // Remove other commands
    });

    // 3. Remove punctuation and special characters for word counting
    // Keep letters, numbers, and apostrophes
    let wordStr = clean.replace(/[^a-zA-Z0-9\s'\-]/g, ' ').replace(/\s+/g, ' ').trim();
    
    // 4. Character count: we usually count visible characters (excluding whitespace) or all characters.
    // The prompt implies a high char count (~8 chars/word), so we stick to raw length of meaningful text.
    // Let's clean up excessive whitespace for the char count.
    let charStr = clean.replace(/\s+/g, ' ').trim();

    const words = wordStr === '' ? [] : wordStr.split(/\s+/);
    
    return {
        words: words.length,
        chars: charStr.length
    };
}

function processLaTeXText(text) {
    if (!text) return emptyStats();

    let workText = text;

    // --- Step 1: Remove Comments ---
    // Handle % but respect escaped \%
    let lines = workText.split('\n');
    let cleanLines = [];
    for (let i = 0; i < lines.length; i++) {
        let line = lines[i];
        let commentStart = -1;
        let slashCount = 0;
        for (let j = 0; j < line.length; j++) {
            if (line[j] === '\\') slashCount++;
            else if (line[j] === '%') {
                if (slashCount % 2 === 0) { commentStart = j; break; }
                slashCount = 0;
            } else slashCount = 0;
        }
        cleanLines.push(commentStart === -1 ? line : line.substring(0, commentStart));
    }
    workText = cleanLines.join('\n');

    // Initialize Stats
    const stats = emptyStats();

    // Helper to extract patterns and accumulate stats
    function extractPattern(regex, category, isCountOnly = false) {
        workText = workText.replace(regex, function(match, group1) {
            if (isCountOnly) return ' '; // Just remove
            
            // group1 is usually the content inside brackets/envs
            const content = group1 || match; 
            const c = countCleanText(content);
            stats[category].words += c.words;
            stats[category].chars += c.chars;
            
            // Special counter for headers
            if (category === 'headers') stats.headers.count++;
            
            return ' '; // Replace with space to avoid double counting
        });
    }

    // --- Step 2: Extract & Count Math ---
    // Display Math ($$...$$, \[...\], \begin{equation}...)
    const displayMathRegex = /(\$\$[\s\S]*?\$\$|\\\[[\s\S]*?\\\]|\\begin\{equation\*?\}[\s\S]*?\\end\{equation\*?\})/g;
    workText = workText.replace(displayMathRegex, () => { stats.math.display++; return ' '; });
    
    // Inline Math ($...$ or \(...\))
    const inlineMathRegex = /(\$[^$\n]+\$|\\\([\s\S]*?\\\))/g;
    workText = workText.replace(inlineMathRegex, () => { stats.math.inline++; return ' '; });

    // --- Step 3: Extract Specific Sections ---
    
    // Abstract
    extractPattern(/\\begin\{abstract\}([\s\S]*?)\\end\{abstract\}/g, 'abstract');

    // Captions
    extractPattern(/\\caption\{((?:[^{}]|\{[^{}]*\})*)\}/g, 'captions');

    // Footnotes
    extractPattern(/\\footnote\{((?:[^{}]|\{[^{}]*\})*)\}/g, 'footnotes');

    // Headers (section, chapter, etc.)
    extractPattern(/\\(?:section|subsection|subsubsection|chapter|paragraph|subparagraph)\*?\{((?:[^{}]|\{[^{}]*\})*)\}/g, 'headers');

    // --- Step 4: Main Text ---
    // Whatever is left is considered Main Text
    const mainC = countCleanText(workText);
    stats.main.words = mainC.words;
    stats.main.chars = mainC.chars;

    // --- Step 5: Aggregation ---
    // "Total" is the sum of Main + Headers + Abstract + Captions + Footnotes
    // "Other" is currently 0 as per request, unless we define specific environments for it.
    
    const categories = ['main', 'headers', 'abstract', 'captions', 'footnotes', 'other'];
    categories.forEach(cat => {
        stats.total.words += stats[cat].words;
        stats.total.chars += stats[cat].chars;
    });

    return stats;
}

function emptyStats() {
    return {
        total: { words: 0, chars: 0 },
        main: { words: 0, chars: 0 },
        headers: { words: 0, chars: 0, count: 0 },
        abstract: { words: 0, chars: 0 },
        captions: { words: 0, chars: 0 },
        footnotes: { words: 0, chars: 0 },
        other: { words: 0, chars: 0 },
        math: { inline: 0, display: 0 }
    };
}