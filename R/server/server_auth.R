  # Initialize reactive values
  rv <- reactiveValues(
    fileJustLoaded = FALSE,
    block_comment_update = FALSE,
    editor_active = FALSE
  )
  
  # Global Reactive Values (shared across modules)
  rv_files <- reactiveVal(character(0))
  currentFile <- reactiveVal("")
  compileLog <- reactiveVal("")
  rv_compiled <- reactiveVal(character(0))
  dockerLog <- reactiveVal("")
  outlineData <- reactiveVal(NULL)
  lintAnnotations <- reactiveVal(list())
  compileAnnotations <- reactiveVal(list())
  historyActiveFile <- reactiveVal("")
  commentUpdate <- reactiveVal(0)

  # User Session State
  user_session <- reactiveValues(
    logged_in = FALSE,
    user_info = NULL,
    last_code = NULL
  )
  
  projectDashboardState <- reactiveVal("active") # Can be "active", "archived", or "trashed"
  
  # State management for homepage sub-views (dashboard vs profile)
  rv$homeSubView <- "dashboard"
  
  output$isProfileView <- reactive({
    (rv$homeSubView %||% "dashboard") == "profile"
  })
  outputOptions(output, "isProfileView", suspendWhenHidden = FALSE)
  
  observeEvent(input$showProfilePage, {
    rv$homeSubView <- "profile"
  })
  
  observeEvent(input$showDashboard, {
    rv$homeSubView <- "dashboard"
  })
  
  # Observers to listen to UI buttons that swap the dashboard
  observeEvent(input$viewActiveProjects, { 
    projectDashboardState("active") 
    projectChangeTrigger(projectChangeTrigger() + 1)
  })
  observeEvent(input$viewArchivedProjects, { 
    projectDashboardState("archived") 
    projectChangeTrigger(projectChangeTrigger() + 1)
  })
  observeEvent(input$viewTrashedProjects, { 
    projectDashboardState("trashed") 
    projectChangeTrigger(projectChangeTrigger() + 1)
  })

  # --- CRITICAL HELPER: Strict Session Reset ---
  # This wipes all user-specific data from memory to prevent leaks between sessions
  resetUserSession <- function() {
    # 1. Nullify Identity
    user_session$user_info <- NULL
    user_session$logged_in <- FALSE

    # 2. Clear App State
    rv$editor_active <- FALSE
    activeProject(NULL)
    activeProjectId(NULL)
    rv_files(character(0))
    currentFile("")

    # 3. Clear UI
    session$sendCustomMessage("updateProjectURL", NULL)
    updateAceEditor(session, "sourceEditor", value = "")

    # 4. Destroy Observers
    clear_file_observers()
  }

  # --- 0. OAUTH & URL HANDLER ---
  observe({
    query <- parseQueryString(session$clientData$url_search)
    
    # --- A. Handle OAuth Callback ---
    if (!is.null(query$code) && !user_session$logged_in) {
      
      # Prevent loop: Skip if we already processed this code in this session
      if (!is.null(user_session$last_code) && query$code == user_session$last_code) {
        return()
      }
      
      # Default to google_login if state missing
      raw_state <- if (!is.null(query$state)) query$state else "google_login"
      
      # Parse State: e.g. "google_login" -> provider="google", intent="login"
      parts <- strsplit(raw_state, "_")[[1]]
      provider <- parts[1]
      intent <- if (length(parts) > 1) parts[2] else "login"
      
      shinyjs::runjs(sprintf("setPreloaderText('Authenticating with %s...');", tools::toTitleCase(provider)))
      
      tryCatch(
        {
          # 1. Exchange Code for Token
          token_data <- exchange_oauth_code(provider, query$code)
          
          # Mark code as processed *immediately* to prevent re-entry
          user_session$last_code <- query$code
          
          # 2. Get User Info
          user_data <- get_oauth_user_info(provider, token_data)
          email <- user_data$email
          ext_id <- user_data$id
          u_name <- if (!is.null(user_data$name)) user_data$name else "User"
          u_pic <- if (!is.null(user_data$picture)) user_data$picture else ""
          
          # 3. Database Check
          con <- get_db_connection()
          existing <- dbGetQuery(
            con,
            "SELECT * FROM users WHERE email = $1",
            list(email)
          )
          
          uid <- NULL
          
          # --- ACCOUNT LOGIC ---
          if (nrow(existing) == 0) {
            # User does not exist in DB
            if (intent == "login") {
              # Login attempted but no account -> Reject
              poolReturn(con)
              
              # Clean URL immediately to prevent reload loops
              shinyjs::runjs("window.history.replaceState({}, '', window.location.pathname);")
              
              # Redirect to Sign Up Page with Alert
              shinyjs::runjs("setPreloaderText('Account not found...');")
              shinyjs::show("auth_wrapper")
              shinyjs::hide("main_app_wrapper")
              shinyjs::addClass(id = "app-preloader", class = "fade-out")
              
              shinyjs::runjs(
                "
                var frame = document.getElementById('auth_frame');
                frame.src = 'sign_up.html';
                setTimeout(function() { 
                  frame.contentWindow.alert('Account not found. Please sign up to create an account.'); 
                }, 500);
                "
              )
              return()
            }
            
            # Intent is "signup" -> Create User
            uid <- uuid::UUIDgenerate()
            dbExecute(
              con,
              "INSERT INTO users (email, user_id, provider, provider_id, username, profile_picture) VALUES ($1, $2, $3, $4, $5, $6)",
              list(email, uid, provider, ext_id, u_name, u_pic)
            )
          } else {
            # User Exists -> Log In (and update provider info)
            uid <- existing$user_id[1]
            dbExecute(
              con,
              "UPDATE users SET provider = $1, provider_id = $2, username = $3, profile_picture = $4 WHERE email = $5",
              list(provider, ext_id, u_name, u_pic, email)
            )
          }
          
          # --- SUCCESSFUL LOGIN FLOW ---
          resetUserSession() # Wipe previous state
          # 4. Generate Session Token
          session_token <- sodium::bin2hex(sodium::random(16))
          # 5. Robust IP Detection
          ip_addr <- get_ip(session$request)
          
          # 6. INSERT ACTIVE SESSION (Redis-First)
          # We store the session in Redis for high-performance retrieval
          # and in Postgres for persistence/auditing.
          user_data <- list(email = email, user_id = uid, provider = provider)
          redis_create_session(session_token, user_data)
          
          dbExecute(
            con,
            "INSERT INTO active_sessions (token, user_id, ip_address, created_at, last_active) VALUES ($1, $2, $3, $4, $5)",
            list(session_token, uid, ip_addr, as.numeric(Sys.time()), as.numeric(Sys.time()))
          )
            poolReturn(con)
          
          # 7. Initialize Environment
          initUserDirectories(uid)
          
          # Sync Profile JSON File
          profilePath <- file.path(getUserBaseDir(uid), ".profile.json")
          if (file.exists(profilePath)) {
            current_prof <- jsonlite::read_json(
              profilePath,
              simplifyVector = FALSE
            )
            current_prof$username <- u_name
            current_prof$profilePicture <- u_pic
            if (is.null(current_prof$email) || current_prof$email == "") {
              current_prof$email <- email
            }
            jsonlite::write_json(
              current_prof,
              profilePath,
              auto_unbox = TRUE,
              pretty = TRUE
            )
          }
          
          loadUserAppCache(uid)
          
          # 8. Set Session State
          user_session$logged_in <- TRUE
          user_session$token <- session_token # Store current token
          user_session$user_info <- list(
            email = email,
            user_id = uid,
            provider = provider
          )
          
          # 9. Set Browser Cookie
          session$sendCustomMessage(
            "set_cookie",
            list(name = "app_session_token", value = session_token, days = 30)
          )
          
          # 10. Clean Up UI (Fix Lock Screen Issues)
          # Delete the lock cookie so we don't get stuck in a locked state
          shinyjs::runjs("document.cookie = 'app_locked_user=; path=/; max-age=0;'") 
          
          # Clean the URL (remove ?code=...)
          shinyjs::runjs(
            "window.history.replaceState({}, '', window.location.pathname);"
          )
          
          shinyjs::hide("auth_wrapper")
          shinyjs::hide("lock_wrapper") # Explicitly hide lock overlay
          shinyjs::show("main_app_wrapper")
          
          shinyjs::runjs("setPreloaderText('Ready'); window.dispatchEvent(new Event('resize'));")
          shinyjs::addClass(id = "app-preloader", class = "fade-out")
        },
        error = function(e) {
          # --- ERROR HANDLER (Fixes the Infinite Loop) ---
          print(paste("OAuth Error:", e$message))
          
          # If the code is stale (400/401) or invalid, we MUST clean the URL to stop the loop
          if (grepl("400", e$message) || grepl("401", e$message) || grepl("Bad Request", e$message)) {
            shinyjs::runjs("window.history.replaceState({}, '', window.location.pathname);")
            shinyjs::show("auth_wrapper")
            shinyjs::hide("main_app_wrapper")
            shinyjs::hide("lock_wrapper") # Ensure lock screen is gone so they can try logging in again
            shinyjs::runjs("setPreloaderText('Error occurred');")
            shinyjs::addClass(id = "app-preloader", class = "fade-out")
            
            # Optional: Force a reload to clear any internal browser state
            # shinyjs::runjs("window.location.reload();") 
          }
          user_session$last_code <- NULL
        }
      )
    }
    
    # --- B. Handle Password Reset Link (Open Form) ---
    if (!is.null(query$reset_token) && is.null(query$action)) {
      shinyjs::runjs(sprintf(
        "document.getElementById('auth_frame').src = 'reset_password.html?token=%s';",
        query$reset_token
      ))
      shinyjs::show("auth_wrapper")
      shinyjs::hide("main_app_wrapper")
      shinyjs::runjs("setPreloaderText('Ready');")
      shinyjs::addClass(id = "app-preloader", class = "fade-out")
    }
    
    # --- C. Handle Password Reset SUBMISSION ---
    if (!is.null(query$action) && query$action == "password_update_submit") {
      token <- query$token
      new_pass <- query$password
      
      con <- get_db_connection()
      user <- dbGetQuery(
        con,
        "SELECT email, reset_expiry FROM users WHERE reset_token = $1",
        list(token)
      )
      
      current_time <- as.numeric(Sys.time())
      
      if (nrow(user) == 1 && user$reset_expiry > current_time) {
        new_hash <- sodium::password_store(new_pass)
        
        dbExecute(
          con,
          "UPDATE users SET password_hash = $1, reset_token = NULL, reset_expiry = NULL WHERE email = $2",
          list(new_hash, user$email)
        )
        
        showNotification(
          "Password updated successfully! Please log in.",
          type = "message",
          duration = 10
        )
        shinyjs::runjs(
          "window.history.replaceState({}, '', window.location.pathname);"
        )
        
        shinyjs::show("auth_wrapper")
        shinyjs::hide("main_app_wrapper")
        shinyjs::runjs(
          "document.getElementById('auth_frame').src = 'sign_in.html';"
        )
      } else {
        showNotification(
          "Error: This reset link is invalid or has expired.",
          type = "error",
          duration = 10
        )
        shinyjs::runjs(
          "window.history.replaceState({}, '', window.location.pathname);"
        )
      }
      
      if (!is.null(con)) poolReturn(con)
    }
  })

  # --- A. Auto-Login (Cookie) REPLACEMENT ---
  observeEvent(input$cookie_login_token, {
    req(!user_session$logged_in)
    token <- input$cookie_login_token
    shinyjs::runjs("setPreloaderText('Checking session...');")
    
    # 1. TRY REDIS FIRST (Fast Path)
    user <- redis_get_session(token)
    
    if (is.null(user)) {
      # 2. FALLBACK TO POSTGRES (Slow Path)
      con <- get_db_connection()
      user <- tryCatch(
        {
          db_res <- dbGetQuery(
            con,
            "SELECT u.email, u.user_id, u.provider, s.token 
             FROM active_sessions s
             JOIN users u ON s.user_id = u.user_id
             WHERE s.token = $1",
            list(token)
          )
          if (nrow(db_res) == 1) {
            # Sync back to Redis for next time
            res_list <- as.list(db_res[1, ])
            redis_create_session(token, res_list)
            res_list
          } else {
            NULL
          }
        },
        error = function(e) NULL,
        finally = {
          if (!is.null(con)) poolReturn(con)
        }
      )
    }
    
    if (!is.null(user)) {
      # Valid Cookie
      resetUserSession()
      
      user_session$logged_in <- TRUE
      user_session$token <- token # Store current token
      user_session$user_info <- list(
        email = user$email,
        user_id = user$user_id,
        provider = user$provider
      )
      
      # Update Last Active
      con <- get_db_connection()
      dbExecute(con, "UPDATE active_sessions SET last_active = $1 WHERE token = $2", 
                list(as.numeric(Sys.time()), token))
      if (!is.null(con)) poolReturn(con)
      
      initUserDirectories(user$user_id)
      loadUserAppCache(user$user_id)
      
      # Add small delay for readability
      Sys.sleep(0.5)
      
      shinyjs::runjs("setPreloaderText('Initializing workspace...');")
      
      # Final delay before revealing app
      Sys.sleep(0.5)
      
      shinyjs::runjs("$('#auth_wrapper').hide(); $('#main_app_wrapper').show(); window.dispatchEvent(new Event('resize'));")
      shinyjs::runjs("setPreloaderText('Ready');")
      shinyjs::addClass(id = "app-preloader", class = "fade-out")
      showTablerAlert("info", "OAuth success", paste("Welcome back,", user$email))
    } else {
      # Invalid Cookie - CHECK IF WE ARE IN AN AUTH TRANSITION FIRST
      query <- parseQueryString(session$clientData$url_search)
      isAuthTransition <- !is.null(query$code) || !is.null(query$reset_token) || (!is.null(query$action) && query$action == "password_update_submit")
      
      if (!isAuthTransition) {
        shinyjs::runjs("$('#main_app_wrapper').hide(); $('#auth_wrapper').show();")
        shinyjs::runjs("setPreloaderText('Please Sign In');")
        shinyjs::addClass(id = "app-preloader", class = "fade-out")
      } else {
        # Just update text, R is still processing OAuth block
        shinyjs::runjs("setPreloaderText('Verifying credentials...');")
      }
    }
  })
  
  # --- B. Manual Login REPLACEMENT (With Robust IP Detection) ---
  observeEvent(input$login_data, {
    shinyjs::runjs("setPreloaderText('Authenticating...'); $('#app-preloader').removeClass('fade-out').show();")
    
    email <- input$login_data$email
    pass <- input$login_data$password
    remember <- isTRUE(input$login_data$remember)
    
    con <- get_db_connection()
    user_rec <- dbGetQuery(
      con,
      "SELECT password_hash, user_id, provider FROM users WHERE email = $1",
      list(email)
    )
    
    valid <- FALSE
    if (nrow(user_rec) == 1) {
      if (user_rec$provider == 'email' && !is.na(user_rec$password_hash)) {
        if (password_verify(user_rec$password_hash, pass)) valid <- TRUE
      }
    }
    
    if (valid) {
      resetUserSession()
      user_session$logged_in <- TRUE
      uid <- user_rec$user_id
      
      # Generate NEW Session Token
      token <- sodium::bin2hex(sodium::random(16))
      user_session$token <- token
      user_session$user_info <- list(
        email = email,
        user_id = uid,
        provider = 'email'
      )
      
      initUserDirectories(uid)
      loadUserAppCache(uid)
      
      ip_addr <- get_ip(session$request)
      # ---------------------------
      
      # Redis Session
      user_data <- list(email = email, user_id = uid, provider = "email")
      redis_create_session(token, user_data)
      
      dbExecute(
        con,
        "INSERT INTO active_sessions (token, user_id, ip_address, created_at, last_active) VALUES ($1, $2, $3, $4, $5)",
        list(token, uid, ip_addr, as.numeric(Sys.time()), as.numeric(Sys.time()))
      )
      
      session$sendCustomMessage(
        "set_cookie",
        list(
          name = "app_session_token",
          value = token,
          days = if (remember) 30 else 0
        )
      )
      
      shinyjs::hide("auth_wrapper")
      shinyjs::show("main_app_wrapper")
      shinyjs::runjs("window.dispatchEvent(new Event('resize'));")
    } else {
      msg <- if (nrow(user_rec) == 1 && user_rec$provider != 'email') {
        "Please sign in using Google or GitHub."
      } else {
        "Invalid email or password"
      }
      shinyjs::runjs(sprintf("document.getElementById('auth_frame').contentWindow.alert('%s');", msg))
    }
    if (!is.null(con)) poolReturn(con)
  })
  # --- C. Sign Up Logic ---
  observeEvent(input$signup_data, {
    email <- input$signup_data$email
    pass <- input$signup_data$password

    con <- get_db_connection()
    tryCatch(
      {
        pass_hash <- password_store(pass)
        uid <- uuid::UUIDgenerate()
        dbExecute(
          con,
          "INSERT INTO users (email, password_hash, user_id, provider) VALUES ($1, $2, $3, 'email')",
          list(email, pass_hash, uid)
        )
        shinyjs::runjs(
          "document.getElementById('auth_frame').contentWindow.alert('Account created! Please log in.');"
        )
        shinyjs::runjs(
          "document.getElementById('auth_frame').src = 'sign_in.html';"
        )
      },
      error = function(e) {
        shinyjs::runjs(
          "document.getElementById('auth_frame').contentWindow.alert('Email already registered.');"
        )
      },
      finally = {
        if (!is.null(con)) poolReturn(con)
      }
    )
  })

  # --- D. Auth Provider Redirect (Bridge) ---
  observeEvent(input$auth_provider_redirect, {
    # Expects "google_login", "google_signup", "github_login", "github_signup"
    provider_state <- input$auth_provider_redirect
    url <- get_oauth_url(provider_state)
    shinyjs::runjs(sprintf("window.location.href = '%s';", url))
  })

  # --- E. Forgot Password (Send Email) ---
  observeEvent(input$forgot_data, {
    email <- input$forgot_data$email
    con <- get_db_connection()
    user <- dbGetQuery(
      con,
      "SELECT user_id, provider FROM users WHERE email = $1",
      list(email)
    )

    if (nrow(user) == 1 && user$provider == 'email') {
      token <- sodium::bin2hex(sodium::random(16))
      expiry <- as.numeric(Sys.time()) + 3600
      dbExecute(
        con,
        "UPDATE users SET reset_token = $1, reset_expiry = $2 WHERE email = $3",
        list(token, expiry, email)
      )

      reset_link <- paste0(
        Sys.getenv("APP_URL"),
        "/reset_password.html?token=",
        URLencode(token, reserved = TRUE)
      )

      # 1. Capture credentials from the main session
      my_user <- Sys.getenv("SMTP_USER")
      my_pass <- Sys.getenv("SMTP_PASSWORD")

      # 2. Run Async
      future::future({
        # Pass the raw strings into the function
        send_reset_email(email, reset_link, my_user, my_pass)
      }) %...>%
        (function(success) {
          if (success) {
            shinyjs::runjs(
              "document.getElementById('auth_frame').contentWindow.alert('Reset link sent to your email.');"
            )
          } else {
            shinyjs::runjs(
              "document.getElementById('auth_frame').contentWindow.alert('Error: Email failed to send. Check console for logs.');"
            )
          }
        }) %...!%
        (function(err) {
          print(paste("Future Error:", err$message))
          shinyjs::runjs(
            "document.getElementById('auth_frame').contentWindow.alert('An internal error occurred.');"
          )
        })
    } else {
      if (nrow(user) == 1 && user$provider != 'email') {
        shinyjs::runjs(
          "document.getElementById('auth_frame').contentWindow.alert('This account uses Social Login. Please sign in with Google/GitHub.');"
        )
      } else {
        shinyjs::runjs(
          "document.getElementById('auth_frame').contentWindow.alert('If an account exists, a reset link has been sent.');"
        )
      }
    }
    if (!is.null(con)) poolReturn(con)
  })

  # --- G. Navigation Handler ---
  observeEvent(input$auth_page_switch, {
    page <- switch(
      input$auth_page_switch,
      "login" = "sign_in.html",
      "signup" = "sign_up.html",
      "forgot" = "forgot_password.html"
    )
    shinyjs::runjs(sprintf(
      "document.getElementById('auth_frame').src = '%s';",
      page
    ))
  })

  # --- LOCK HANDLER (Auto & Manual) ---
  observeEvent(c(input$app_idle_lock, input$manual_lock_trigger), {
    rv$editor_active <- FALSE
    rv$block_comment_update <- TRUE

    # Update project timestamp
    if (!is.null(activeProject())) {
      updateProjectTimestamp(activeProject())
    }

    # --- FIX: Clean up observers ---
    clear_file_observers()
    # -------------------------------

    # Clear active project persistence
    uid <- isolate(user_session$user_info$user_id)
    if (!is.null(uid)) {
      cacheDir <- getUserAppCacheDir(uid)
      if (!is.null(cacheDir)) {
        apFile <- file.path(cacheDir, "activeProject.txt")
        if (file.exists(apFile)) {
          file.remove(apFile)
        }
      }
    }

    shinyjs::runjs(
      "var l = document.getElementById('dashboardLoader'); if(l) l.classList.remove('show');"
    )

    showHomepage(TRUE)
    activeProject(NULL)
    activeProjectId(NULL)
    rv_files(character(0)) # Clear file list
    session$sendCustomMessage("updateProjectURL", NULL)

    req(user_session$logged_in)
    email <- user_session$user_info$email
    provider <- user_session$user_info$provider %||% "email" # Pass provider

    user_session$logged_in <- FALSE

    con <- get_db_connection()
    dbExecute(
      con,
      "UPDATE users SET session_token = NULL WHERE email = $1",
      list(email)
    )
    if (!is.null(con)) poolReturn(con)

    # Redis Cleanup
    if (!is.null(user_session$token)) {
      redis_delete_session(user_session$token)
    }

    session$sendCustomMessage("delete_cookie", "app_session_token")
    shinyjs::runjs(sprintf(
      "document.cookie = 'app_locked_user=%s; path=/; max-age=31536000';",
      email
    ))

    shinyjs::hide("main_app_wrapper")
    shinyjs::hide("auth_wrapper")
    shinyjs::show("lock_wrapper")

    avatar_ui <- tags$div(
      class = "avatar-xl text-decoration-none",
      style = "pointer-events: none; cursor: default; display: inline-block;",
      HTML(generateAvatarLinkHTML(email))
    )
    avatar_json <- jsonlite::toJSON(as.character(avatar_ui), auto_unbox = TRUE)

    # Pass provider to locked.html
    shinyjs::runjs(sprintf(
      "
      var frame = document.getElementById('lock_frame');
      if(frame && frame.contentWindow) {
        frame.contentWindow.postMessage({
          type: 'set_user', 
          email: '%s', 
          provider: '%s',
          avatar_html: %s 
        }, '*');
      }
    ",
      email,
      provider,
      avatar_json
    ))
  })

  # --- RESTORE LOCK HANDLER (Auto & Manual) ---
  observeEvent(input$restore_lock_state, {
    email <- input$restore_lock_state
    user_session$user_info <- list(email = email)

    shinyjs::hide("auth_wrapper")
    shinyjs::hide("main_app_wrapper")
    shinyjs::show("lock_wrapper")

    # --- PREPARE AVATAR HTML ---
    avatar_ui <- tags$div(
      class = "avatar-xl text-decoration-none",
      style = "pointer-events: none; cursor: default; display: inline-block;",
      HTML(generateAvatarLinkHTML(email))
    )

    avatar_str <- as.character(generateAvatarLinkHTML(email))
    avatar_json <- jsonlite::toJSON(avatar_str, auto_unbox = TRUE)

    # --- SEND TO IFRAME ---
    shinyjs::runjs(sprintf(
      "
    var frame = document.getElementById('lock_frame');
    if(frame && frame.contentWindow) {
      frame.contentWindow.postMessage({
        type: 'set_user', 
        email: '%s', 
        avatar_html: %s 
      }, '*');
    }
  ",
      email,
      avatar_json
    ))
  })

  # --- I. Unlock Handler ---
  observeEvent(input$unlock_attempt, {
    pass <- input$unlock_attempt$password
    # Default to "email" if null to prevent crashes
    provider <- input$unlock_attempt$provider %||% "email" 
    email <- user_session$user_info$email
    
    if (provider != 'email') {
      # --- FIX: OAuth Unlock ---
      # 1. Clear the lock cookie immediately so the returning page loads as a fresh session
      shinyjs::runjs("document.cookie = 'app_locked_user=; path=/; max-age=0;'")
      
      # 2. Construct the provider state (e.g., "google_login")
      provider_state <- paste0(provider, "_login")
      
      # 3. Redirect
      url <- get_oauth_url(provider_state)
      shinyjs::runjs(sprintf("window.location.href = '%s';", url))
      return()
    }
    
    con <- get_db_connection()
    user_rec <- dbGetQuery(con, "SELECT password_hash, user_id FROM users WHERE email = $1", list(email))
    if (!is.null(con)) poolReturn(con)
    
    if (nrow(user_rec) == 1 && password_verify(user_rec$password_hash, pass)) {
      user_session$logged_in <- TRUE
      user_session$user_info$user_id <- user_rec$user_id
      
      # Generate NEW Session Token
      token <- sodium::bin2hex(sodium::random(16))
      user_session$token <- token
      
      initUserDirectories(user_rec$user_id)
      loadUserAppCache(user_rec$user_id)
      
      # Insert into active_sessions
      ip_addr <- "Unknown" 
      if (!is.null(session$request$REMOTE_ADDR)) ip_addr <- session$request$REMOTE_ADDR
      
      con <- get_db_connection()
      # Redis Session
      user_data <- list(email = email, user_id = user_rec$user_id, provider = provider)
      redis_create_session(token, user_data)
      
      dbExecute(con, 
                "INSERT INTO active_sessions (token, user_id, ip_address, created_at, last_active) VALUES ($1, $2, $3, $4, $5)",
                list(token, user_rec$user_id, ip_addr, as.numeric(Sys.time()), as.numeric(Sys.time()))
      )
      if (!is.null(con)) poolReturn(con)
      
      session$sendCustomMessage("set_cookie", list(name = "app_session_token", value = token, days = 0))
      
      # Clear lock cookie
      shinyjs::runjs("document.cookie = 'app_locked_user=; path=/; max-age=0;'")
      
      shinyjs::hide("lock_wrapper")
      shinyjs::show("main_app_wrapper")
      shinyjs::runjs("window.dispatchEvent(new Event('resize'));")
      shinyjs::runjs("document.getElementById('lock_frame').contentWindow.document.getElementById('passwordInput').value = '';")
    } else {
      shinyjs::runjs("document.getElementById('lock_frame').contentWindow.alert('Incorrect password');")
    }
  })

  # --- SWITCH USER HANDLER (From locked.html) ---
  observeEvent(input$lock_switch_user, {
    # 1. Delete the Lock Cookie
    shinyjs::runjs("document.cookie = 'app_locked_user=; path=/; max-age=0;'")
    
    # 2. Delete Session Cookie (Just in case)
    session$sendCustomMessage("delete_cookie", "app_session_token")
    
    # 3. Reload to force fresh login screen
    shinyjs::runjs("window.location.reload();")
  })

  # --- E. Logout Handler REPLACEMENT ---
  observeEvent(input$logout_btn, {
    if (!is.null(activeProject())) {
      updateProjectTimestamp(activeProject())
    }
    
    uid <- isolate(user_session$user_info$user_id)
    if (!is.null(uid)) {
      cacheDir <- getUserAppCacheDir(uid)
      if (!is.null(cacheDir)) {
        apFile <- file.path(cacheDir, "activeProject.txt")
        if (file.exists(apFile)) file.remove(apFile)
      }
    }
    
    # CHANGED: Remove specific session from DB & Redis
    curr_token <- user_session$token
    if (!is.null(curr_token)) {
      # 1. Clean Redis
      redis_delete_session(curr_token)
      
      # 2. Clean Postgres
      con <- get_db_connection()
      dbExecute(con, "DELETE FROM active_sessions WHERE token = $1", list(curr_token))
      if (!is.null(con)) poolReturn(con)
    }
    
    resetUserSession()
    
    shinyjs::runjs("var l = document.getElementById('dashboardLoader'); if(l) l.classList.remove('show');")
    showHomepage(TRUE)
    
    session$sendCustomMessage("delete_cookie", "app_session_token")
    shinyjs::hide("main_app_wrapper")
    shinyjs::runjs("window.location.reload();")
    shinyjs::show("auth_wrapper")
    shinyjs::runjs("document.getElementById('auth_frame').src = 'sign_in.html';")
  })
  
  
  
