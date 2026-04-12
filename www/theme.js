document.addEventListener("DOMContentLoaded", function () {
  var themeConfig = {
    "theme": "dark",
    "theme-base": "zinc",
    "theme-font": "sans-serif",
    "theme-primary": "green",
    "theme-radius": "1",
  };
  
  var url = new URL(window.location);
  var form = document.getElementById("offcanvasSettings");
  var resetButton = document.getElementById("reset-changes");
  
  // Function to forcefully check form items - unconventional but guaranteed
  var checkItems = function () {
    // Small delay to ensure DOM is fully ready
    setTimeout(function() {
      if (!form) return;
      for (var key in themeConfig) {
        var value = window.localStorage["tabler-" + key] || themeConfig[key];
        if (!!value) {
          var inputs = form.querySelectorAll(`[name="${key}"]`);
          if (!!inputs && inputs.length > 0) {
            inputs.forEach((input) => {
              if (input.value === value) {
                input.checked = true;
                // Force attribute update
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
  
  // Initialize URL with current settings from localStorage
  var initializeUrl = function () {
    for (var key in themeConfig) {
      var value = window.localStorage["tabler-" + key];
      if (value && value !== themeConfig[key]) {
        url.searchParams.set(key, value);
      }
    }
    window.history.replaceState({}, "", url);
  };
  
  // Handle form changes - update in real-time AND update URL
  if (form) {
    form.addEventListener("change", function (event) {
      var target = event.target,
        name = target.name,
        value = target.value;
      
      for (var key in themeConfig) {
        if (name === key) {
          document.documentElement.setAttribute("data-bs-" + key, value);
          window.localStorage.setItem("tabler-" + key, value);
          url.searchParams.set(key, value);
        }
      }
      
      // Update URL without reload
      window.history.pushState({}, "", url);
    });
  }
  
  // Handle Reset button click
  if (resetButton) {
    resetButton.addEventListener("click", function () {
      for (var key in themeConfig) {
        var value = themeConfig[key];
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
  
  // Ensure default color is selected if none is checked
  setTimeout(function() {
    if (!form.querySelector('[name="theme-primary"]:checked')) {
      var defaultColor = form.querySelector('[name="theme-primary"][value="green"]');
      if (defaultColor) {
        defaultColor.checked = true;
        defaultColor.setAttribute('checked', 'checked');
      }
    }
  }, 150);
  
  // Re-check items when tab is shown (for Bootstrap tabs)
  document.addEventListener('shown.bs.tab', function (event) {
    if (form.closest('.tab-pane') && form.closest('.tab-pane').classList.contains('active')) {
      checkItems();
    }
  });
  
  // Also check when clicking on the tab itself
  var settingsTab = document.querySelector('[data-bs-toggle="tab"][href*="settings"], [data-bs-toggle="tab"][data-bs-target*="settings"]');
  if (settingsTab) {
    settingsTab.addEventListener('click', function() {
      setTimeout(checkItems, 50);
    });
  }
});

// URL parameter handling (keep your existing code)
var themeConfig2 = {
  "theme": "dark",
  "theme-base": "zinc",
  "theme-font": "sans-serif",
  "theme-primary": "green",
  "theme-radius": "1",
}

var params = new Proxy(new URLSearchParams(window.location.search), {
  get: (searchParams, prop) => searchParams.get(prop),
})

for (const key in themeConfig2) {
  const param = params[key]
  let selectedValue

  if (!!param) {
    localStorage.setItem('tabler-' + key, param)
    selectedValue = param
  } else {
    const storedTheme = localStorage.getItem('tabler-' + key)
    selectedValue = storedTheme ? storedTheme : themeConfig2[key]
  }

  // Always set the attribute even if it matches the default, to ensure consistency across pages
  document.documentElement.setAttribute('data-bs-' + key, selectedValue)
}

var saveSettingsBtn = document.getElementById('save-settings');
if (saveSettingsBtn) {
  saveSettingsBtn.addEventListener('click', function(e) {
    e.preventDefault();
    
    // Build query string manually
    var params = [];
    var form = document.getElementById("offcanvasSettings");
    
    // Check if form exists before querying it to prevent errors inside the click handler
    if (form) {
      params.push('theme=' + form.querySelector('[name="theme"]:checked').value);
      params.push('theme-primary=' + form.querySelector('[name="theme-primary"]:checked').value);
      params.push('theme-font=' + form.querySelector('[name="theme-font"]:checked').value);
      params.push('theme-base=' + form.querySelector('[name="theme-base"]:checked').value);
      params.push('theme-radius=' + form.querySelector('[name="theme-radius"]:checked').value);
      
      // Simple redirect
      window.location.href = window.location.pathname + '?' + params.join('&');
    }
  });
}
