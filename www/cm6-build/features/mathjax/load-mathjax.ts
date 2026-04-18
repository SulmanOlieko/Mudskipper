let loadPromise = null;

export function loadMathJax() {
  if (window.MathJax && window.MathJax.tex2svgPromise) {
    return Promise.resolve(window.MathJax);
  }
  if (loadPromise) return loadPromise;

  loadPromise = new Promise((resolve) => {
    window.MathJax = {
      tex: {
        packages: {'[+]': ['base', 'ams']}
      },
      startup: {
        typeset: false,
        ready: () => {
          MathJax.startup.defaultReady();
          resolve(window.MathJax);
        }
      }
    };
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js';
    script.async = true;
    document.head.appendChild(script);
  });
  
  return loadPromise;
}
