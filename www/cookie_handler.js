// www/cookie_handler.js

// 1. Helper to get cookie by name
function getCookie(name) {
  var match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
  if (match) return match[2];
}

// 2. Helper to set cookie
Shiny.addCustomMessageHandler('set_cookie', function(message) {
  var expires = "";
  if (message.days && message.days > 0) {
    var d = new Date();
    d.setTime(d.getTime() + (message.days * 24 * 60 * 60 * 1000));
    expires = "; expires=" + d.toUTCString();
  }
  document.cookie = message.name + "=" + message.value + expires + ";path=/";
  console.log("Cookie set:", message.name);
});

// 3. Helper to delete cookie
Shiny.addCustomMessageHandler('delete_cookie', function(name) {
  document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
  console.log("Cookie deleted:", name);
});

// 4. On App Load: Check for token
$(document).on('shiny:connected', function() {
  console.log("Shiny Connected. Checking for session cookie...");
  
  var token = getCookie("app_session_token");
  const params = new URLSearchParams(window.location.search);
  const isAuthTransition = params.has('code') || params.has('reset_token') || (params.has('action') && params.get('action') === 'password_update_submit');
  
  if (token) {
    console.log("Cookie found! Attempting auto-login.");
    Shiny.setInputValue("cookie_login_token", token, {priority: "event"});
  } else if (isAuthTransition) {
    console.log("No cookie, but Auth transition detected in URL. Preserving preloader.");
    // Do nothing. Let R's server_auth.R handle the UI switch once processing is complete.
  } else {
    console.log("No cookie found. Showing login screen.");
    // Reveal Login Page immediately.
    $('#app-preloader').addClass('fade-out');
    $('#auth_wrapper').show(); 
    $('#main_app_wrapper').hide();
    
    // Remove preloader from DOM after animation
    setTimeout(function() {
      $('#app-preloader').remove();
    }, 6000);
  }
});