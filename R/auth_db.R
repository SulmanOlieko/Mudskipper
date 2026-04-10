# ==============================================================================
# AUTHENTICATION & WRAPPER LOGIC (Updated for OAuth & SMTP)
# ==============================================================================
library(DBI)
library(RSQLite)
library(sodium)
library(shinyjs)
library(blastula) # Required for emails
library(jose) # Required for decoding ID tokens

# ==============================================================================
# 1. ROBUST DATABASE HELPER (Lazy Initialization + Absolute Path)
# ==============================================================================

# Define absolute path to ensure all parts of the app hit the same file
DB_PATH <- file.path(getwd(), ".users.db")

get_db_connection <- function() {
  con <- dbConnect(RSQLite::SQLite(), DB_PATH)
  
  # AUTO-HEAL: If table is missing, create it immediately
  if (!dbExistsTable(con, "users")) {
    dbExecute(
      con,
      "CREATE TABLE users (
      email TEXT PRIMARY KEY, 
      password_hash TEXT, 
      session_token TEXT, 
      user_id TEXT,
      username TEXT,
      institution TEXT,
      bio TEXT,
      profile_picture TEXT,
      provider TEXT DEFAULT 'email',
      provider_id TEXT,
      reset_token TEXT,
      reset_expiry NUMERIC
    )"
    )
  }
  
  # --- NEW: Session Management Table ---
  if (!dbExistsTable(con, "active_sessions")) {
    dbExecute(
      con,
      "CREATE TABLE active_sessions (
        token TEXT PRIMARY KEY,
        user_id TEXT,
        ip_address TEXT,
        user_agent TEXT,
        created_at NUMERIC,
        last_active NUMERIC
      )"
    )
  }
  # -------------------------------------
  
  # AUTO-MIGRATE: Ensure all columns exist (for older DB files)
  needed_cols <- c(
    "username",
    "institution",
    "bio",
    "profile_picture",
    "provider",
    "provider_id",
    "reset_token",
    "reset_expiry"
  )
  
  existing_cols <- dbListFields(con, "users")
  for (col in needed_cols) {
    if (!(col %in% existing_cols)) {
      tryCatch(
        {
          dbExecute(con, paste0("ALTER TABLE users ADD COLUMN ", col, " TEXT"))
        },
        error = function(e) {
          NULL
        }
      )
    }
  }
  
  return(con)
}

# Run once at startup to ensure DB exists
tryCatch(
  {
    con <- get_db_connection()
    dbDisconnect(con)
  },
  error = function(e) {
    stop(paste("CRITICAL DB ERROR:", e$message))
  }
)


# --- 2. OAuth Configuration Helpers ---
get_oauth_url <- function(provider_state) {
  app_url <- Sys.getenv("APP_URL", "http://127.0.0.1:8000")
  redirect_uri <- app_url

  # The input 'provider_state' will be something like "google_login" or "github_signup"
  # We split it to get the provider name for the URL logic
  parts <- strsplit(provider_state, "_")[[1]]
  provider <- parts[1]

  # Manual URL builder
  build_query_url <- function(base, params) {
    params <- params[!sapply(params, is.null)]
    query_parts <- sapply(names(params), function(k) {
      val <- utils::URLencode(as.character(params[[k]]), reserved = TRUE)
      paste0(k, "=", val)
    })
    paste0(base, "?", paste(query_parts, collapse = "&"))
  }

  if (provider == "google") {
    return(build_query_url(
      "https://accounts.google.com/o/oauth2/v2/auth",
      list(
        client_id = Sys.getenv("GOOGLE_CLIENT_ID"),
        redirect_uri = redirect_uri,
        scope = "openid email profile",
        response_type = "code",
        state = provider_state, # Pass full state (e.g. "google_login")
        access_type = "online",
        prompt = "consent"
      )
    ))
  } else if (provider == "github") {
    return(build_query_url(
      "https://github.com/login/oauth/authorize",
      list(
        client_id = Sys.getenv("GITHUB_CLIENT_ID"),
        redirect_uri = redirect_uri,
        scope = "user:email",
        state = provider_state # Pass full state
      )
    ))
  }
}

exchange_oauth_code <- function(provider, code) {
  app_url <- Sys.getenv("APP_URL", "http://127.0.0.1:3838")
  req <- NULL

  if (provider == "google") {
    req <- request("https://oauth2.googleapis.com/token") %>%
      req_body_form(
        code = code,
        client_id = Sys.getenv("GOOGLE_CLIENT_ID"),
        client_secret = Sys.getenv("GOOGLE_CLIENT_SECRET"),
        redirect_uri = app_url,
        grant_type = "authorization_code"
      )
  } else if (provider == "github") {
    req <- request("https://github.com/login/oauth/access_token") %>%
      req_body_form(
        code = code,
        client_id = Sys.getenv("GITHUB_CLIENT_ID"),
        client_secret = Sys.getenv("GITHUB_CLIENT_SECRET"),
        redirect_uri = app_url
      ) %>%
      req_headers(Accept = "application/json")
  }

  resp <- req_perform(req)
  jsonlite::fromJSON(resp_body_string(resp))
}

get_oauth_user_info <- function(provider, token_data) {
  if (provider == "google") {
    req <- request("https://www.googleapis.com/oauth2/v3/userinfo") %>%
      req_headers(Authorization = paste("Bearer", token_data$access_token))

    info <- jsonlite::fromJSON(resp_body_string(req_perform(req)))

    # Standardize return list
    return(list(
      email = info$email,
      id = info$sub,
      name = info$name,
      picture = info$picture
    ))
  } else if (provider == "github") {
    # Get User Profile
    req <- request("https://api.github.com/user") %>%
      req_headers(Authorization = paste("Bearer", token_data$access_token))
    user <- jsonlite::fromJSON(resp_body_string(req_perform(req)))

    # Get Email (if private)
    email_val <- user$email
    if (is.null(email_val)) {
      req_em <- request("https://api.github.com/user/emails") %>%
        req_headers(Authorization = paste("Bearer", token_data$access_token))
      emails <- jsonlite::fromJSON(resp_body_string(req_perform(req_em)))
      email_val <- emails$email[emails$primary == TRUE][1]
    }

    # Standardize return list
    return(list(
      email = email_val,
      id = as.character(user$id),
      name = if (!is.null(user$name)) user$name else user$login, # Fallback to handle if name is empty
      picture = user$avatar_url
    ))
  }
}

# --- 3. SMTP Helper ---
send_reset_email <- function(to_email, reset_link, smtp_user, smtp_pass) {
  # 1. Clean the password
  clean_pass <- gsub(" ", "", smtp_pass)

  # 2. Set a specific environment variable for this session.
  #    We use a fixed name. Since 'future' isolates the process,
  #    we don't need complex dynamic names.
  Sys.setenv(MUD_TEMP_PASS = clean_pass)

  email <- blastula::compose_email(
    body = blastula::md(paste0(
      "## Password Reset Request\n\n",
      "Click the link below to reset your password:\n\n",
      "[Reset Password](",
      reset_link,
      ")\n\n",
      "If you did not request this, please ignore this email."
    ))
  )

  tryCatch(
    {
      email %>%
        blastula::smtp_send(
          to = to_email,
          from = smtp_user,
          subject = "Reset your Mudskipper password",
          credentials = blastula::creds_envvar(
            user = smtp_user,
            pass_envvar = "MUD_TEMP_PASS", # Points to the var we set above
            host = "smtp.gmail.com",
            port = 465, # Port 465 for Gmail
            use_ssl = TRUE # TRUE for Port 465
          ),
          verbose = TRUE
        )

      # Cleanup
      Sys.unsetenv("MUD_TEMP_PASS")
      return(TRUE)
    },
    error = function(e) {
      # Cleanup
      Sys.unsetenv("MUD_TEMP_PASS")
      warning("SMTP Error Details: ", conditionMessage(e))
      return(FALSE)
    }
  )
}

# --- USER DIRECTORY HELPERS ---
if (!dir.exists("project")) {
  dir.create("project")
}
addResourcePath("project", "project")

getUserBaseDir <- function(userId) {
  if (is.null(userId) || userId == "") {
    return(NULL)
  }
  file.path("project", userId)
}

getUserProjectDir <- function(userId) {
  base <- getUserBaseDir(userId)
  if (is.null(base)) {
    return(NULL)
  }
  file.path(base, "projects")
}

getUserTrashedDir <- function(userId) {
  base <- getUserBaseDir(userId)
  if (is.null(base)) return(NULL)
  file.path(base, "trashed")
}

getUserArchivedDir <- function(userId) {
  base <- getUserBaseDir(userId)
  if (is.null(base)) return(NULL)
  file.path(base, "archived")
}






getUserCommentsDir <- function(userId) {
  base <- getUserBaseDir(userId)
  if (is.null(base)) {
    return(NULL)
  }
  file.path(base, "comments")
}
getUserStatsDir <- function(userId) {
  base <- getUserBaseDir(userId)
  if (is.null(base)) {
    return(NULL)
  }
  file.path(base, "stats")
}
getUserAppCacheDir <- function(userId) {
  base <- getUserBaseDir(userId)
  if (is.null(base)) {
    return(NULL)
  }
  file.path(base, "cache")
}
getUserCompiledDir <- function(userId) {
  base <- getUserBaseDir(userId)
  if (is.null(base)) {
    return(NULL)
  }
  file.path(base, "compiled")
}

initUserDirectories <- function(userId) {
  if (is.null(userId) || userId == "") {
    return()
  }
  dirs <- c(
    getUserBaseDir(userId),
    getUserProjectDir(userId),
    getUserTrashedDir(userId), 
    getUserArchivedDir(userId),
    getUserCommentsDir(userId),
    getUserStatsDir(userId),
    getUserAppCacheDir(userId),
    getUserCompiledDir(userId),
    file.path(getUserCompiledDir(userId), "cache")
  )
  for (d in dirs) {
    if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  }

  profilePath <- file.path(getUserBaseDir(userId), ".profile.json")
  if (!file.exists(profilePath)) {
    defaultProfile <- list(
      userId = userId,
      username = "New User",
      email = "",
      institution = "",
      bio = "",
      profilePicture = "",
      verified = FALSE,
      collaborators = 0,
      memberSince = as.character(Sys.time()),
      lastActive = as.character(Sys.time())
    )
    jsonlite::write_json(
      defaultProfile,
      profilePath,
      auto_unbox = TRUE,
      pretty = TRUE
    )
  }
}
