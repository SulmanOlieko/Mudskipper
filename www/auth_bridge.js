// www/auth_bridge.js
document.addEventListener('DOMContentLoaded', function() {
  
  function sendToShiny(id, data) {
    if (window.parent && window.parent.Shiny) {
      window.parent.Shiny.setInputValue(id, data);
    }
  }


  // --- FORGOT PASSWORD SUBMIT (New) ---
  const forgotSubmitBtn = document.getElementById('submit_forgot');
  if (forgotSubmitBtn) {
    forgotSubmitBtn.addEventListener('click', function(e) {
      e.preventDefault();
      const email = document.getElementById('forgot_email').value;
      if(email) {
        sendToShiny('forgot_data', {email: email, nonce: Math.random()});
      }
    });
  }
  
  // --- RESET PASSWORD SUBMIT (New for reset page) ---
  const resetBtn = document.getElementById('submit_reset');
  if (resetBtn) {
    resetBtn.addEventListener('click', function(e) {
      e.preventDefault();
      const p1 = document.getElementById('reset_password').value;
      const p2 = document.getElementById('reset_password_confirm').value;
      const urlParams = new URLSearchParams(window.location.search);
      const token = urlParams.get('token');
      
      if(p1 !== p2) {
        alert("Passwords do not match");
        return;
      }
      sendToShiny('reset_password_data', {token: token, password: p1, nonce: Math.random()});
    });
  }

  // --- LOGIN ---
  const loginBtn = document.getElementById('submit_login');
  if (loginBtn) {
    loginBtn.addEventListener('click', function(e) {
      e.preventDefault();
      const email = document.getElementById('email').value;
      const pass = document.getElementById('password').value;
      const checkbox = document.getElementById('remember_me');
      const remember = checkbox ? checkbox.checked : false;

      sendToShiny('login_data', {
          email: email, 
          password: pass, 
          remember: remember, 
          nonce: Math.random()
      });
    });
  }

  // --- SIGNUP LOGIC ---
  const signupBtn = document.getElementById('submit_signup');
  if (signupBtn) {
    signupBtn.addEventListener('click', function(e) {
      e.preventDefault();
      const email = document.getElementById('signup_email').value;
      const pass = document.getElementById('signup_password').value;
      sendToShiny('signup_data', {email: email, password: pass, nonce: Math.random()});
    });
  }

  // --- NAVIGATION LINKS ---
  const linkSignup = document.getElementById('goto_signup');
  if (linkSignup) {
    linkSignup.addEventListener('click', function(e) {
      e.preventDefault();
      sendToShiny('auth_page_switch', 'signup');
    });
  }

  const linkLogin = document.getElementById('goto_login');
  if (linkLogin) {
    linkLogin.addEventListener('click', function(e) {
      e.preventDefault();
      sendToShiny('auth_page_switch', 'login');
    });
  }
  
  const linkForgot = document.getElementById('goto_forgot');
  if (linkForgot) {
    linkForgot.addEventListener('click', function(e) {
      e.preventDefault();
      sendToShiny('auth_page_switch', 'forgot');
    });
  }
});