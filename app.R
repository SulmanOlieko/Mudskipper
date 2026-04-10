# =============================================================================
# app.R — Mudskipper Entry Point
#
# This file is intentionally minimal. All logic lives in R/ modules:
#
#   R/00_globals.R          — Libraries & constants
#   R/01_assets.R           — PWA asset bootstrapping (Split.js, dicts, SW, manifest)
#   R/02_illustrations.R    — SVG helper functions
#   R/03_html_pages.R       — Inline HTML page writers (presentation.html, etc.)
#   R/04_auth_db.R          — Database helpers, OAuth config, SMTP, user directories
#   R/05_compile_worker.R   — compile_bg_task(), parse_tex_log(), get_ip()
#   R/ui/ui_main.R          — Full editor UI (app_ui)
#   R/ui/ui_wrapper.R       — Outer auth/lock wrapper (ui)
#   R/server/server_auth.R  — Login, logout, signup, OAuth, lock/unlock
#   R/server/server_sessions.R  — Session management UI logic
#   R/server/server_projects.R  — Project management, tagging, dashboard
#   R/server/server_profile.R   — User profile, counters, dynamic title
#   R/server/server_stats.R     — Usage statistics, activity tracking
#   R/server/server_editor.R    — File click, rename, cursor, BIB/label helpers
#   R/server/server_compile.R   — Compile trigger, monitor loop, stop handler
#   R/server/server_review.R    — Review, comments, filter, PDF render, SyncTeX
#   R/server/server_misc.R      — Modals, imports, downloads, inserts, citations
#   R/server/server_chat.R      — AI chat, history, message stream
# =============================================================================

# ---- 1. Global libraries, options, and constants ----
source("R/00_globals.R")

# ---- 2. Bootstrap static assets (must run at startup, before shinyApp) ----
source("R/01_assets.R")

# ---- 3. SVG illustration helpers ----
source("R/02_illustrations.R")

# ---- 4. HTML page writers (generates www/*.html files) ----
source("R/03_html_pages.R")

# ---- 5. Authentication, database, and user-directory helpers ----
source("R/04_auth_db.R")

# ---- 6. Background compile worker and log parser ----
source("R/05_compile_worker.R")

# ---- 7. Main app UI (app_ui) ----
source("R/ui/ui_main.R")

# ---- 8. Outer auth/lock wrapper UI (defines `ui`) ----
source("R/ui/ui_wrapper.R")

# ---- 9. Server function ----
server <- function(input, output, session) {
  # Each sub-file is sourced with local = TRUE so it shares the server environment.
  # Order matters: auth must come first (defines rv, user_session, etc.).
  source("R/server/server_auth.R",     local = TRUE)
  source("R/server/server_sessions.R", local = TRUE)
  source("R/server/server_projects.R", local = TRUE)
  source("R/server/server_profile.R",  local = TRUE)
  source("R/server/server_stats.R",    local = TRUE)
  source("R/server/server_editor.R",   local = TRUE)
  source("R/server/server_compile.R",  local = TRUE)
  source("R/server/server_review.R",   local = TRUE)
  source("R/server/server_misc.R",     local = TRUE)
  source("R/server/server_chat.R",     local = TRUE)
}

# ---- 10. Run ----
options(shiny.port = 8000)
options(shiny.host = "127.0.0.1")

shinyApp(ui = ui, server = server)
