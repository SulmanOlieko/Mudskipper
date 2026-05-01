(function() {
  const themeConfig = {
    "theme": "dark",
    "theme-base": "zinc",
    "theme-font": "sans-serif",
    "theme-primary": "green",
    "theme-radius": "1",
  };
  
  const url = new URL(window.location);
  const form = document.getElementById("offcanvasSettings");
  const resetButton = document.getElementById("reset-changes");
  
  const checkItems = function () {
    if (!form) return;
    setTimeout(function() {
      for (const key in themeConfig) {
        const value = window.localStorage["tabler-" + key] || themeConfig[key];
        if (value) {
          const inputs = form.querySelectorAll(`[name="${key}"]`);
          if (inputs && inputs.length > 0) {
            inputs.forEach((input) => {
              if (input.value === value) {
                input.checked = true;
                input.setAttribute('checked', 'checked');
              } else {
                input.checked = false;
                input.removeAttribute('checked');
              }
            });
          }
        }
      }
    }, 100);
  };
  
  const initializeUrl = function () {
    for (const key in themeConfig) {
      const value = window.localStorage["tabler-" + key];
      if (value && value !== themeConfig[key]) {
        url.searchParams.set(key, value);
      }
    }
    window.history.replaceState({}, "", url);
  };
  
  if (form) {
    form.addEventListener("change", function (event) {
      const target = event.target;
      const name = target.name;
      const value = target.value;
      
      for (const key in themeConfig) {
        if (name === key) {
          document.documentElement.setAttribute("data-bs-" + key, value);
          window.localStorage.setItem("tabler-" + key, value);
          url.searchParams.set(key, value);
        }
      }
      window.history.pushState({}, "", url);
    });
  }
  
  if (resetButton) {
    resetButton.addEventListener("click", function () {
      for (const key in themeConfig) {
        const value = themeConfig[key];
        document.documentElement.setAttribute("data-bs-" + key, value);
        window.localStorage.removeItem("tabler-" + key);
        url.searchParams.delete(key);
      }
      checkItems();
      window.history.pushState({}, "", url);
    });
  }
  
  checkItems();
  initializeUrl();
  
  setTimeout(function() {
    if (form) {
      const checked = form.querySelector('[name="theme-primary"]:checked');
      if (!checked) {
        const defaultColor = form.querySelector('[name="theme-primary"][value="green"]');
        if (defaultColor) {
          defaultColor.checked = true;
          defaultColor.setAttribute('checked', 'checked');
        }
      }
    }
  }, 150);
  
  document.addEventListener('shown.bs.tab', function (event) {
    if (form) {
      const pane = form.closest('.tab-pane');
      if (pane && pane.classList.contains('active')) {
        checkItems();
      }
    }
  });
  
  const settingsTab = document.querySelector('[data-bs-toggle="tab"][href*="settings"], [data-bs-toggle="tab"][data-bs-target*="settings"]');
  if (settingsTab) {
    settingsTab.addEventListener('click', function() {
      setTimeout(checkItems, 50);
    });
  }

  const saveSettingsBtn = document.getElementById('save-settings');
  if (saveSettingsBtn) {
    saveSettingsBtn.addEventListener('click', function(e) {
      e.preventDefault();
      const settingsForm = document.getElementById("offcanvasSettings");
      if (settingsForm) {
        const params = [];
        const configKeys = ["theme", "theme-primary", "theme-font", "theme-base", "theme-radius"];
        configKeys.forEach(key => {
          const checked = settingsForm.querySelector(`[name="${key}"]:checked`);
          if (checked) params.push(`${key}=${checked.value}`);
        });
        window.location.href = window.location.pathname + '?' + params.join('&');
      }
    });
  }
})();

// Global parameter sync (runs immediately)
(function() {
  const themeConfig = {
    "theme": "dark",
    "theme-base": "zinc",
    "theme-font": "sans-serif",
    "theme-primary": "green",
    "theme-radius": "1",
  };
  const searchParams = new URLSearchParams(window.location.search);
  for (const key in themeConfig) {
    const param = searchParams.get(key);
    let selectedValue;
    if (param) {
      localStorage.setItem('tabler-' + key, param);
      selectedValue = param;
    } else {
      const storedTheme = localStorage.getItem('tabler-' + key);
      selectedValue = storedTheme ? storedTheme : themeConfig[key];
    }
    document.documentElement.setAttribute('data-bs-' + key, selectedValue);
  }
})();
